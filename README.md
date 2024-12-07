# layrz_ble
Managed by Golden M.

## Motivation
This plugin is a universal wrapper for BLE devices, which allows you to scan, connect, and interact with BLE devices in a simple and easy way.
Our goal is to provide a simple and easy-to-use library for Flutter developers to interact with BLE devices, and support as many platforms as possible.

## Usage
To use this plugin, add `layrz_ble` as a [dependency in your pubspec.yaml file](https://flutter.dev/docs/development/packages-and-plugins/using-packages).

```yaml
dependencies:
  flutter:
    sdk: flutter
  layrz_ble: ^latest_version
```

Then you can import the package in your Dart code:

```dart
import 'package:layrz_ble/layrz_ble.dart';

/// ...

final ble = LayrzBle();

// Listen for events
ble.onEvent.listen((BleEvent event) { // Class included on the package
  debugPrint(event);
});

// Listen for device discovery
ble.onScan.listen((BleDevice device) { // BleDevice is a class from `layrz_models` package, but we exported it here for convenience
  debugPrint(device);
});

// Check capabilities
final BleCapabilities capabilities = await ble.checkCapabilities(); // Class included on the package

// Scan for BLE devices
final bool startResult = await ble.startScan();

// Stop scanning
final bool stopResult = await ble.stopScan();
```

## Goals
### Capabilities
- [x] Scan for BLE devices
- [ ] Connect to BLE devices (Work in progress)
- [ ] Disconnect from BLE devices
- [ ] Read and write characteristics
- [ ] Subscribe to characteristic notifications

## Platforms
- [ ] Support for Android (Work in progress)
- [ ] Support for iOS
- [ ] Support for Web
- [ ] Support for macOS
- [ ] Support for Windows

## Permissions
Each platform requires some permissions to be granted in order to work properly. Here is a list of permissions required by each platform:

### Android
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
  <!-- Location is required for BLE scan -->
  <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
  <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />

  <!-- Of course, Bluetooth -->
  <uses-permission android:name="android.permission.BLUETOOTH" />

  <!--
  Required for BLE scan 
  
  Uses or BLUETOOTH_SCAN or BLUETOOTH_ADMIN permission depending on the API level.
  If your app has a minSdkVersion of 31 or above, you should use BLUETOOTH_SCAN permission only,
  otherwise we strongly recommend using both as shown below.
  -->
  <uses-permission
    android:name="android.permission.BLUETOOTH_SCAN"
    android:usesPermissionFlags="neverForLocation"
    android:minSdkVersion="31" /> <!-- This permission is only for API level 31 or above -->
  <uses-permission
    android:name="android.permission.BLUETOOTH_ADMIN"
    android:maxSdkVersion="30" /> <!-- This permission is only for API level 30 or below -->

  <!-- Required for BLE connection -->
  <uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />

  <!-- ... -->
</manifest>
```

### iOS
To be added.

### Web
To be added.

### macOS
To be added.

### Windows
To be added.
