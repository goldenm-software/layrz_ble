import 'dart:typed_data';

class BleCapabilities {
  /// [locationPermission] is true if the app has location permission.
  ///
  /// On Android:
  /// `<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />`
  ///
  /// On iOS, macOS, windows, web or linux, this will always return
  /// the same value as [bluetoothPermission]
  final bool locationPermission;

  /// [bluetoothPermission] is true if the app has bluetooth permission.
  ///
  /// On Android:
  /// `<uses-permission android:name="android.permission.BLUETOOTH" />`
  ///
  /// On iOS and macOS:
  /// You need to add the `NSBluetoothAlwaysUsageDescription` key to your Info.plist file.
  ///
  /// On web:
  /// Will return true if the browser supports Web Bluetooth.
  ///
  /// On windows:
  /// If the library can find a Bluetooth adapter (radio) on the system.
  ///
  /// On linux:
  /// If the library can find a Bluetooth adapter and `bluez` installed.
  final bool bluetoothPermission;

  /// [bluetoothAdminOrScanPermission] is true if the app has bluetooth admin or scan permission.
  ///
  /// On Android:
  /// On API level 31 or above, the app needs to have scan permission.
  /// `<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />`
  ///
  /// On API level 30 or below, the app needs to have admin permission.
  /// `<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />`
  ///
  /// On iOS, macOS, windows, web or linux, this will always return the same value
  /// as [bluetoothPermission]
  final bool bluetoothAdminOrScanPermission;

  /// [bluetoothConnectPermission] is true if the app has bluetooth connect permission.
  ///
  /// On Android (API level 31 or above):
  /// `<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />`
  /// On Android (API level 30 or below) will always return true.
  ///
  /// On iOS, macOS, windows, web or linux, this will always return the same value
  /// as [bluetoothPermission]
  final bool bluetoothConnectPermission;

  /// [BleCapabilities] defines the capabilities of the device or browser.
  ///
  /// Denending on your platform, some capabilities may not be available.
  BleCapabilities({
    required this.locationPermission,
    required this.bluetoothPermission,
    required this.bluetoothAdminOrScanPermission,
    required this.bluetoothConnectPermission,
  });

  factory BleCapabilities.fromMap(Map<String, dynamic> map) {
    return BleCapabilities(
      locationPermission: map['locationPermission'] ?? false,
      bluetoothPermission: map['bluetoothPermission'] ?? false,
      bluetoothAdminOrScanPermission: map['bluetoothAdminOrScanPermission'] ?? false,
      bluetoothConnectPermission: map['bluetoothConnectPermission'] ?? false,
    );
  }

  @override
  String toString() {
    return 'BleCapabilities(locationPermission: $locationPermission, bluetoothPermission: $bluetoothPermission, '
        'bluetoothAdminOrScanPermission: $bluetoothAdminOrScanPermission, '
        'bluetoothConnectPermission: $bluetoothConnectPermission)';
  }
}

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
  scanStopped,
  ;

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

class BleCharacteristicNotification {
  /// [serviceUuid] is the UUID of the service.
  final String serviceUuid;

  /// [characteristicUuid] is the UUID of the characteristic.
  final String characteristicUuid;

  /// [payload] is the data received from the characteristic.
  final Uint8List value;

  BleCharacteristicNotification({
    required this.serviceUuid,
    required this.characteristicUuid,
    required this.value,
  });

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
