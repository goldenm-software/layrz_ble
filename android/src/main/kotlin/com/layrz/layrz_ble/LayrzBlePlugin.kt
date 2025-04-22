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
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.ParcelUuid
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
import java.util.UUID

class LayrzBlePlugin : FlutterPlugin, MethodCallHandler, ActivityAware,
											 PluginRegistry.ActivityResultListener, BroadcastReceiver() {
	private lateinit var checkCapabilitiesChannel: MethodChannel
	private lateinit var checkScanPermissionsChannel: MethodChannel
	private lateinit var checkAdvertisePermissionsChannel: MethodChannel
	private lateinit var getStatusesChannel: MethodChannel

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
	private lateinit var sendNotificationChannel: MethodChannel

	private lateinit var context: Context
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

	// Bluetooth device connection
	private var filteredMacAddress: String? = null
	private val devices: HashMap<String, BluetoothDevice> = HashMap()
	private var searchingMacAddress: String? = null
	private var connectable: Boolean = false
	private var gattServer: BluetoothGattServer? = null
	private var gattDevices: MutableMap<String, BluetoothDevice> = mutableMapOf()
	private var gattServices: MutableList<BluetoothGattService> = mutableListOf()

	private var isScanning = false
	private var lastOperation: LastOperation? = null
	private var connectedDevices: MutableMap<String, BluetoothGatt> = mutableMapOf()
	private var currentNotifications: MutableList<String> = mutableListOf()
	private var servicesAndCharacteristics: MutableMap<String, List<BleService>> = mutableMapOf()

	private var originalName: String = ""

	private val scanCallback = object : ScanCallback() {
		override fun onScanResult(callbackType: Int, result: ScanResult?) {
			super.onScanResult(callbackType, result)
			val scanRecord = result?.scanRecord ?: return

			val device = result.device
			val macAddress = device.address.uppercase()

			if (filteredMacAddress != null && macAddress != filteredMacAddress) return

			val name = scanRecord.deviceName ?: device.name ?: "Unknown"

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

			var txPower: Int? = scanRecord.txPowerLevel
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
			Log.d(TAG, "onConnectionStateChange: $newState - $status")
			if (gatt == null) return
			val addr = gatt.device.address.uppercase()

			when (newState) {
				BluetoothProfile.STATE_CONNECTED -> {
					connectedDevices[addr] = gatt
					servicesAndCharacteristics.remove(addr)
					Log.i(TAG, "Connected to ${gatt.device.address}, discovering services")
					gatt.discoverServices()
				}

				BluetoothProfile.STATE_DISCONNECTED -> {
					Log.w(TAG, "${gatt.device.address} disconnected")
					gatt.disconnect()
					connectedDevices.remove(addr)
					servicesAndCharacteristics.remove(addr)
					Handler(Looper.getMainLooper()).post {
						eventsChannel.invokeMethod(
							"onDisconnected",
							mutableMapOf(
								"macAddress" to addr,
								"name" to gatt.device.name
							)
						)
					}
				}

				else -> {
					Log.e(TAG, "Unknown state: $newState")
				}
			}
		}

		override fun onServicesDiscovered(gatt: BluetoothGatt?, status: Int) {
			super.onServicesDiscovered(gatt, status)
			if (lastOperation != LastOperation.CONNECT) return
			if (gatt == null) return
			val addr = gatt.device.address.uppercase()

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

					if (servicesAndCharacteristics[addr] == null) {
						servicesAndCharacteristics[addr] = mutableListOf()
					}

					Log.d(TAG, "Service discovered: ${standarizeUuid(service.uuid)} for $addr")
					servicesAndCharacteristics[addr] = servicesAndCharacteristics[addr]!!.plus(
						BleService(
							service = service,
							uuid = standarizeUuid(service.uuid),
							characteristics = characteristics
						)
					)
				}

				Log.d(TAG, "Services discovered")
				connectResult?.success(true)
				connectResult = null

				Handler(Looper.getMainLooper()).post {
					eventsChannel.invokeMethod(
						"onConnected",
						mutableMapOf(
							"macAddress" to addr,
							"name" to gatt.device.name
						)
					)
				}
			} else {
				Log.d(TAG, "Discover services failed")
				connectResult?.success(false)
				connectResult = null
			}
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
		}

		@Deprecated("Deprecated in Java")
		override fun onCharacteristicChanged(
			gatt: BluetoothGatt,
			characteristic: BluetoothGattCharacteristic
		) {
			super.onCharacteristicChanged(gatt, characteristic)
			Handler(Looper.getMainLooper()).post {
				eventsChannel.invokeMethod(
					"onNotify",
					mapOf(
						"macAddress" to gatt.device.address,
						"serviceUuid" to characteristic.service.uuid.toString().uppercase().trim(),
						"characteristicUuid" to characteristic.uuid.toString().uppercase().trim(),
						"value" to characteristic.value
					)
				)
			}
		}
	}

	private var advertiseCallback: AdvertiseCallback? = null
	private var advertiseSetCallback: AdvertisingSetCallback? = null

	private var gattServerCallback = object : BluetoothGattServerCallback() {
		override fun onConnectionStateChange(
			device: BluetoothDevice?,
			status: Int,
			newState: Int
		) {
			super.onConnectionStateChange(device, status, newState)
			Log.w(TAG, "onConnectionStateChange: $newState - $device - $status")
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
						"serviceUuid" to standarizeUuid(characteristic.service.uuid),
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
						"serviceUuid" to standarizeUuid(characteristic.service.uuid),
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

		override fun onDescriptorReadRequest(
			device: BluetoothDevice?,
			requestId: Int,
			offset: Int,
			descriptor: BluetoothGattDescriptor?
		) {
			super.onDescriptorReadRequest(device, requestId, offset, descriptor)
			Log.d(TAG, "onDescriptorReadRequest")
			if (device == null || descriptor == null) {
				Log.d(TAG, "Device or descriptor is null")
				gattServer!!.sendResponse(
					device,
					requestId,
					BluetoothGatt.GATT_FAILURE,
					offset,
					null
				)
				return
			}
			if (descriptor.uuid == CCD_CHARACTERISTIC) {
				if (descriptor.value == null) {
					Log.d(TAG, "Descriptor value is null")
					descriptor.value = BluetoothGattDescriptor.DISABLE_NOTIFICATION_VALUE
				}
			}

			gattServer!!.sendResponse(
				device,
				requestId,
				BluetoothGatt.GATT_SUCCESS,
				offset,
				descriptor.value
			)
		}

		override fun onDescriptorWriteRequest(
			device: BluetoothDevice?,
			requestId: Int,
			descriptor: BluetoothGattDescriptor?,
			preparedWrite: Boolean,
			responseNeeded: Boolean,
			offset: Int,
			value: ByteArray?
		) {
			super.onDescriptorWriteRequest(device, requestId, descriptor, preparedWrite, responseNeeded, offset, value)
			Log.d(TAG, "onDescriptorWriteRequest - UUID: ${descriptor?.uuid} - value: ${value?.contentToString()}")

			if (descriptor == null || device == null) {
				Log.d(TAG, "Device or descriptor is null")
				gattServer!!.sendResponse(
					device,
					requestId,
					BluetoothGatt.GATT_FAILURE,
					offset,
					null
				)
				return
			}

			if (descriptor.uuid == CCD_CHARACTERISTIC) {
				descriptor.value = value
				if (responseNeeded) {
					gattServer!!.sendResponse(
						device,
						requestId,
						BluetoothGatt.GATT_SUCCESS,
						offset,
						value
					)
				}

				if (value.contentEquals(BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE)) {
					descriptor.characteristic.value = byteArrayOf()
					gattServer!!.notifyCharacteristicChanged(
						device,
						descriptor.characteristic,
						false
					)
				}
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
		getStatusesChannel =
			MethodChannel(flutterPluginBinding.binaryMessenger, "com.layrz.ble.getStatuses")
		getStatusesChannel.setMethodCallHandler(this)

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
		sendNotificationChannel =
			MethodChannel(flutterPluginBinding.binaryMessenger, "com.layrz.ble.sendNotification")
		sendNotificationChannel.setMethodCallHandler(this)

		context = flutterPluginBinding.applicationContext

		context.registerReceiver(
			this,
			android.content.IntentFilter(BluetoothAdapter.ACTION_STATE_CHANGED)
		)
	}

	override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
		checkCapabilitiesChannel.setMethodCallHandler(null)
		checkScanPermissionsChannel.setMethodCallHandler(null)
		checkAdvertisePermissionsChannel.setMethodCallHandler(null)
		getStatusesChannel.setMethodCallHandler(null)

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
		sendNotificationChannel.setMethodCallHandler(null)

		context.unregisterReceiver(this)
	}

	override fun onMethodCall(call: MethodCall, result: Result) {
		Log.d(TAG, "Method call: ${call.method}")

		when (call.method) {
			"checkCapabilities" -> checkCapabilities(result = result)
			"checkScanPermissions" -> result.success(checkScanPermissions())
			"checkAdvertisePermissions" -> result.success(checkAdvertisePermissions())
			"getStatuses" -> getStatuses(result = result)
			"startScan" -> startScan(call = call, result = result)
			"stopScan" -> stopScan(result = result)
			"connect" -> connect(call = call, result = result)
			"disconnect" -> disconnect(call = call, result = result)
			"discoverServices" -> discoverServices(call = call, result = result)
			"setMtu" -> setMtu(call = call, result = result)
			"writeCharacteristic" -> writeCharacteristic(call = call, result = result)
			"readCharacteristic" -> readCharacteristic(call = call, result = result)
			"startNotify" -> startNotify(call = call, result = result)
			"stopNotify" -> stopNotify(call = call, result = result)
			"startAdvertise" -> startAdvertise(call = call, result = result)
			"stopAdvertise" -> stopAdvertise(result = result)
			"respondReadRequest" -> respondReadRequest(call = call, result = result)
			"respondWriteRequest" -> respondWriteRequest(call = call, result = result)
			"sendNotification" -> sendNotification(call = call, result = result)
			else -> result.notImplemented()
		}
	}

	/* Gets the current status of all procedures */
	private fun getStatuses(result: Result) {
		val statuses = mapOf(
			"scanning" to isScanning,
			"advertising" to (gattServer != null)
		)
		result.success(statuses)
	}

	/* Publish a change into a Characteristic */
	private fun sendNotification(call: MethodCall, result: Result) {
		if (gattServer == null) {
			Log.d(TAG, "Gatt server is null")
			result.success(false)
			return
		}
		val rawServiceUuid = call.argument<String>("serviceUuid")
		val rawCharacteristicUuid = call.argument<String>("characteristicUuid")
		val payload = call.argument<ByteArray>("payload")
		val requestConfirmation = call.argument<Boolean>("requestConfirmation") ?: false
		if (rawCharacteristicUuid == null || rawServiceUuid == null || payload == null) {
			Log.d(TAG, "Invalid arguments")
			result.success(false)
			return
		}

		val serviceUuid = UUID.fromString(rawServiceUuid)
		val service = gattServer!!.services.find { it.uuid == serviceUuid }
		if (service == null) {
			Log.d(TAG, "Service not found")
			result.success(false)
			return
		}

		val characteristicUuid = UUID.fromString(rawCharacteristicUuid)
		val characteristic = service.characteristics.find { it.uuid == characteristicUuid }
		if (characteristic == null) {
			Log.d(TAG, "Characteristic not found")
			result.success(false)
			return
		}

		characteristic.value = payload
		for (device in gattDevices.values) {
			gattServer!!.notifyCharacteristicChanged(
				device,
				characteristic,
				requestConfirmation
			)
		}

		result.success(true)
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
		val rawServiceUuid = call.argument<String>("serviceUuid")
		val rawCharacteristicUuid = call.argument<String>("characteristicUuid")
		val value = call.argument<ByteArray?>("data")
		if (macAddress == null || requestId == null || offset == null || rawCharacteristicUuid == null || rawServiceUuid == null) {
			Log.d(TAG, "Invalid arguments")
			result.success(false)
			return
		}

		val device = gattDevices[macAddress]
		if (device == null) {
			Log.d(TAG, "Device not found")
			result.success(false)
			return
		}

		val serviceUuid = UUID.fromString(rawServiceUuid)
		val service = gattServer!!.services.find { it.uuid == serviceUuid }
		if (service == null) {
			Log.d(TAG, "Service not found")
			result.success(false)
			return
		}

		val characteristicUuid = UUID.fromString(rawCharacteristicUuid)
		val characteristic = service.characteristics.find { it.uuid == characteristicUuid }
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
		val rawServiceUuid = call.argument<String>("serviceUuid")
		val rawCharacteristicUuid = call.argument<String>("characteristicUuid")
		val success = call.argument<Boolean>("success")
		if (macAddress == null || requestId == null || offset == null || rawCharacteristicUuid == null || rawServiceUuid == null) {
			Log.d(TAG, "Invalid arguments")
			result.success(false)
			return
		}

		val device = gattDevices[macAddress]
		if (device == null) {
			Log.d(TAG, "Device not found")
			result.success(false)
			return
		}

		val serviceUuid = UUID.fromString(rawServiceUuid)
		val service = gattServer!!.services.find { it.uuid == serviceUuid }
		if (service == null) {
			Log.d(TAG, "Service not found")
			result.success(false)
			return
		}

		val characteristicUuid = UUID.fromString(rawCharacteristicUuid)
		val characteristic = service.characteristics.find { it.uuid == characteristicUuid }
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
			bluetooth = context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
		}

		val adapter = bluetooth!!.adapter
		if (!adapter.isEnabled) {
			Log.d(TAG, "Bluetooth is not enabled, requesting to enable. You will need to manually re-try")
			val btEnableIntent = Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE)
			startActivityForResult(activity!!, btEnableIntent, REQUEST_ENABLE_BT, null)
			return result.success(false)
		}

		val advertiser = adapter.bluetoothLeAdvertiser
		startAdvertiseResult = result
		for (service in gattServices) {
			gattServer?.removeService(service)
		}
		gattServices.clear()
		for (device in gattDevices.values) {
			gattServer?.cancelConnection(device)
		}
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

					if (rawProperties.contains("NOTIFY") || rawProperties.contains("INDICATE")) {
						gattCharacteristic.addDescriptor(
							BluetoothGattDescriptor(
								CCD_CHARACTERISTIC,
								BluetoothGattDescriptor.PERMISSION_READ or BluetoothGattDescriptor.PERMISSION_WRITE
							)
						)
					}
					gattService.addCharacteristic(gattCharacteristic)
				}
				gattServices.add(gattService)
			}
		}

		val data = AdvertiseData.Builder()

		val name = call.argument<String>("name")
		if (name != null) {
			originalName = bluetooth!!.adapter.name
			bluetooth!!.adapter.name = name
			data.setIncludeDeviceName(true)
		} else {
			data.setIncludeDeviceName(false)
		}

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

			advertiseSetCallback = object : AdvertisingSetCallback() {
				override fun onAdvertisingSetStarted(advertisingSet: AdvertisingSet?, txPower: Int, status: Int) {
					super.onAdvertisingSetStarted(advertisingSet, txPower, status)

					if (status == ADVERTISE_SUCCESS) {
						Log.i(TAG, "Advertise set started successfully")
						startAdvertiseResult?.success(true)
						startAdvertiseResult = null

						if (bluetooth == null) return
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

		advertiseCallback = object : AdvertiseCallback() {
			override fun onStartSuccess(settingsInEffect: AdvertiseSettings?) {
				super.onStartSuccess(settingsInEffect)
				Log.i(TAG, "Advertise started successfully")

				startAdvertiseResult?.success(true)
				startAdvertiseResult = null

				if (bluetooth == null) return
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
		advertiser.startAdvertising(settings, data.build(), advertiseCallback)
	}

	/* Stops the avertisement */
	private fun stopAdvertise(result: Result) {
		if (gattServer == null) {
			Log.d(TAG, "Gatt server is null")
			result.success(true)
			return
		}

		val advertiser = bluetooth!!.adapter.bluetoothLeAdvertiser
		if (advertiser == null) {
			Log.d(TAG, "Bluetooth advertiser is null")
			result.success(true)
			return
		}

		if (originalName.isNotEmpty()) {
			bluetooth!!.adapter.name = originalName
		}

		originalName = ""

		for (device in gattDevices.values) {
			gattServer!!.cancelConnection(device)
			bluetooth!!.adapter
		}
		gattDevices.clear()
		gattServer!!.clearServices()
		gattServices.clear()
		gattServer!!.close()
		gattServer = null

		if (advertiseCallback != null) {
			Log.i(TAG, "Stopping advertisement (Bluetooth Legacy)")
			advertiser.stopAdvertising(advertiseCallback)
			advertiseCallback = null
		}

		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && advertiseSetCallback != null) {
			Log.i(TAG, "Stopping advertisement (Bluetooth 5.0)")
			advertiser.stopAdvertisingSet(advertiseSetCallback)
			advertiseSetCallback = null
		}

		Log.d(TAG, "Advertisement stopped")
		result.success(true)
	}

	/* Checks if the device supports BLE */
	private fun checkCapabilities(result: Result) {
		bluetooth =
			context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager

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
			bluetooth = context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
		}

		val adapter = bluetooth!!.adapter

		if (!adapter.isEnabled) {
			Log.d(TAG, "Bluetooth is not enabled, requesting to enable. You will need to manually re-try")
			val btEnableIntent = Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE)
			startActivityForResult(activity!!, btEnableIntent, REQUEST_ENABLE_BT, null)
			return result.success(false)
		}
		Log.d(TAG, "Bluetooth is enabled, starting scan")
		isScanning = true
		lastOperation = LastOperation.SCAN

		val settings = composeSettings(adapter = adapter)

		bluetooth!!.adapter.bluetoothLeScanner.startScan(null, settings.build(), scanCallback)
		result.success(true)
		startScanResult = null
		Handler(Looper.getMainLooper()).post {
			eventsChannel.invokeMethod("onScanStarted", null)
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
			result.success(true)
			stopScanResult = null
			return
		}

		if (bluetooth == null) {
			Log.d(TAG, "Bluetooth is null, initializing")
			bluetooth = context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
		}

		val adapter = bluetooth!!.adapter
		Log.d(TAG, "Stopping scan")
		adapter!!.bluetoothLeScanner.stopScan(scanCallback)
		result.success(true)
		stopScanResult = null
		filteredMacAddress = null
		Handler(Looper.getMainLooper()).post {
			eventsChannel.invokeMethod("onScanStopped", null)
		}
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

		val macAddress = searchingMacAddress!!.uppercase()

		if (!devices.containsKey(macAddress)) {
			Log.d(TAG, "Device not found")
			result.success(false)
			connectResult = null
			return
		}

		if (connectedDevices.containsKey(macAddress)) {
			Log.d(TAG, "Device already connected")
			result.success(true)
			connectResult = null
			return
		}

		val device = devices[macAddress]!!
		connectResult = result
		lastOperation = LastOperation.CONNECT
		val gatt = device.connectGatt(context, false, gattCallback)
		gatt!!.connect()
	}

	/* Disconnects from a BLE device */
	private fun disconnect(call: MethodCall, result: Result) {
		val macAddress = call.arguments as String?
		if (macAddress == null) {
			for (device in connectedDevices.values) {
				device.disconnect()
			}
			servicesAndCharacteristics.clear()
			connectedDevices.clear()
		} else {
			val device = connectedDevices[macAddress]
			if (device == null) {
				Log.d(TAG, "Device not connected")
				result.success(false)
				disconnectResult = null
				return
			}
			device.disconnect()
			servicesAndCharacteristics.remove(macAddress)
			connectedDevices.remove(macAddress)
		}
		result.success(true)
		disconnectResult = null
	}

	/* Discovers the services of a BLE device */
	private fun discoverServices(call: MethodCall, result: Result) {
		val output: MutableList<Map<String, Any>> = mutableListOf()

		val macAddress = call.argument<String>("macAddress")
		if (macAddress == null) {
			Log.d(TAG, "No macAddress provided")
			result.success(null)
			discoverServicesResult = null
			return
		}

		if (!connectedDevices.containsKey(macAddress)) {
			Log.d(TAG, "Device not connected")
			result.success(null)
			discoverServicesResult = null
			return
		}

		if (!servicesAndCharacteristics.containsKey(macAddress)) {
			Log.d(TAG, "Services not found")
			result.success(null)
			discoverServicesResult = null
			return
		}

		val services = servicesAndCharacteristics[macAddress]!!
		for (service in services) {
			val characteristics = service.characteristics.map { characteristic ->
				mapOf(
					"uuid" to characteristic.uuid,
					"properties" to characteristic.properties
				)
			}
			output.add(
				mapOf(
					"uuid" to service.uuid,
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
		val newMtu = call.argument<Int>("newMtu")
		if (newMtu == null) {
			Log.d(TAG, "No mtu provided")
			result.success(null)
			setMtuResult = null
			return
		}

		val macAddress = call.argument<String>("macAddress")
		if (macAddress == null) {
			Log.d(TAG, "No macAddress provided")
			result.success(null)
			setMtuResult = null
			return
		}

		if (!connectedDevices.containsKey(macAddress)) {
			Log.d(TAG, "Device not connected")
			result.success(null)
			setMtuResult = null
			return
		}

		val gatt = connectedDevices[macAddress]
		setMtuResult = result
		lastOperation = LastOperation.SET_MTU
		gatt!!.requestMtu(newMtu)
	}

	/* Sends a payload to a BLE device */
	private fun writeCharacteristic(call: MethodCall, result: Result) {
		val macAddress = call.argument<String>("macAddress")
		if (macAddress == null) {
			Log.d(TAG, "No macAddress provided")
			result.success(null)
			writeCharacteristicResult = null
			return
		}

		if (!connectedDevices.containsKey(macAddress)) {
			Log.d(TAG, "Device not connected")
			result.success(null)
			writeCharacteristicResult = null
			return
		}

		val gatt = connectedDevices[macAddress]
		if (gatt == null) {
			Log.d(TAG, "No device connected")
			result.success(null)
			writeCharacteristicResult = null
			return
		}

		val serviceUuid = call.argument<String>("serviceUuid")?.uppercase()
		if (serviceUuid == null) {
			Log.d(TAG, "No serviceUuid provided")
			result.success(null)
			writeCharacteristicResult = null
			return
		}

		val characteristicUuid = call.argument<String>("characteristicUuid")?.uppercase()
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

		val writeType = call.argument<Boolean>("withResponse") ?: true

		Log.d(TAG, "Service: $serviceUuid")
		val service = servicesAndCharacteristics[macAddress]?.find { it.uuid == serviceUuid }
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

		if (!characteristic.properties.contains("WRITE") && !characteristic.properties.contains("WRITE_WO_RSP")) {
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
			gatt.writeCharacteristic(
				characteristic.characteristic,
				payload,
				type,
			)
		} else {
			characteristic.characteristic.value = payload
			characteristic.characteristic.writeType = type
			gatt.writeCharacteristic(characteristic.characteristic)
		}
	}

	/* Reads a payload from a BLE device */
	private fun readCharacteristic(call: MethodCall, result: Result) {
		val macAddress = call.argument<String>("macAddress")
		if (macAddress == null) {
			Log.d(TAG, "No macAddress provided")
			result.success(null)
			readCharacteristicResult = null
			return
		}

		if (!connectedDevices.containsKey(macAddress)) {
			Log.d(TAG, "Device not connected")
			result.success(null)
			readCharacteristicResult = null
			return
		}

		val gatt = connectedDevices[macAddress]
		if (gatt == null) {
			Log.d(TAG, "No device connected")
			result.success(null)
			readCharacteristicResult = null
			return
		}

		val serviceUuid = call.argument<String>("serviceUuid")?.uppercase()
		if (serviceUuid == null) {
			Log.d(TAG, "No serviceUuid provided")
			result.success(null)
			readCharacteristicResult = null
			return
		}

		val characteristicUuid = call.argument<String>("characteristicUuid")?.uppercase()
		if (characteristicUuid == null) {
			Log.d(TAG, "No characteristicUuid provided")
			result.success(null)
			readCharacteristicResult = null
			return
		}

		val service = gatt.getService(UUID.fromString(serviceUuid))
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
		gatt.readCharacteristic(characteristic)
	}

	/* Subscribe to a characteristic */
	private fun startNotify(call: MethodCall, result: Result) {
		val macAddress = call.argument<String>("macAddress")?.uppercase()
		if (macAddress == null) {
			Log.d(TAG, "No macAddress provided")
			result.success(false)
			startNotifyResult = null
			return
		}

		if (!connectedDevices.containsKey(macAddress)) {
			Log.d(TAG, "Device not connected")
			result.success(false)
			startNotifyResult = null
			return
		}

		val gatt = connectedDevices[macAddress]
		if (gatt == null) {
			Log.d(TAG, "No device connected")
			result.success(false)
			startNotifyResult = null
			return
		}

		val serviceUuid = call.argument<String>("serviceUuid")?.uppercase()
		if (serviceUuid == null) {
			Log.d(TAG, "No serviceUuid provided")
			result.success(false)
			startNotifyResult = null
			return
		}

		val characteristicUuid = call.argument<String>("characteristicUuid")?.uppercase()
		if (characteristicUuid == null) {
			Log.d(TAG, "No characteristicUuid provided")
			result.success(false)
			startNotifyResult = null
			return
		}

		val keyOfMap = "${characteristicUuid}-${macAddress}"
		if (currentNotifications.contains(keyOfMap)) {
			Log.d(TAG, "Already subscribed")
			result.success(true)
			startNotifyResult = null
			return
		}

		val service = servicesAndCharacteristics[macAddress]?.find { it.uuid == serviceUuid }
		if (service == null) {
			Log.d(TAG, "Service not found")
			result.success(false)
			startNotifyResult = null
			return
		}

		val characteristic = service.characteristics.find { it.uuid == characteristicUuid }
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

		val notificationResult = gatt.setCharacteristicNotification(
			characteristic.characteristic,
			true
		)

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
		gatt.writeDescriptor(descriptor)

		currentNotifications.add(keyOfMap)
		result.success(true)
		startNotifyResult = null
	}

	/* Unsubscribe from a characteristic */
	private fun stopNotify(call: MethodCall, result: Result) {
		val macAddress = call.argument<String>("macAddress")
		if (macAddress == null) {
			Log.d(TAG, "No macAddress provided")
			result.success(false)
			stopNotifyResult = null
			return
		}

		if (!connectedDevices.containsKey(macAddress)) {
			Log.d(TAG, "Device not connected")
			result.success(false)
			stopNotifyResult = null
			return
		}

		val gatt = connectedDevices[macAddress]
		if (gatt == null) {
			Log.d(TAG, "No device connected")
			result.success(false)
			stopNotifyResult = null
			return
		}

		val rawServiceUuid = call.argument<String>("serviceUuid")?.uppercase()
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

		val rawCharacteristicUuid = call.argument<String>("characteristicUuid")?.uppercase()
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

		val keyOfMap = "${standarizeUuid(characteristicUuid)}-${macAddress}"
		if (!currentNotifications.contains(keyOfMap)) {
			Log.d(TAG, "Not subscribed")
			result.success(true)
			stopNotifyResult = null
			return
		}

		val service = servicesAndCharacteristics[macAddress]?.find { it.uuid == standarizeUuid(serviceUuid) }
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

		gatt.setCharacteristicNotification(characteristic.characteristic, false)
		currentNotifications.remove(keyOfMap)
		result.success(true)
		stopNotifyResult = null
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
					val adapter = bluetooth!!.adapter
					val settings = composeSettings(adapter = adapter)
					adapter.bluetoothLeScanner.startScan(null, settings.build(), scanCallback)
					isScanning = true
					lastOperation = LastOperation.SCAN
					startScanResult?.success(true)
					startScanResult = null
					Handler(Looper.getMainLooper()).post {
						eventsChannel.invokeMethod("onScanStarted", null)
					}
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
			return true
		}
		return false
	}

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

	private fun notifyOff() {
		Log.i(TAG, "Bluetooth is turned off")
		Handler(Looper.getMainLooper()).post {
			eventsChannel.invokeMethod("onBluetoothOff", "BLUETOOTH_OFF")
		}
	}

	private fun notifyOn() {
		Log.i(TAG, "Bluetooth is turned on")
		Handler(Looper.getMainLooper()).post {
			eventsChannel.invokeMethod("onBluetoothOn", "BLUETOOTH_ON")
		}
	}

	private fun forceStopAll() {
		Log.i(TAG, "Bluetooth is stopping")
		gattServer?.clearServices()
		gattServer?.close()
		gattServer = null

		devices.clear()
		servicesAndCharacteristics.clear()
		gattServices.clear()
		gattDevices.clear()

		val bluetooth = bluetooth ?: return
		if (isScanning) {
			bluetooth.adapter.bluetoothLeScanner.stopScan(scanCallback)
		}
	}

	private fun composeSettings(adapter: BluetoothAdapter): ScanSettings.Builder {
		val settings = ScanSettings.Builder()
		settings.setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY)
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
