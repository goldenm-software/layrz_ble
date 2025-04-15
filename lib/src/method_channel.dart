import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:layrz_ble/src/types/types.dart';
import 'package:layrz_models/layrz_models.dart';

import 'platform_interface.dart';

/// An implementation of [LayrzBlePlatform] that uses method channels.
class LayrzBleNative extends LayrzBlePlatform {
  void log(String message) {
    debugPrint('LayrzBlePlugin/Dart: $message');
  }

  LayrzBleNative() {
    eventsChannel.setMethodCallHandler((call) async {
      switch (call.method) {
        /* GATT Server (Advertising) */
        case 'onGattConnected':
          try {
            final args = Map<String, dynamic>.from(call.arguments);
            final event = GattConnected.fromMap(args);
            _gattController.add(event);
          } catch (e) {
            log('Error parsing GattConnected: $e');
          }
          break;
        case 'onGattDisconnected':
          try {
            final event = GattDisconnected(macAddress: call.arguments);
            _gattController.add(event);
          } catch (e) {
            log('Error parsing GattDisconnected: $e');
          }
          break;
        case 'onGattReadRequest':
          try {
            final args = Map<String, dynamic>.from(call.arguments);
            final event = GattReadRequest.fromMap(args);
            _gattController.add(event);
          } catch (e) {
            log('Error parsing GattReadRequest: $e - ${call.arguments}');
          }
          break;
        case 'onGattWriteRequest':
          try {
            final args = Map<String, dynamic>.from(call.arguments);
            final event = GattWriteRequest.fromMap(args);
            _gattController.add(event);
          } catch (e) {
            log('Error parsing GattWriteRequest: $e - ${call.arguments}');
          }
          break;
        case 'onGattMtuChanged':
          try {
            final args = Map<String, dynamic>.from(call.arguments);
            final event = GattMtuChanged.fromMap(args);
            _gattController.add(event);
          } catch (e) {
            log('Error parsing GattMtuChanged: $e - ${call.arguments}');
          }
          break;
        /* /GATT Server (Advertising) */

        /* Scan and connect */
        case 'onScan':
          try {
            final args = Map<String, dynamic>.from(call.arguments);
            if (args['serviceData'] == null) {
              args['serviceData'] = [];
            }

            final serviceData =
                args['serviceData'].map((e) {
                  return Map<String, dynamic>.from(e);
                }).toList();

            args['serviceData'] = serviceData;

            if (args['manufacturerData'] == null) {
              args['manufacturerData'] = [];
            }

            final manufacturerData =
                args['manufacturerData'].map((e) {
                  return Map<String, dynamic>.from(e);
                }).toList();

            args['manufacturerData'] = manufacturerData;

            final device = BleDevice.fromJson(args);
            _scanController.add(device);
          } catch (e) {
            log('Error parsing BleDevice: $e - ${call.arguments}');
          }
          break;
        /* /Scan and connect */

        /* Events */
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
            final notification = BleCharacteristicNotification.fromMap(Map<String, dynamic>.from(call.arguments));
            if (notification.value.isEmpty) return;
            _notifyController.add(notification);
          } catch (e) {
            log('Error parsing BleCharacteristicNotification: $e');
          }
          break;
        /* /Events */

        default:
          log('Unknown method: ${call.method}');
          break;
      }
    });
  }

  final checkCapabilitiesChannel = const MethodChannel('com.layrz.ble.checkCapabilities');
  final checkScanPermissionsChannel = const MethodChannel('com.layrz.ble.checkScanPermissions');
  final checkAdvertisePermissionsChannel = const MethodChannel('com.layrz.ble.checkAdvertisePermissions');
  final startScanChannel = const MethodChannel('com.layrz.ble.startScan');
  final stopScanChannel = const MethodChannel('com.layrz.ble.stopScan');
  final connectChannel = const MethodChannel('com.layrz.ble.connect');
  final disconnectChannel = const MethodChannel('com.layrz.ble.disconnect');
  final discoverServicesChannel = const MethodChannel('com.layrz.ble.discoverServices');
  final setMtuChannel = const MethodChannel('com.layrz.ble.setMtu');
  final writeCharacteristicChannel = const MethodChannel('com.layrz.ble.writeCharacteristic');
  final readCharacteristicChannel = const MethodChannel('com.layrz.ble.readCharacteristic');
  final startNotifyChannel = const MethodChannel('com.layrz.ble.startNotify');
  final stopNotifyChannel = const MethodChannel('com.layrz.ble.stopNotify');
  final eventsChannel = const MethodChannel('com.layrz.ble.events');
  final startAdvertiseChannel = const MethodChannel('com.layrz.ble.startAdvertise');
  final stopAdvertiseChannel = const MethodChannel('com.layrz.ble.stopAdvertise');
  final respondReadRequestChannel = const MethodChannel('com.layrz.ble.respondReadRequest');
  final respondWriteRequestChannel = const MethodChannel('com.layrz.ble.respondWriteRequest');
  final sendNotificationChannel = const MethodChannel('com.layrz.ble.sendNotification');

  final StreamController<BleDevice> _scanController = StreamController<BleDevice>.broadcast();
  final StreamController<BleEvent> _eventController = StreamController<BleEvent>.broadcast();
  final StreamController<BleCharacteristicNotification> _notifyController =
      StreamController<BleCharacteristicNotification>.broadcast();
  final StreamController<BleGattEvent> _gattController = StreamController<BleGattEvent>.broadcast();

  @override
  Stream<BleDevice> get onScan => _scanController.stream;

  @override
  Stream<BleEvent> get onEvent => _eventController.stream;

  @override
  Stream<BleCharacteristicNotification> get onNotify => _notifyController.stream;

  @override
  Stream<BleGattEvent> get onGattUpdate => _gattController.stream;

  @override
  Future<bool?> startScan({String? macAddress, List<String>? servicesUuids}) =>
      startScanChannel.invokeMethod<bool>('startScan', {if (macAddress != null) 'macAddress': macAddress});

  @override
  Future<bool?> stopScan() => stopScanChannel.invokeMethod<bool>('stopScan');

  @override
  Future<bool> checkCapabilities() =>
      checkCapabilitiesChannel.invokeMethod<bool>('checkCapabilities').then((value) => value ?? false);

  @override
  Future<bool> checkScanPermissions() =>
      checkScanPermissionsChannel.invokeMethod<bool>('checkScanPermissions').then((value) => value ?? false);

  @override
  Future<bool> checkAdvertisePermissions() =>
      checkAdvertisePermissionsChannel.invokeMethod<bool>('checkAdvertisePermissions').then((value) => value ?? false);

  @override
  Future<int?> setMtu({required int newMtu}) => setMtuChannel.invokeMethod<int>('setMtu', newMtu);

  @override
  Future<bool?> connect({required String macAddress}) => connectChannel.invokeMethod<bool>('connect', macAddress);

  @override
  Future<bool?> disconnect() => disconnectChannel.invokeMethod<bool>('disconnect');

  @override
  Future<List<BleService>?> discoverServices({
    /// [timeout] is the duration to wait for the services to be discovered.
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final result = await discoverServicesChannel.invokeMethod<List>('discoverServices', {'timeout': timeout.inSeconds});
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
            characteristics.add(BleCharacteristic.fromJson(Map<String, dynamic>.from(characteristic)));
          } catch (e) {
            log('Error parsing BleCharacteristic: $e');
          }
        }

        services.add(BleService(uuid: service['uuid'], characteristics: characteristics));
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
    final result = await writeCharacteristicChannel.invokeMethod<bool>('writeCharacteristic', <String, dynamic>{
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
    final result = await readCharacteristicChannel.invokeMethod<Uint8List>('readCharacteristic', <String, dynamic>{
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
  Future<bool?> startNotify({required String serviceUuid, required String characteristicUuid}) {
    return startNotifyChannel.invokeMethod<bool>('startNotify', <String, String>{
      'serviceUuid': serviceUuid,
      'characteristicUuid': characteristicUuid,
    });
  }

  @override
  Future<bool?> stopNotify({required String serviceUuid, required String characteristicUuid}) {
    return stopNotifyChannel.invokeMethod<bool>('stopNotify', <String, String>{
      'serviceUuid': serviceUuid,
      'characteristicUuid': characteristicUuid,
    });
  }

  @override
  Future<bool> startAdvertise({
    List<BleManufacturerData> manufacturerData = const [],
    List<BleServiceData> serviceData = const [],
    bool canConnect = true,
    List<BleService> servicesSpecs = const [],
    bool allowBluetooth5 = false,
  }) {
    return startAdvertiseChannel
        .invokeMethod<bool>('startAdvertise', {
          'manufacturerData':
              manufacturerData
                  .map((e) => {'companyId': e.companyId, 'data': Uint8List.fromList(e.data ?? [])})
                  .toList(),
          'serviceData': serviceData.map((e) => {'uuid': e.uuid, 'data': Uint8List.fromList(e.data ?? [])}).toList(),
          'canConnect': canConnect,
          'servicesSpecs': servicesSpecs.map((e) => e.toJson()).toList(),
          'allowBluetooth5': allowBluetooth5,
        })
        .then((value) => value ?? false);
  }

  @override
  Future<bool> stopAdvertise() =>
      stopAdvertiseChannel.invokeMethod<bool>('stopAdvertise').then((value) => value ?? false);

  @override
  Future<bool> respondReadRequest({
    required int requestId,
    required String macAddress,
    required int offset,
    required String serviceUuid,
    required String characteristicUuid,
    Uint8List? data,
  }) => respondReadRequestChannel
      .invokeMethod<bool>('respondReadRequest', {
        'requestId': requestId,
        'macAddress': macAddress,
        'offset': offset,
        'serviceUuid': serviceUuid,
        'characteristicUuid': characteristicUuid,
        'data': data,
      })
      .then((value) => value ?? false);

  @override
  Future<bool> respondWriteRequest({
    required int requestId,
    required String macAddress,
    required int offset,
    required String serviceUuid,
    required String characteristicUuid,
    required bool success,
  }) => respondWriteRequestChannel
      .invokeMethod<bool>('respondWriteRequest', {
        'requestId': requestId,
        'macAddress': macAddress,
        'offset': offset,
        'serviceUuid': serviceUuid,
        'characteristicUuid': characteristicUuid,
        'success': success,
      })
      .then((value) => value ?? false);

  @override
  Future<bool> sendNotification({
    required String serviceUuid,
    required String characteristicUuid,
    required Uint8List payload,
    bool requestConfirmation = false,
  }) => sendNotificationChannel
      .invokeMethod<bool>('sendNotification', {
        'serviceUuid': serviceUuid,
        'characteristicUuid': characteristicUuid,
        'payload': payload,
        'requestConfirmation': requestConfirmation,
      })
      .then((value) => value ?? false);
}
