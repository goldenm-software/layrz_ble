part of '../types.dart';

enum BleEvent {
  /// [onScan] is an event that is triggered when a BLE device is found.
  onScan,

  /// [connected] is an event that is triggered when a BLE device is connected.
  connected,

  /// [disconnected] is an event that is triggered when a BLE device is disconnected.
  disconnected,

  /// [unknown] is an event that is triggered when an unknown event is received.
  unknown,

  /// [scanStopped] is an event that is triggered when the scan is stopped.
  /// This event can be triggered by the user or by the system when you are connected to a device.
  scanStopped;

  @override
  String toString() => toPlatform();

  String toPlatform() {
    switch (this) {
      case BleEvent.onScan:
        return 'ON_SCAN';
      case BleEvent.connected:
        return 'CONNECTED';
      case BleEvent.disconnected:
        return 'DISCONNECTED';
      case BleEvent.scanStopped:
        return 'SCAN_STOPPED';
      default:
        return 'UNKNOWN';
    }
  }

  static BleEvent fromPlatform(String platform) {
    switch (platform) {
      case 'ON_SCAN':
        return BleEvent.onScan;
      case 'CONNECTED':
        return BleEvent.connected;
      case 'DISCONNECTED':
        return BleEvent.disconnected;
      case 'SCAN_STOPPED':
        return BleEvent.scanStopped;
      default:
        return BleEvent.unknown;
    }
  }
}
