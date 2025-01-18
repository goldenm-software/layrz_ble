import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:layrz_ble/src/platform_interface.dart';
import 'package:layrz_ble/src/types.dart';
import 'package:layrz_models/layrz_models.dart';
import 'package:flutter_web_bluetooth/flutter_web_bluetooth.dart';

class LayrzBlePluginWeb extends LayrzBlePlatform {
  LayrzBlePluginWeb();

  static void registerWith(Registrar registrar) {
    LayrzBlePlatform.instance = LayrzBlePluginWeb();
  }

  BluetoothDevice? _currentConnected;
  final Map<String, StreamSubscription<ByteData>> _notifications = {};
  final Map<String, BluetoothDevice> _devices = {};

  final StreamController<BleDevice> _scanController = StreamController<BleDevice>.broadcast();
  final StreamController<BleEvent> _eventController = StreamController<BleEvent>.broadcast();
  final StreamController<BleCharacteristicNotification> _notifyController =
      StreamController<BleCharacteristicNotification>.broadcast();

  @override
  Stream<BleDevice> get onScan => _scanController.stream;

  @override
  Stream<BleEvent> get onEvent => _eventController.stream;

  @override
  Stream<BleCharacteristicNotification> get onNotify => _notifyController.stream;

  @override
  Future<BleCapabilities> checkCapabilities() async {
    final supported = FlutterWebBluetooth.instance.isBluetoothApiSupported;

    return BleCapabilities(
      bluetoothAdminOrScanPermission: supported,
      locationPermission: supported,
      bluetoothPermission: supported,
      bluetoothConnectPermission: supported,
    );
  }

  @override
  Future<bool?> startScan({String? macAddress, List<String>? servicesUuids}) async {
    _devices.clear();
    final requestOptions = RequestOptionsBuilder.acceptAllDevices(optionalServices: servicesUuids);
    try {
      final device = await FlutterWebBluetooth.instance.requestDevice(requestOptions);
      final bleDevice = BleDevice(macAddress: device.id, name: device.name);
      _devices[device.id] = device;
      _scanController.add(bleDevice);
      _eventController.add(BleEvent.scanStopped);
      return true;
    } catch (e) {
      _eventController.add(BleEvent.scanStopped);
      log("Error getting device: $e");
      return false;
    }
  }

  @override
  Future<bool?> stopScan() => Future.value(true);

  @override
  Future<int?> setMtu({required int newMtu}) async {
    log("Feature not supported on Web");
    return null;
  }

  @override
  Future<bool?> connect({required String macAddress}) async {
    if (!_devices.containsKey(macAddress)) {
      log("Device not found: $macAddress");
      return false;
    }

    final device = _devices[macAddress]!;

    await device.connect(timeout: null);
    _currentConnected = device;
    return true;
  }

  @override
  Future<bool?> disconnect() async {
    if (_currentConnected == null) {
      log("No device connected");
      return true;
    }

    _currentConnected!.disconnect();
    _currentConnected = null;
    return true;
  }

  @override
  Future<List<BleService>?> discoverServices({
    Duration timeout = const Duration(seconds: 30),
    List<String>? serviceUuids,
  }) async {
    if (_currentConnected == null) {
      log("No device connected");
      return null;
    }

    try {
      final services = await _currentConnected!.discoverServices();
      List<BleService> result = [];

      for (final service in services) {
        final characteristics = await service.getCharacteristics();
        final bleCharacteristics = characteristics.map((c) {
          return BleCharacteristic(
            uuid: c.uuid,
            properties: [
              if (c.properties.read) BleProperty.read,
              if (c.properties.write) BleProperty.write,
              if (c.properties.notify) BleProperty.notify,
              if (c.properties.indicate) BleProperty.indicate,
              if (c.properties.authenticatedSignedWrites) BleProperty.authenticatedSignedWrites,
              if (c.properties.broadcast) BleProperty.broadcast,
              if (c.properties.writableAuxiliaries) BleProperty.extendedProperties,
              if (c.properties.writeWithoutResponse) BleProperty.writeWithoutResponse,
            ],
          );
        }).toList();

        result.add(BleService(
          uuid: service.uuid,
          characteristics: bleCharacteristics,
        ));
      }

      return result;
    } catch (e) {
      log("Error discovering services: $e");
      return null;
    }
  }

  @override
  Future<bool> writeCharacteristic({
    required String serviceUuid,
    required String characteristicUuid,
    required Uint8List payload,
    Duration timeout = const Duration(seconds: 30),
    required bool withResponse,
  }) async {
    if (_currentConnected == null) {
      log("No device connected");
      return false;
    }

    await _currentConnected!.connect();

    try {
      final services = await _currentConnected!.discoverServices();
      final service = services.firstWhereOrNull((s) => s.uuid.toLowerCase() == serviceUuid.toLowerCase());
      if (service == null) {
        log("Service not found: $serviceUuid");
        return false;
      }

      try {
        final characteristic = await service.getCharacteristic(characteristicUuid);
        if (withResponse) {
          await characteristic.writeValueWithResponse(payload);
        } else {
          await characteristic.writeValueWithoutResponse(payload);
        }
        return true;
      } catch (e) {
        log("Error getting characteristic: $e");
        return false;
      }
    } catch (e) {
      log("Error discovering services: $e");
      return false;
    }
  }

  @override
  Future<Uint8List?> readCharacteristic({
    required String serviceUuid,
    required String characteristicUuid,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (_currentConnected == null) {
      log("No device connected");
      return null;
    }

    final services = await _currentConnected!.discoverServices();
    final service = services.firstWhereOrNull((s) => s.uuid.toLowerCase() == serviceUuid.toLowerCase());
    if (service == null) {
      log("Service not found: $serviceUuid");
      return null;
    }

    if (_notifications.containsKey(characteristicUuid)) {
      log("Stop notify before reading");
      return null;
    }

    try {
      final characteristic = await service.getCharacteristic(characteristicUuid);
      final value = await characteristic.readValue(timeout: timeout);
      return value.buffer.asUint8List();
    } catch (e) {
      log("Error getting characteristic: $e");
      return null;
    }
  }

  @override
  Future<bool?> startNotify({
    required String serviceUuid,
    required String characteristicUuid,
  }) async {
    if (_currentConnected == null) {
      log("No device connected");
      return false;
    }

    final services = await _currentConnected!.discoverServices();
    final service = services.firstWhereOrNull((s) => s.uuid.toLowerCase() == serviceUuid.toLowerCase());
    if (service == null) {
      log("Service not found: $serviceUuid");
      return false;
    }

    try {
      final characteristic = await service.getCharacteristic(characteristicUuid);
      if (characteristic.isNotifying) {
        log("Already notifying");
        return true;
      }
      await characteristic.startNotifications();
      _notifications[characteristicUuid] = characteristic.value.listen((event) {
        _notifyController.add(BleCharacteristicNotification(
          serviceUuid: serviceUuid,
          characteristicUuid: characteristicUuid,
          value: event.buffer.asUint8List(),
        ));
      });
      return true;
    } catch (e) {
      log("Error getting characteristic: $e");
      return false;
    }
  }

  @override
  Future<bool?> stopNotify({
    required String serviceUuid,
    required String characteristicUuid,
  }) async {
    if (_currentConnected == null) {
      log("No device connected");
      return false;
    }

    final services = await _currentConnected!.discoverServices();
    final service = services.firstWhereOrNull((s) => s.uuid.toLowerCase() == serviceUuid.toLowerCase());
    if (service == null) {
      log("Service not found: $serviceUuid");
      return false;
    }

    try {
      final characteristic = await service.getCharacteristic(characteristicUuid);
      if (!characteristic.isNotifying) {
        log("Is not notifying");
        return true;
      }
      await characteristic.stopNotifications();
      if (_notifications.containsKey(characteristicUuid)) {
        _notifications[characteristicUuid]!.cancel();
        _notifications.remove(characteristicUuid);
      }
      return true;
    } catch (e) {
      log("Error getting characteristic: $e");
      return false;
    }
  }

  void log(String message) {
    debugPrint("LayrzBlePlugin/Web: $message");
  }
}
