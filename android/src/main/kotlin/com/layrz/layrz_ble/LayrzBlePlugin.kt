package com.layrz.layrz_ble


import android.Manifest
import android.app.Activity
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.bluetooth.le.ScanCallback
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.app.ActivityCompat.startActivityForResult
import io.flutter.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry

class LayrzBlePlugin : FlutterPlugin, MethodCallHandler, ActivityAware,
    PluginRegistry.ActivityResultListener {
    private lateinit var channel: MethodChannel
    private lateinit var context: android.content.Context
    private var bluetooth: BluetoothManager? = null

    private var activity: Activity? = null
    private var result: Result? = null

    private var isScanning = false
    private val scanCallback = object : ScanCallback() {
        override fun onScanResult(callbackType: Int, result: android.bluetooth.le.ScanResult?) {
            super.onScanResult(callbackType, result)
            if (result != null) {
                val device = result.device
                val name = if (ActivityCompat.checkSelfPermission(
                        context,
                        Manifest.permission.BLUETOOTH_CONNECT
                    ) == PackageManager.PERMISSION_GRANTED
                ) {
                    device.name ?: "Unknown"
                } else {
                    "Unknown"
                }
                val macAddress = device.address
                val rssi = result.rssi
                val advertisementData = result.scanRecord?.bytes

                channel.invokeMethod(
                    "onScan",
                    mapOf(
                        "name" to name,
                        "macAddress" to macAddress,
                        "rssi" to rssi,
                        "advertisementData" to advertisementData
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
            result.error("operation_in_progress", "Operation in progress, ignoring new call", null)
            return
        }

        when (call.method) {
            "checkCapabilities" -> checkCapabilities(result = result)
            "startScan" -> startScan(result = result)
            "stopScan" -> stopScan(result = result)
            "connect" -> connect(call = call, result = result)
            "disconnect" -> disconnect(call = call, result = result)
            "sendPayload" -> sendPayload(call = call, result = result)
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
                    Manifest.permission.BLUETOOTH_CONNECT
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
    private fun startScan(result: Result) {
        if (isScanning) {
            Log.d(TAG, "Already scanning")
            result.success(true)
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
                Log.d(TAG, "No location permission")
                result.success(false)
                return
            }
        }

        if (bluetooth == null) {
            Log.d(TAG, "Bluetooth is null, initializing")
            bluetooth =
                context.getSystemService(android.content.Context.BLUETOOTH_SERVICE) as BluetoothManager
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
            adapter!!.bluetoothLeScanner.startScan(scanCallback)
            result.success(true)
        }
    }

    /* Stops the scanning */
    private fun stopScan(result: Result) {
        if (!isScanning) {
            Log.d(TAG, "Not scanning")
            result.success(true)
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
    }

    /* Connects to a BLE device */
    private fun connect(call: MethodCall, result: Result) {
        result.success(true)
    }

    /* Disconnects from a BLE device */
    private fun disconnect(call: MethodCall, result: Result) {
        result.success(true)
    }

    /* Sends a payload to a BLE device */
    private fun sendPayload(call: MethodCall, result: Result) {
        result.success(true)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        Log.d(TAG, "onActivityResult $requestCode $resultCode $data")
        if (requestCode == REQUEST_ENABLE_BT) {
            if (resultCode == Activity.RESULT_OK) {
                Log.d(TAG, "Bluetooth enabled, starting scan")
                if (ActivityCompat.checkSelfPermission(
                        context,
                        Manifest.permission.BLUETOOTH_SCAN
                    ) != PackageManager.PERMISSION_GRANTED
                ) {
                    bluetooth!!.adapter.bluetoothLeScanner.startScan(scanCallback)
                    isScanning = true
                    result?.success(true)
                } else {
                    Log.d(TAG, "No location permission")
                    result?.success(false)
                }
            } else {
                Log.d(TAG, "Bluetooth not enabled")
                result?.success(false)
            }
            return true
        }
        return false
    }
}
