import 'dart:async';

import 'package:bluez/bluez.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:layrz_ble/src/platform_interface.dart';
import 'package:layrz_ble/src/types.dart';
import 'package:layrz_models/layrz_models.dart';

class LayrzBlePluginLinux extends LayrzBlePlatform {
  LayrzBlePluginLinux();

  static void registerWith() {
    LayrzBlePlatform.instance = LayrzBlePluginLinux();
  }

  final Map<String, BlueZDevice> _devices = {};
  String? _macAddressFilter;
  BlueZClient? _client;
  BlueZDevice? _connectedDevice;

  final Map<String, StreamSubscription<ByteData>> _notifications = {};

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
      final client = BlueZClient();
      await client.connect();
      can = client.adapters.isNotEmpty;
      await client.close();
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
    if (_client != null) {
      log("Other process is already doing things");
      return false;
    }

    _macAddressFilter = macAddress;
    try {
      _client = BlueZClient();
      await _client!.connect();
      final adapter = _client!.adapters.firstOrNull;
      await adapter?.startDiscovery();
      _client!.deviceAdded.listen(_onScanAdded);
      return true;
    } catch (e) {
      log("Error initializing BlueZClient: $e");
      return false;
    }
  }

  @override
  Future<bool?> stopScan() async {
    await _client?.close();
    _client = null;
    return true;
  }

  @override
  Future<int?> setMtu({required int newMtu}) async {
    log("Feature not supported on Web");
    return null;
  }

  @override
  Future<bool?> connect({required String macAddress}) async {
    if (_devices[macAddress.toLowerCase()] == null) {
      log("Device not found: $macAddress");
      return false;
    }

    final device = _devices[macAddress.toLowerCase()]!;
    await device.connect();
    _connectedDevice = device;
    return true;
  }

  @override
  Future<bool> disconnect() async {
    _connectedDevice?.disconnect();
    _connectedDevice = null;
    return true;
  }

  @override
  Future<List<BleService>?> discoverServices({
    Duration timeout = const Duration(seconds: 30),
    List<String>? serviceUuids,
  }) async {
    return null;
  }

  @override
  Future<bool> writeCharacteristic({
    required String serviceUuid,
    required String characteristicUuid,
    required Uint8List payload,
    Duration timeout = const Duration(seconds: 30),
    required bool withResponse,
  }) async {
    return false;
  }

  @override
  Future<Uint8List?> readCharacteristic({
    required String serviceUuid,
    required String characteristicUuid,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    return null;
  }

  @override
  Future<bool?> startNotify({
    required String serviceUuid,
    required String characteristicUuid,
  }) async {
    return false;
  }

  @override
  Future<bool?> stopNotify({
    required String serviceUuid,
    required String characteristicUuid,
  }) async {
    return false;
  }

  void log(String message) {
    debugPrint("LayrzBlePlugin/Linux: $message");
  }

  void _onScanAdded(BlueZDevice device) {
    if (_macAddressFilter != null && _macAddressFilter!.toLowerCase() != device.address.toLowerCase()) {
      if (kDebugMode) log("Skipping device ${device.address}");
      return;
    }

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

    _scanController.add(BleDevice(
      macAddress: device.address,
      name: device.name.isEmpty ? 'Unknown' : device.name,
      rssi: device.rssi,
      manufacturerData: manufacturerData,
      serviceData: serviceData,
      servicesIdentifiers: servicesIdentifiers,
    ));
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
