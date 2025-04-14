part of '../types.dart';

class BleCharacteristicNotification {
  /// [serviceUuid] is the UUID of the service.
  final String serviceUuid;

  /// [characteristicUuid] is the UUID of the characteristic.
  final String characteristicUuid;

  /// [payload] is the data received from the characteristic.
  final Uint8List value;

  BleCharacteristicNotification({required this.serviceUuid, required this.characteristicUuid, required this.value});

  factory BleCharacteristicNotification.fromMap(Map<String, dynamic> map) {
    return BleCharacteristicNotification(
      serviceUuid: map['serviceUuid'],
      characteristicUuid: map['characteristicUuid'],
      value: Uint8List.fromList(List<int>.from(map['value'])),
    );
  }

  @override
  String toString() {
    return 'BleCharacteristicNotification(serviceUuid: $serviceUuid, '
        'characteristicUuid: $characteristicUuid, value: $value)';
  }
}
