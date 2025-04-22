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

  /// [startAdvertise] starts advertising a BLE device.
  ///
  /// The advertisement packet will contain the [manufacturerData] and [serviceData] provided, and the advertisement
  /// will include the name of the device. So, be careful with the len of the contents, you need to consider
  /// the restrictions of the Bluetooth Low Energy specification.
  Future<bool> startAdvertise({
    /// [manufacturerData] is the data to be sent in the advertisement packet.
    List<BleManufacturerData> manufacturerData = const [],

    /// [serviceData] is the data to be sent in the advertisement packet.
    List<BleServiceData> serviceData = const [],

    /// [canConnect] is a flag to indicate if the device can be connected to.
    /// This property enables the GATT Server to be started and the device to be connected to.
    bool canConnect = false,

    /// [servicesSpecs] defines the list of services to be available in the GATT Server.
    /// This property is only used if [canConnect] is set to `true`.
    List<BleService> servicesSpecs = const [],

    /// [forceBluetooth5] is a flag to indicate if the advertisement can be using the Bluetooth 5.0 specification.
    bool allowBluetooth5 = true,

    /// [name] will be the name of the device on advertisement.
    /// If you don't provide a name, the device will not be advertised with a name.
    String? name,
  }) =>
      throw UnimplementedError('startAdvertise() has not been implemented.');

  /// [stopAdvertise] stops advertising a BLE device.
  Future<bool> stopAdvertise() => throw UnimplementedError('stopAdvertise() has not been implemented.');

  /// [respondReadRequest] responds to a GATT request.
  /// This method is designed to be a response from an event from [onGattUpdate] stream. Whhen the
  /// [GattReadRequest] is received, you can use this method to respond to the request.
  Future<bool> respondReadRequest({
    /// [requestId] is the ID of the request.
    required int requestId,

    /// [macAddress] is the MAC address of the device.
    required String macAddress,

    /// [offset] is the offset of the data to be read.
    required int offset,

    /// [serviceUuid] is the UUID of the service.
    required String serviceUuid,

    /// [characteristicUuid] is the UUID of the characteristic.
    required String characteristicUuid,

    /// [data] is the data to be sent in response to the request.
    Uint8List? data,
  }) =>
      throw UnimplementedError('respondReadRequest() has not been implemented.');

  /// [respondWriteRequest] responds to a GATT request.
  /// This method is designed to be a response from an event from [onGattUpdate] stream. Whhen the
  /// [GattWriteRequest] is received, you can use this method to respond to the request.
  Future<bool> respondWriteRequest({
    /// [requestId] is the ID of the request.
    required int requestId,

    /// [macAddress] is the MAC address of the device.
    required String macAddress,

    /// [offset] is the offset of the data to be read.
    required int offset,

    /// [serviceUuid] is the UUID of the service.
    required String serviceUuid,

    /// [characteristicUuid] is the UUID of the characteristic.
    required String characteristicUuid,

    /// [success] is a flag to indicate if the request was successful.
    required bool success,
  }) =>
      throw UnimplementedError('respondWriteRequest() has not been implemented.');

  /// [sendNotification] sends a notification to a BLE characteristic.
  /// You can use this method to send information to an specific characteristic, but requires a GATT server
  /// enabled, so, you need to use [startAdvertise] with [canConnect] set to `true`.
  Future<bool> sendNotification({
    /// [serviceUuid] is the UUID of the service.
    required String serviceUuid,

    /// [characteristicUuid] is the UUID of the characteristic.
    required String characteristicUuid,

    /// [payload] is the data to send to the characteristic.
    required Uint8List payload,

    /// [requestConfirmation] is a flag to indicate if the notification should be sent with confirmation.
    bool requestConfirmation = false,
  }) =>
      throw UnimplementedError('sendNotification() has not been implemented.');
}
