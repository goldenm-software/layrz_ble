library layrz_ble;

import 'dart:typed_data';

import 'package:layrz_ble/src/types.dart';
import 'package:layrz_models/layrz_models.dart';
import 'src/platform_interface.dart';

export 'src/platform_interface.dart';
export 'src/method_channel.dart';
export 'src/types.dart';
export 'package:layrz_models/layrz_models.dart' show BleDevice, BleService, BleCharacteristic, BleProperty;

class LayrzBle {
  /// [onScan] is a stream of BLE devices detected during a scan.
  Stream<BleDevice> get onScan => LayrzBlePlatform.instance.onScan;

  /// [onEvent] is a stream of BLE events.
  Stream<BleEvent> get onEvent => LayrzBlePlatform.instance.onEvent;

  /// [onNotify] is a stream of BLE notifications.
  /// To add a new notification listener, use [startNotify] method.
  /// This stream will emit the raw bytes of the notification.
  Stream<Uint8List> get onNotify => LayrzBlePlatform.instance.onNotify;

  /// [startScan] starts scanning for BLE devices.
  ///
  /// To get the results, you need to set a callback function using [onScanResult].
  Future<bool?> startScan() => LayrzBlePlatform.instance.startScan();

  /// [stopScan] stops scanning for BLE devices.
  ///
  /// This method will stop the streaming of BLE devices.
  Future<bool?> stopScan() => LayrzBlePlatform.instance.stopScan();

  /// [checkCapabilities] checks if the device supports BLE.
  Future<BleCapabilities> checkCapabilities() => LayrzBlePlatform.instance.checkCapabilities();

  /// [setMtu] sets the MTU size for the BLE connection.
  /// The MTU size is the maximum number of bytes that can be sent in a single packet.
  ///
  /// The return value is the new MTU size, after the handshake with the peripheral.
  Future<int?> setMtu({required int newMtu}) => LayrzBlePlatform.instance.setMtu(newMtu: newMtu);

  /// [connect] connects to a BLE device.
  Future<bool?> connect({required String macAddress}) => LayrzBlePlatform.instance.connect(macAddress: macAddress);

  /// [disconnect] disconnects from any connected BLE device.
  Future<bool?> disconnect() => LayrzBlePlatform.instance.disconnect();

  /// [discoverServices] discovers the services of a BLE device.
  Future<List<BleService>?> discoverServices({required String macAddress}) =>
      LayrzBlePlatform.instance.discoverServices(macAddress: macAddress);

  /// [discoverCharacteristics] discovers the characteristics of a BLE service.
  Future<List<BleCharacteristic>?> discoverCharacteristics({
    required String macAddress,
    required String serviceUuid,
  }) =>
      LayrzBlePlatform.instance.discoverCharacteristics(
        macAddress: macAddress,
        serviceUuid: serviceUuid,
      );

  /// [sendPayload] sends a payload to a BLE characteristic.
  ///
  /// The return value is `true` if the payload was sent successfully.
  Future<bool> sendPayload({
    required String macAddress,
    required String serviceUuid,
    required String characteristicUuid,
    required Uint8List payload,
  }) =>
      LayrzBlePlatform.instance.sendPayload(
        macAddress: macAddress,
        serviceUuid: serviceUuid,
        characteristicUuid: characteristicUuid,
        payload: payload,
      );

  /// [startNotify] starts listening to notifications from a BLE characteristic.
  /// To stop listening, use [stopNotify] method and to get the notifications, use [onNotify] stream.
  Future<bool?> startNotify({
    required String macAddress,
    required String serviceUuid,
    required String characteristicUuid,
  }) =>
      LayrzBlePlatform.instance.startNotify(
        macAddress: macAddress,
        serviceUuid: serviceUuid,
        characteristicUuid: characteristicUuid,
      );

  /// [stopNotify] stops listening to notifications from a BLE characteristic.
  Future<bool?> stopNotify({
    required String macAddress,
    required String serviceUuid,
    required String characteristicUuid,
  }) =>
      LayrzBlePlatform.instance.stopNotify(
        macAddress: macAddress,
        serviceUuid: serviceUuid,
        characteristicUuid: characteristicUuid,
      );
}
