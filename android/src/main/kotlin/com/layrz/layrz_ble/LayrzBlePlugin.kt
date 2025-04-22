@file:Suppress("DEPRECATION", "SpellCheckingInspection", "MissingPermission", "KotlinConstantConditions")

package com.layrz.layrz_ble

import android.Manifest
import android.app.Activity
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
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

	private val devices: HashMap<String, BluetoothDevice> = HashMap()
	private var macFilter: String? = null

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
		TODO("Not yet implemented")
	}

	override fun disconnect(macAddress: String?, callback: (Result<Boolean>) -> Unit) {
		TODO("Not yet implemented")
	}

	override fun setMtu(macAddress: String, mtu: Long, callback: (Result<Long?>) -> Unit) {
		TODO("Not yet implemented")
	}

	override fun discoverServices(macAddress: String, callback: (Result<List<BtService>>) -> Unit) {
		TODO("Not yet implemented")
	}

	override fun readCharacteristic(
		macAddress: String,
		serviceUuid: String,
		characteristicUuid: String,
		callback: (Result<ByteArray>) -> Unit
	) {
		TODO("Not yet implemented")
	}

	override fun writeCharacteristic(
		macAddress: String,
		serviceUuid: String,
		characteristicUuid: String,
		payload: ByteArray,
		withResponse: Boolean,
		callback: (Result<Boolean>) -> Unit
	) {
		TODO("Not yet implemented")
	}

	override fun startNotify(
		macAddress: String,
		serviceUuid: String,
		characteristicUuid: String,
		callback: (Result<Boolean>) -> Unit
	) {
		TODO("Not yet implemented")
	}

	override fun stopNotify(
		macAddress: String,
		serviceUuid: String,
		characteristicUuid: String,
		callback: (Result<Boolean>) -> Unit
	) {
		TODO("Not yet implemented")
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
//		val bluetooth = bluetooth ?: return
//		if (isScanning) {
//			bluetooth.adapter.bluetoothLeScanner.stopScan(scanCallback)
//		}
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
