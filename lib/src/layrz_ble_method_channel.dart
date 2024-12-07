import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:layrz_ble/src/types.dart';
import 'package:layrz_models/layrz_models.dart';

import 'layrz_ble_platform_interface.dart';

/// An implementation of [LayrzBlePlatform] that uses method channels.
class MethodChannelLayrzBle extends LayrzBlePlatform {
  void log(String message) {
    debugPrint('LayrzBlePlugin/Dart: $message');
  }

  MethodChannelLayrzBle() {
    methodChannel.setMethodCallHandler((call) async {
      log('MethodChannelLayrzBle: ${call.method}');
      switch (call.method) {
        case 'onScan':
          try {
            final device = BleDevice.fromJson(Map<String, dynamic>.from(call.arguments));
            _scanController.add(device);
          } catch (e) {
            log('Error parsing BleDevice: $e');
          }
          break;
        default:
          throw MissingPluginException();
      }
    });
  }

  @visibleForTesting
  final methodChannel = const MethodChannel('com.layrz.layrz_ble');

  final StreamController<BleDevice> _scanController = StreamController<BleDevice>.broadcast();
  final StreamController<BleEvent> _eventController = StreamController<BleEvent>.broadcast();

  @override
  Stream<BleDevice> get onScan => _scanController.stream;

  @override
  Stream<BleEvent> get onEvent => _eventController.stream;

  @override
  Future<bool?> startScan() => methodChannel.invokeMethod<bool>('startScan');

  @override
  Future<bool?> stopScan() => methodChannel.invokeMethod<bool>('stopScan');

  @override
  Future<BleCapabilities> checkCapabilities() async {
    final result = await methodChannel.invokeMethod<Map>('checkCapabilities');
    if (result == null) {
      log('Error checking BleCapabilities from native side');
      return BleCapabilities(
        locationPermission: false,
        bluetoothPermission: false,
        bluetoothAdminOrScanPermission: false,
        bluetoothConnectPermission: false,
      );
    }

    try {
      return BleCapabilities.fromMap(Map<String, dynamic>.from(result));
    } catch (e) {
      log('Error parsing BleCapabilities: $e');
      return BleCapabilities(
        locationPermission: false,
        bluetoothPermission: false,
        bluetoothAdminOrScanPermission: false,
        bluetoothConnectPermission: false,
      );
    }
  }
}
