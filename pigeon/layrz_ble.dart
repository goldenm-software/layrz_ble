import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartPackageName: 'layrz_ble',
    dartOut: 'lib/src/layrz_ble_pigeon/layrz_ble.g.dart',
    dartOptions: DartOptions(),
    kotlinOut: 'android/src/main/kotlin/com/layrz/layrz_ble/LayrzBle.g.kt',
    swiftOut: 'darwin/layrz_ble/Sources/layrz_ble/LayrzBle.g.swift',
    kotlinOptions: KotlinOptions(package: 'com.layrz.layrz_ble'),
    swiftOptions: SwiftOptions(),
    cppOptions: CppOptions(namespace: 'layrz_ble'),
    cppHeaderOut: 'windows/src/generated/layrz_ble.g.h',
    cppSourceOut: 'windows/src/generated/layrz_ble.g.cpp',
    debugGenerators: true,
  ),
)

// Host API from Flutter to Native
@HostApi()
abstract class LayrzBlePlatformChannel {
  @async
  BtStatus getStatuses();

  @async
  bool checkCapabilities();

  @async
  bool checkScanPermissions();

  @async
  bool checkAdvertisePermissions();

  @async
  bool startScan({String? macAddress, List<String>? servicesUuids});

  @async
  bool stopScan({String? macAddress});

  @async
  bool connect({required String macAddress});

  @async
  bool disconnect({String? macAddress});

  @async
  int? setMtu({required String macAddress, required int newMtu});

  @async
  List<BtService> discoverServices({required String macAddress});

  @async
  Uint8List readCharacteristic({
    required String macAddress,
    required String serviceUuid,
    required String characteristicUuid,
  });

  @async
  bool writeCharacteristic({
    required String macAddress,
    required String serviceUuid,
    required String characteristicUuid,
    required Uint8List payload,
    required bool withResponse,
  });

  @async
  bool startNotify({
    required String macAddress,
    required String serviceUuid,
    required String characteristicUuid,
  });

  @async
  bool stopNotify({
    required String macAddress,
    required String serviceUuid,
    required String characteristicUuid,
  });
}

// Flutter API from Native to Flutter
@FlutterApi()
abstract class LayrzBleCallbackChannel {
  void onScanResult(BtDevice device);

  void onBluetoothOn();
  void onBluetoothOff();

  void onScanStarted();
  void onScanStopped();

  void onConnected(BtDevice device);
  void onDisconnected(BtDevice device);

  void onCharacteristicUpdate(BtCharacteristicNotification notification);
}

class BtStatus {
  final bool advertising;
  final bool scanning;

  const BtStatus({
    this.advertising = false,
    this.scanning = false,
  });
}

class BtDevice {
  final String macAddress;
  final String? name;
  final int? rssi;
  final int? txPower;
  final List<BtManufacturerData> manufacturerData;
  final List<BtServiceData> serviceData;

  const BtDevice({
    required this.macAddress,
    this.name,
    this.rssi,
    this.txPower,
    this.manufacturerData = const [],
    this.serviceData = const [],
  });
}

class BtManufacturerData {
  final int companyId;
  final Uint8List? data;

  const BtManufacturerData({
    this.companyId = 0x0000,
    this.data,
  });
}

class BtServiceData {
  final int uuid;
  final Uint8List? data;

  const BtServiceData({
    this.uuid = 0x0000,
    this.data,
  });
}

class BtService {
  final String uuid;
  final List<BtCharacteristic> characteristics;

  const BtService({
    required this.uuid,
    this.characteristics = const [],
  });
}

class BtCharacteristic {
  final String uuid;
  final List<String> properties;

  const BtCharacteristic({
    required this.uuid,
    this.properties = const [],
  });
}

class BtCharacteristicNotification {
  final String macAddress;
  final String serviceUuid;
  final String characteristicUuid;
  final Uint8List value;

  const BtCharacteristicNotification({
    required this.macAddress,
    required this.serviceUuid,
    required this.characteristicUuid,
    required this.value,
  });
}
