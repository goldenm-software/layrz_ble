import 'package:pigeon/pigeon.dart';

// dart run pigeon --input pigeon/layrz_ble.dart
@ConfigurePigeon(
  PigeonOptions(
    dartPackageName: 'layrz_ble',
    dartOut: 'lib/src/layrz_ble_pigeon/layrz_ble.g.dart',
    dartOptions: DartOptions(),
    kotlinOut:
        'android/src/main/kotlin/com/layrz/layrz_ble/LayrzBle.g.kt',
    swiftOut: 'darwin/Classes/LayrzBle.g.swift',
    kotlinOptions: KotlinOptions(package: 'com.layrz.layrz_ble'),
    swiftOptions: SwiftOptions(),
    cppOptions: CppOptions(namespace: 'layrz_ble'),
    cppHeaderOut: 'windows/src/generated/layrz_ble.g.h',
    cppSourceOut: 'windows/src/generated/layrz_ble.g.cpp',
    debugGenerators: true,
  ),
)