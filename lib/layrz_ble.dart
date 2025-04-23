library;

import 'dart:typed_data';

import 'package:layrz_ble/layrz_ble.dart';
import 'package:layrz_ble/src/layrz_ble_pigeon/pigeon_channel.dart';
import 'package:layrz_ble/src/platform_interface.dart';

export 'package:layrz_models/layrz_models.dart'
    show BleDevice, BleService, BleCharacteristic, BleProperty, BleManufacturerData, BleServiceData;

export 'platforms/stub.dart' if (dart.library.io) 'platforms/linux.dart';

export 'src/types/types.dart';

class LayrzBle {
  /// [_platform] is the platform interface for the LayrzBle plugin.
  static LayrzBlePlatform _platform = _defaultPlatform();

  /// [setInstance] is used to set the platform interface for the LayrzBle plugin.
  static void setInstance(LayrzBlePlatform instance) => _platform = instance;

  /// [_defaultPlatform] is used to get the default platform interface for the LayrzBle plugin.
  static LayrzBlePlatform _defaultPlatform() {
    // if (kIsWeb) return LayrzBleWeb.instance;
    // if (defaultTargetPlatform == TargetPlatform.linux) {
    //   return LayrzBleLinux.instance;
    // }
    return LayrzBlePigeonChannel.instance;
  }

  /// [isAdvertising] is a getter that returns `true` if the device is advertising.
  /// This property is updated based on the functions `startAdvertise` and `stopAdvertise`.
  ///
  /// Also, can be updated automatically when you call `getStatuses` method.
  bool get isAdvertising => throw UnimplementedError('isAdvertising has not been implemented.');

  /// [isScanning] is a getter that returns `true` if the device is scanning.
  /// This property is updated based on the functions `startScan` and `stopScan`.
  ///
  /// Also, can be updated automatically when you call `getStatuses` method.
  bool get isScanning => throw UnimplementedError('isScanning has not been implemented.');

  /// [onScan] is a stream of BLE devices detected during a scan.
  Stream<BleDevice> get onScan => _platform.onScan;

  /// [onEvent] is a stream of BLE events.
  Stream<BleEvent> get onEvent => _platform.onEvent;

  /// [onNotify] is a stream of BLE notifications.
  /// To add a new notification listener, use [startNotify] method.
  /// This stream will emit the raw bytes of the notification.
  Stream<BleCharacteristicNotification> get onNotify => _platform.onNotify;

  /// [onGattUpdate] is the stream of BLE GATT server updates.
  /// You can listen it, but you need to use [startAdvertise] with [canConnect] set to `true` to really
  /// start a GATT server.
  Stream<BleGattEvent> get onGattUpdate => throw UnimplementedError('onGattUpdate has not been implemented.');

  /// [getStatuses] is a getter function that returns the status of the BLE components statuses.
  Future<BleStatus> getStatuses() {
    return _platform.getStatuses();
  }

  /// [checkCapabilities] checks if the device supports BLE.
  Future<bool> checkCapabilities() {
    return _platform.checkCapabilities();
  }

  /// [checkScanPermissions] checks if the app has the permissions to scan for BLE devices.
  Future<bool> checkScanPermissions() {
    return _platform.checkScanPermissions();
  }

  /// [checkAdvertisePermissions] checks if the app has the permissions to advertise BLE devices.
  Future<bool> checkAdvertisePermissions() {
    return _platform.checkAdvertisePermissions();
  }

  /// [startScan] starts scanning for BLE devices.
  ///
  /// To get the results, you need to set a callback function using [onScanResult].
  Future<bool> startScan({
    /// [macAddress] is the MAC address or UUID of the device to scan.
    /// If this value is not provided, the scan will search for all devices.
    ///
    /// On Web platform, this property is ignored.
    String? macAddress,

    /// [servicesUuids] is a list of service UUIDs to filter the services to be discovered.
    /// This property is only working on Web, other platforms will be ignored.
    List<String>? servicesUuids,
  }) {
    return _platform.startScan(
      macAddress: macAddress,
      servicesUuids: servicesUuids,
    );
  }

  /// [stopScan] stops scanning for BLE devices.
  ///
  /// This method will stop the streaming of BLE devices.
  Future<bool> stopScan() {
    return _platform.stopScan();
  }

  /// [setMtu] sets the MTU size for the BLE connection.
  /// The MTU size is the maximum number of bytes that can be sent in a single packet, also, MTU means
  /// Maximum Transmission Unit and it is the maximum size of a packet that can be sent in a single transmission.
  ///
  /// The return value is the new MTU size, after a negotion with the peripheral.
  Future<int?> setMtu({required String macAddress, required int newMtu}) {
    return _platform.setMtu(macAddress: macAddress, newMtu: newMtu);
  }

  /// [connect] connects to a BLE device.
  Future<bool> connect({
    /// [macAddress] is the MAC address or UUID of the device to connect.
    required String macAddress,
  }) {
    return _platform.connect(macAddress: macAddress);
  }

  /// [disconnect] disconnects from any connected BLE device.
  Future<bool> disconnect({
    /// [macAddress] is the MAC address that you want to disconnect.
    ///
    /// In case of that value is `null`, the disconnect will be from all connected devices.
    String? macAddress,
  }) {
    return _platform.disconnect(macAddress: macAddress);
  }

  /// [discoverServices] discovers the services of a BLE device.
  Future<List<BleService>?> discoverServices({
    /// [macAddress] is the MAC address of the device.
    required String macAddress,
  }) {
    return _platform.discoverServices(macAddress: macAddress);
  }

  /// [writeCharacteristic] sends a payload to a BLE characteristic.
  ///
  /// The return value is `true` if the payload was sent successfully.
  Future<bool> writeCharacteristic({
    /// [macAddress] is the MAC address of the device.
    required String macAddress,

    /// [serviceUuid] is the UUID of the service.
    required String serviceUuid,

    /// [characteristicUuid] is the UUID of the characteristic.
    required String characteristicUuid,

    /// [payload] is the data to send to the characteristic.
    required Uint8List payload,

    /// [withResponse] is a flag to indicate if the write should be with response or not.
    required bool withResponse,
  }) {
    return _platform.writeCharacteristic(
      macAddress: macAddress,
      serviceUuid: serviceUuid,
      characteristicUuid: characteristicUuid,
      payload: payload,
      withResponse: withResponse,
    );
  }

  /// [readCharacteristic] reads the value of a BLE characteristic.
  /// The return value is the raw bytes of the characteristic.
  ///
  /// If the characteristic is not readable, this method will return null.
  Future<Uint8List?> readCharacteristic({
    /// [macAddress] is the MAC address of the device.
    required String macAddress,

    /// [serviceUuid] is the UUID of the service.
    required String serviceUuid,

    /// [characteristicUuid] is the UUID of the characteristic.
    required String characteristicUuid,
  }) {
    return _platform.readCharacteristic(
      macAddress: macAddress,
      serviceUuid: serviceUuid,
      characteristicUuid: characteristicUuid,
    );
  }

  /// [startNotify] starts listening to notifications from a BLE characteristic.
  /// To stop listening, use [stopNotify] method and to get the notifications, use [onNotify] stream.
  Future<bool> startNotify({
    /// [macAddress] is the MAC address of the device.
    required String macAddress,

    /// [serviceUuid] is the UUID of the service.
    required String serviceUuid,

    /// [characteristicUuid] is the UUID of the characteristic.
    required String characteristicUuid,
  }) {
    return _platform.startNotify(
      macAddress: macAddress,
      serviceUuid: serviceUuid,
      characteristicUuid: characteristicUuid,
    );
  }

  /// [stopNotify] stops listening to notifications from a BLE characteristic.
  Future<bool> stopNotify({
    /// [macAddress] is the MAC address of the device.
    required String macAddress,

    /// [serviceUuid] is the UUID of the service.
    required String serviceUuid,

    /// [characteristicUuid] is the UUID of the characteristic.
    required String characteristicUuid,
  }) {
    return _platform.stopNotify(
      macAddress: macAddress,
      serviceUuid: serviceUuid,
      characteristicUuid: characteristicUuid,
    );
  }
}
