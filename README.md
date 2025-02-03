# layrz_ble

[![Pub version](https://img.shields.io/pub/v/layrz_ble?logo=flutter)](https://pub.dev/packages/layrz_ble)
[![Pub Points](https://img.shields.io/pub/points/layrz_ble)](https://pub.dev/packages/layrz_ble/score)
[![likes](https://img.shields.io/pub/likes/layrz_ble?logo=flutter)](https://pub.dev/packages/layrz_ble/score)
[![GitHub license](https://img.shields.io/github/license/goldenm-software/layrz_ble?logo=github)](https://github.com/goldenm-software/layrz_ble)

A simple way to interact with BLE devices in Flutter.

## Why should I use this library?

Other libraries on the market are either too complex to use, or does not fully support functionalities like reading service data from the advertisement, or crop the manufacturer data, our objective is provide a fully functional library, with all of the ideal capabilities of a BLE library for Flutter.

For example, most of the libraries out there requires services and characteristics discovered before interacting with the device, but we auto-discover that for you, in this way, you will never forget about the services and characteristics of the device.

## Functionalities available per platform

✅ - Supported | ❌ - Not available | 🟨 - Partially supported

| Feature | Android | iOS | macOS | Windows | Web | Linux | Method(s) | 
| --- | --- | --- | --- | --- | --- | --- | --- |
| <b>Role: As a scanner</b> | --- | --- | --- | --- | --- | --- | --- |
| Scan for BLE devices | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | `startScan`, `stopScan` and `onScan` |
| Connect to BLE devices | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | `connect` and `onEvent` |
| Disconnect from BLE devices | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | `disconnect` and `onEvent` |
| Negotiate a new MTU | ✅ | ✅ | ✅ | 🟨 | ❌ | 🟨 | `setMtu` |
| Get services and characteristics | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | `discoverServices` |
| Read from characteristics | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | `readCharacteristic` |
| Write to characteristics | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | `writeCharacteristic` |
| Subscribe to characteristic notifications | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | `startNotify`, `stopNotify` and `onNotify` |
| <b>Role: As a BLE device</b> | --- | --- | --- | --- | --- | --- | --- |
| Advertise | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | TBD |
| Allow incoming connections | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | TBD |
| --- | --- | --- | --- | --- | --- | --- | --- |
| <b>Language used</b> | Kotlin | Swift | Swift | C++ | Dart | Dart | --- |

### MTU thing...
🟨 : Well, Windows (Directly on C++) and Linux (through [`bluez` package](https://pub.dev/packages/bluez)) does not support the capability to negotiate the MTU, but yes to return the max MTU allowed, so, when you call `setMtu` you will receive the max allowed from the APIs, not a negotiated value. And why this value is important? Well, you have a size limit of the things that you want to send to your device, knowing the MTU helps to adjusts your packets sizes before sending it to the device.

❌ : Web does not support neither negotiate nor getting the MTU, so, when you call `setMtu` you will receive a `null` value. Why a `null` instead of an error? Well, right now (early 2025) the Web Bluetooth API does not support the MTU, but it's on the roadmap to be implemented, so, we are returning a `null` value to indicate that the feature is not available yet, hopefully, this will change in the future.

## Minimum requirements
### Android

5.0 Lollipop (API Level 21) or later. Be careful with the permissions!.

### iOS

iOS 14.0 or later.

### macOS

11.0 Big Sur or later.

### Windows

Windows 10.0 or later (Like as the versions supported by [Flutter](https://docs.flutter.dev/reference/supported-platforms)).

### Web

Chromium-based browsers:
- Google Chrome 56 or later
- Microsoft Edge 79 or later
- Opera 43 or later
- Google Chrome Android 56 or later
- Samsung Internet 6.0 or later

Unfortunatelly, neither of these browsers supports Bluetooth API:
- Mozilla Firefox
- Apple Safari
- Google Android WebView
- Apple iOS WebView

### Linux

We think that any Linux distribution supported by [Flutter](https://docs.flutter.dev/reference/supported-platforms) with [`bluez`](https://www.bluez.org/) stack installed should work, but we tested on Ubuntu 24.04 LTS.

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

### Disclaimer about some classes used on this library

Part of the classes used on this library are from the [`layrz_models`](https://pub.dev/packages/layrz_models) package.

```dart
BleDevice         // Defines the BLE device itself, and of course the packet data separated on manufacturer and service data
BleService        // Defines the service, with the UUID and the characteristics
BleCharacteristic // Defines the characteristic, with the UUID and the properties (In a enum format to be easy to use)
BleProperty       // Defines the properties of the characteristic, with the most common properties defined.
```

Of course, if you think that you need more attributes, or do you want to add other, feel free to request it on [layrz_ble](https://github.com/goldenm-software/layrz_ble) repository or in the [layrz_models](https://github.com/goldenm-software/layrz_models) repository if you already has the changes done on the `layrz_ble` package. We are open to contributions and suggestions.

## Permissions and requirements

Before getting into the platform specific permissions, always raises the question "How can I handle the permissions on my Flutter app?". Well, you can use the [`permission_handler`](https://pub.dev/packages/permission_handler) package to handle the permissions on your Flutter app, or you can handle them manually with native code, the choice is yours.

### Android
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
  <!-- Location is required for BLE scan, required since Android 10 (API Level 29) -->
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

  <!-- android:usesPermissionFlags="neverForLocation" is for tell Android that you dont want location,
       but if you want to scan iBeacons or smart tags, you need to enable this -->
  <uses-permission
    android:name="android.permission.BLUETOOTH_SCAN"
    android:usesPermissionFlags="neverForLocation"
    android:minSdkVersion="31" /> <!-- This permission is only for API level 31 or above -->
    
  <uses-permission
    android:name="android.permission.BLUETOOTH_ADMIN"
    android:maxSdkVersion="30" /> <!-- This permission is only for API level 30 or below -->

  <!-- Required for BLE connection, in all API Levels -->
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

### Why on some platforms I'm getting an UUID instead of a Mac Address?
On web, Bluetooth API does not allow developers to access the MAC Address of the devices, instead, it returns a randomly generated string for the device. Be careful with this string, is not an unique identifier along the time and devices. More information on [mdn BluetoothDevice id property](https://developer.mozilla.org/en-US/docs/Web/API/BluetoothDevice/id).

On Apple ecosystem (aka, iOS, iPadOS and macOS), Apple privacy policies are very strict, and they don't allow developers to access the MAC Address of the devices, instead, Apple OSs return a UUID for the device. Be careful with this UUID, is not an unique identifier along the time and devices. More information on [Apple Developer CBPeripheral entity documentation](https://developer.apple.com/documentation/corebluetooth/cbperipheral)

### In Web, why I need to supply the services and characteristics?
This is a limitation of the Web Bluetooth API, you need to supply the services and characteristics to interact with the device. This is a security measure to prevent malicious websites to interact with your devices.

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
