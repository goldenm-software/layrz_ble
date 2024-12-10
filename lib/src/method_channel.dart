import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:layrz_ble/src/types.dart';
import 'package:layrz_models/layrz_models.dart';

import 'platform_interface.dart';

/// An implementation of [LayrzBlePlatform] that uses method channels.
class LayrzBleNative extends LayrzBlePlatform {
  void log(String message) {
    debugPrint('LayrzBlePlugin/Dart: $message');
  }

  LayrzBleNative() {
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
  final StreamController<List<int>> _notifyController = StreamController<List<int>>.broadcast();

  @override
  Stream<BleDevice> get onScan => _scanController.stream;

  @override
  Stream<BleEvent> get onEvent => _eventController.stream;

  @override
  Stream<List<int>> get onNotify => _notifyController.stream;

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

  @override
  Future<int?> setMtu({required int newMtu}) => methodChannel.invokeMethod<int>('setMtu', newMtu);

  @override
  Future<bool?> connect({required String macAddress}) => methodChannel.invokeMethod<bool>('connect', macAddress);

  @override
  Future<bool?> disconnect() => methodChannel.invokeMethod<bool>('disconnect');

  @override
  Future<List<BleService>?> discoverServices({required String macAddress}) async {
    final result = await methodChannel.invokeMethod<List>('discoverServices', macAddress);
    if (result == null) {
      log('Error discovering services from native side');
      return null;
    }

    try {
      return result.map((e) => BleService.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (e) {
      log('Error parsing BleService: $e');
      return null;
    }
  }

  @override
  Future<List<BleCharacteristic>?> discoverCharacteristics({
    required String macAddress,
    required String serviceUuid,
  }) async {
    final result = await methodChannel.invokeMethod<List>('discoverCharacteristics', <String, String>{
      'macAddress': macAddress,
      'uuid': serviceUuid,
    });

    if (result == null) {
      log('Error discovering characteristics from native side');
      return null;
    }

    try {
      return result.map((e) => BleCharacteristic.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (e) {
      log('Error parsing BleCharacteristic: $e');
      return null;
    }
  }

  @override
  Future<bool> sendPayload({
    required String macAddress,
    required String serviceUuid,
    required String characteristicUuid,
    required List<int> payload,
  }) async {
    final result = await methodChannel.invokeMethod<bool>('sendPayload', <String, dynamic>{
      'macAddress': macAddress,
      'serviceUuid': serviceUuid,
      'characteristicUuid': characteristicUuid,
      'payload': payload,
    });

    if (result == null) {
      log('Error sending payload from native side');
      return false;
    }

    return result;
  }

  @override
  Future<bool?> startNotify({
    required String macAddress,
    required String serviceUuid,
    required String characteristicUuid,
  }) {
    return methodChannel.invokeMethod<bool>('startNotify', <String, String>{
      'macAddress': macAddress,
      'serviceUuid': serviceUuid,
      'characteristicUuid': characteristicUuid,
    });
  }

  @override
  Future<bool?> stopNotify({
    required String macAddress,
    required String serviceUuid,
    required String characteristicUuid,
  }) {
    return methodChannel.invokeMethod<bool>('stopNotify', <String, String>{
      'macAddress': macAddress,
      'serviceUuid': serviceUuid,
      'characteristicUuid': characteristicUuid,
    });
  }
}
