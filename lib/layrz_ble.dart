library layrz_ble;

import 'dart:typed_data';

import 'package:layrz_ble/src/types/types.dart';
import 'package:layrz_models/layrz_models.dart';
import 'src/platform_interface.dart';

export 'src/platform_interface.dart';
export 'src/method_channel.dart';
export 'src/types/types.dart';
export 'package:layrz_models/layrz_models.dart'
    show BleDevice, BleService, BleCharacteristic, BleProperty, BleManufacturerData, BleServiceData;

export 'platforms/stub.dart' if (dart.library.io) 'platforms/linux.dart';

class LayrzBle {
  /// [onScan] is a stream of BLE devices detected during a scan.
  Stream<BleDevice> get onScan => LayrzBlePlatform.instance.onScan;

  /// [onEvent] is a stream of BLE events.
  Stream<BleEvent> get onEvent => LayrzBlePlatform.instance.onEvent;

  /// [onNotify] is a stream of BLE notifications.
  /// To add a new notification listener, use [startNotify] method.
  /// This stream will emit the raw bytes of the notification.
  Stream<BleCharacteristicNotification> get onNotify => LayrzBlePlatform.instance.onNotify;

  /// [onGattUpdate] is the stream of BLE GATT server updates.
  /// You can listen it, but you need to use [startAdvertise] with [canConnect] set to `true` to really
  /// start a GATT server.
  Stream<BleGattEvent> get onGattUpdate => LayrzBlePlatform.instance.onGattUpdate;

  /// [startScan] starts scanning for BLE devices.
  ///
  /// To get the results, you need to set a callback function using
  /// [onScanResult].
  Future<bool?> startScan({
    /// [macAddress] is the MAC address or UUID of the device to scan.
    /// If this value is not provided, the scan will search for all devices.
    ///
    /// On Web platform, this property is ignored.
    String? macAddress,

    /// [servicesUuids] is a list of service UUIDs to filter the services to
    /// be discovered.
    /// This property is only working on Web, other platforms will be ignored.
    List<String>? servicesUuids,
  }) => LayrzBlePlatform.instance.startScan(macAddress: macAddress, servicesUuids: servicesUuids);

  /// [stopScan] stops scanning for BLE devices.
  ///
  /// This method will stop the streaming of BLE devices.
  Future<bool?> stopScan() => LayrzBlePlatform.instance.stopScan();

  /// [checkCapabilities] checks if the device supports BLE.
  Future<bool> checkCapabilities() => LayrzBlePlatform.instance.checkCapabilities();

  /// [checkScanPermissions] checks if the app has the permissions to scan for BLE devices.
  Future<bool> checkScanPermissions() => LayrzBlePlatform.instance.checkScanPermissions();

  /// [checkAdvertisePermissions] checks if the app has the permissions to advertise BLE devices.
  Future<bool> checkAdvertisePermissions() => LayrzBlePlatform.instance.checkAdvertisePermissions();

  /// [setMtu] sets the MTU size for the BLE connection.
  /// The MTU size is the maximum number of bytes that can be sent in a
  /// single packet, also, MTU means
  /// Maximum Transmission Unit and it is the maximum size of a packet that
  /// can be sent in a single transmission.
  ///
  /// The return value is the new MTU size, after a negotion with
  /// the peripheral.
  Future<int?> setMtu({required int newMtu}) => LayrzBlePlatform.instance.setMtu(newMtu: newMtu);

  /// [connect] connects to a BLE device.
  Future<bool?> connect({required String macAddress}) => LayrzBlePlatform.instance.connect(macAddress: macAddress);

  /// [disconnect] disconnects from any connected BLE device.
  Future<bool?> disconnect() => LayrzBlePlatform.instance.disconnect();

  /// [discoverServices] discovers the services of a BLE device.
  Future<List<BleService>?> discoverServices({
    /// [timeout] is the duration to wait for the services to be discovered.
    Duration timeout = const Duration(seconds: 30),
  }) => LayrzBlePlatform.instance.discoverServices(timeout: timeout);

  /// [writeCharacteristic] sends a payload to a BLE characteristic.
  ///
  /// The return value is `true` if the payload was sent successfully.
  Future<bool> writeCharacteristic({
    required String serviceUuid,
    required String characteristicUuid,
    required Uint8List payload,
    Duration timeout = const Duration(seconds: 30),
    required bool withResponse,
  }) => LayrzBlePlatform.instance.writeCharacteristic(
    serviceUuid: serviceUuid,
    characteristicUuid: characteristicUuid,
    payload: payload,
    timeout: timeout,
    withResponse: withResponse,
  );

  /// [readCharacteristic] reads the value of a BLE characteristic.
  /// The return value is the raw bytes of the characteristic.
  ///
  /// If the characteristic is not readable, this method will return `null`.
  Future<Uint8List?> readCharacteristic({required String serviceUuid, required String characteristicUuid}) =>
      LayrzBlePlatform.instance.readCharacteristic(serviceUuid: serviceUuid, characteristicUuid: characteristicUuid);

  /// [startNotify] starts listening to notifications from a
  /// BLE characteristic. To stop listening, use [stopNotify] method and
  /// to get the notifications, use [onNotify] stream.
  Future<bool?> startNotify({required String serviceUuid, required String characteristicUuid}) =>
      LayrzBlePlatform.instance.startNotify(serviceUuid: serviceUuid, characteristicUuid: characteristicUuid);

  /// [stopNotify] stops listening to notifications from a BLE characteristic.
  Future<bool?> stopNotify({required String serviceUuid, required String characteristicUuid}) =>
      LayrzBlePlatform.instance.stopNotify(serviceUuid: serviceUuid, characteristicUuid: characteristicUuid);

  /// [startAdvertise] starts advertising a BLE device.
  ///
  /// The advertisement packet will contain the [manufacturerData] and [serviceData] provided, and the advertisement
  /// will include the name of the device. So, be careful with the len of the contents, you need to consider
  /// the restrictions of the Bluetooth Low Energy specification.
  Future<bool> startAdvertise({
    /// [manufacturerData] is the data to be sent in the advertisement packet.
    List<BleManufacturerData> manufacturerData = const [],

    /// [serviceData] is the data to be sent in the advertisement packet.
    List<BleServiceData> serviceData = const [],

    /// [canConnect] is a flag to indicate if the device can be connected to.
    /// This property enables the GATT Server to be started and the device to be connected to.
    bool canConnect = false,

    /// [servicesSpecs] defines the list of services to be available in the GATT Server.
    /// This property is only used if [canConnect] is set to `true`.
    List<BleService> servicesSpecs = const [],

    /// [forceBluetooth5] is a flag to indicate if the advertisement can be using the Bluetooth 5.0 specification.
    bool allowBluetooth5 = true,
  }) => LayrzBlePlatform.instance.startAdvertise(
    manufacturerData: manufacturerData,
    serviceData: serviceData,
    canConnect: canConnect,
    servicesSpecs: servicesSpecs,
    allowBluetooth5: allowBluetooth5,
  );

  /// [stopAdvertise] stops advertising a BLE device.
  Future<bool> stopAdvertise() => LayrzBlePlatform.instance.stopAdvertise();

  /// [respondReadRequest] responds to a GATT request.
  /// This method is designed to be a response from an event from [onGattUpdate] stream. Whhen the
  /// [GattReadRequest] is received, you can use this method to respond to the request.
  Future<bool> respondReadRequest({
    /// [requestId] is the ID of the request.
    required int requestId,

    /// [macAddress] is the MAC address of the device.
    required String macAddress,

    /// [offset] is the offset of the data to be read.
    required int offset,

    /// [characteristicUuid] is the UUID of the characteristic.
    required String characteristicUuid,

    /// [data] is the data to be sent in response to the request.
    Uint8List? data,
  }) => LayrzBlePlatform.instance.respondReadRequest(
    requestId: requestId,
    macAddress: macAddress,
    offset: offset,
    characteristicUuid: characteristicUuid,
    data: data,
  );

  /// [respondWriteRequest] responds to a GATT request.
  /// This method is designed to be a response from an event from [onGattUpdate] stream. Whhen the
  /// [GattWriteRequest] is received, you can use this method to respond to the request.
  Future<bool> respondWriteRequest({
    /// [requestId] is the ID of the request.
    required int requestId,

    /// [macAddress] is the MAC address of the device.
    required String macAddress,

    /// [offset] is the offset of the data to be read.
    required int offset,

    /// [characteristicUuid] is the UUID of the characteristic.
    required String characteristicUuid,

    /// [success] is a flag to indicate if the request was successful.
    required bool success,
  }) => LayrzBlePlatform.instance.respondWriteRequest(
    requestId: requestId,
    macAddress: macAddress,
    offset: offset,
    characteristicUuid: characteristicUuid,
    success: success,
  );
}
