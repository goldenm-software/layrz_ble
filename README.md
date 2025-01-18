# layrz_ble

[![Pub version](https://img.shields.io/pub/v/layrz_ble?logo=flutter)](https://pub.dev/packages/layrz_ble)
[![popularity](https://img.shields.io/pub/popularity/layrz_ble?logo=flutter)](https://pub.dev/packages/layrz_ble/score)
[![likes](https://img.shields.io/pub/likes/layrz_ble?logo=flutter)](https://pub.dev/packages/layrz_ble/score)
[![GitHub license](https://img.shields.io/github/license/goldenm-software/layrz_ble?logo=github)](https://github.com/goldenm-software/layrz_ble)

A simple way to interact with BLE devices in Flutter.

## Motivation
Our goal is to provide a simple and easy-to-use library for Flutter developers to interact with BLE devices, and support as many platforms as possible.

## Why should I use this library?
Other libraries on the market are either too complex to use, or does not fully support functionalities like reading service data from the advertisement, or crop the manufacturer data, our objective is provide a fully functional library, with all of the ideal capabilities of a BLE library for Flutter.

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

## Features available per platform

✅ - Supported | ❌ - Not available | 🟨 - Partially supported

| Feature | Android | iOS | macOS | Windows | Web | Linux |
| --- | --- | --- | --- | --- | --- | --- |
| Scan for BLE devices | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Connect to BLE devices | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Disconnect from BLE devices | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Negotiate a new MTU | ✅ | ✅ | ✅ | 🟨 | ❌ | 🟨 |
| Get services and characteristics | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Read from characteristics | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Write to characteristics | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Subscribe to characteristic notifications | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Send a payload to a BLE device | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| --- | --- | --- | --- | --- | --- | --- |
| Language used | Kotlin | Swift | Swift | C++ | Dart | Dart |

## Permissions and requirements

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
  <!-- Required for BLE -->
  <key>NSBluetoothAlwaysUsageDescription</key>
  <string>The app need access to the Bluetooth to extract sensor values and diagnostics of the devices</string>
  <key>NSBluetoothPeripheralUsageDescription</key>
  <string>The app need access to the Bluetooth to do a remote configuration of the devices compatible with</string>
  <!-- ... -->
</dict>
</plist>
```

### macOS
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <!-- ... -->
  <!-- Required for BLE -->
  <key>NSBluetoothAlwaysUsageDescription</key>
  <string>This app uses Bluetooth to connect to your device.</string>
  <!-- ... -->
</dict>
</plist>
```

### Windows
If you use [`msix` package](https://pub.dev/packages/msix) to build your Windows app, you need to declare the permission for Bluetooth, this is an example of how to do it on your pubspec.yaml

```yaml
msix_config:
  capabilities: bluetooth,radios
```

More information about the capabilities on Windows can be found on [Microsoft documentation](https://learn.microsoft.com/en-us/windows/uwp/packaging/app-capability-declarations)

### Web
Nothing to do here :)

### Linux
Your platform should have `bluez` stack installed to work, otherwise the lib will not work.

## Roadmap
⬜ Permission support for each platform

## FAQ

### Why on iOS and macOS I'm getting an UUID instead of a Mac Address?
Apple privacy policies are very strict, and they don't allow developers to access the MAC Address of the devices, instead, Apple OSs return a UUID for the device. Be careful with this UUID, is not an unique identifier along the time and devices. More information on [Apple Developer CBPeripheral entity documentation](https://developer.apple.com/documentation/corebluetooth/cbperipheral)

### And why on Web, I cannot get the MAC Address?
Web Bluetooth API does not allow developers to access the MAC Address of the devices, instead, it returns a randomly generated string for the device. Be careful with this string, is not an unique identifier along the time and devices. More information on [mdn BluetoothDevice id property](https://developer.mozilla.org/en-US/docs/Web/API/BluetoothDevice/id)

### In Web, why I need to supply the services and characteristics?
This is a limitation of the Web Bluetooth API, you need to supply the services and characteristics to interact with the device. This is a security measure to prevent malicious websites to interact with your devices.

### And, why on Web and Linux, I cannot negotiate the MTU?
This functionality on Web Bluetooth API is currently not available, similar case with Linux, the wrapper implemented [bluez package](https://pub.dev/packages/bluez) does not support this feature.

Disclaimer: On Linux and Windows, if you call `setMtu`, the response is the allowed MTU from the device and the system, not the negotiated MTU.

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
