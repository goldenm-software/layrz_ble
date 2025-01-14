import 'dart:async';
import 'dart:typed_data';

import 'package:layrz_ble/src/types.dart';
import 'package:layrz_models/layrz_models.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'method_channel.dart';

abstract class LayrzBlePlatform extends PlatformInterface {
  LayrzBlePlatform() : super(token: _token);

  static final Object _token = Object();
  static LayrzBlePlatform _instance = LayrzBleNative();
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
  Stream<BleCharacteristicNotification> get onNotify =>
      throw UnimplementedError('_notifySubscription has not been implemented.');

  /// [startScan] starts scanning for BLE devices.
  ///
  /// To get the results, you need to set a callback function using [onScanResult].
  Future<bool?> startScan({
    /// [macAddress] is the MAC address or UUID of the device to scan.
    /// If this value is not provided, the scan will search for all devices.
    String? macAddress,
  }) =>
      throw UnimplementedError('startScan() has not been implemented.');

  /// [stopScan] stops scanning for BLE devices.
  ///
  /// This method will stop the streaming of BLE devices.
  Future<bool?> stopScan() => throw UnimplementedError('stopScan() has not been implemented.');

  /// [checkCapabilities] checks if the device supports BLE.
  Future<BleCapabilities> checkCapabilities() =>
      throw UnimplementedError('checkCapabilities() has not been implemented.');

  /// [setMtu] sets the MTU size for the BLE connection.
  /// The MTU size is the maximum number of bytes that can be sent in a single packet, also, MTU means
  /// Maximum Transmission Unit and it is the maximum size of a packet that can be sent in a single transmission.
  ///
  /// The return value is the new MTU size, after a negotion with the peripheral.
  Future<int?> setMtu({required int newMtu}) => throw UnimplementedError('setMtu() has not been implemented.');

  /// [connect] connects to a BLE device.
  Future<bool?> connect({
    /// [macAddress] is the MAC address or UUID of the device to connect.
    required String macAddress,
  }) =>
      throw UnimplementedError('connect() has not been implemented.');

  /// [disconnect] disconnects from any connected BLE device.
  Future<bool?> disconnect() => throw UnimplementedError('disconnect() has not been implemented.');

  /// [discoverServices] discovers the services of a BLE device.
  Future<List<BleService>?> discoverServices({
    /// [timeout] is the duration to wait for the services to be discovered.
    Duration timeout = const Duration(seconds: 30),
  }) =>
      throw UnimplementedError('discoverServices() has not been implemented.');

  /// [writeCharacteristic] sends a payload to a BLE characteristic.
  ///
  /// The return value is `true` if the payload was sent successfully.
  Future<bool> writeCharacteristic({
    /// [serviceUuid] is the UUID of the service.
    required String serviceUuid,

    /// [characteristicUuid] is the UUID of the characteristic.
    required String characteristicUuid,

    /// [payload] is the data to send to the characteristic.
    required Uint8List payload,

    /// [timeout] is the duration to wait for the characteristic to be written.
    Duration timeout = const Duration(seconds: 30),

    /// [withResponse] is a flag to indicate if the write should be with response or not.
    required bool withResponse,
  }) =>
      throw UnimplementedError('writeCharacteristic() has not been implemented.');

  /// [readCharacteristic] reads the value of a BLE characteristic.
  /// The return value is the raw bytes of the characteristic.
  ///
  /// If the characteristic is not readable, this method will return null.
  Future<Uint8List?> readCharacteristic({
    /// [serviceUuid] is the UUID of the service.
    required String serviceUuid,

    /// [characteristicUuid] is the UUID of the characteristic.
    required String characteristicUuid,

    /// [timeout] is the duration to wait for the characteristic to be read.
    Duration timeout = const Duration(seconds: 30),
  }) =>
      throw UnimplementedError('readCharacteristic() has not been implemented.');

  /// [startNotify] starts listening to notifications from a BLE characteristic.
  /// To stop listening, use [stopNotify] method and to get the notifications, use [onNotify] stream.
  Future<bool?> startNotify({
    /// [serviceUuid] is the UUID of the service.
    required String serviceUuid,

    /// [characteristicUuid] is the UUID of the characteristic.
    required String characteristicUuid,
  }) =>
      throw UnimplementedError('startNotify() has not been implemented.');

  /// [stopNotify] stops listening to notifications from a BLE characteristic.
  Future<bool?> stopNotify({
    /// [serviceUuid] is the UUID of the service.
    required String serviceUuid,

    /// [characteristicUuid] is the UUID of the characteristic.
    required String characteristicUuid,
  }) =>
      throw UnimplementedError('stopNotify() has not been implemented.');
}
