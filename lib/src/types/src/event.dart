part of '../types.dart';

abstract class BleEvent {}

class BleConnected extends BleEvent {
  final String macAddress;
  final String? name;

  BleConnected({required this.macAddress, this.name});

  static BleConnected fromMap(Map<String, dynamic> map) {
    return BleConnected(macAddress: map['macAddress'], name: map['name']);
  }
}

class BleDisconnected extends BleEvent {
  final String macAddress;

  BleDisconnected({required this.macAddress});

  static BleDisconnected fromMap(Map<String, dynamic> map) {
    return BleDisconnected(macAddress: map['macAddress']);
  }
}

class BleScanStarted extends BleEvent {}

class BleScanStopped extends BleEvent {}
