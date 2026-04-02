# Changelog

## 1.3.5
- update to 1.3.5
- Force to use meta  1.7.0

## 1.3.4
- Add `meta` in pubspect.yaml

## 1.3.3
- Add in `BleStatus` `isEnabled`
- Add `openBluetoothSettings` to open Bluetooth settings in Macos, iOs, android, Windows

## 1.3.2

- Reduced # of logs on Windows implementation
- Standarized `toUppercase` on all UUIDs and Mac addresses on Windows implementation

## 1.3.1

- Some fixes on Windows implementation

## 1.3.0

- Stable release of the 1.3.0 version.

## 1.3.0-rc.3

- Fixed an issue with the service data parser on Linux

## 1.3.0-rc.2

- Added `platforms` on the `pubspec.yaml` to prevent issues with `pub.dev`

## 1.3.0-rc.1

- Fixes related to disconnection on iOS and macOS.
- Testing phase started

## 1.3.0-prerelease.1

- Migrated the plugin to use `pigeon` instead of manual `MethodChannel` implementation.

## 1.3.0-beta.6

- Fixed issues with scan of Bluetooth Core 5.0 spec on Android.

## 1.3.0-beta.5

- Removed timeout

## 1.3.0-beta.4

- Some fixes on Windows implementations

## 1.3.0-beta.3

- Downgraded sdk to preserve legacy formatting.
- Added `getStatuses` to get the status of the connection.
- Added getters of `isAdvertising` and `isScanning` to get the current status.
- Reviewed Web and Linux based on the recent changes.

## 1.3.0-beta.2

- Added multi-connection support on Android. Pending on other platforms.

## 1.3.0-beta.1

- Applied fixes related to the return information of `checkCapabilities` on darwin (iOS and macOS).

## 1.3.0-alpha.6

- Some fixes on Android
- Tested the implementation on Windows, and does not work due to some unknown restrictions.

## 1.3.0-alpha.5

- Some fixes related with the advertisement on Android.

## 1.3.0-alpha.4

- Solved issues related to the advertisement stop and start, before throws a error 3 (Already advertising) when you try to start the advertisement after stopping it. Now, it will stop and start the advertisement without any error.

## 1.3.0-alpha.3

- Fixes on notifications on Android.

## 1.3.0-alpha.2

- Updated README.md

## 1.3.0-alpha.1

- Added `startAdvertise()`, `stopAdvertise()`, `respondWriteRequest()` and `respondReadRequest()` methods on Android to support Advertisement using GATT server.

## 1.2.3

- Segmented MethodChannel's in different channels to prevent overloading.
- Fixed an issue on Android where the device would not disconnect properly. Now, when a disconnection is detected, the gatt will be closed.
- Unified iOS and macOS to use the same codebase (darwin).

## 1.2.2

- Added try/catch around the read and write characteristic functions to prevent crashes when the device is disconnected

## 1.2.1

- Added txPower to the data that can be received from the device

## 1.2.0

- Updated all platforms to support multiple manufacturer data

## 1.1.3

- Removed parser things from this library

## 1.1.2

- Added `BleCondition`, `BleConversion`, `BleParser`, `BleParserConfig`, `BleParserProperty`, `BleServiceData`, `BleOperation`, `BleParserSource` and `BleWatch` to the export.

## 1.1.1

- Added Advertisement data parsers to the main class.

## 1.1.0

- Changed service data schema

## 1.0.1

- Added auto-discovery of the servcices and characteristics of the device

## 1.0.0

- Initial release
