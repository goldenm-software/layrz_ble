part of '../types.dart';

sealed class BleGattEvent {
  const BleGattEvent.event();
}

@freezed
abstract class GattConnected extends BleGattEvent with _$GattConnected {
  const GattConnected._() : super.event();

  /// [GattConnected] is the event received when a device is connected.
  const factory GattConnected({
    /// [macAddress] is the ID of the device.
    required String macAddress,

    /// [name] is the name of the device.
    /// Can be null if not available.
    String? name,
  }) = _GattConnected;

  factory GattConnected.fromJson(Map<String, dynamic> json) => _$GattConnectedFromJson(json);
}

@freezed
abstract class GattDisconnected extends BleGattEvent with _$GattDisconnected {
  const GattDisconnected._() : super.event();

  const factory GattDisconnected({
    /// [macAddress] is the ID of the device.
    required String macAddress,
  }) = _GattDisconnected;

  factory GattDisconnected.fromJson(Map<String, dynamic> json) => _$GattDisconnectedFromJson(json);
}

@freezed
abstract class GattReadRequest extends BleGattEvent with _$GattReadRequest {
  const GattReadRequest._() : super.event();

  /// [GattReadRequest] is the event received when a read request is received.
  const factory GattReadRequest({
    /// [macAddress] is the ID of the device.
    required String macAddress,

    /// [requestId] is the ID of the request.
    required int requestId,

    /// [offset] is the offset of the data to be read.
    required int offset,

    /// [serviceUuid] is the UUID of the service.
    required String serviceUuid,

    /// [characteristicUuid] is the UUID of the characteristic.
    required String characteristicUuid,
  }) = _GattReadRequest;

  factory GattReadRequest.fromJson(Map<String, dynamic> json) => _$GattReadRequestFromJson(json);
}

@freezed
abstract class GattWriteRequest extends BleGattEvent with _$GattWriteRequest {
  const GattWriteRequest._() : super.event();

  /// [GattWriteRequest] is the event received when a write request is received.
  const factory GattWriteRequest({
    /// [macAddress] is the ID of the device.
    required String macAddress,

    /// [requestId] is the ID of the request.
    required int requestId,

    /// [offset] is the offset of the data to be read.
    required int offset,

    /// [serviceUuid] is the UUID of the service.
    required String serviceUuid,

    /// [characteristicUuid] is the UUID of the characteristic.
    required String characteristicUuid,

    /// [data] is the data to be written.
    @UintListOrNullConverter() Uint8List? data,

    /// [preparedWrite] is true if the request is a prepared write request.
    @Default(false) bool preparedWrite,

    /// [responseNeeded] is true if the request needs a response.
    @Default(false) bool responseNeeded,
  }) = _GattWriteRequest;

  factory GattWriteRequest.fromJson(Map<String, dynamic> json) => _$GattWriteRequestFromJson(json);
}

@freezed
abstract class GattMtuChanged extends BleGattEvent with _$GattMtuChanged {
  const GattMtuChanged._() : super.event();

  /// [GattMtuChanged] is the event received when the MTU size is changed.
  const factory GattMtuChanged({
    /// [macAddress] is the ID of the device.
    required String macAddress,

    /// [mtu] is the new MTU size.
    required int mtu,
  }) = _GattMtuChanged;

  factory GattMtuChanged.fromJson(Map<String, dynamic> json) => _$GattMtuChangedFromJson(json);
}
