import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:layrz_ble/src/platform_interface.dart';
import 'package:layrz_ble/src/types/types.dart';
import 'package:layrz_models/layrz_models.dart';

class LayrzBlePluginStub extends LayrzBlePlatform {
  LayrzBlePluginStub();

  static void registerWith() {
    LayrzBlePlatform.instance = LayrzBlePluginStub();
  }

  @override
  Stream<BleDevice> get onScan => throw UnimplementedError('_scanSubscription has not been implemented.');

  @override
  Stream<BleEvent> get onEvent => throw UnimplementedError('_eventSubscription has not been implemented.');

  @override
  Stream<BleCharacteristicNotification> get onNotify =>
      throw UnimplementedError('_notifySubscription has not been implemented.');

  @override
  Future<bool> startScan({String? macAddress, List<String>? servicesUuids}) =>
      throw UnimplementedError('startScan() has not been implemented.');

  @override
  Future<bool> stopScan() => throw UnimplementedError('stopScan() has not been implemented.');

  @override
  Future<bool> checkCapabilities() => throw UnimplementedError('checkCapabilities() has not been implemented.');

  @override
  Future<bool> checkScanPermissions() => throw UnimplementedError('checkScanPermissions() has not been implemented.');

  @override
  Future<bool> checkAdvertisePermissions() =>
      throw UnimplementedError('checkAdvertisePermissions() has not been implemented.');

  @override
  Future<int?> setMtu({required String macAddress, required int newMtu}) =>
      throw UnimplementedError('setMtu() has not been implemented.');

  @override
  Future<bool> connect({required String macAddress}) => throw UnimplementedError('connect() has not been implemented.');

  @override
  Future<bool> disconnect({String? macAddress}) => throw UnimplementedError('disconnect() has not been implemented.');

  @override
  Future<List<BleService>?> discoverServices({
    required String macAddress,
    Duration timeout = const Duration(seconds: 30),
  }) => throw UnimplementedError('discoverServices() has not been implemented.');

  @override
  Future<bool> writeCharacteristic({
    required String macAddress,
    required String serviceUuid,
    required String characteristicUuid,
    required Uint8List payload,
    Duration timeout = const Duration(seconds: 30),
    required bool withResponse,
  }) => throw UnimplementedError('writeCharacteristic() has not been implemented.');

  @override
  Future<Uint8List?> readCharacteristic({
    required String macAddress,
    required String serviceUuid,
    required String characteristicUuid,
    Duration timeout = const Duration(seconds: 30),
  }) => throw UnimplementedError('readCharacteristic() has not been implemented.');

  @override
  Future<bool> startNotify({
    required String macAddress,
    required String serviceUuid,
    required String characteristicUuid,
  }) => throw UnimplementedError('startNotify() has not been implemented.');

  @override
  Future<bool> stopNotify({
    required String macAddress,
    required String serviceUuid,
    required String characteristicUuid,
  }) => throw UnimplementedError('stopNotify() has not been implemented.');
}
