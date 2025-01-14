# layrz_ble

[![Pub version](https://img.shields.io/pub/v/layrz_ble?logo=flutter)](https://pub.dev/packages/layrz_ble)
[![popularity](https://img.shields.io/pub/popularity/layrz_ble?logo=flutter)](https://pub.dev/packages/layrz_ble/score)
[![likes](https://img.shields.io/pub/likes/layrz_ble?logo=flutter)](https://pub.dev/packages/layrz_ble/score)
[![GitHub license](https://img.shields.io/github/license/goldenm-software/layrz_ble?logo=github)](https://github.com/goldenm-software/layrz_ble)

A simple way to interact with BLE devices in Flutter.

## Motivation
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

/// Listen for events
///
/// `BleEvent` is from this package
ble.onEvent.listen((BleEvent event) {
  debugPrint(event);
});

/// Listen for device discovery
///
/// `BleDevice` is from `layrz_models` package, but we exported it here for convenience
ble.onScan.listen((BleDevice device) {
  debugPrint(device);
});

/// Check capabilities
///
/// `BleCapabilities` is from this package
final BleCapabilities capabilities = await ble.checkCapabilities();

/// Scan for BLE devices
final bool startResult = await ble.startScan();

/// Stop scanning
final bool stopResult = await ble.stopScan();
```

## Working checklist per platform
### Android
- [x] Scan for BLE devices
- [x] Connect to BLE devices
- [x] Disconnect from BLE devices
- [x] Negotiate a new MTU
- [x] Get services and characteristics
- [x] Read from characteristics
- [x] Write to characteristics
- [x] Subscribe to characteristic notifications
- [x] Send a payload to a BLE device

### iOS
- [x] Scan for BLE devices
- [x] Connect to BLE devices
- [x] Disconnect from BLE devices
- [x] Negotiate a new MTU
- [x] Get services and characteristics
- [x] Read from characteristics
- [x] Write to characteristics
- [x] Subscribe to characteristic notifications
- [x] Send a payload to a BLE device

### macOS
- [x] Scan for BLE devices
- [x] Connect to BLE devices
- [x] Disconnect from BLE devices
- [x] Negotiate a new MTU
- [x] Get services and characteristics
- [x] Read from characteristics
- [x] Write to characteristics
- [x] Subscribe to characteristic notifications
- [x] Send a payload to a BLE device

### Windows
- [ ] Scan for BLE devices
- [ ] Connect to BLE devices
- [ ] Disconnect from BLE devices
- [ ] Negotiate a new MTU
- [ ] Get services and characteristics
- [ ] Read from characteristics
- [ ] Write to characteristics
- [ ] Subscribe to characteristic notifications
- [ ] Send a payload to a BLE device

## Permissions

Before getting into the platform specific permissions, always raises the question "How can I handle the permissions on my Flutter app?". Well, you can use the [`permission_handler`](https://pub.dev/packages/permission_handler) package to handle the permissions on your Flutter app, or you can handle them manually with native code, the choice is yours.

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
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <!-- ... -->
  <!-- Required for BLE scan -->
	<key>NSBluetoothAlwaysUsageDescription</key>
	<string>The app need access to the Bluetooth to extract sensor values and diagnostics of the devices</string>
	<key>NSBluetoothPeripheralUsageDescription</key>
	<string>The app need access to the Bluetooth to do a remote configuration of the devices compatible with</string>
  <!-- ... -->
</dict>
</plist>
```

### macOS
To be added.

### Windows
To be added.

## FAQ

### Why on iOS and macOS I'm getting an UUID instead of a Mac Address?
Apple privacy policies are very strict, and they don't allow developers to access the MAC Address of the devices, instead, Apple OSs return a UUID for the device. Be careful with this UUID, is not an unique identifier along the time and devices.

### Why this library does not support Linux?
Honestly, is a matter of priorities, we are focusing on the most used platforms first for the end users. If you want to help us to support Linux, feel free to open a pull request on the [Repository](https://github.com/goldenm-software/layrz_ble)!

### And, why web is not supported?
Web Bluetooth API is a very powerful tool, and we are considering to support it in the future, but for now, we are focusing on the mobile and desktop platforms (Native code). If you want to help us to support Web, feel free to open a pull request on the [Repository](https://github.com/goldenm-software/layrz_ble)!

### Why is this package called `layrz_ble`?
All packages developed by [Layrz](https://layrz.com) are prefixed with `layrz_`, check out our other packages on [pub.dev](https://pub.dev/publishers/goldenm.com/packages).

### I need to pay to use this package?
<b>No!</b> This library is free and open source, you can use it in your projects without any cost, but if you want to support us, give us a thumbs up here in [pub.dev](https://pub.dev/packages/layrz_ble) and star our [Repository](https://github.com/goldenm-software/layrz_ble)!

### Can I contribute to this package?
<b>Yes!</b> We are open to contributions, feel free to open a pull request or an issue on the [Repository](https://github.com/goldenm-software/layrz_ble)!

### I have a question, how can I contact you?
If you need more assistance, you open an issue on the [Repository](https://github.com/goldenm-software/layrz_ble) and we're happy to help you :)

## License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

This project is maintained by [Golden M](https://goldenm.com) with authorization of [Layrz LTD](https://layrz.com).

## Who are you? / Want to work with us?
<b>Golden M</b> is a software and hardware development company what is working on a new, innovative and disruptive technologies. For more information, contact us at [sales@goldenm.com](mailto:sales@goldenm.com) or via WhatsApp at [+(507)-6979-3073](https://wa.me/50769793073?text="From%20layrz_ble%20flutter%20library.%20Hello").
