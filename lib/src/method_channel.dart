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
      debugPrint('Method call: ${call.method} - ${call.arguments}');
      switch (call.method) {
        /* GATT Server (Advertising) */
        case 'onGattConnected':
          try {
            final event = GattConnected.fromJson(Map<String, dynamic>.from(call.arguments));
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
            final event = GattReadRequest.fromJson(Map<String, dynamic>.from(call.arguments));
            _gattController.add(event);
          } catch (e) {
            log('Error parsing GattReadRequest: $e - ${call.arguments}');
          }
          break;
        case 'onGattWriteRequest':
          try {
            final event = GattWriteRequest.fromJson(Map<String, dynamic>.from(call.arguments));
            _gattController.add(event);
          } catch (e) {
            log('Error parsing GattWriteRequest: $e - ${call.arguments}');
          }
          break;
        case 'onGattMtuChanged':
          try {
            final event = GattMtuChanged.fromJson(Map<String, dynamic>.from(call.arguments));
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

            final serviceData = args['serviceData'].map((e) {
              return Map<String, dynamic>.from(e);
            }).toList();

            args['serviceData'] = serviceData;

            if (args['manufacturerData'] == null) {
              args['manufacturerData'] = [];
            }

            final manufacturerData = args['manufacturerData'].map((e) {
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
        case 'onConnected':
          try {
            final event = BleConnected.fromJson(Map<String, dynamic>.from(call.arguments));
            _eventController.add(event);
          } catch (e) {
            log('Error parsing BleConnected: $e - ${call.arguments}');
          }
          break;

        case 'onDisconnected':
          try {
            final event = BleDisconnected.fromJson(Map<String, dynamic>.from(call.arguments));
            _eventController.add(event);
          } catch (e) {
            log('Error parsing BleDisconnected: $e - ${call.arguments}');
          }
          break;

        case 'onScanStarted':
          _eventController.add(const BleScanStarted());
          break;

        case 'onScanStopped':
          _eventController.add(const BleScanStopped());
          break;

        case 'onBluetoothOff':
          _eventController.add(const BleAdapterOff());
          break;

        case 'onBluetoothOn':
          _eventController.add(const BleAdapterOn());
          break;

        case 'onNotify':
          try {
            final notification = BleCharacteristicNotification.fromJson(Map<String, dynamic>.from(call.arguments));
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

  bool _isAdvertising = false;
  @override
  bool get isAdvertising => _isAdvertising;

  bool _isScanning = false;
  @override
  bool get isScanning => _isScanning;

  final checkCapabilitiesChannel = const MethodChannel('com.layrz.ble.checkCapabilities');
  final checkScanPermissionsChannel = const MethodChannel('com.layrz.ble.checkScanPermissions');
  final checkAdvertisePermissionsChannel = const MethodChannel('com.layrz.ble.checkAdvertisePermissions');
  final getStatusesChannel = const MethodChannel('com.layrz.ble.getStatuses');

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
  Future<BleStatus> getStatuses() async {
    final result = await getStatusesChannel.invokeMethod<Map>('getStatuses');
    if (result == null) {
      log('Error getting statuses from native side');
      return const BleStatus(advertising: false, scanning: false);
    }

    final output = BleStatus.fromJson(Map<String, bool>.from(result));
    _isAdvertising = output.advertising;
    _isScanning = output.scanning;
    return output;
  }

  @override
  Future<bool> startScan({String? macAddress, List<String>? servicesUuids}) async {
    final result = await startScanChannel.invokeMethod<bool>('startScan', {
      if (macAddress != null) 'macAddress': macAddress,
    });

    if (result == null) {
      log('Error starting scan from native side');
      return false;
    }

    _isScanning = result;
    return result;
  }

  @override
  Future<bool> stopScan() async {
    final result = await stopScanChannel.invokeMethod<bool>('stopScan');
    if (result == null) {
      log('Error stopping scan from native side');
      return false;
    }

    _isScanning = false;
    return result;
  }

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
  Future<int?> setMtu({required String macAddress, required int newMtu}) =>
      setMtuChannel.invokeMethod<int>('setMtu', {'macAddress': macAddress, 'newMtu': newMtu});

  @override
  Future<bool> connect({required String macAddress}) async {
    final result = await connectChannel.invokeMethod<bool>('connect', macAddress);
    if (result == null) {
      log('Error connecting to device from native side');
      return false;
    }

    return result;
  }

  @override
  Future<bool> disconnect({String? macAddress}) async {
    final result = await disconnectChannel.invokeMethod<bool>('disconnect', macAddress);
    if (result == null) {
      log('Error disconnecting from device from native side');
      return false;
    }

    return result;
  }

  @override
  Future<List<BleService>?> discoverServices({
    required String macAddress,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final result = await discoverServicesChannel.invokeMethod<List>('discoverServices', {
      'timeout': timeout.inSeconds,
      'macAddress': macAddress,
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
    required String macAddress,
    required String serviceUuid,
    required String characteristicUuid,
    required Uint8List payload,
    Duration timeout = const Duration(seconds: 30),
    required bool withResponse,
  }) async {
    final result = await writeCharacteristicChannel.invokeMethod<bool>('writeCharacteristic', <String, dynamic>{
      'macAddress': macAddress,
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
    required String macAddress,
    required String serviceUuid,
    required String characteristicUuid,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final result = await readCharacteristicChannel.invokeMethod<Uint8List>('readCharacteristic', <String, dynamic>{
      'macAddress': macAddress,
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
  Future<bool> startNotify({
    required String macAddress,
    required String serviceUuid,
    required String characteristicUuid,
  }) async {
    final result = await startNotifyChannel.invokeMethod<bool>('startNotify', <String, String>{
      'macAddress': macAddress,
      'serviceUuid': serviceUuid,
      'characteristicUuid': characteristicUuid,
    });

    if (result == null) {
      log('Error starting notification from native side');
      return false;
    }

    return result;
  }

  @override
  Future<bool> stopNotify({
    required String macAddress,
    required String serviceUuid,
    required String characteristicUuid,
  }) async {
    final result = await stopNotifyChannel.invokeMethod<bool>('stopNotify', <String, String>{
      'macAddress': macAddress,
      'serviceUuid': serviceUuid,
      'characteristicUuid': characteristicUuid,
    });

    if (result == null) {
      log('Error stopping notification from native side');
      return false;
    }

    return result;
  }

  @override
  Future<bool> startAdvertise({
    List<BleManufacturerData> manufacturerData = const [],
    List<BleServiceData> serviceData = const [],
    bool canConnect = true,
    List<BleService> servicesSpecs = const [],
    bool allowBluetooth5 = false,
    String? name,
  }) async {
    final result = await startAdvertiseChannel.invokeMethod<bool>('startAdvertise', {
      'manufacturerData': manufacturerData.map((e) {
        return {'companyId': e.companyId, 'data': Uint8List.fromList(e.data ?? [])};
      }).toList(),
      'serviceData': serviceData.map((e) {
        return {'uuid': e.uuid, 'data': Uint8List.fromList(e.data ?? [])};
      }).toList(),
      'canConnect': canConnect,
      'servicesSpecs': servicesSpecs.map((e) => e.toJson()).toList(),
      'allowBluetooth5': allowBluetooth5,
      'name': name,
    });

    if (result == null) {
      log('Error starting advertising from native side');
      return false;
    }

    _isAdvertising = result;
    return result;
  }

  @override
  Future<bool> stopAdvertise() async {
    final result = await stopAdvertiseChannel.invokeMethod<bool>('stopAdvertise');
    if (result == null) {
      log('Error stopping advertising from native side');
      return false;
    }

    _isAdvertising = false;
    return result;
  }

  @override
  Future<bool> respondReadRequest({
    required int requestId,
    required String macAddress,
    required int offset,
    required String serviceUuid,
    required String characteristicUuid,
    Uint8List? data,
  }) =>
      respondReadRequestChannel.invokeMethod<bool>('respondReadRequest', {
        'requestId': requestId,
        'macAddress': macAddress,
        'offset': offset,
        'serviceUuid': serviceUuid,
        'characteristicUuid': characteristicUuid,
        'data': data,
      }).then((value) => value ?? false);

  @override
  Future<bool> respondWriteRequest({
    required int requestId,
    required String macAddress,
    required int offset,
    required String serviceUuid,
    required String characteristicUuid,
    required bool success,
  }) =>
      respondWriteRequestChannel.invokeMethod<bool>('respondWriteRequest', {
        'requestId': requestId,
        'macAddress': macAddress,
        'offset': offset,
        'serviceUuid': serviceUuid,
        'characteristicUuid': characteristicUuid,
        'success': success,
      }).then((value) => value ?? false);

  @override
  Future<bool> sendNotification({
    required String serviceUuid,
    required String characteristicUuid,
    required Uint8List payload,
    bool requestConfirmation = false,
  }) =>
      sendNotificationChannel.invokeMethod<bool>('sendNotification', {
        'serviceUuid': serviceUuid,
        'characteristicUuid': characteristicUuid,
        'payload': payload,
        'requestConfirmation': requestConfirmation,
      }).then((value) => value ?? false);
}
