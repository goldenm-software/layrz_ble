import 'dart:async';

import 'package:layrz_ble/src/types.dart';
import 'package:layrz_models/layrz_models.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'layrz_ble_method_channel.dart';

abstract class LayrzBlePlatform extends PlatformInterface {
  LayrzBlePlatform() : super(token: _token);

  static final Object _token = Object();
  static LayrzBlePlatform _instance = MethodChannelLayrzBle();
  static LayrzBlePlatform get instance => _instance;

  static set instance(LayrzBlePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// [onScan] is a stream of BLE devices detected during a scan.
  Stream<BleDevice> get onScan => throw UnimplementedError('_scanSubscription has not been implemented.');

  /// [onEvent] is a stream of BLE events.
  Stream<BleEvent> get onEvent => throw UnimplementedError('_eventSubscription has not been implemented.');

  /// [onNotify] is a stream of BLE notifications.
  /// To add a new notification listener, use [startNotify] method.
  /// This stream will emit the raw bytes of the notification.
  Stream<List<int>> get onNotify => throw UnimplementedError('_notifySubscription has not been implemented.');

  /// [startScan] starts scanning for BLE devices.
  ///
  /// To get the results, you need to set a callback function using [onScanResult].
  Future<bool?> startScan() => throw UnimplementedError('startScan() has not been implemented.');

  /// [stopScan] stops scanning for BLE devices.
  ///
  /// This method will stop the streaming of BLE devices.
  Future<bool?> stopScan() => throw UnimplementedError('stopScan() has not been implemented.');

  /// [checkCapabilities] checks if the device supports BLE.
  Future<BleCapabilities> checkCapabilities() =>
      throw UnimplementedError('checkCapabilities() has not been implemented.');

  /// [setMtu] sets the MTU size for the BLE connection.
  /// The MTU size is the maximum number of bytes that can be sent in a single packet.
  ///
  /// The return value is the new MTU size, after the handshake with the peripheral.
  Future<int?> setMtu({required int newMtu}) => throw UnimplementedError('setMtu() has not been implemented.');

  /// [connect] connects to a BLE device.
  Future<bool?> connect({required String macAddress}) =>
      throw UnimplementedError('connect() has not been implemented.');

  /// [disconnect] disconnects from any connected BLE device.
  Future<bool?> disconnect() => throw UnimplementedError('disconnect() has not been implemented.');

  /// [discoverServices] discovers the services of a BLE device.
  Future<List<BleService>?> discoverServices({required String macAddress}) =>
      throw UnimplementedError('discoverServices() has not been implemented.');

  /// [discoverCharacteristics] discovers the characteristics of a BLE service.
  Future<List<BleCharacteristic>?> discoverCharacteristics({
    required String macAddress,
    required String serviceUuid,
  }) =>
      throw UnimplementedError('discoverCharacteristics() has not been implemented.');

  /// [sendPayload] sends a payload to a BLE characteristic.
  ///
  /// The return value is `true` if the payload was sent successfully.
  Future<bool> sendPayload({
    required String macAddress,
    required String serviceUuid,
    required String characteristicUuid,
    required List<int> payload,
  }) =>
      throw UnimplementedError('sendPayload() has not been implemented.');

  /// [startNotify] starts listening to notifications from a BLE characteristic.
  /// To stop listening, use [stopNotify] method and to get the notifications, use [onNotify] stream.
  Future<bool?> startNotify({
    required String macAddress,
    required String serviceUuid,
    required String characteristicUuid,
  }) =>
      throw UnimplementedError('startNotify() has not been implemented.');

  /// [stopNotify] stops listening to notifications from a BLE characteristic.
  Future<bool?> stopNotify({
    required String macAddress,
    required String serviceUuid,
    required String characteristicUuid,
  }) =>
      throw UnimplementedError('stopNotify() has not been implemented.');
}
