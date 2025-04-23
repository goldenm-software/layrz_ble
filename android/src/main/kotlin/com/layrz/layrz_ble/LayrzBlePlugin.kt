@file:Suppress("DEPRECATION", "SpellCheckingInspection", "MissingPermission", "KotlinConstantConditions")

package com.layrz.layrz_ble

import android.Manifest
import android.app.Activity
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothGatt
import android.bluetooth.BluetoothGattCallback
import android.bluetooth.BluetoothGattCharacteristic
import android.bluetooth.BluetoothGattDescriptor
import android.bluetooth.BluetoothManager
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanResult
import android.bluetooth.le.ScanSettings
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Context.RECEIVER_EXPORTED
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import androidx.core.app.ActivityCompat
import androidx.core.util.keyIterator
import io.flutter.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.PluginRegistry
import java.util.UUID

class LayrzBlePlugin : LayrzBlePlatformChannel, FlutterPlugin, ActivityAware, PluginRegistry.ActivityResultListener {
	private var callbackChannel: LayrzBleCallbackChannel? = null
	private var mainLooper: Handler? = null

	private lateinit var context: Context
	private var bluetooth: BluetoothManager? = null
	private var activity: Activity? = null

	private var isScanning = false
	private var isAdverising = false

	private val devices: MutableMap<String, BluetoothDevice> = mutableMapOf()
	private var connectedDevices: MutableMap<String, BluetoothGatt> = mutableMapOf()
	private var macFilter: String? = null

	private var connectCallback: ((Result<Boolean>) -> Unit)? = null
	private var mtuCallback: ((Result<Long?>) -> Unit)? = null
	private var readCallback: ((Result<ByteArray>) -> Unit)? = null
	private var writeCallback: ((Result<Boolean>) -> Unit)? = null

	private var servicesAndCharacteristics: MutableMap<String, List<BleService>> = mutableMapOf()

	companion object {
		private const val TAG = "LayrzBlePlugin/Android"
		private const val REQUEST_ENABLE_BT = 20040831
		val CCD_CHARACTERISTIC: UUID = UUID.fromString("00002902-0000-1000-8000-00805f9b34fb")
	}

	override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
		LayrzBlePlatformChannel.setUp(flutterPluginBinding.binaryMessenger, this)
		callbackChannel = LayrzBleCallbackChannel(flutterPluginBinding.binaryMessenger)
		context = flutterPluginBinding.applicationContext
		mainLooper = Handler(Looper.getMainLooper())
		bluetooth = context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager

		val intentFilter = IntentFilter(BluetoothAdapter.ACTION_STATE_CHANGED)
		intentFilter.addAction(BluetoothDevice.ACTION_BOND_STATE_CHANGED)

		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
			context.registerReceiver(broadcastReceiver, intentFilter, RECEIVER_EXPORTED)
		} else {
			context.registerReceiver(broadcastReceiver, intentFilter)
		}
	}

	override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
		bluetooth?.adapter?.bluetoothLeScanner?.stopScan(scanCallback)
		context.unregisterReceiver(broadcastReceiver)
		callbackChannel = null
		mainLooper = null
	}

	override fun getStatuses(callback: (Result<BtStatus>) -> Unit) {
		callback(Result.success(BtStatus(advertising = isAdverising, scanning = isScanning)))
	}

	override fun checkCapabilities(callback: (Result<Boolean>) -> Unit) {
		initalizeBluetoothIfRequired()

		val packageManager = context.packageManager
		val isBleSupported = packageManager.hasSystemFeature(PackageManager.FEATURE_BLUETOOTH_LE)
		if (!isBleSupported || bluetooth == null) {
			callback(Result.success(false))
			return
		}

		callback(Result.success(true))
		return
	}

	override fun checkScanPermissions(callback: (Result<Boolean>) -> Unit) {
		callback(Result.success(validateScanPerms()))
	}

	private fun validateScanPerms(): Boolean {
		val location = ActivityCompat.checkSelfPermission(
			context,
			Manifest.permission.ACCESS_FINE_LOCATION
		) == PackageManager.PERMISSION_GRANTED

		val bluetooth = ActivityCompat.checkSelfPermission(
			context,
			Manifest.permission.BLUETOOTH
		) == PackageManager.PERMISSION_GRANTED

		val bluetoothAdminOrScan = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
			ActivityCompat.checkSelfPermission(
				context,
				Manifest.permission.BLUETOOTH_SCAN
			) == PackageManager.PERMISSION_GRANTED
		} else {
			ActivityCompat.checkSelfPermission(
				context,
				Manifest.permission.BLUETOOTH_ADMIN
			) == PackageManager.PERMISSION_GRANTED
		}

		val bluetoothConnect = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
			ActivityCompat.checkSelfPermission(
				context,
				Manifest.permission.BLUETOOTH_CONNECT
			) == PackageManager.PERMISSION_GRANTED
		} else {
			true
		}

		return location && bluetooth && bluetoothAdminOrScan && bluetoothConnect
	}

	override fun checkAdvertisePermissions(callback: (Result<Boolean>) -> Unit) {
		callback(Result.success(validateAdvertisePerm()))
	}

	private fun validateAdvertisePerm(): Boolean {
		val location = ActivityCompat.checkSelfPermission(
			context,
			Manifest.permission.ACCESS_FINE_LOCATION
		) == PackageManager.PERMISSION_GRANTED

		val bluetooth = ActivityCompat.checkSelfPermission(
			context,
			Manifest.permission.BLUETOOTH
		) == PackageManager.PERMISSION_GRANTED

		val bluetoothConnect = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
			ActivityCompat.checkSelfPermission(
				context,
				Manifest.permission.BLUETOOTH_CONNECT
			) == PackageManager.PERMISSION_GRANTED
		} else {
			true
		}

		val bluetoothAdvertise = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
			ActivityCompat.checkSelfPermission(
				context,
				Manifest.permission.BLUETOOTH_ADVERTISE
			) == PackageManager.PERMISSION_GRANTED
		} else {
			true
		}

		return location && bluetooth && bluetoothConnect && bluetoothAdvertise
	}

	override fun startScan(macAddress: String?, servicesUuids: List<String>?, callback: (Result<Boolean>) -> Unit) {
		if (!validateScanPerms()) {
			Log.d(TAG, "Permissions not granted")
			callback(Result.success(false))
			return
		}

		if (isScanning) {
			Log.d(TAG, "Already scanning")
			callback(Result.success(true))
			return
		}

		initalizeBluetoothIfRequired()

		val adapter = bluetooth?.adapter ?: run {
			Log.d(TAG, "Bluetooth not supported")
			callback(Result.success(false))
			return
		}

		if (!adapter.isEnabled) {
			Log.d(TAG, "Bluetooth is not enabled")
			callback(Result.success(false))
			return
		}

		val scanner = adapter.bluetoothLeScanner ?: run {
			Log.d(TAG, "Bluetooth LE Scanner not supported")
			callback(Result.success(false))
			return
		}

		val settings = composeSettings(adapter)

		if (macAddress != null) macFilter = macAddress.uppercase()

		scanner.startScan(null, settings.build(), scanCallback)

		isScanning = true
		Log.d(TAG, "Started scanning")
		callback(Result.success(true))
		return
	}

	override fun stopScan(macAddress: String?, callback: (Result<Boolean>) -> Unit) {
		if (bluetooth == null) {
			Log.d(TAG, "Bluetooth not initialized or not supported")
			callback(Result.success(false))
			return
		}

		val adapter = bluetooth?.adapter ?: run {
			Log.d(TAG, "Bluetooth not supported")
			callback(Result.success(false))
			return
		}

		if (!adapter.isEnabled) {
			Log.d(TAG, "Bluetooth is not enabled")
			callback(Result.success(false))
			return
		}

		val scanner = adapter.bluetoothLeScanner ?: run {
			Log.d(TAG, "Bluetooth LE Scanner not supported")
			callback(Result.success(false))
			return
		}

		if (isScanning) {
			scanner.stopScan(scanCallback)
			isScanning = false
			Log.d(TAG, "Stopped scanning")
			macFilter = null
		}

		callback(Result.success(true))
		return
	}

	override fun connect(macAddress: String, callback: (Result<Boolean>) -> Unit) {
		if (!validateScanPerms()) {
			Log.d(TAG, "Permissions not granted")
			callback(Result.success(false))
			return
		}

		initalizeBluetoothIfRequired()

		val adapter = bluetooth?.adapter ?: run {
			Log.d(TAG, "Bluetooth not supported")
			callback(Result.success(false))
			return
		}

		if (!adapter.isEnabled) {
			Log.d(TAG, "Bluetooth is not enabled")
			callback(Result.success(false))
			return
		}

		val device = devices[macAddress.uppercase()] ?: run {
			Log.d(TAG, "Device not found")
			callback(Result.success(false))
			return
		}

		connectCallback = callback
		val gatt = device.connectGatt(context, false, gattCallback)
		gatt.connect()
	}

	override fun disconnect(macAddress: String?, callback: (Result<Boolean>) -> Unit) {
		if (!validateScanPerms()) {
			Log.d(TAG, "Permissions not granted")
			callback(Result.success(false))
			return
		}

		initalizeBluetoothIfRequired()

		val adapter = bluetooth?.adapter ?: run {
			Log.d(TAG, "Bluetooth not supported")
			callback(Result.success(false))
			return
		}

		if (!adapter.isEnabled) {
			Log.d(TAG, "Bluetooth is not enabled")
			callback(Result.success(false))
			return
		}

		if (macAddress == null) {
			for (device in connectedDevices.values) {
				device.disconnect()
				device.close()
			}

			connectedDevices.clear()
			servicesAndCharacteristics.clear()
			callback(Result.success(true))
			return
		}

		val gatt = connectedDevices[macAddress.uppercase()] ?: run {
			Log.d(TAG, "Device not found")
			callback(Result.success(false))
			return
		}

		gatt.disconnect()
		gatt.close()

		connectedDevices.remove(macAddress.uppercase())
		servicesAndCharacteristics.remove(macAddress.uppercase())
		callback(Result.success(true))
		return
	}

	override fun setMtu(macAddress: String, newMtu: Long, callback: (Result<Long?>) -> Unit) {
		if (!validateScanPerms()) {
			Log.d(TAG, "Permissions not granted")
			callback(Result.success(null))
			return
		}

		initalizeBluetoothIfRequired()

		val adapter = bluetooth?.adapter ?: run {
			Log.d(TAG, "Bluetooth not supported")
			callback(Result.success(null))
			return
		}

		if (!adapter.isEnabled) {
			Log.d(TAG, "Bluetooth is not enabled")
			callback(Result.success(null))
			return
		}

		val gatt = connectedDevices[macAddress.uppercase()] ?: run {
			Log.d(TAG, "Device not found")
			callback(Result.success(null))
			return
		}

		mtuCallback = callback
		gatt.requestMtu(newMtu.toInt())
	}

	override fun discoverServices(macAddress: String, callback: (Result<List<BtService>>) -> Unit) {
		val serviceAndCharacteristics = servicesAndCharacteristics[macAddress.uppercase()] ?: run {
			Log.d(TAG, "Device not found")
			callback(Result.success(emptyList()))
			return
		}

		if (serviceAndCharacteristics.isEmpty()) {
			Log.d(TAG, "No services found")
			callback(Result.success(emptyList()))
			return
		}

		val services = serviceAndCharacteristics.map { it.obj }
		callback(Result.success(services))
		return
	}

	override fun readCharacteristic(
		macAddress: String,
		serviceUuid: String,
		characteristicUuid: String,
		callback: (Result<ByteArray>) -> Unit
	) {
		val gatt = connectedDevices[macAddress.uppercase()] ?: run {
			Log.d(TAG, "Device not found")
			callback(Result.success(byteArrayOf()))
			return
		}

		val service = gatt.getService(UUID.fromString(serviceUuid)) ?: run {
			Log.d(TAG, "Service not found")
			callback(Result.success(byteArrayOf()))
			return
		}

		val characteristic = service.getCharacteristic(UUID.fromString(characteristicUuid)) ?: run {
			Log.d(TAG, "Characteristic not found")
			callback(Result.success(byteArrayOf()))
			return
		}

		if (characteristic.properties and BluetoothGattCharacteristic.PROPERTY_READ == 0) {
			Log.d(TAG, "Characteristic not readable")
			callback(Result.success(byteArrayOf()))
			return
		}

		readCallback = callback
		gatt.readCharacteristic(characteristic)
	}

	override fun writeCharacteristic(
		macAddress: String,
		serviceUuid: String,
		characteristicUuid: String,
		payload: ByteArray,
		withResponse: Boolean,
		callback: (Result<Boolean>) -> Unit
	) {
		val gatt = connectedDevices[macAddress.uppercase()] ?: run {
			Log.d(TAG, "Device not found")
			callback(Result.success(false))
			return
		}

		val service = gatt.getService(UUID.fromString(serviceUuid)) ?: run {
			Log.d(TAG, "Service not found")
			callback(Result.success(false))
			return
		}

		val characteristic = service.getCharacteristic(UUID.fromString(characteristicUuid)) ?: run {
			Log.d(TAG, "Characteristic not found")
			callback(Result.success(false))
			return
		}

		val type = if (withResponse) {
			BluetoothGattCharacteristic.WRITE_TYPE_DEFAULT
		} else {
			BluetoothGattCharacteristic.WRITE_TYPE_NO_RESPONSE
		}

		if (withResponse) {
			if (characteristic.properties and BluetoothGattCharacteristic.PROPERTY_WRITE == 0) {
				Log.d(TAG, "Characteristic not writable with response")
				callback(Result.success(false))
				return
			}
		} else {
			if (characteristic.properties and BluetoothGattCharacteristic.PROPERTY_WRITE_NO_RESPONSE == 0) {
				Log.d(TAG, "Characteristic not writable without response")
				callback(Result.success(false))
				return
			}
		}

		writeCallback = callback
		if (Build.VERSION.SDK_INT > Build.VERSION_CODES.TIRAMISU) {
			gatt.writeCharacteristic(characteristic, payload, type)
		} else {
			characteristic.value = payload
			characteristic.writeType = type
			gatt.writeCharacteristic(characteristic)
		}
	}

	override fun startNotify(
		macAddress: String,
		serviceUuid: String,
		characteristicUuid: String,
		callback: (Result<Boolean>) -> Unit
	) {
		val gatt = connectedDevices[macAddress.uppercase()] ?: run {
			Log.d(TAG, "Device not found")
			callback(Result.success(false))
			return
		}

		val service = gatt.getService(UUID.fromString(serviceUuid)) ?: run {
			Log.d(TAG, "Service not found")
			callback(Result.success(false))
			return
		}

		val characteristic = service.getCharacteristic(UUID.fromString(characteristicUuid)) ?: run {
			Log.d(TAG, "Characteristic not found")
			callback(Result.success(false))
			return
		}

		val notifResult = gatt.setCharacteristicNotification(characteristic, true)
		if (!notifResult) {
			Log.d(TAG, "Failed to set characteristic notification")
			callback(Result.success(false))
			return
		}

		val descriptor = characteristic.getDescriptor(CCD_CHARACTERISTIC) ?: run {
			Log.d(TAG, "Descriptor not found")
			callback(Result.success(false))
			return
		}
		if (descriptor.value.contentEquals(BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE)) {
			Log.d(TAG, "Descriptor already enabled")
			callback(Result.success(true))
			return
		}

		descriptor.value = BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE
		gatt.writeDescriptor(descriptor)
		callback(Result.success(true))
		return
	}

	override fun stopNotify(
		macAddress: String,
		serviceUuid: String,
		characteristicUuid: String,
		callback: (Result<Boolean>) -> Unit
	) {
		val gatt = connectedDevices[macAddress.uppercase()] ?: run {
			Log.d(TAG, "Device not found")
			callback(Result.success(false))
			return
		}

		val service = gatt.getService(UUID.fromString(serviceUuid)) ?: run {
			Log.d(TAG, "Service not found")
			callback(Result.success(false))
			return
		}

		val characteristic = service.getCharacteristic(UUID.fromString(characteristicUuid)) ?: run {
			Log.d(TAG, "Characteristic not found")
			callback(Result.success(false))
			return
		}

		val notifResult = gatt.setCharacteristicNotification(characteristic, false)
		if (!notifResult) {
			Log.d(TAG, "Failed to set characteristic notification")
			callback(Result.success(false))
			return
		}

		val descriptor = characteristic.getDescriptor(CCD_CHARACTERISTIC) ?: run {
			Log.d(TAG, "Descriptor not found")
			callback(Result.success(false))
			return
		}

		if (descriptor.value.contentEquals(BluetoothGattDescriptor.DISABLE_NOTIFICATION_VALUE)) {
			Log.d(TAG, "Descriptor already disabled")
			callback(Result.success(true))
			return
		}

		descriptor.value = BluetoothGattDescriptor.DISABLE_NOTIFICATION_VALUE
		gatt.writeDescriptor(descriptor)
		callback(Result.success(true))
		return
	}

	override fun onAttachedToActivity(binding: ActivityPluginBinding) {
		activity = binding.activity
		binding.addActivityResultListener(this)
	}

	override fun onDetachedFromActivityForConfigChanges() {}
	override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {}
	override fun onDetachedFromActivity() {
		activity = null
	}

	override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
		Log.d(TAG, "onActivityResult $requestCode $resultCode $data")
		return false
	}

	private fun notifyOff() {
		Log.i(TAG, "Bluetooth is turned off")
		mainLooper?.post {
			callbackChannel?.onBluetoothOff {}
		}
	}

	private fun notifyOn() {
		Log.i(TAG, "Bluetooth is turned on")
		mainLooper?.post {
			callbackChannel?.onBluetoothOn {}
		}
	}

	private fun forceStopAll() {
		Log.i(TAG, "Bluetooth is stopping")
//		gattServer?.clearServices()
//		gattServer?.close()
//		gattServer = null
//
//		devices.clear()
//		servicesAndCharacteristics.clear()
//		gattServices.clear()
//		gattDevices.clear()
//
		val bluetooth = bluetooth ?: return
		if (isScanning) {
			bluetooth.adapter.bluetoothLeScanner.stopScan(scanCallback)
		}
	}

	private val scanCallback = object : ScanCallback() {
		override fun onScanResult(callbackType: Int, result: ScanResult?) {
			super.onScanResult(callbackType, result)
			val scanRecord = result?.scanRecord ?: return

			val device = result.device
			val macAddress = device.address.uppercase()

			if (macFilter != null && macAddress != macFilter) return

			val name = scanRecord.deviceName ?: device.name ?: "Unknown"

			val rssi = result.rssi
			val rec = result.scanRecord

			val rawManufacturerData = rec?.manufacturerSpecificData
			val manufacturerData = mutableListOf<BtManufacturerData>()

			if (rawManufacturerData != null) {
				for (key in rawManufacturerData.keyIterator()) {
					val data = rawManufacturerData.get(key)
					if (data != null) {
						manufacturerData.add(BtManufacturerData(companyId = key.toLong(), data = data))
					}
				}
			}

			val serviceData = mutableListOf<BtServiceData>()
			for ((uuid, data) in rec?.serviceData ?: emptyMap()) {
				if (uuid == null) continue
				serviceData.add(BtServiceData(uuid = castServiceUuid(uuid.uuid).toLong(), data = data))
			}

			var txPower: Int? = scanRecord.txPowerLevel
			if (txPower == Int.MIN_VALUE) {
				txPower = null
			}

			mainLooper?.post {
				callbackChannel?.onScanResult(
					deviceArg = BtDevice(
						name = name,
						macAddress = macAddress,
						rssi = rssi.toLong(),
						manufacturerData = manufacturerData,
						serviceData = serviceData,
						txPower = txPower?.toLong()
					)
				) {}
			}

			devices[macAddress] = device
		}
	}

	private var gattCallback = object : BluetoothGattCallback() {
		override fun onCharacteristicChanged(
			gatt: BluetoothGatt,
			characteristic: BluetoothGattCharacteristic,
			value: ByteArray
		) {
			super.onCharacteristicChanged(gatt, characteristic, value)
			val macAddress = gatt.device.address.uppercase()
			val serviceUuid = standarizeUuid(characteristic.service.uuid)
			val characteristicUuid = standarizeUuid(characteristic.uuid)

			mainLooper?.post {
				callbackChannel?.onCharacteristicUpdate(
					notificationArg = BtCharacteristicNotification(
						macAddress = macAddress,
						serviceUuid = serviceUuid,
						characteristicUuid = characteristicUuid,
						value = value
					)
				) {}
			}
		}

		override fun onCharacteristicRead(
			gatt: BluetoothGatt,
			characteristic: BluetoothGattCharacteristic,
			value: ByteArray,
			status: Int
		) {
			super.onCharacteristicRead(gatt, characteristic, value, status)
			readCallback?.invoke(Result.success(value))
			readCallback = null
			return
		}

		override fun onCharacteristicWrite(
			gatt: BluetoothGatt?,
			characteristic: BluetoothGattCharacteristic?,
			status: Int
		) {
			super.onCharacteristicWrite(gatt, characteristic, status)
			if (gatt == null || characteristic == null) return
			writeCallback?.invoke(Result.success(status == BluetoothGatt.GATT_SUCCESS))
			writeCallback = null
		}

		override fun onMtuChanged(gatt: BluetoothGatt?, mtu: Int, status: Int) {
			super.onMtuChanged(gatt, mtu, status)
			if (gatt == null) return

			if (status == BluetoothGatt.GATT_SUCCESS) {
				Log.d(TAG, "MTU changed to $mtu")

				mtuCallback?.invoke(Result.success(mtu.toLong()))
				mtuCallback = null
				return
			}

			Log.d(TAG, "MTU change failed $status")
			mtuCallback?.invoke(Result.success(null))
			mtuCallback = null
		}

		override fun onServicesDiscovered(gatt: BluetoothGatt?, status: Int) {
			super.onServicesDiscovered(gatt, status)
			if (gatt == null) return
			val macAddress = gatt.device.address.uppercase()

			if (status == BluetoothGatt.GATT_SUCCESS) {
				for (service in gatt.services) {
					val characteristics = mutableListOf<BtCharacteristic>()
					for (characteristic in service.characteristics) {
						val properties = mutableListOf<String>()
						if (characteristic.properties and BluetoothGattCharacteristic.PROPERTY_READ != 0) {
							properties.add("READ")
						}
						if (characteristic.properties and BluetoothGattCharacteristic.PROPERTY_WRITE != 0) {
							properties.add("WRITE")
						}
						if (characteristic.properties and BluetoothGattCharacteristic.PROPERTY_WRITE_NO_RESPONSE != 0) {
							properties.add("WRITE_WO_RSP")
						}
						if (characteristic.properties and BluetoothGattCharacteristic.PROPERTY_NOTIFY != 0) {
							properties.add("NOTIFY")
						}
						if (characteristic.properties and BluetoothGattCharacteristic.PROPERTY_INDICATE != 0) {
							properties.add("INDICATE")
						}
						if (characteristic.properties and BluetoothGattCharacteristic.PROPERTY_SIGNED_WRITE != 0) {
							properties.add("AUTH_SIGN_WRITES")
						}
						if (characteristic.properties and BluetoothGattCharacteristic.PROPERTY_BROADCAST != 0) {
							properties.add("BROADCAST")
						}
						if (characteristic.properties and BluetoothGattCharacteristic.PROPERTY_EXTENDED_PROPS != 0) {
							properties.add("EXTENDED_PROP")
						}

						characteristics.add(
							BtCharacteristic(
								uuid = standarizeUuid(characteristic.uuid),
								properties = properties
							)
						)
					}

					if (servicesAndCharacteristics[macAddress] == null) {
						servicesAndCharacteristics[macAddress] = mutableListOf()
					}

					servicesAndCharacteristics[macAddress] = servicesAndCharacteristics[macAddress]!!.plus(
						BleService(
							service = service,
							obj = BtService(
								uuid = standarizeUuid(service.uuid),
								characteristics = characteristics
							)
						)
					)
				}

				Log.d(TAG, "onServicesDiscovered success")
				connectCallback?.invoke(Result.success(true))
				connectCallback = null

				connectedDevices[macAddress] = gatt

				mainLooper?.post {
					callbackChannel?.onConnected(
						deviceArg = BtDevice(
							macAddress = macAddress,
							name = gatt.device.name ?: "Unknown",
							manufacturerData = emptyList(),
							serviceData = emptyList(),
						)
					) {}
				}
				return
			}

			Log.d(TAG, "onServicesDiscovered failed $status")
			gatt.close()
			connectCallback?.invoke(Result.success(false))
			connectCallback = null

			mainLooper?.post {
				callbackChannel?.onDisconnected(
					deviceArg = BtDevice(
						macAddress = macAddress,
						name = gatt.device.name ?: "Unknown",
						manufacturerData = emptyList(),
						serviceData = emptyList(),
					)
				) {}
			}
			return
		}

		override fun onConnectionStateChange(gatt: BluetoothGatt, status: Int, newState: Int) {
			super.onConnectionStateChange(gatt, status, newState)
			Log.d(TAG, "onConnectionStateChange $status $newState")
			when (newState) {
				BluetoothGatt.STATE_CONNECTED -> {
					Log.d(TAG, "GATT connection success, discovering services.")
					gatt.discoverServices()
				}

				BluetoothGatt.STATE_DISCONNECTED -> {
					Log.d(TAG, "GATT disconnected")
					gatt.close()
					connectCallback?.invoke(Result.success(false))
					connectCallback = null

					connectedDevices.remove(gatt.device.address.uppercase())
					servicesAndCharacteristics.remove(gatt.device.address.uppercase())
					mainLooper?.post {
						callbackChannel?.onDisconnected(
							deviceArg = BtDevice(
								macAddress = gatt.device.address.uppercase(),
								name = gatt.device.name ?: "Unknown",
								manufacturerData = emptyList(),
								serviceData = emptyList(),
							)
						) {}
					}
				}

				else -> Log.d(TAG, "GATT unknown status $newState")
			}
		}
	}

	private var broadcastReceiver = object : BroadcastReceiver() {
		override fun onReceive(context: Context?, intent: Intent?) {
			Log.d(TAG, "onReceive $intent")
			if (intent?.action == BluetoothAdapter.ACTION_STATE_CHANGED) {
				when (intent.getIntExtra(BluetoothAdapter.EXTRA_STATE, BluetoothAdapter.ERROR)) {
					BluetoothAdapter.STATE_OFF -> notifyOff()
					BluetoothAdapter.STATE_TURNING_OFF -> forceStopAll()
					BluetoothAdapter.STATE_ON -> notifyOn()
					else -> Log.i(TAG, "Bluetooth state changed")
				}
			}
		}
	}

	private fun initalizeBluetoothIfRequired() {
		if (bluetooth == null) {
			bluetooth = context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
		}
	}

	private fun composeSettings(adapter: BluetoothAdapter): ScanSettings.Builder {
		val settings = ScanSettings.Builder()
		// settings.setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY)
		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && adapter.isLeExtendedAdvertisingSupported) {
			Log.d(TAG, "Bluetooth 5.0 supported, using extended advertising")
			settings.setLegacy(false)
			settings.setPhy(ScanSettings.PHY_LE_ALL_SUPPORTED)
		} else {
			Log.d(TAG, "Bluetooth 5.0 not supported, using legacy advertising")
		}

		return settings
	}
}
