@file:Suppress("DEPRECATION", "SpellCheckingInspection")

package com.layrz.layrz_ble


import android.Manifest
import android.annotation.SuppressLint
import android.app.Activity
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothGatt
import android.bluetooth.BluetoothGattCharacteristic
import android.bluetooth.BluetoothGattDescriptor
import android.bluetooth.BluetoothManager
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanResult
import android.bluetooth.le.ScanSettings
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
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
    private lateinit var channel: MethodChannel
    private lateinit var context: android.content.Context
    private var bluetooth: BluetoothManager? = null

    private var activity: Activity? = null
    private var result: Result? = null

    // Bluetooth device connection
    private var filteredMacAddress: String? = null
    private val devices: HashMap<String, android.bluetooth.BluetoothDevice> = HashMap()
    private var searchingMacAddress: String? = null
    private var gatt: BluetoothGatt? = null
    private var connectedDevice: android.bluetooth.BluetoothDevice? = null

    private var isScanning = false
    private var lastOperation: LastOperation? = null
    private var currentNotifications: MutableList<String> = mutableListOf()
    private var servicesAndCharacteristics: MutableMap<String, BleService> = mutableMapOf()

    private val scanCallback = object : ScanCallback() {
        @SuppressLint("MissingPermission")
        override fun onScanResult(callbackType: Int, result: ScanResult?) {
            super.onScanResult(callbackType, result)
            val scanRecord = result?.scanRecord
            if (result == null) {
                Log.d(TAG, "No result")
                return
            }

            if (lastOperation != LastOperation.SCAN) {
                Log.d(TAG, "Not scanning")
                return
            }

            val device = result.device
            val macAddress = device.address.uppercase()

            if (filteredMacAddress != null && macAddress != filteredMacAddress) {
//                Log.d(TAG, "Filter applied and mac address does not match - $macAddress - $filteredMacAddress")
                return
            }

            val name = scanRecord?.deviceName ?: device.name ?: "Unknown"
            Log.d(TAG, "Found device $name - $macAddress")
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

            channel.invokeMethod(
                "onScan",
                mapOf(
                    "name" to name,
                    "macAddress" to macAddress,
                    "rssi" to rssi,
                    "manufacturerData" to manufacturerData,
                    "serviceData" to serviceData
                )
            )

            devices[macAddress] = device
        }
    }

    private val gattCallback = object : android.bluetooth.BluetoothGattCallback() {
        @SuppressLint("MissingPermission")
        override fun onConnectionStateChange(
            gatt: BluetoothGatt?,
            status: Int,
            newState: Int
        ) {
            super.onConnectionStateChange(gatt, status, newState)
            if (connectedDevice == null) return
            if (lastOperation != LastOperation.CONNECT) {
                if (status == BluetoothGatt.STATE_DISCONNECTED) {
                    connectedDevice = null
                    Handler(Looper.getMainLooper()).post {
                        channel.invokeMethod(
                            "onEvent",
                            "DISCONNECTED"
                        )
                    }
                }
                return
            }
            if (result == null) return

            if (newState == android.bluetooth.BluetoothProfile.STATE_CONNECTED) {
                connectedDevice = gatt!!.device
                servicesAndCharacteristics.clear()
                Log.d(TAG, "Connected to ${connectedDevice!!.address}, discovering services")
                gatt.discoverServices()
            } else {
                Log.d(TAG, "Connection failed")
                result!!.success(false)
                result = null
            }
        }

        override fun onServicesDiscovered(gatt: BluetoothGatt?, status: Int) {
            super.onServicesDiscovered(gatt, status)
            if (connectedDevice == null) return
            if (lastOperation != LastOperation.CONNECT) return
            if (result == null) return
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
                                uuid = standarizeUuid(characteristic.uuid),
                                properties = propertyList
                            )
                        )
                    }

                    servicesAndCharacteristics[standarizeUuid(service.uuid)] = BleService(
                        uuid = standarizeUuid(service.uuid),
                        characteristics = characteristics
                    )
                }

                Log.d(TAG, "Services discovered")
                result!!.success(true)
                result = null
            } else {
                Log.d(TAG, "Discover services failed")
                result!!.success(null)
                result = null
            }
        }

        override fun onMtuChanged(gatt: BluetoothGatt?, mtu: Int, status: Int) {
            super.onMtuChanged(gatt, mtu, status)

            if (lastOperation != LastOperation.SET_MTU) return
            if (result == null) return

            if (status == BluetoothGatt.GATT_SUCCESS) {
                result!!.success(mtu)
            } else {
                Log.d(TAG, "MTU change failed")
                result!!.success(null)
            }

            result = null
        }

        override fun onCharacteristicWrite(
            gatt: BluetoothGatt?,
            characteristic: BluetoothGattCharacteristic?,
            status: Int
        ) {
            super.onCharacteristicWrite(gatt, characteristic, status)

            if (lastOperation != LastOperation.WRITE_CHARACTERISTIC) return
            if (result == null) return

            if (status == BluetoothGatt.GATT_SUCCESS) {
                result!!.success(true)
            } else {
                Log.d(TAG, "Characteristic write failed")
                result!!.success(false)
            }
            result = null
        }

        @Deprecated("Deprecated in Java")
        override fun onCharacteristicRead(
            gatt: BluetoothGatt,
            characteristic: BluetoothGattCharacteristic,
            status: Int
        ) {
            super.onCharacteristicRead(gatt, characteristic, status)

            if (lastOperation != LastOperation.READ_CHARACTERISTIC) return
            if (result == null) return

            if (status == BluetoothGatt.GATT_SUCCESS) {
                result!!.success(characteristic.value)
            } else {
                Log.d(TAG, "Characteristic read failed")
                result!!.success(null)
            }

            result = null
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
                channel.invokeMethod(
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
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.layrz.layrz_ble")
        channel.setMethodCallHandler(this)

        context = flutterPluginBinding.applicationContext
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        Log.d(TAG, "Method call: ${call.method}")

        if (this.result != null) {
            Log.d(TAG, "Operation in progress, ignoring new call")
            result.error(
                "OPERATION_IN_PROGRESS",
                "$lastOperation in progress, ignoring new call",
                null,
            )
            return
        }

        when (call.method) {
            "checkCapabilities" -> checkCapabilities(result = result)
            "startScan" -> startScan(call = call, result = result)
            "stopScan" -> stopScan(result = result)
            "connect" -> connect(call = call, result = result)
            "disconnect" -> disconnect(result = result)
            "discoverServices" -> discoverServices(call = call, result = result)
            "setMtu" -> setMtu(call = call, result = result)
            "writeCharacteristic" -> writeCharacteristic(call = call, result = result)
            "readCharacteristic" -> readCharacteristic(call = call, result = result)
            "startNotify" -> startNotify(call = call, result = result)
            "stopNotify" -> stopNotify(call = call, result = result)
            else -> result.notImplemented()
        }
    }

    /* Validates the capabilities of the BLE */
    private fun checkCapabilities(result: Result) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
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

            result.success(
                mapOf(
                    "locationPermission" to location,
                    "bluetoothPermission" to bluetooth,
                    "bluetoothAdminOrScanPermission" to bluetoothAdminOrScan,
                    "bluetoothConnectPermission" to bluetoothConnect
                )
            )
        } else {
            result.success(null)
        }
    }

    /* Starts the scanning */
    private fun startScan(call: MethodCall, result: Result) {
        @SuppressLint("MissingPermission")
        if (isScanning) {
            bluetooth!!.adapter.bluetoothLeScanner.stopScan(scanCallback)
        }

        filteredMacAddress = call.argument<String>("macAddress")
        if (filteredMacAddress != null) {
            Log.d(TAG, "Filtering by macAddress: $filteredMacAddress")
            filteredMacAddress = filteredMacAddress!!.uppercase()
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val perm1 = ActivityCompat.checkSelfPermission(
                context,
                Manifest.permission.ACCESS_FINE_LOCATION
            ) == PackageManager.PERMISSION_GRANTED
            val perm2 = ActivityCompat.checkSelfPermission(
                context,
                Manifest.permission.BLUETOOTH
            ) == PackageManager.PERMISSION_GRANTED
            val perm3 = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                ActivityCompat.checkSelfPermission(
                    context,
                    Manifest.permission.BLUETOOTH_CONNECT
                ) == PackageManager.PERMISSION_GRANTED
            } else {
                ActivityCompat.checkSelfPermission(
                    context,
                    Manifest.permission.BLUETOOTH_ADMIN
                ) == PackageManager.PERMISSION_GRANTED
            }

            if (!(perm1 && perm2 && perm3)) {
                Log.d(TAG, "No location permission")
                result.success(false)
                return
            }
        }

        if (bluetooth == null) {
            Log.d(TAG, "Bluetooth is null, initializing")
            bluetooth = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                context.getSystemService(BluetoothManager::class.java)
            } else {
                context.getSystemService(android.content.Context.BLUETOOTH_SERVICE) as BluetoothManager
            }
        }

        val adapter = bluetooth!!.adapter

        if (!adapter.isEnabled) {
            Log.d(TAG, "Bluetooth is not enabled, requesting to enable")
            val btEnableIntent = Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE)
            startActivityForResult(activity!!, btEnableIntent, REQUEST_ENABLE_BT, null)
            this.result = result
        } else {
            Log.d(TAG, "Bluetooth is enabled, starting scan")
            isScanning = true
            lastOperation = LastOperation.SCAN
            bluetooth!!.adapter.bluetoothLeScanner.startScan(scanCallback)
            result.success(true)
            this.result = null
        }
    }

    /* Stops the scanning */
    private fun stopScan(result: Result) {
        if (!isScanning) {
            Log.d(TAG, "Not scanning")
            result.success(true)
            this.result = null
            return
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val perm1 = ActivityCompat.checkSelfPermission(
                context,
                Manifest.permission.ACCESS_FINE_LOCATION
            ) == PackageManager.PERMISSION_GRANTED
            val perm2 = ActivityCompat.checkSelfPermission(
                context,
                Manifest.permission.BLUETOOTH
            ) == PackageManager.PERMISSION_GRANTED
            val perm3 = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                ActivityCompat.checkSelfPermission(
                    context,
                    Manifest.permission.BLUETOOTH_CONNECT
                ) == PackageManager.PERMISSION_GRANTED
            } else {
                ActivityCompat.checkSelfPermission(
                    context,
                    Manifest.permission.BLUETOOTH_ADMIN
                ) == PackageManager.PERMISSION_GRANTED
            }

            if (!(perm1 && perm2 && perm3)) {
                Log.d(TAG, "No permissions")
                result.success(false)
                this.result = null
                return
            }
        }

        if (bluetooth == null) {
            Log.d(TAG, "Bluetooth is null, initializing")
            bluetooth =
                context.getSystemService(android.content.Context.BLUETOOTH_SERVICE) as BluetoothManager
        }

        val adapter = bluetooth!!.adapter

        Log.d(TAG, "Stopping scan")
        adapter!!.bluetoothLeScanner.stopScan(scanCallback)
        result.success(true)
        this.result = null
        filteredMacAddress = null
    }

    /* Connects to a BLE device */
    @SuppressLint("MissingPermission")
    private fun connect(call: MethodCall, result: Result) {
        searchingMacAddress = call.arguments as String?

        if (searchingMacAddress == null) {
            Log.d(TAG, "No macAddress provided")
            result.success(false)
            this.result = null
            return
        }

        if (!devices.containsKey(searchingMacAddress!!)) {
            Log.d(TAG, "Device not found")
            result.success(false)
            this.result = null
            return
        }

        if (isScanning) {
            isScanning = false
            channel.invokeMethod("onEvent", "SCAN_STOPPED")
            bluetooth!!.adapter.bluetoothLeScanner.stopScan(scanCallback)
        }

        connectedDevice = devices[searchingMacAddress!!]!!
        this.result = result
        lastOperation = LastOperation.CONNECT
        gatt = connectedDevice!!.connectGatt(context, true, gattCallback)
    }

    /* Disconnects from a BLE device */
    @SuppressLint("MissingPermission")
    private fun disconnect(result: Result) {
        if (gatt == null) {
            Log.d(TAG, "No device connected")
            result.success(false)
            this.result = null
            return
        }

        gatt!!.disconnect()
        result.success(true)
        this.result = null
    }

    /* Discovers the services of a BLE device */
    @SuppressLint("MissingPermission")
    private fun discoverServices(call: MethodCall, result: Result) {
        if (gatt == null) {
            Log.d(TAG, "No device connected")
            result.success(null)
            this.result = null
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
        this.result = null
        return
    }

    /* Sets the MTU of a BLE device */
    @SuppressLint("MissingPermission")
    private fun setMtu(call: MethodCall, result: Result) {
        val newMtu = call.arguments as Int?
        if (newMtu == null) {
            Log.d(TAG, "No mtu provided")
            result.success(null)
            this.result = null
            return
        }

        if (gatt == null) {
            Log.d(TAG, "No device connected")
            result.success(null)
            this.result = null
            return
        }

        this.result = result
        lastOperation = LastOperation.SET_MTU
        gatt!!.requestMtu(newMtu)
    }

    /* Sends a payload to a BLE device */
    @SuppressLint("MissingPermission")
    private fun writeCharacteristic(call: MethodCall, result: Result) {
        val serviceUuid = call.argument<String>("serviceUuid")
        if (serviceUuid == null) {
            Log.d(TAG, "No serviceUuid provided")
            result.success(null)
            this.result = null
            return
        }

        val characteristicUuid = call.argument<String>("characteristicUuid")
        if (characteristicUuid == null) {
            Log.d(TAG, "No characteristicUuid provided")
            result.success(null)
            this.result = null
            return
        }

        val payload = call.argument<ByteArray>("payload")
        if (payload == null) {
            Log.d(TAG, "No payload provided")
            result.success(null)
            this.result = null
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
            this.result = null
            return
        }

        Log.d(TAG, "Service: $serviceUuid")
        val service = gatt!!.getService(UUID.fromString(serviceUuid))
        if (service == null) {
            Log.d(TAG, "Service not found")
            result.success(null)
            this.result = null
            return
        }

        val characteristic =
            service.getCharacteristic(UUID.fromString(characteristicUuid))
        if (characteristic == null) {
            Log.d(TAG, "Characteristic not found")
            result.success(null)
            this.result = null
            return
        }

        if (characteristic.properties and BluetoothGattCharacteristic.PROPERTY_WRITE == 0) {
            Log.d(TAG, "Characteristic does not support write")
            result.success(null)
            this.result = null
            return
        }

        this.result = result
        lastOperation = LastOperation.WRITE_CHARACTERISTIC

        val type = if (writeType) {
            BluetoothGattCharacteristic.WRITE_TYPE_DEFAULT
        } else {
            BluetoothGattCharacteristic.WRITE_TYPE_NO_RESPONSE
        }
        if (Build.VERSION.SDK_INT > Build.VERSION_CODES.TIRAMISU) {
            gatt!!.writeCharacteristic(
                characteristic,
                payload,
                type,
            )
        } else {
            characteristic.value = payload
            characteristic.writeType = type
            gatt!!.writeCharacteristic(characteristic)
        }

        // Timeout
        spawnTimeout(
            operation = LastOperation.WRITE_CHARACTERISTIC,
            timeoutSeconds = timeoutSeconds,
        )
    }

    /* Reads a payload from a BLE device */
    @SuppressLint("MissingPermission")
    private fun readCharacteristic(call: MethodCall, result: Result) {
        val serviceUuid = call.argument<String>("serviceUuid")
        if (serviceUuid == null) {
            Log.d(TAG, "No serviceUuid provided")
            result.success(null)
            this.result = null
            return
        }

        val characteristicUuid = call.argument<String>("characteristicUuid")
        if (characteristicUuid == null) {
            Log.d(TAG, "No characteristicUuid provided")
            result.success(null)
            this.result = null
            return
        }

        var timeoutSeconds: Int = call.argument<Int>("timeout") ?: 30
        if (timeoutSeconds < 1) {
            timeoutSeconds = 1
        }

        if (gatt == null) {
            Log.d(TAG, "No device connected")
            result.success(null)
            this.result = null
            return
        }

        val service = gatt!!.getService(UUID.fromString(serviceUuid))
        if (service == null) {
            Log.d(TAG, "Service not found")
            result.success(null)
            this.result = null
            return
        }

        val characteristic =
            service.getCharacteristic(UUID.fromString(characteristicUuid))
        if (characteristic == null) {
            Log.d(TAG, "Characteristic not found")
            result.success(null)
            this.result = null
            return
        }

        if (characteristic.properties and BluetoothGattCharacteristic.PROPERTY_READ == 0) {
            Log.d(TAG, "Characteristic does not support read")
            result.success(null)
            this.result = null
            return
        }

        this.result = result
        lastOperation = LastOperation.READ_CHARACTERISTIC
        gatt!!.readCharacteristic(characteristic)

        // Timeout
        spawnTimeout(
            operation = LastOperation.READ_CHARACTERISTIC,
            timeoutSeconds = timeoutSeconds,
        )
    }

    /* Subscribe to a characteristic */
    @SuppressLint("MissingPermission")
    private fun startNotify(call: MethodCall, result: Result) {
        val rawServiceUuid = call.argument<String>("serviceUuid")
        if (rawServiceUuid == null) {
            Log.d(TAG, "No serviceUuid provided")
            result.success(false)
            this.result = null
            return
        }

        val serviceUuid: UUID?
        try {
            serviceUuid = UUID.fromString(rawServiceUuid)
        } catch (e: IllegalArgumentException) {
            Log.d(TAG, "Invalid serviceUuid provided - $rawServiceUuid")
            result.success(false)
            this.result = null
            return
        }

        val rawCharacteristicUuid = call.argument<String>("characteristicUuid")
        if (rawCharacteristicUuid == null) {
            Log.d(TAG, "No characteristicUuid provided")
            result.success(false)
            this.result = null
            return
        }
        val characteristicUuid: UUID?
        try {
            characteristicUuid = UUID.fromString(rawCharacteristicUuid)
        } catch (e: IllegalArgumentException) {
            Log.d(TAG, "Invalid characteristicUuid provided - $rawCharacteristicUuid")
            result.success(false)
            this.result = null
            return
        }

        if (currentNotifications.contains(standarizeUuid(characteristicUuid))) {
            Log.d(TAG, "Already subscribed")
            result.success(true)
            this.result = null
            return
        }

        if (gatt == null) {
            Log.d(TAG, "No device connected")
            result.success(false)
            this.result = null
            return
        }

        val service = gatt!!.getService(serviceUuid)
        if (service == null) {
            Log.d(TAG, "Service not found")
            result.success(false)
            this.result = null
            return
        }

        val characteristic = service.getCharacteristic(characteristicUuid)
        if (characteristic == null) {
            Log.d(TAG, "Characteristic not found")
            result.success(false)
            this.result = null
            return
        }

        if (characteristic.properties and BluetoothGattCharacteristic.PROPERTY_NOTIFY == 0) {
            Log.d(TAG, "Characteristic does not support notify")
            result.success(false)
            this.result = null
            return
        }

        val notificationResult = gatt!!.setCharacteristicNotification(characteristic, true)
        Log.d(TAG, "Notification subscription result: $notificationResult")
        if (!notificationResult) {
            Log.d(TAG, "Notification failed")
            result.success(false)
            this.result = null
            return
        }

        val descriptor = characteristic.getDescriptor(CCD_CHARACTERISTIC)

        if (descriptor == null) {
            Log.d(TAG, "Descriptor not found")
            result.success(false)
            this.result = null
            return
        }

        descriptor.value = BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE
        gatt!!.writeDescriptor(descriptor)

        currentNotifications.add(characteristic.uuid.toString().uppercase().trim())
        result.success(true)
        this.result = null
    }

    /* Unsubscribe from a characteristic */
    @SuppressLint("MissingPermission")
    private fun stopNotify(call: MethodCall, result: Result) {
        val serviceUuid = call.argument<String>("serviceUuid")
        if (serviceUuid == null) {
            Log.d(TAG, "No serviceUuid provided")
            result.success(false)
            this.result = null
            return
        }

        val characteristicUuid = call.argument<String>("characteristicUuid")
        if (characteristicUuid == null) {
            Log.d(TAG, "No characteristicUuid provided")
            result.success(false)
            this.result = null
            return
        }

        if (!currentNotifications.contains(characteristicUuid.uppercase().trim())) {
            Log.d(TAG, "Not subscribed")
            result.success(true)
            this.result = null
            return
        }

        if (gatt == null) {
            Log.d(TAG, "No device connected")
            result.success(false)
            this.result = null
            return
        }

        val service = gatt!!.getService(UUID.fromString(serviceUuid))
        if (service == null) {
            Log.d(TAG, "Service not found")
            result.success(false)
            this.result = null
            return
        }

        val characteristic =
            service.getCharacteristic(UUID.fromString(characteristicUuid))
        if (characteristic == null) {
            Log.d(TAG, "Characteristic not found")
            result.success(false)
            this.result = null
            return
        }

        if (characteristic.properties and BluetoothGattCharacteristic.PROPERTY_NOTIFY == 0) {
            Log.d(TAG, "Characteristic does not support notify")
            result.success(false)
            this.result = null
            return
        }

        gatt!!.setCharacteristicNotification(characteristic, false)
        currentNotifications.remove(characteristic.uuid.toString().uppercase().trim())
        result.success(true)
        this.result = null
    }

    private fun spawnTimeout(operation: LastOperation, timeoutSeconds: Int) {
        CoroutineScope(Dispatchers.IO + Job()).launch {
            delay(timeoutSeconds * 1000L)
            if (lastOperation == operation && result != null) {
                Log.d(TAG, "$operation timed out")
                result?.success(null)
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
                    result?.success(true)
                    this.result = null
                } else {
                    Log.d(TAG, "No location permission")
                    result?.success(false)
                    this.result = null
                }
            } else {
                Log.d(TAG, "Bluetooth not enabled")
                result?.success(false)
                this.result = null
            }
            return true
        }
        return false
    }
}
