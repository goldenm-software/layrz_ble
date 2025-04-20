part of '../types.dart';

@freezed
abstract class BleStatus with _$BleStatus {
  const BleStatus._();

  /// [BleStatus] is the status of the Bluetooth Low Energy (BLE) adapter.
  /// It contains the status of the advertising and scanning.
  const factory BleStatus({
    /// [advertising] is the status of the advertising.
    required bool advertising,

    /// [scanning] is the status of the scanning.
    required bool scanning,
  }) = _BleStatus;

  factory BleStatus.fromJson(Map<String, dynamic> json) => _$BleStatusFromJson(json);
}
