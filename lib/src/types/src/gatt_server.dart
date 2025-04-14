part of '../types.dart';

sealed class BleGattEvent {}

class GattConnected extends BleGattEvent {
  /// [macAddress] is the ID of the device.
  final String macAddress;

  /// [name] is the name of the device.
  /// Can be null if not available.
  final String? name;

  GattConnected({required this.macAddress, required this.name});

  factory GattConnected.fromMap(Map<String, dynamic> map) {
    return GattConnected(macAddress: map['macAddress'] as String, name: map['name'] as String?);
  }

  @override
  String toString() {
    return 'GattConnected(macAddress: $macAddress, name: $name)';
  }
}

class GattDisconnected extends BleGattEvent {
  /// [macAddress] is the ID of the device.
  final String macAddress;

  GattDisconnected({required this.macAddress});

  factory GattDisconnected.fromMap(Map<String, dynamic> map) {
    return GattDisconnected(macAddress: map['macAddress'] as String);
  }

  @override
  String toString() {
    return 'GattDisconnected(macAddress: $macAddress)';
  }
}

class GattReadRequest extends BleGattEvent {
  /// [macAddress] is the ID of the device.
  final String macAddress;

  /// [requestId] is the ID of the request.
  final int requestId;

  /// [offset] is the offset of the data to be read.
  final int offset;

  /// [serviceUuid] is the UUID of the service.
  final String serviceUuid;

  /// [characteristicUuid] is the UUID of the characteristic.
  final String characteristicUuid;

  GattReadRequest({
    required this.macAddress,
    required this.requestId,
    required this.offset,
    required this.serviceUuid,
    required this.characteristicUuid,
  });

  factory GattReadRequest.fromMap(Map<String, dynamic> map) {
    return GattReadRequest(
      macAddress: map['macAddress'] as String,
      requestId: map['requestId'] as int,
      offset: map['offset'] as int,
      serviceUuid: map['serviceUuid'] as String,
      characteristicUuid: map['characteristicUuid'] as String,
    );
  }

  @override
  String toString() {
    return 'GattReadRequest(macAddress: $macAddress, '
        'requestId: $requestId, '
        'offset: $offset, '
        'serviceUuid: $serviceUuid, '
        'characteristicUuid: $characteristicUuid)';
  }
}

class GattWriteRequest extends BleGattEvent {
  /// [macAddress] is the ID of the device.
  final String macAddress;

  /// [requestId] is the ID of the request.
  final int requestId;

  /// [offset] is the offset of the data to be read.
  final int offset;

  /// [serviceUuid] is the UUID of the service.
  final String serviceUuid;

  /// [characteristicUuid] is the UUID of the characteristic.
  final String characteristicUuid;

  /// [data] is the data to be written.
  final Uint8List? data;

  /// [preparedWrite] is true if the request is a prepared write request.
  final bool preparedWrite;

  /// [responseNeeded] is true if the request needs a response.
  final bool responseNeeded;

  GattWriteRequest({
    required this.macAddress,
    required this.requestId,
    required this.offset,
    required this.serviceUuid,
    required this.characteristicUuid,
    this.data,
    this.preparedWrite = false,
    this.responseNeeded = false,
  });

  factory GattWriteRequest.fromMap(Map<String, dynamic> map) {
    return GattWriteRequest(
      macAddress: map['macAddress'] as String,
      requestId: map['requestId'] as int,
      offset: map['offset'] as int,
      serviceUuid: map['serviceUuid'] as String,
      characteristicUuid: map['characteristicUuid'] as String,
      data: map['data'] != null ? map['data'] as Uint8List : null,
      preparedWrite: map['preparedWrite'] as bool? ?? false,
      responseNeeded: map['responseNeeded'] as bool? ?? false,
    );
  }

  @override
  String toString() {
    return 'GattWriteRequest('
        'macAddress: $macAddress, '
        'requestId: $requestId, '
        'offset: $offset, '
        'characteristicUuid: $characteristicUuid, '
        'data: $data, '
        'preparedWrite: $preparedWrite, '
        'responseNeeded: $responseNeeded)';
  }
}

class GattMtuChanged extends BleGattEvent {
  /// [macAddress] is the ID of the device.
  final String macAddress;

  /// [mtu] is the new MTU size.
  final int mtu;

  GattMtuChanged({required this.macAddress, required this.mtu});

  factory GattMtuChanged.fromMap(Map<String, dynamic> map) {
    return GattMtuChanged(macAddress: map['macAddress'] as String, mtu: map['mtu'] as int);
  }

  @override
  String toString() {
    return 'GattMtuChanged(macAddress: $macAddress, mtu: $mtu)';
  }
}
