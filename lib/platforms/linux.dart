import 'dart:async';

import 'package:bluez/bluez.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:layrz_ble/src/platform_interface.dart';
import 'package:layrz_ble/src/types.dart';
import 'package:layrz_models/layrz_models.dart';

class LayrzBlePluginLinux extends LayrzBlePlatform {
  LayrzBlePluginLinux() {
    try {
      _client = BlueZClient();
      _client!.connect().then((_) {
        _client!.deviceAdded.listen(_onScanAdded);
      });
    } catch (e) {
      log("Error initializing BlueZClient: $e");
    }
  }

  static void registerWith() {
    LayrzBlePlatform.instance = LayrzBlePluginLinux();
  }

  bool _isScanning = false;
  final Map<String, BlueZDevice> _devices = {};
  String? _macAddressFilter;
  BlueZClient? _client;
  BlueZDevice? _connectedDevice;

  final Map<BlueZUUID, StreamSubscription<List<String>>> _notifications = {};

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
    bool can = false;
    try {
      can = _client?.adapters.isNotEmpty ?? false;
    } catch (e) {
      log("Error initializing BlueZClient: $e");
      can = false;
    }

    return BleCapabilities(
      bluetoothAdminOrScanPermission: can,
      locationPermission: can,
      bluetoothPermission: can,
      bluetoothConnectPermission: can,
    );
  }

  @override
  Future<bool?> startScan({String? macAddress, List<String>? servicesUuids}) async {
    if (_client == null) {
      log("Error initializing BlueZClient");
      return false;
    }

    _isScanning = true;
    _macAddressFilter = macAddress;

    try {
      final adapter = _client!.adapters.firstOrNull;
      await adapter?.startDiscovery();

      for (final device in _client!.devices) {
        _onScanAdded(device);
      }

      return true;
    } catch (e) {
      log("Error initializing BlueZClient: $e");
      return false;
    }
  }

  @override
  Future<bool?> stopScan() async {
    if (!_isScanning) return true;

    _eventController.add(BleEvent.scanStopped);
    try {
      final adapter = _client?.adapters.firstOrNull;
      await adapter?.stopDiscovery();
      _isScanning = false;
      return true;
    } catch (e) {
      log("Error initializing BlueZClient: $e");
      return false;
    }
  }

  @override
  Future<int?> setMtu({required int newMtu}) async {
    if (_connectedDevice == null) {
      log("Not connected to any device");
      return null;
    }

    final service = _connectedDevice!.gattServices.firstOrNull;
    if (service == null) {
      log("Service not found");
      return null;
    }

    final characteristic = service.characteristics.firstOrNull;
    if (characteristic == null) {
      log("Characteristic not found");
      return null;
    }

    return characteristic.mtu;
  }

  @override
  Future<bool?> connect({required String macAddress}) async {
    if (_client == null) {
      log("Error initializing BlueZClient");
      return false;
    }

    stopScan();

    if (_devices[macAddress.toLowerCase()] == null) {
      log("Device not found: $macAddress");
      return false;
    }

    final device = _devices[macAddress.toLowerCase()]!;
    await device.connect();
    _connectedDevice = device;

    _eventController.add(BleEvent.connected);
    return true;
  }

  @override
  Future<bool> disconnect() async {
    _connectedDevice?.disconnect();
    _connectedDevice = null;
    _eventController.add(BleEvent.disconnected);
    return true;
  }

  @override
  Future<List<BleService>?> discoverServices({
    Duration timeout = const Duration(seconds: 30),
    List<String>? serviceUuids,
  }) async {
    if (_connectedDevice == null) {
      log("Not connected to any device");
      return null;
    }

    List<BleService> services = [];

    for (final service in _connectedDevice!.gattServices) {
      for (final characteristic in service.characteristics) {
        services.add(BleService(
          uuid: service.uuid.toString(),
          characteristics: [
            BleCharacteristic(
              uuid: characteristic.uuid.toString(),
              properties: [
                if (characteristic.flags.contains(BlueZGattCharacteristicFlag.read)) BleProperty.read,
                if (characteristic.flags.contains(BlueZGattCharacteristicFlag.write)) BleProperty.write,
                if (characteristic.flags.contains(BlueZGattCharacteristicFlag.notify)) BleProperty.notify,
                if (characteristic.flags.contains(BlueZGattCharacteristicFlag.broadcast)) BleProperty.broadcast,
                if (characteristic.flags.contains(BlueZGattCharacteristicFlag.writeWithoutResponse))
                  BleProperty.writeWithoutResponse,
                if (characteristic.flags.contains(BlueZGattCharacteristicFlag.indicate)) BleProperty.indicate,
                if (characteristic.flags.contains(BlueZGattCharacteristicFlag.authenticatedSignedWrites))
                  BleProperty.authenticatedSignedWrites,
                if (characteristic.flags.contains(BlueZGattCharacteristicFlag.extendedProperties))
                  BleProperty.extendedProperties,
              ],
            ),
          ],
        ));
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
    if (_connectedDevice == null) {
      log("Not connected to any device");
      return false;
    }

    final service = _connectedDevice!.gattServices.firstWhereOrNull((element) {
      return element.uuid.toString().toLowerCase() == serviceUuid.toLowerCase();
    });
    if (service == null) {
      log("Service not found: $serviceUuid");
      return false;
    }

    final characteristic = service.characteristics.firstWhereOrNull((element) {
      return element.uuid.toString().toLowerCase() == characteristicUuid.toLowerCase();
    });

    if (characteristic == null) {
      log("Characteristic not found: $characteristicUuid");
      return false;
    }

    await characteristic.writeValue(payload);
    return true;
  }

  @override
  Future<Uint8List?> readCharacteristic({
    required String serviceUuid,
    required String characteristicUuid,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (_connectedDevice == null) {
      log("Not connected to any device");
      return null;
    }

    final service = _connectedDevice!.gattServices.firstWhereOrNull((element) {
      return element.uuid.toString().toLowerCase() == serviceUuid.toLowerCase();
    });
    if (service == null) {
      log("Service not found: $serviceUuid");
      return null;
    }

    final characteristic = service.characteristics.firstWhereOrNull((element) {
      return element.uuid.toString().toLowerCase() == characteristicUuid.toLowerCase();
    });

    if (characteristic == null) {
      log("Characteristic not found: $characteristicUuid");
      return null;
    }

    if (characteristic.notifying) {
      log("Characteristic is notifying: $characteristicUuid");
      return null;
    }

    final value = await characteristic.readValue();
    return Uint8List.fromList(value);
  }

  @override
  Future<bool?> startNotify({
    required String serviceUuid,
    required String characteristicUuid,
  }) async {
    if (_connectedDevice == null) {
      log("Not connected to any device");
      return false;
    }

    final service = _connectedDevice!.gattServices.firstWhereOrNull((element) {
      return element.uuid.toString().toLowerCase() == serviceUuid.toLowerCase();
    });
    if (service == null) {
      log("Service not found: $serviceUuid");
      return false;
    }

    final characteristic = service.characteristics.firstWhereOrNull((element) {
      return element.uuid.toString().toLowerCase() == characteristicUuid.toLowerCase();
    });

    if (characteristic == null) {
      log("Characteristic not found: $characteristicUuid");
      return false;
    }

    if (characteristic.notifying) {
      log("Characteristic already notifying: $characteristicUuid");
      return false;
    }

    _notifications[characteristic.uuid] = characteristic.propertiesChanged.listen((events) {
      debugPrint("Events: $events");
      for (final event in events) {
        if (event == 'Value') {
          final receivedValue = characteristic.value;
          _notifyController.add(BleCharacteristicNotification(
            serviceUuid: serviceUuid,
            characteristicUuid: characteristicUuid,
            value: Uint8List.fromList(receivedValue),
          ));
        }
      }
    });
    await characteristic.startNotify();
    return true;
  }

  @override
  Future<bool?> stopNotify({
    required String serviceUuid,
    required String characteristicUuid,
  }) async {
    if (_connectedDevice == null) {
      log("Not connected to any device");
      return false;
    }

    final service = _connectedDevice!.gattServices.firstWhereOrNull((element) {
      return element.uuid.toString().toLowerCase() == serviceUuid.toLowerCase();
    });
    if (service == null) {
      log("Service not found: $serviceUuid");
      return false;
    }

    final characteristic = service.characteristics.firstWhereOrNull((element) {
      return element.uuid.toString().toLowerCase() == characteristicUuid.toLowerCase();
    });

    if (characteristic == null) {
      log("Characteristic not found: $characteristicUuid");
      return false;
    }

    if (_notifications.containsKey(characteristic.uuid)) {
      _notifications[characteristic.uuid]?.cancel();
      _notifications.remove(characteristic.uuid);
    }

    if (!characteristic.notifying) {
      log("Characteristic not notifying: $characteristicUuid");
      return false;
    }

    await characteristic.stopNotify();
    return true;
  }

  void log(String message) {
    debugPrint("LayrzBlePlugin/Linux: $message");
  }

  void _onScanAdded(BlueZDevice device) {
    if (!_isScanning) return;
    if (_macAddressFilter != null && _macAddressFilter!.toLowerCase() != device.address.toLowerCase()) {
      if (kDebugMode) log("Skipping device ${device.address}");
      return;
    }

    _scanController.add(_compose(device));
  }

  BleDevice _compose(BlueZDevice device) {
    List<int> manufacturerData = [];
    for (final entry in device.manufacturerData.entries) {
      final companyId = entry.key;
      final data = entry.value;

      manufacturerData.addAll(_intToLittleEndian(companyId.id).toList());
      manufacturerData.addAll(data);
    }

    List<int> serviceData = [];
    List<List<int>> servicesIdentifiers = [];

    final sortedServices = device.serviceData.keys.toList()..sort((a, b) => a.toString().compareTo(b.toString()));
    for (final serviceUuid in sortedServices) {
      final data = device.serviceData[serviceUuid] ?? [];

      serviceData.addAll(data);

      final bytes = serviceUuid.value;

      List<int> serviceUuidShort = [bytes[2], bytes[3]];
      servicesIdentifiers.add(serviceUuidShort);
    }

    _devices[device.address.toLowerCase()] = device;

    return BleDevice(
      macAddress: device.address,
      name: device.name.isEmpty ? 'Unknown' : device.name,
      rssi: device.rssi,
      manufacturerData: manufacturerData,
      serviceData: serviceData,
      servicesIdentifiers: servicesIdentifiers,
    );
  }

  Uint8List _intToLittleEndian(int value) {
    if (value < 0 || value > 0xFFFF) {
      log("Value must be between 0 and 65535 - $value");
      return Uint8List(0);
    }

    // Create a 2-byte buffer
    final buffer = ByteData(2);

    // Write the value as little-endian
    buffer.setUint16(0, value, Endian.little);

    return buffer.buffer.asUint8List();
  }
}
