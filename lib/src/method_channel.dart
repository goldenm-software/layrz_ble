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
      switch (call.method) {
        case 'onScan':
          try {
            final device = BleDevice.fromJson(Map.from(call.arguments));
            _scanController.add(device);
          } catch (e) {
            log('Error parsing BleDevice: $e');
          }
          break;

        case 'onEvent':
          try {
            final event = BleEvent.fromPlatform(call.arguments);
            _eventController.add(event);
          } catch (e) {
            log('Error parsing BleEvent: $e');
          }
          break;

        case 'onNotify':
          try {
            final notification = BleCharacteristicNotification.fromMap(
                Map<String, dynamic>.from(call.arguments));
            _notifyController.add(notification);
          } catch (e) {
            log('Error parsing BleCharacteristicNotification: $e');
          }
          break;

        default:
          log('Unknown method: ${call.method}');
          break;
      }
    });
  }

  @visibleForTesting
  final methodChannel = const MethodChannel('com.layrz.layrz_ble');

  final StreamController<BleDevice> _scanController =
      StreamController<BleDevice>.broadcast();
  final StreamController<BleEvent> _eventController =
      StreamController<BleEvent>.broadcast();
  final StreamController<BleCharacteristicNotification> _notifyController =
      StreamController<BleCharacteristicNotification>.broadcast();

  @override
  Stream<BleDevice> get onScan => _scanController.stream;

  @override
  Stream<BleEvent> get onEvent => _eventController.stream;

  @override
  Stream<BleCharacteristicNotification> get onNotify =>
      _notifyController.stream;

  @override
  Future<bool?> startScan({String? macAddress, List<String>? servicesUuids}) =>
      methodChannel.invokeMethod<bool>(
        'startScan',
        {'macAddress': macAddress},
      );

  @override
  Future<bool?> stopScan() => methodChannel.invokeMethod<bool>('stopScan');

  @override
  Future<BleCapabilities> checkCapabilities() async {
    debugPrint("Calling");
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
  Future<int?> setMtu({required int newMtu}) =>
      methodChannel.invokeMethod<int>('setMtu', newMtu);

  @override
  Future<bool?> connect({required String macAddress}) =>
      methodChannel.invokeMethod<bool>('connect', macAddress);

  @override
  Future<bool?> disconnect() => methodChannel.invokeMethod<bool>('disconnect');

  @override
  Future<List<BleService>?> discoverServices({
    /// [timeout] is the duration to wait for the services to be discovered.
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final result = await methodChannel.invokeMethod<List>('discoverServices', {
      'timeout': timeout.inSeconds,
    });
    if (result == null) {
      log('Error discovering services from native side');
      return null;
    }

    List<BleService> services = [];

    for (var service in result) {
      try {
        List<BleCharacteristic> characteristics = [];

        for (var characteristic in service['characteristics']) {
          try {
            characteristics.add(BleCharacteristic.fromJson(
                Map<String, dynamic>.from(characteristic)));
          } catch (e) {
            log('Error parsing BleCharacteristic: $e');
          }
        }

        services.add(BleService(
          uuid: service['uuid'],
          characteristics: characteristics,
        ));
      } catch (e) {
        log('Error parsing BleService: $e');
      }
    }
    return services;
  }

  @override
  Future<bool> writeCharacteristic({
    required String serviceUuid,
    required String characteristicUuid,
    required Uint8List payload,
    Duration timeout = const Duration(seconds: 30),
    required bool withResponse,
  }) async {
    final result = await methodChannel
        .invokeMethod<bool>('writeCharacteristic', <String, dynamic>{
      'serviceUuid': serviceUuid,
      'characteristicUuid': characteristicUuid,
      'payload': payload,
      'timeout': timeout.inSeconds,
      'withResponse': withResponse,
    });

    if (result == null) {
      log('Error sending payload from native side');
      return false;
    }

    return result;
  }

  @override
  Future<Uint8List?> readCharacteristic({
    required String serviceUuid,
    required String characteristicUuid,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final result = await methodChannel
        .invokeMethod<Uint8List>('readCharacteristic', <String, dynamic>{
      'serviceUuid': serviceUuid,
      'characteristicUuid': characteristicUuid,
      'timeout': timeout.inSeconds,
    });

    if (result == null) {
      log('Error reading characteristic from native side');
      return null;
    }

    return result;
  }

  @override
  Future<bool?> startNotify({
    required String serviceUuid,
    required String characteristicUuid,
  }) {
    return methodChannel.invokeMethod<bool>('startNotify', <String, String>{
      'serviceUuid': serviceUuid,
      'characteristicUuid': characteristicUuid,
    });
  }

  @override
  Future<bool?> stopNotify({
    required String serviceUuid,
    required String characteristicUuid,
  }) {
    return methodChannel.invokeMethod<bool>('stopNotify', <String, String>{
      'serviceUuid': serviceUuid,
      'characteristicUuid': characteristicUuid,
    });
  }
}
