# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Install dependencies
flutter pub get

# Lint / static analysis
flutter analyze

# Run tests
flutter test

# Run a single test file
flutter test test/bluetooth_status_widget_test.dart

# Run tests with coverage
flutter test --machine --coverage

# Regenerate code (freezed, json_serializable, pigeon)
dart run build_runner build --delete-conflicting-outputs

# Regenerate pigeon bindings only
dart run pigeon --input pigeon/layrz_ble.dart
```

## Architecture

This is a **Flutter federated plugin** for BLE (Bluetooth Low Energy) supporting Android, iOS, macOS, Windows, Linux, and Web.

### Platform dispatch

`LayrzBle` (`lib/layrz_ble.dart`) is the public facade. It selects the platform implementation at runtime:
- **Web** → `LayrzBlePluginWeb` (`lib/src/layrz_ble_web/web_channel.dart`)
- **Linux** → `LayrzBlePluginLinux` (`lib/src/layrz_ble_linux/linux_channel.dart`) — pure Dart using `bluez` package
- **Android / iOS / macOS / Windows** → `LayrzBlePigeonChannel` (`lib/src/layrz_ble_pigeon/pigeon_channel.dart`) — communicates via Pigeon-generated bindings

All platform implementations extend `LayrzBlePlatform` (`lib/src/platform_interface.dart`).

### Pigeon

The Pigeon schema lives in `pigeon/layrz_ble.dart`. Running `dart run pigeon --input pigeon/layrz_ble.dart` regenerates:
- `lib/src/layrz_ble_pigeon/layrz_ble.g.dart` (Dart)
- `android/src/main/kotlin/com/layrz/layrz_ble/LayrzBle.g.kt` (Kotlin)
- `darwin/layrz_ble/Sources/layrz_ble/LayrzBle.g.swift` (Swift, shared iOS/macOS)
- `windows/src/generated/layrz_ble.g.{h,cpp}` (C++)

Pigeon defines two channels:
- `LayrzBlePlatformChannel` — Flutter → Native (host API)
- `LayrzBleCallbackChannel` — Native → Flutter (callback API)

### Types

`lib/src/types/` contains Dart-only types (`BleEvent`, `BleStatus`, `BleCharacteristicNotification`, `BleGattEvent`), generated with `freezed` + `json_serializable`. The `types.freezed.dart` and `types.g.dart` files are generated — do not edit them manually.

Types shared with other Layrz packages (`BleDevice`, `BleService`, `BleCharacteristic`, `BleProperty`, `BleManufacturerData`, `BleServiceData`) come from `layrz_models` and are re-exported from `lib/layrz_ble.dart`.

### Native implementations

| Platform | Location | Language |
|---|---|---|
| Android | `android/` | Kotlin |
| iOS + macOS | `darwin/` (shared) | Swift |
| Windows | `windows/` | C++ |

Linux and Web have no native layer — they are implemented entirely in Dart.

### Streams (event model)

The plugin exposes four streams on `LayrzBle`:
- `onScan` — discovered `BleDevice` during scan
- `onEvent` — connection/disconnection `BleEvent`
- `onNotify` — `BleCharacteristicNotification` from subscribed characteristics
- `onGattUpdate` — `BleGattEvent` for GATT server events (advertising/connectable mode, Android only)
- `onBluetoothStateChanged` — Bluetooth enabled/disabled state

### Code generation notes

- After modifying any `@freezed` class or `@JsonSerializable` class, run `build_runner`.
- After modifying `pigeon/layrz_ble.dart`, run pigeon and update all four native targets.
- `build.yaml` configures `json_serializable` with `explicit_to_json: true`.
