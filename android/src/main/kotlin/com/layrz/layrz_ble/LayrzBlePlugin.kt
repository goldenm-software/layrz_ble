@file:Suppress("DEPRECATION", "SpellCheckingInspection", "MissingPermission")

package com.layrz.layrz_ble


import android.Manifest
import android.app.Activity
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothGatt
import android.bluetooth.BluetoothGattCallback
import android.bluetooth.BluetoothGattCharacteristic
import android.bluetooth.BluetoothGattDescriptor
import android.bluetooth.BluetoothGattServer
import android.bluetooth.BluetoothGattServerCallback
import android.bluetooth.BluetoothGattService
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothProfile
import android.bluetooth.le.AdvertiseCallback
import android.bluetooth.le.AdvertiseData
import android.bluetooth.le.AdvertiseSettings
import android.bluetooth.le.AdvertisingSet
import android.bluetooth.le.AdvertisingSetCallback
import android.bluetooth.le.AdvertisingSetParameters
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanResult
import android.bluetooth.le.ScanSettings
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.ParcelUuid
import androidx.annotation.RequiresApi
import androidx.core.app.ActivityCompat
import androidx.core.app.ActivityCompat.startActivityForResult
import androidx.core.util.keyIterator
import io.flutter.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import java.util.UUID

class LayrzBlePlugin : FlutterPlugin, MethodCallHandler, ActivityAware,
											 PluginRegistry.ActivityResultListener {
	private lateinit var checkCapabilitiesChannel: MethodChannel
	private lateinit var checkScanPermissionsChannel: MethodChannel
	private lateinit var checkAdvertisePermissionsChannel: MethodChannel
	private lateinit var startScanChannel: MethodChannel
	private lateinit var stopScanChannel: MethodChannel
	private lateinit var connectChannel: MethodChannel
	private lateinit var disconnectChannel: MethodChannel
	private lateinit var discoverServicesChannel: MethodChannel
	private lateinit var setMtuChannel: MethodChannel
	private lateinit var writeCharacteristicChannel: MethodChannel
	private lateinit var readCharacteristicChannel: MethodChannel
	private lateinit var startNotifyChannel: MethodChannel
	private lateinit var stopNotifyChannel: MethodChannel
	private lateinit var eventsChannel: MethodChannel
	private lateinit var startAdvertiseChannel: MethodChannel
	private lateinit var stopAdvertiseChannel: MethodChannel
	private lateinit var respondWriteRequestChannel: MethodChannel
	private lateinit var respondReadRequestChannel: MethodChannel

	private lateinit var context: android.content.Context
	private var bluetooth: BluetoothManager? = null

	private var activity: Activity? = null

	private var startScanResult: Result? = null
	private var stopScanResult: Result? = null
	private var connectResult: Result? = null
	private var disconnectResult: Result? = null
	private var discoverServicesResult: Result? = null
	private var setMtuResult: Result? = null
	private var writeCharacteristicResult: Result? = null
	private var readCharacteristicResult: Result? = null
	private var startNotifyResult: Result? = null
	private var stopNotifyResult: Result? = null
	private var startAdvertiseResult: Result? = null

	private var coroutine: Job? = null

	// Bluetooth device connection
	private var filteredMacAddress: String? = null
	private val devices: HashMap<String, BluetoothDevice> = HashMap()
	private var searchingMacAddress: String? = null
	private var gatt: BluetoothGatt? = null
	private var connectedDevice: BluetoothDevice? = null
	private var connectable: Boolean = false
	private var gattServer: BluetoothGattServer? = null
	private var gattDevices: MutableMap<String, BluetoothDevice> = mutableMapOf()
	private var gattServices: MutableList<BluetoothGattService> = mutableListOf()

	private var isScanning = false
	private var lastOperation: LastOperation? = null
	private var currentNotifications: MutableList<String> = mutableListOf()
	private var servicesAndCharacteristics: MutableMap<String, BleService> = mutableMapOf()

	private val scanCallback = object : ScanCallback() {
		override fun onScanResult(callbackType: Int, result: ScanResult?) {
			super.onScanResult(callbackType, result)
			val scanRecord = result?.scanRecord
			if (result == null) {
				Log.d(TAG, "No result")
				return
			}

			val device = result.device
			val macAddress = device.address.uppercase()

			if (filteredMacAddress != null && macAddress != filteredMacAddress) return

			val name = scanRecord?.deviceName ?: device.name ?: "Unknown"
			val rssi = result.rssi
			val rec = result.scanRecord

			val rawManufacturerData = rec?.manufacturerSpecificData
			val manufacturerData = mutableListOf<Map<String, Any>>()

			if (rawManufacturerData != null) {
				for (key in rawManufacturerData.keyIterator()) {
					val data = rawManufacturerData.get(key)
					if (data != null) {
						manufacturerData.add(
							mapOf<String, Any>(
								"companyId" to key,
								"data" to data
							)
						)
					}
				}
			}

			val serviceData = mutableListOf<Map<String, Any>>()
			for ((uuid, data) in rec?.serviceData ?: emptyMap()) {
				if (uuid == null) continue
				serviceData.add(
					mapOf(
						"uuid" to castServiceUuid(uuid.uuid),
						"data" to data
					)
				)
			}

			var txPower: Int? = scanRecord?.txPowerLevel
			if (txPower == Int.MIN_VALUE) {
				txPower = null
			}

			Handler(Looper.getMainLooper()).post {
				eventsChannel.invokeMethod(
					"onScan",
					mapOf(
						"name" to name,
						"macAddress" to macAddress,
						"rssi" to rssi,
						"manufacturerData" to manufacturerData,
						"serviceData" to serviceData,
						"txPower" to txPower,
					)
				)
			}

			devices[macAddress] = device
		}
	}

	private val gattCallback = object : BluetoothGattCallback() {
		override fun onConnectionStateChange(
			gatt: BluetoothGatt?,
			status: Int,
			newState: Int
		) {
			super.onConnectionStateChange(gatt, status, newState)
			if (connectedDevice == null) return
			if (lastOperation != LastOperation.CONNECT) {
				if (status == BluetoothGatt.STATE_DISCONNECTED) {
					Log.d(TAG, "Disconnected")
					gatt?.disconnect()
					connectedDevice = null
					servicesAndCharacteristics.clear()
					Handler(Looper.getMainLooper()).post {
						eventsChannel.invokeMethod(
							"onEvent",
							"DISCONNECTED"
						)
					}
					return
				}
			}

			if (newState == BluetoothProfile.STATE_CONNECTED) {
				connectedDevice = gatt!!.device
				servicesAndCharacteristics.clear()
				Log.d(TAG, "Connected to ${connectedDevice!!.address}, discovering services")
				gatt.discoverServices()
			} else {
				Log.d(TAG, "Connection failed")
				connectResult?.success(false)
				connectResult = null
			}

			coroutine?.cancel()
			coroutine = null
		}

		override fun onServicesDiscovered(gatt: BluetoothGatt?, status: Int) {
			super.onServicesDiscovered(gatt, status)
			if (connectedDevice == null) return
			if (lastOperation != LastOperation.CONNECT) return
			if (gatt == null) return

			if (status == BluetoothGatt.GATT_SUCCESS) {
				for (service in gatt.services) {
					val characteristics = mutableListOf<BleCharacteristic>()
					for (characteristic in service.characteristics) {
						val properties = characteristic.properties
						val propertyList: MutableList<String> = mutableListOf()

						if (properties and BluetoothGattCharacteristic.PROPERTY_READ != 0) {
							propertyList.add("READ")
						}
						if (properties and BluetoothGattCharacteristic.PROPERTY_WRITE != 0) {
							propertyList.add("WRITE")
						}
						if (properties and BluetoothGattCharacteristic.PROPERTY_WRITE_NO_RESPONSE != 0) {
							propertyList.add("WRITE_WO_RSP")
						}
						if (properties and BluetoothGattCharacteristic.PROPERTY_NOTIFY != 0) {
							propertyList.add("NOTIFY")
						}
						if (properties and BluetoothGattCharacteristic.PROPERTY_INDICATE != 0) {
							propertyList.add("INDICATE")
						}
						if (properties and BluetoothGattCharacteristic.PROPERTY_SIGNED_WRITE != 0) {
							propertyList.add("AUTH_SIGN_WRITES")
						}
						if (properties and BluetoothGattCharacteristic.PROPERTY_BROADCAST != 0) {
							propertyList.add("BROADCAST")
						}
						if (properties and BluetoothGattCharacteristic.PROPERTY_EXTENDED_PROPS != 0) {
							propertyList.add("EXTENDED_PROP")
						}

						characteristics.add(
							BleCharacteristic(
								characteristic = characteristic,
								uuid = standarizeUuid(characteristic.uuid),
								properties = propertyList
							)
						)
					}

					servicesAndCharacteristics[standarizeUuid(service.uuid)] = BleService(
						service = service,
						uuid = standarizeUuid(service.uuid),
						characteristics = characteristics
					)
				}

				Log.d(TAG, "Services discovered")
				connectResult?.success(true)
				connectResult = null
			} else {
				Log.d(TAG, "Discover services failed")
				connectResult?.success(false)
				connectResult = null
			}
			coroutine?.cancel()
			coroutine = null
		}

		override fun onMtuChanged(gatt: BluetoothGatt?, mtu: Int, status: Int) {
			super.onMtuChanged(gatt, mtu, status)

			if (lastOperation != LastOperation.SET_MTU) return

			if (status == BluetoothGatt.GATT_SUCCESS) {
				setMtuResult?.success(mtu)
			} else {
				Log.d(TAG, "MTU change failed")
				setMtuResult?.success(null)
			}

			setMtuResult = null
			coroutine?.cancel()
		}

		override fun onCharacteristicWrite(
			gatt: BluetoothGatt?,
			characteristic: BluetoothGattCharacteristic?,
			status: Int
		) {
			super.onCharacteristicWrite(gatt, characteristic, status)

			if (lastOperation != LastOperation.WRITE_CHARACTERISTIC) return

			if (status == BluetoothGatt.GATT_SUCCESS) {
				Log.d(TAG, "Write successful")
				writeCharacteristicResult?.success(true)
			} else {
				Log.d(TAG, "Characteristic write failed")
				writeCharacteristicResult?.success(false)
			}
			writeCharacteristicResult = null
			coroutine?.cancel()
			coroutine = null
		}

		@Deprecated("Deprecated in Java")
		override fun onCharacteristicRead(
			gatt: BluetoothGatt,
			characteristic: BluetoothGattCharacteristic,
			status: Int
		) {
			super.onCharacteristicRead(gatt, characteristic, status)

			if (lastOperation != LastOperation.READ_CHARACTERISTIC) return

			if (status == BluetoothGatt.GATT_SUCCESS) {
				readCharacteristicResult?.success(characteristic.value)
			} else {
				Log.d(TAG, "Characteristic read failed")
				readCharacteristicResult?.success(null)
			}

			readCharacteristicResult = null
			coroutine?.cancel()
			coroutine = null
		}

		@Deprecated("Deprecated in Java")
		override fun onCharacteristicChanged(
			gatt: BluetoothGatt,
			characteristic: BluetoothGattCharacteristic
		) {
			super.onCharacteristicChanged(gatt, characteristic)
			Log.d(
				TAG,
				"onCharacteristicChanged ${characteristic.uuid} - ${characteristic.value.size}"
			)

			Handler(Looper.getMainLooper()).post {
				eventsChannel.invokeMethod(
					"onNotify",
					mapOf(
						"serviceUuid" to characteristic.service.uuid.toString().uppercase().trim(),
						"characteristicUuid" to characteristic.uuid.toString().uppercase().trim(),
						"value" to characteristic.value
					)
				)
			}
		}
	}

	private val advertiseCallback = object : AdvertiseCallback() {
		override fun onStartSuccess(settingsInEffect: AdvertiseSettings?) {
			super.onStartSuccess(settingsInEffect)
			Log.i(TAG, "Advertise started successfully")

			startAdvertiseResult?.success(true)
			startAdvertiseResult = null

			if (bluetooth == null) return;
			if (gattServer != null) {
				Log.w(TAG, "Gatt server already exists")
				return
			}

			gattServer = bluetooth!!.openGattServer(context, gattServerCallback)
			for (service in gattServices) {
				Log.i(TAG, "Adding ${service.uuid} to gatt server (Bluetooth Legacy)")
				gattServer!!.addService(service)
			}
		}

		override fun onStartFailure(errorCode: Int) {
			super.onStartFailure(errorCode)
			Log.w(TAG, "Advertise failed with error code: $errorCode")
			startAdvertiseResult?.success(false)
			startAdvertiseResult = null
		}
	}

	private val advertiseSetCallback = @RequiresApi(Build.VERSION_CODES.O)
	object : AdvertisingSetCallback() {
		override fun onAdvertisingSetStarted(advertisingSet: AdvertisingSet?, txPower: Int, status: Int) {
			super.onAdvertisingSetStarted(advertisingSet, txPower, status)

			if (status == ADVERTISE_SUCCESS) {
				Log.i(TAG, "Advertise set started successfully")
				startAdvertiseResult?.success(true)
				startAdvertiseResult = null

				if (bluetooth == null) return;
				if (gattServer != null) {
					Log.w(TAG, "Gatt server already exists")
					return
				}

				gattServer = bluetooth!!.openGattServer(context, gattServerCallback)
				for (service in gattServices) {
					Log.i(TAG, "Adding ${service.uuid} to gatt server (Bluetooth 5.0)")
					gattServer!!.addService(service)
				}
			} else {
				Log.w(TAG, "Advertise set failed with error code: $status")
				startAdvertiseResult?.success(false)
				startAdvertiseResult = null
			}
		}

		override fun onAdvertisingSetStopped(advertisingSet: AdvertisingSet?) {
			super.onAdvertisingSetStopped(advertisingSet)

			Log.i(TAG, "Advertise set stopped")
		}
	}

	private var gattServerCallback = object : BluetoothGattServerCallback() {
		override fun onConnectionStateChange(
			device: BluetoothDevice?,
			status: Int,
			newState: Int
		) {
			super.onConnectionStateChange(device, status, newState)
			if (device == null) return

			when (newState) {
				BluetoothProfile.STATE_CONNECTED -> {
					if (!gattDevices.containsKey(device.address)) {
						gattDevices[device.address] = device
					}

					Handler(Looper.getMainLooper()).post {
						eventsChannel.invokeMethod(
							"onGattConnected",
							mapOf(
								"macAddress" to device.address,
								"name" to device.name
							)
						)
					}
				}

				BluetoothProfile.STATE_DISCONNECTED -> {
					if (gattDevices.containsKey(device.address)) {
						gattDevices.remove(device.address)
					}

					Handler(Looper.getMainLooper()).post {
						eventsChannel.invokeMethod("onGattDisconnected", device.address)
					}
				}

				else -> {
					Log.i(TAG, "Device ${device.name} - ${device.address} state changed to $newState")
				}
			}
		}

		override fun onCharacteristicWriteRequest(
			device: BluetoothDevice?,
			requestId: Int,
			characteristic: BluetoothGattCharacteristic?,
			preparedWrite: Boolean,
			responseNeeded: Boolean,
			offset: Int,
			value: ByteArray?
		) {
			super.onCharacteristicWriteRequest(
				device,
				requestId,
				characteristic,
				preparedWrite,
				responseNeeded,
				offset,
				value
			)

			if (device == null || characteristic == null) return

			Handler(Looper.getMainLooper()).post {
				eventsChannel.invokeMethod(
					"onGattWriteRequest",
					mapOf(
						"macAddress" to device.address,
						"requestId" to requestId,
						"offset" to offset,
						"characteristicUuid" to standarizeUuid(characteristic.uuid),
						"data" to value,
						"responseNeeded" to responseNeeded,
						"preparedWrite" to preparedWrite
					)
				)
			}
		}

		override fun onCharacteristicReadRequest(
			device: BluetoothDevice?,
			requestId: Int,
			offset: Int,
			characteristic: BluetoothGattCharacteristic?
		) {
			super.onCharacteristicReadRequest(device, requestId, offset, characteristic)

			if (device == null || characteristic == null) return

			Handler(Looper.getMainLooper()).post {
				eventsChannel.invokeMethod(
					"onGattReadRequest",
					mapOf(
						"macAddress" to device.address,
						"requestId" to requestId,
						"offset" to offset,
						"characteristicUuid" to standarizeUuid(characteristic.uuid)
					)
				)
			}
		}

		override fun onMtuChanged(device: BluetoothDevice?, mtu: Int) {
			super.onMtuChanged(device, mtu)

			if (device == null) return

			Handler(Looper.getMainLooper()).post {
				eventsChannel.invokeMethod(
					"onGattMtuChanged",
					mapOf(
						"macAddress" to device.address,
						"mtu" to mtu
					)
				)
			}
		}
	}

	override fun onDetachedFromActivity() {
		Log.d(TAG, "onDetachedFromActivity")
		activity = null
	}

	override fun onAttachedToActivity(binding: ActivityPluginBinding) {
		Log.d(TAG, "onAttachedToActivity")
		activity = binding.activity
	}

	override fun onDetachedFromActivityForConfigChanges() {
		Log.d(TAG, "onDetachedFromActivityForConfigChanges")
		activity = null
	}

	override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
		Log.d(TAG, "onReattachedToActivityForConfigChanges")
		activity = binding.activity
	}


	companion object {
		private const val TAG = "LayrzBlePlugin/Android"
		private const val REQUEST_ENABLE_BT = 20040831
		val CCD_CHARACTERISTIC: UUID = UUID.fromString("00002902-0000-1000-8000-00805f9b34fb")
	}

	override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
		checkCapabilitiesChannel =
			MethodChannel(flutterPluginBinding.binaryMessenger, "com.layrz.ble.checkCapabilities")
		checkCapabilitiesChannel.setMethodCallHandler(this)
		checkScanPermissionsChannel = MethodChannel(
			flutterPluginBinding.binaryMessenger,
			"com.layrz.ble.checkScanPermissions"
		)
		checkScanPermissionsChannel.setMethodCallHandler(this)
		checkAdvertisePermissionsChannel = MethodChannel(
			flutterPluginBinding.binaryMessenger,
			"com.layrz.ble.checkAdvertisePermissions"
		)
		checkAdvertisePermissionsChannel.setMethodCallHandler(this)
		startScanChannel =
			MethodChannel(flutterPluginBinding.binaryMessenger, "com.layrz.ble.startScan")
		startScanChannel.setMethodCallHandler(this)
		stopScanChannel =
			MethodChannel(flutterPluginBinding.binaryMessenger, "com.layrz.ble.stopScan")
		stopScanChannel.setMethodCallHandler(this)
		connectChannel =
			MethodChannel(flutterPluginBinding.binaryMessenger, "com.layrz.ble.connect")
		connectChannel.setMethodCallHandler(this)
		disconnectChannel =
			MethodChannel(flutterPluginBinding.binaryMessenger, "com.layrz.ble.disconnect")
		disconnectChannel.setMethodCallHandler(this)
		discoverServicesChannel =
			MethodChannel(flutterPluginBinding.binaryMessenger, "com.layrz.ble.discoverServices")
		discoverServicesChannel.setMethodCallHandler(this)
		setMtuChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.layrz.ble.setMtu")
		setMtuChannel.setMethodCallHandler(this)
		writeCharacteristicChannel =
			MethodChannel(flutterPluginBinding.binaryMessenger, "com.layrz.ble.writeCharacteristic")
		writeCharacteristicChannel.setMethodCallHandler(this)
		readCharacteristicChannel =
			MethodChannel(flutterPluginBinding.binaryMessenger, "com.layrz.ble.readCharacteristic")
		readCharacteristicChannel.setMethodCallHandler(this)
		startNotifyChannel =
			MethodChannel(flutterPluginBinding.binaryMessenger, "com.layrz.ble.startNotify")
		startNotifyChannel.setMethodCallHandler(this)
		stopNotifyChannel =
			MethodChannel(flutterPluginBinding.binaryMessenger, "com.layrz.ble.stopNotify")
		stopNotifyChannel.setMethodCallHandler(this)
		eventsChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.layrz.ble.events")
		eventsChannel.setMethodCallHandler(this)
		startAdvertiseChannel =
			MethodChannel(flutterPluginBinding.binaryMessenger, "com.layrz.ble.startAdvertise")
		startAdvertiseChannel.setMethodCallHandler(this)
		stopAdvertiseChannel =
			MethodChannel(flutterPluginBinding.binaryMessenger, "com.layrz.ble.stopAdvertise")
		stopAdvertiseChannel.setMethodCallHandler(this)
		respondWriteRequestChannel =
			MethodChannel(flutterPluginBinding.binaryMessenger, "com.layrz.ble.respondWriteRequest")
		respondWriteRequestChannel.setMethodCallHandler(this)
		respondReadRequestChannel =
			MethodChannel(flutterPluginBinding.binaryMessenger, "com.layrz.ble.respondReadRequest")
		respondReadRequestChannel.setMethodCallHandler(this)

		context = flutterPluginBinding.applicationContext
	}

	override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
		checkCapabilitiesChannel.setMethodCallHandler(null)
		startScanChannel.setMethodCallHandler(null)
		stopScanChannel.setMethodCallHandler(null)
		connectChannel.setMethodCallHandler(null)
		disconnectChannel.setMethodCallHandler(null)
		discoverServicesChannel.setMethodCallHandler(null)
		setMtuChannel.setMethodCallHandler(null)
		writeCharacteristicChannel.setMethodCallHandler(null)
		readCharacteristicChannel.setMethodCallHandler(null)
		startNotifyChannel.setMethodCallHandler(null)
		stopNotifyChannel.setMethodCallHandler(null)
		eventsChannel.setMethodCallHandler(null)
		startAdvertiseChannel.setMethodCallHandler(null)
		stopAdvertiseChannel.setMethodCallHandler(null)
		respondWriteRequestChannel.setMethodCallHandler(null)
		respondReadRequestChannel.setMethodCallHandler(null)
	}

	override fun onMethodCall(call: MethodCall, result: Result) {
		Log.d(TAG, "Method call: ${call.method}")

		when (call.method) {
			"checkCapabilities" -> checkCapabilities(result = result)
			"checkScanPermissions" -> result.success(checkScanPermissions())
			"checkAdvertisePermissions" -> result.success(checkAdvertisePermissions())
			"startScan" -> startScan(call = call, result = result)
			"stopScan" -> stopScan(result = result)
			"connect" -> connect(call = call, result = result)
			"disconnect" -> disconnect(result = result)
			"discoverServices" -> discoverServices(result = result)
			"setMtu" -> setMtu(call = call, result = result)
			"writeCharacteristic" -> writeCharacteristic(call = call, result = result)
			"readCharacteristic" -> readCharacteristic(call = call, result = result)
			"startNotify" -> startNotify(call = call, result = result)
			"stopNotify" -> stopNotify(call = call, result = result)
			"startAdvertise" -> startAdvertise(call = call, result = result)
			"stopAdvertise" -> stopAdvertise(call = call, result = result)
			"respondReadRequest" -> respondReadRequest(call = call, result = result)
			"respondWriteRequest" -> respondWriteRequest(call = call, result = result)
			else -> result.notImplemented()
		}
	}

	/* Responds a Read Request received from the GATT server */
	private fun respondReadRequest(call: MethodCall, result: Result) {
		if (gattServer == null) {
			Log.d(TAG, "Gatt server is null")
			result.success(false)
			return
		}
		val macAddress = call.argument<String>("macAddress")
		val requestId = call.argument<Int>("requestId")
		val offset = call.argument<Int>("offset")
		val rawCharacteristicUuid = call.argument<String>("characteristicUuid")
		val value = call.argument<ByteArray?>("data")
		if (macAddress == null || requestId == null || offset == null || rawCharacteristicUuid == null) {
			Log.d(TAG, "Invalid arguments")
			result.success(false)
			return
		}

		val characteristicUuid = UUID.fromString(rawCharacteristicUuid)
		val device = gattDevices[macAddress]
		if (device == null) {
			Log.d(TAG, "Device not found")
			result.success(false)
			return
		}

		val characteristic = gattServer!!.services.find { service ->
			service.characteristics.any { it.uuid == characteristicUuid }
		}?.characteristics?.find { it.uuid == characteristicUuid }
		if (characteristic == null) {
			Log.d(TAG, "Characteristic not found")
			result.success(false)
			return
		}

		gattServer!!.sendResponse(
			device,
			requestId,
			BluetoothGatt.GATT_SUCCESS,
			offset,
			value
		)
		result.success(true)
	}

	/* Responds a Write Request received from the GATT server */
	private fun respondWriteRequest(call: MethodCall, result: Result) {
		if (gattServer == null) {
			Log.d(TAG, "Gatt server is null")
			result.success(false)
			return
		}
		val macAddress = call.argument<String>("macAddress")
		val requestId = call.argument<Int>("requestId")
		val offset = call.argument<Int>("offset")
		val rawCharacteristicUuid = call.argument<String>("characteristicUuid")
		val success = call.argument<Boolean>("success")
		if (macAddress == null || requestId == null || offset == null || rawCharacteristicUuid == null) {
			Log.d(TAG, "Invalid arguments")
			result.success(false)
			return
		}

		val characteristicUuid = UUID.fromString(rawCharacteristicUuid)
		val device = gattDevices[macAddress]
		if (device == null) {
			Log.d(TAG, "Device not found")
			result.success(false)
			return
		}

		val characteristic = gattServer!!.services.find { service ->
			service.characteristics.any { it.uuid == characteristicUuid }
		}?.characteristics?.find { it.uuid == characteristicUuid }
		if (characteristic == null) {
			Log.d(TAG, "Characteristic not found")
			result.success(false)
			return
		}

		gattServer!!.sendResponse(
			device,
			requestId,
			if (success == true) BluetoothGatt.GATT_SUCCESS else BluetoothGatt.GATT_FAILURE,
			offset,
			null
		)
		result.success(true)
	}

	/* Starts the advertisement */
	private fun startAdvertise(call: MethodCall, result: Result) {
		if (!checkAdvertisePermissions()) {
			Log.d(TAG, "No permissions")
			result.success(false)
			startAdvertiseResult = null
			return
		}

		if (bluetooth == null) {
			Log.d(TAG, "Bluetooth is null, initializing")
			bluetooth = context.getSystemService(android.content.Context.BLUETOOTH_SERVICE) as BluetoothManager
		}

		val adapter = bluetooth!!.adapter
		val advertiser = adapter.bluetoothLeAdvertiser
		startAdvertiseResult = result
		gattServices.clear()
		gattDevices.clear()

		val rawServices = call.argument<List<Map<String, Any>>>("servicesSpecs")
		if (rawServices != null) {
			Log.d(TAG, "Services: $rawServices")
			for (service in rawServices) {
				val uuid = service["uuid"] as String
				@Suppress("UNCHECKED_CAST") val characteristics =
					service["characteristics"] as List<Map<String, Any>>? ?: emptyList()
				val gattService = BluetoothGattService(
					UUID.fromString(uuid),
					BluetoothGattService.SERVICE_TYPE_PRIMARY
				)
				for (characteristic in characteristics) {
					val charUuid = characteristic["uuid"] as String

					@Suppress("UNCHECKED_CAST")
					val rawProperties = characteristic["properties"] as List<String>
					var properties = 0
					var permissions = 0
					if (rawProperties.contains("BROADCAST")) {
						properties = properties or BluetoothGattCharacteristic.PROPERTY_BROADCAST
						permissions = permissions or BluetoothGattCharacteristic.PERMISSION_WRITE
					}
					if (rawProperties.contains("READ")) {
						properties = properties or BluetoothGattCharacteristic.PROPERTY_READ
						permissions = permissions or BluetoothGattCharacteristic.PERMISSION_READ
					}
					if (rawProperties.contains("WRITE")) {
						properties = properties or BluetoothGattCharacteristic.PROPERTY_WRITE
						permissions = permissions or BluetoothGattCharacteristic.PERMISSION_WRITE
					}
					if (rawProperties.contains("WRITE_WO_RSP")) {
						properties = properties or BluetoothGattCharacteristic.PROPERTY_WRITE_NO_RESPONSE
						permissions = permissions or BluetoothGattCharacteristic.PERMISSION_WRITE
					}
					if (rawProperties.contains("NOTIFY")) {
						properties = properties or BluetoothGattCharacteristic.PROPERTY_NOTIFY
					}
					if (rawProperties.contains("INDICATE")) {
						properties = properties or BluetoothGattCharacteristic.PROPERTY_INDICATE
					}
					if (rawProperties.contains("AUTH_SIGN_WRITES")) {
						properties = properties or BluetoothGattCharacteristic.PROPERTY_SIGNED_WRITE
						permissions = permissions or BluetoothGattCharacteristic.PERMISSION_WRITE_SIGNED
					}
					if (rawProperties.contains("EXTENDED_PROP")) {
						properties = properties or BluetoothGattCharacteristic.PROPERTY_EXTENDED_PROPS
						permissions = permissions or BluetoothGattCharacteristic.PERMISSION_READ
					}

					val gattCharacteristic = BluetoothGattCharacteristic(
						UUID.fromString(charUuid),
						properties,
						permissions
					)
					gattService.addCharacteristic(gattCharacteristic)
				}
				gattServices.add(gattService)
			}
		}

		val data = AdvertiseData.Builder().setIncludeDeviceName(true)
		connectable = call.argument<Boolean>("canConnect") ?: false
		val canBt5 = call.argument<Boolean>("allowBluetooth5") ?: true

		val manufacturerDataList = call.argument<List<Map<String, Any>>>("manufacturerData")
		if (manufacturerDataList != null) {
			Log.d(TAG, "Manufacturer data: $manufacturerDataList")
			for (manufacturerData in manufacturerDataList) {
				val companyId = manufacturerData["companyId"] as Int
				val mfdata = manufacturerData["data"] as ByteArray
				data.addManufacturerData(companyId, mfdata)
			}
		}

		val serviceDataList = call.argument<List<Map<String, Any>>>("serviceData")
		if (serviceDataList != null) {
			Log.d(TAG, "Service data: $serviceDataList")
			for (serviceData in serviceDataList) {
				val rawUuid = serviceData["uuid"] as Int
				val uuid = String.format("%04X", rawUuid)
				val sdata = serviceData["data"] as ByteArray
				data.addServiceData(ParcelUuid.fromString("0000$uuid-0000-1000-8000-00805f9b34fb"), sdata)
			}
		}

		// Support Bluetooth Low Energy 5.0 Extended Advertising
		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && adapter.isLeExtendedAdvertisingSupported && canBt5) {
			Log.d(TAG, "Using extended advertising characteristic from Bluetooth 5.0 - Connection state: $connectable")
			val parameters = AdvertisingSetParameters.Builder()
				.setConnectable(connectable)
				.setLegacyMode(false) // Use extended advertising
				.setInterval(AdvertisingSetParameters.INTERVAL_HIGH)
				.setTxPowerLevel(AdvertisingSetParameters.TX_POWER_HIGH)
				.build()

			advertiser.startAdvertisingSet(
				parameters,
				data.build(),
				null,
				null,
				null,
				advertiseSetCallback
			)
			return
		}

		val settings = AdvertiseSettings.Builder()
			.setAdvertiseMode(AdvertiseSettings.ADVERTISE_MODE_BALANCED)
			.setTxPowerLevel(AdvertiseSettings.ADVERTISE_TX_POWER_HIGH)
			.setConnectable(connectable)
			.build()

		advertiser.startAdvertising(settings, data.build(), advertiseCallback)
	}

	/* Stops the avertisement */
	private fun stopAdvertise(call: MethodCall, result: Result) {
		if (!checkAdvertisePermissions()) {
			Log.d(TAG, "No permissions")
			result.success(false)
			return
		}

		if (bluetooth == null) {
			Log.d(TAG, "Bluetooth is null, initializing")
			bluetooth = context.getSystemService(android.content.Context.BLUETOOTH_SERVICE) as BluetoothManager
		}

		val advertiser = bluetooth!!.adapter.bluetoothLeAdvertiser
		if (advertiser == null) {
			Log.d(TAG, "Bluetooth advertiser is null")
			result.success(false)
			return
		}

		for (device in gattDevices.values) {
			gattServer?.cancelConnection(device)
		}

		gattDevices.clear()
		gattServices.clear()
		gattServer?.close()
		gattServer = null

		advertiser.stopAdvertising(advertiseCallback)
		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
			advertiser.stopAdvertisingSet(advertiseSetCallback)
		}
		Log.d(TAG, "Advertisement stopped")
		result.success(true)
	}

	/* Checks if the device supports BLE */
	private fun checkCapabilities(result: Result) {
		bluetooth =
			context.getSystemService(android.content.Context.BLUETOOTH_SERVICE) as BluetoothManager

		val packageManager = context.packageManager
		val hasBle = packageManager.hasSystemFeature(PackageManager.FEATURE_BLUETOOTH_LE)
		if (!hasBle || bluetooth == null) { // The device doesn't support BLE
			return result.success(false)
		}

		return result.success(true)
	}

	/* Validates if the app has BLE permissions granted for Scan */
	private fun checkScanPermissions(): Boolean {
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

	/* Validates if the app has BLE permissions granted for Advertise */
	private fun checkAdvertisePermissions(): Boolean {
		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
			return ActivityCompat.checkSelfPermission(
				context,
				Manifest.permission.BLUETOOTH_ADVERTISE
			) == PackageManager.PERMISSION_GRANTED
		}

		return true
	}

	/* Starts the scanning */
	private fun startScan(call: MethodCall, result: Result) {
		if (!checkScanPermissions()) {
			Log.d(TAG, "No permissions")
			result.success(false)
			startScanResult = null
			return
		}

		if (isScanning) {
			bluetooth!!.adapter.bluetoothLeScanner.stopScan(scanCallback)
		}

		filteredMacAddress = call.argument<String>("macAddress")
		if (filteredMacAddress != null) {
			Log.d(TAG, "Filtering by macAddress: $filteredMacAddress")
			filteredMacAddress = filteredMacAddress!!.uppercase()
		}

		if (bluetooth == null) {
			Log.d(TAG, "Bluetooth is null, initializing")
			bluetooth = context.getSystemService(android.content.Context.BLUETOOTH_SERVICE) as BluetoothManager
		}

		val adapter = bluetooth!!.adapter

		if (!adapter.isEnabled) {
			Log.d(TAG, "Bluetooth is not enabled, requesting to enable")
			val btEnableIntent = Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE)
			startActivityForResult(activity!!, btEnableIntent, REQUEST_ENABLE_BT, null)
			startScanResult = result
		} else {
			Log.d(TAG, "Bluetooth is enabled, starting scan")
			isScanning = true
			lastOperation = LastOperation.SCAN
			bluetooth!!.adapter.bluetoothLeScanner.startScan(scanCallback)
			result.success(true)
			startScanResult = null
		}
	}

	/* Stops the scanning */
	private fun stopScan(result: Result) {
		if (!isScanning) {
			Log.d(TAG, "Not scanning")
			result.success(true)
			stopScanResult = null
			return
		}

		if (!checkScanPermissions()) {
			Log.d(TAG, "No permissions")
			result.success(false)
			stopScanResult = null
			return
		}

		if (bluetooth == null) {
			Log.d(TAG, "Bluetooth is null, initializing")
			bluetooth = context.getSystemService(
				android.content.Context.BLUETOOTH_SERVICE
			) as BluetoothManager
		}

		val adapter = bluetooth!!.adapter

		Log.d(TAG, "Stopping scan")
		adapter!!.bluetoothLeScanner.stopScan(scanCallback)
		result.success(true)
		stopScanResult = null
		filteredMacAddress = null
	}

	/* Connects to a BLE device */
	private fun connect(call: MethodCall, result: Result) {
		if (!checkScanPermissions()) {
			Log.d(TAG, "No permissions")
			result.success(false)
			connectResult = null
			return
		}

		searchingMacAddress = call.arguments as String?

		if (searchingMacAddress == null) {
			Log.d(TAG, "No macAddress provided")
			result.success(false)
			connectResult = null
			return
		}

		if (!devices.containsKey(searchingMacAddress!!)) {
			Log.d(TAG, "Device not found")
			result.success(false)
			connectResult = null
			return
		}

		if (isScanning) {
			isScanning = false
			Handler(Looper.getMainLooper()).post {
				eventsChannel.invokeMethod("onEvent", "SCAN_STOPPED")
			}
			bluetooth!!.adapter.bluetoothLeScanner.stopScan(scanCallback)
		}

		connectedDevice = devices[searchingMacAddress!!]!!
		connectResult = result
		lastOperation = LastOperation.CONNECT
		gatt = connectedDevice!!.connectGatt(context, false, gattCallback)
		gatt!!.connect()
	}

	/* Disconnects from a BLE device */
	private fun disconnect(result: Result) {
		if (gatt == null) {
			Log.d(TAG, "No device connected")
			result.success(false)
			disconnectResult = null
			return
		}

		gatt!!.disconnect()
		result.success(true)
		disconnectResult = null
	}

	/* Discovers the services of a BLE device */
	private fun discoverServices(result: Result) {
		if (gatt == null) {
			Log.d(TAG, "No device connected")
			result.success(null)
			discoverServicesResult = null
			return
		}

		val output: MutableList<Map<String, Any>> = mutableListOf()
		// Iterate over the servicesAndCharacteristics
		for ((serviceUuid, service) in servicesAndCharacteristics) {
			val characteristics = service.characteristics.map { characteristic ->
				mapOf(
					"uuid" to characteristic.uuid,
					"properties" to characteristic.properties
				)
			}
			output.add(
				mapOf(
					"uuid" to serviceUuid,
					"characteristics" to characteristics
				)
			)
		}
		result.success(output)
		discoverServicesResult = null
		return
	}

	/* Sets the MTU of a BLE device */
	private fun setMtu(call: MethodCall, result: Result) {
		val newMtu = call.arguments as Int?
		if (newMtu == null) {
			Log.d(TAG, "No mtu provided")
			result.success(null)
			setMtuResult = null
			return
		}

		if (gatt == null) {
			Log.d(TAG, "No device connected")
			result.success(null)
			setMtuResult = null
			return
		}

		setMtuResult = result
		lastOperation = LastOperation.SET_MTU
		gatt!!.requestMtu(newMtu)

		spawnTimeout(
			operation = LastOperation.SET_MTU,
			timeoutSeconds = 10,
		)
	}

	/* Sends a payload to a BLE device */
	private fun writeCharacteristic(call: MethodCall, result: Result) {
		val serviceUuid = call.argument<String>("serviceUuid")
		if (serviceUuid == null) {
			Log.d(TAG, "No serviceUuid provided")
			result.success(null)
			writeCharacteristicResult = null
			return
		}

		val characteristicUuid = call.argument<String>("characteristicUuid")
		if (characteristicUuid == null) {
			Log.d(TAG, "No characteristicUuid provided")
			result.success(null)
			writeCharacteristicResult = null
			return
		}

		val payload = call.argument<ByteArray>("payload")
		if (payload == null) {
			Log.d(TAG, "No payload provided")
			result.success(null)
			writeCharacteristicResult = null
			return
		}

		var timeoutSeconds: Int = call.argument<Int>("timeout") ?: 30
		if (timeoutSeconds < 1) {
			timeoutSeconds = 1
		}

		val writeType = call.argument<Boolean>("withResponse") ?: true

		if (gatt == null) {
			Log.d(TAG, "No device connected")
			result.success(null)
			writeCharacteristicResult = null
			return
		}

		Log.d(TAG, "Service: $serviceUuid")
		val service = servicesAndCharacteristics[serviceUuid]
		if (service == null) {
			Log.d(TAG, "Service not found")
			result.success(null)
			writeCharacteristicResult = null
			return
		}

		val characteristic = service.characteristics.find { it.uuid == characteristicUuid }
		if (characteristic == null) {
			Log.d(TAG, "Characteristic not found")
			result.success(null)
			writeCharacteristicResult = null
			return
		}

		if (!characteristic.properties.contains("WRITE")) {
			Log.d(TAG, "Characteristic does not support write")
			result.success(null)
			writeCharacteristicResult = null
			return
		}

		writeCharacteristicResult = result
		lastOperation = LastOperation.WRITE_CHARACTERISTIC

		val type = if (writeType) {
			BluetoothGattCharacteristic.WRITE_TYPE_DEFAULT
		} else {
			BluetoothGattCharacteristic.WRITE_TYPE_NO_RESPONSE
		}
		if (Build.VERSION.SDK_INT > Build.VERSION_CODES.TIRAMISU) {
			gatt!!.writeCharacteristic(
				characteristic.characteristic,
				payload,
				type,
			)
		} else {
			characteristic.characteristic.value = payload
			characteristic.characteristic.writeType = type
			gatt!!.writeCharacteristic(characteristic.characteristic)
		}

		// Timeout
		spawnTimeout(
			operation = LastOperation.WRITE_CHARACTERISTIC,
			timeoutSeconds = timeoutSeconds,
		)
	}

	/* Reads a payload from a BLE device */
	private fun readCharacteristic(call: MethodCall, result: Result) {
		val serviceUuid = call.argument<String>("serviceUuid")
		if (serviceUuid == null) {
			Log.d(TAG, "No serviceUuid provided")
			result.success(null)
			readCharacteristicResult = null
			return
		}

		val characteristicUuid = call.argument<String>("characteristicUuid")
		if (characteristicUuid == null) {
			Log.d(TAG, "No characteristicUuid provided")
			result.success(null)
			readCharacteristicResult = null
			return
		}

		var timeoutSeconds: Int = call.argument<Int>("timeout") ?: 30
		if (timeoutSeconds < 1) {
			timeoutSeconds = 1
		}

		if (gatt == null) {
			Log.d(TAG, "No device connected")
			result.success(null)
			readCharacteristicResult = null
			return
		}

		val service = gatt!!.getService(UUID.fromString(serviceUuid))
		if (service == null) {
			Log.d(TAG, "Service not found")
			result.success(null)
			readCharacteristicResult = null
			return
		}

		val characteristic =
			service.getCharacteristic(UUID.fromString(characteristicUuid))
		if (characteristic == null) {
			Log.d(TAG, "Characteristic not found")
			result.success(null)
			readCharacteristicResult = null
			return
		}

		if (characteristic.properties and BluetoothGattCharacteristic.PROPERTY_READ == 0) {
			Log.d(TAG, "Characteristic does not support read")
			result.success(null)
			readCharacteristicResult = null
			return
		}

		readCharacteristicResult = result
		lastOperation = LastOperation.READ_CHARACTERISTIC
		gatt!!.readCharacteristic(characteristic)

		// Timeout
		spawnTimeout(
			operation = LastOperation.READ_CHARACTERISTIC,
			timeoutSeconds = timeoutSeconds,
		)
	}

	/* Subscribe to a characteristic */
	private fun startNotify(call: MethodCall, result: Result) {
		val rawServiceUuid = call.argument<String>("serviceUuid")
		if (rawServiceUuid == null) {
			Log.d(TAG, "No serviceUuid provided")
			result.success(false)
			startNotifyResult = null
			return
		}

		val serviceUuid: UUID?
		try {
			serviceUuid = UUID.fromString(rawServiceUuid)
		} catch (e: IllegalArgumentException) {
			Log.d(TAG, "Invalid serviceUuid provided - $rawServiceUuid")
			result.success(false)
			startNotifyResult = null
			return
		}

		val rawCharacteristicUuid = call.argument<String>("characteristicUuid")
		if (rawCharacteristicUuid == null) {
			Log.d(TAG, "No characteristicUuid provided")
			result.success(false)
			startNotifyResult = null
			return
		}
		val characteristicUuid: UUID?
		try {
			characteristicUuid = UUID.fromString(rawCharacteristicUuid)
		} catch (e: IllegalArgumentException) {
			Log.d(TAG, "Invalid characteristicUuid provided - $rawCharacteristicUuid")
			result.success(false)
			startNotifyResult = null
			return
		}

		if (currentNotifications.contains(standarizeUuid(characteristicUuid))) {
			Log.d(TAG, "Already subscribed")
			result.success(true)
			startNotifyResult = null
			return
		}

		if (gatt == null) {
			Log.d(TAG, "No device connected")
			result.success(false)
			startNotifyResult = null
			return
		}

		val service = servicesAndCharacteristics[standarizeUuid(serviceUuid)]
		if (service == null) {
			Log.d(TAG, "Service not found")
			result.success(false)
			startNotifyResult = null
			return
		}

		val characteristic =
			service.characteristics.find { it.uuid == standarizeUuid(characteristicUuid) }
		if (characteristic == null) {
			Log.d(TAG, "Characteristic not found")
			result.success(false)
			startNotifyResult = null
			return
		}

		if (!characteristic.properties.contains("NOTIFY")) {
			Log.d(TAG, "Characteristic does not support notify")
			result.success(false)
			startNotifyResult = null
			return
		}

		val notificationResult = gatt!!.setCharacteristicNotification(
			characteristic.characteristic,
			true
		)
		Log.d(TAG, "Notification subscription result: $notificationResult")
		if (!notificationResult) {
			Log.d(TAG, "Notification failed")
			result.success(false)
			startNotifyResult = null
			return
		}

		val descriptor = characteristic.characteristic.getDescriptor(CCD_CHARACTERISTIC)

		if (descriptor == null) {
			Log.d(TAG, "Descriptor not found")
			result.success(false)
			startNotifyResult = null
			return
		}

		descriptor.value = BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE
		gatt!!.writeDescriptor(descriptor)

		currentNotifications.add(characteristic.uuid.uppercase().trim())
		result.success(true)
		startNotifyResult = null
	}

	/* Unsubscribe from a characteristic */
	private fun stopNotify(call: MethodCall, result: Result) {
		val rawServiceUuid = call.argument<String>("serviceUuid")
		if (rawServiceUuid == null) {
			Log.d(TAG, "No serviceUuid provided")
			result.success(false)
			stopNotifyResult = null
			return
		}

		val serviceUuid: UUID?
		try {
			serviceUuid = UUID.fromString(rawServiceUuid)
		} catch (e: IllegalArgumentException) {
			Log.d(TAG, "Invalid serviceUuid provided - $rawServiceUuid")
			result.success(false)
			startNotifyResult = null
			return
		}

		val rawCharacteristicUuid = call.argument<String>("characteristicUuid")
		if (rawCharacteristicUuid == null) {
			Log.d(TAG, "No characteristicUuid provided")
			result.success(false)
			stopNotifyResult = null
			return
		}

		val characteristicUuid: UUID?
		try {
			characteristicUuid = UUID.fromString(rawCharacteristicUuid)
		} catch (e: IllegalArgumentException) {
			Log.d(TAG, "Invalid characteristicUuid provided - $rawCharacteristicUuid")
			result.success(false)
			stopNotifyResult = null
			return
		}

		if (!currentNotifications.contains(characteristicUuid.toString().uppercase().trim())) {
			Log.d(TAG, "Not subscribed")
			result.success(true)
			stopNotifyResult = null
			return
		}

		if (gatt == null) {
			Log.d(TAG, "No device connected")
			result.success(false)
			stopNotifyResult = null
			return
		}

		val service = servicesAndCharacteristics[standarizeUuid(serviceUuid)]
		if (service == null) {
			Log.d(TAG, "Service not found")
			result.success(false)
			stopNotifyResult = null
			return
		}

		val characteristic =
			service.characteristics.find { it.uuid == standarizeUuid(characteristicUuid) }
		if (characteristic == null) {
			Log.d(TAG, "Characteristic not found")
			result.success(false)
			stopNotifyResult = null
			return
		}

		if (!characteristic.properties.contains("NOTIFY")) {
			Log.d(TAG, "Characteristic does not support notify")
			result.success(false)
			stopNotifyResult = null
			return
		}

		gatt!!.setCharacteristicNotification(characteristic.characteristic, false)
		currentNotifications.remove(characteristic.uuid.uppercase().trim())
		result.success(true)
		stopNotifyResult = null
	}

	private fun spawnTimeout(operation: LastOperation, timeoutSeconds: Int) {
		coroutine = CoroutineScope(Dispatchers.IO + Job()).launch {
			delay(timeoutSeconds * 1000L)
			if (lastOperation == operation) {
				Log.d(TAG, "$operation timed out")
				when (operation) {
					LastOperation.WRITE_CHARACTERISTIC -> {
						writeCharacteristicResult?.success(false)
						writeCharacteristicResult = null
					}

					LastOperation.READ_CHARACTERISTIC -> {
						readCharacteristicResult?.success(null)
						readCharacteristicResult = null
					}

					LastOperation.SCAN -> {
						bluetooth!!.adapter.bluetoothLeScanner.stopScan(scanCallback)
						isScanning = false
						Handler(Looper.getMainLooper()).post {
							eventsChannel.invokeMethod("onEvent", "SCAN_STOPPED")
						}
						startScanResult?.success(false)
						startScanResult = null
					}

					LastOperation.CONNECT -> {
						gatt?.disconnect()
						connectResult?.success(false)
						connectResult = null
					}

					LastOperation.SET_MTU -> {
						setMtuResult?.success(null)
						setMtuResult = null
					}
				}
			}
		}
	}

	override fun onActivityResult(
		requestCode: Int,
		resultCode: Int,
		data: Intent?
	): Boolean {
		Log.d(TAG, "onActivityResult $requestCode $resultCode $data")
		if (requestCode == REQUEST_ENABLE_BT) {
			if (resultCode == Activity.RESULT_OK) {
				Log.d(TAG, "Bluetooth enabled, starting scan")
				if (ActivityCompat.checkSelfPermission(
						context,
						Manifest.permission.BLUETOOTH_SCAN
					) != PackageManager.PERMISSION_GRANTED
				) {
					val settings = ScanSettings.Builder()
						.setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY)
						.build()
					bluetooth!!.adapter.bluetoothLeScanner.startScan(null, settings, scanCallback)
					isScanning = true
					lastOperation = LastOperation.SCAN
					startScanResult?.success(true)
					startScanResult = null
				} else {
					Log.d(TAG, "No location permission")
					startScanResult?.success(false)
					startScanResult = null
				}
			} else {
				Log.d(TAG, "Bluetooth not enabled")
				startScanResult?.success(false)
				startScanResult = null
			}

			coroutine?.cancel()
			coroutine = null
			return true
		}

		coroutine?.cancel()
		coroutine = null
		return false
	}
}
