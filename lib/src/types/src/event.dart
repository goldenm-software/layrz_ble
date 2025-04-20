part of '../types.dart';

sealed class BleEvent {
  const BleEvent.event();
}

@freezed
abstract class BleConnected extends BleEvent with _$BleConnected {
  const BleConnected._() : super.event();

  /// [BleConnected] is the event received when a device is connected.
  const factory BleConnected({
    /// [macAddress] is the MAC address of the device.
    required String macAddress,

    /// [name] is the name of the device.
    ///
    /// Can be `null` if the device does not advertise its name.
    String? name,
  }) = _BleConnected;
  factory BleConnected.fromJson(Map<String, dynamic> json) => _$BleConnectedFromJson(json);
}

@freezed
abstract class BleDisconnected extends BleEvent with _$BleDisconnected {
  const BleDisconnected._() : super.event();

  /// [BleDisconnected] is the event received when a device is disconnected.
  const factory BleDisconnected({
    /// [macAddress] is the MAC address of the device.
    required String macAddress,
  }) = _BleDisconnected;

  factory BleDisconnected.fromJson(Map<String, dynamic> json) => _$BleDisconnectedFromJson(json);
}

class BleScanStarted extends BleEvent {
  const BleScanStarted() : super.event();
}

class BleScanStopped extends BleEvent {
  const BleScanStopped() : super.event();
}

class BleAdapterOff extends BleEvent {
  const BleAdapterOff() : super.event();
}

class BleAdapterOn extends BleEvent {
  const BleAdapterOn() : super.event();
}
