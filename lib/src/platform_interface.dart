import 'dart:async';
import 'dart:typed_data';

import 'package:layrz_ble/src/types/types.dart';
import 'package:layrz_models/layrz_models.dart';

abstract class LayrzBlePlatform {
  bool get isAdvertising => throw UnimplementedError('isAdvertising has not been implemented.');
  bool get isScanning => throw UnimplementedError('isScanning has not been implemented.');
  Stream<BleDevice> get onScan => throw UnimplementedError('onScan has not been implemented.');
  Stream<BleEvent> get onEvent => throw UnimplementedError('onEvent has not been implemented.');
  Stream<BleCharacteristicNotification> get onNotify => throw UnimplementedError('onNotify has not been implemented.');
  Stream<BleGattEvent> get onGattUpdate => throw UnimplementedError('onGattUpdate has not been implemented.');
  Stream<bool> get onBluetoothStateChanged => throw UnimplementedError('onBluetoothStateChanged has not been implemented.');

  Future<BleStatus> getStatuses() => throw UnimplementedError('getStatuses has not been implemented.');
  Future<bool> checkCapabilities() => throw UnimplementedError('checkCapabilities() has not been implemented.');
  Future<bool> checkScanPermissions() => throw UnimplementedError('checkScanPermissions() has not been implemented.');
  Future<bool> checkAdvertisePermissions() =>
      throw UnimplementedError('checkAdvertisePermissions() has not been implemented.');

  Future<bool> startScan({String? macAddress, List<String>? servicesUuids}) =>
      throw UnimplementedError('startScan() has not been implemented.');
  Future<bool> stopScan() => throw UnimplementedError('stopScan() has not been implemented.');

  Future<bool> connect({required String macAddress}) => throw UnimplementedError('connect() has not been implemented.');
  Future<bool> disconnect({String? macAddress}) => throw UnimplementedError('disconnect() has not been implemented.');
  Future<int?> setMtu({required String macAddress, required int newMtu}) =>
      throw UnimplementedError('setMtu() has not been implemented.');

  Future<List<BleService>?> discoverServices({required String macAddress}) =>
      throw UnimplementedError('discoverServices() has not been implemented.');

  Future<bool> writeCharacteristic({
    required String macAddress,
    required String serviceUuid,
    required String characteristicUuid,
    required Uint8List payload,
    required bool withResponse,
  }) =>
      throw UnimplementedError('writeCharacteristic() has not been implemented.');

  Future<Uint8List?> readCharacteristic({
    required String macAddress,
    required String serviceUuid,
    required String characteristicUuid,
  }) =>
      throw UnimplementedError('readCharacteristic() has not been implemented.');

  Future<bool> startNotify({
    required String macAddress,
    required String serviceUuid,
    required String characteristicUuid,
  }) =>
      throw UnimplementedError('startNotify() has not been implemented.');

  Future<bool> stopNotify({
    required String macAddress,
    required String serviceUuid,
    required String characteristicUuid,
  }) =>
      throw UnimplementedError('stopNotify() has not been implemented.');

  Future<bool> startAdvertise({
    List<BleManufacturerData> manufacturerData = const [],
    List<BleServiceData> serviceData = const [],
    bool canConnect = false,
    List<BleService> servicesSpecs = const [],
    bool allowBluetooth5 = true,
    String? name,
  }) =>
      throw UnimplementedError('startAdvertise() has not been implemented.');

  Future<bool> stopAdvertise() => throw UnimplementedError('stopAdvertise() has not been implemented.');

  Future<bool> respondReadRequest({
    required int requestId,
    required String macAddress,
    required int offset,
    Uint8List? data,
  }) =>
      throw UnimplementedError('respondReadRequest() has not been implemented.');

  Future<bool> respondWriteRequest({
    required int requestId,
    required String macAddress,
    required int offset,
    required bool success,
  }) =>
      throw UnimplementedError('respondWriteRequest() has not been implemented.');

  Future<bool> sendNotification({
    required String serviceUuid,
    required String characteristicUuid,
    required Uint8List payload,
    bool requestConfirmation = false,
  }) =>
      throw UnimplementedError('sendNotification() has not been implemented.');

  Future<bool> openBluetoothSettings() =>
      throw UnimplementedError('openBluetoothSettings() has not been implemented.');
}
