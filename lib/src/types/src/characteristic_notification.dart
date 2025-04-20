part of '../types.dart';

@freezed
abstract class BleCharacteristicNotification with _$BleCharacteristicNotification {
  const BleCharacteristicNotification._();

  /// [BleCharacteristicNotification] is the notification received from a BLE characteristic.
  /// It contains the MAC address of the device, the UUID of the service,
  const factory BleCharacteristicNotification({
    /// [macAddress] is the MAC address of the device.
    required String macAddress,

    /// [serviceUuid] is the UUID of the service.
    required String serviceUuid,

    /// [characteristicUuid] is the UUID of the characteristic.
    required String characteristicUuid,

    /// [payload] is the data received from the characteristic.
    @UintListConverter() required Uint8List value,
  }) = _BleCharacteristicNotification;

  factory BleCharacteristicNotification.fromJson(Map<String, dynamic> json) =>
      _$BleCharacteristicNotificationFromJson(json);
}
