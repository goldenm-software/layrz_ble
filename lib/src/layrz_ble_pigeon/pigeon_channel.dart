import 'dart:async';
import 'dart:typed_data';

import 'package:layrz_ble/src/layrz_ble_pigeon/layrz_ble.g.dart';
import 'package:layrz_ble/src/platform_interface.dart';
import 'package:layrz_ble/src/types/types.dart';
import 'package:layrz_models/layrz_models.dart';

class LayrzBlePigeonChannel extends LayrzBlePlatform {
  static LayrzBlePigeonChannel? _instance;
  static LayrzBlePigeonChannel get instance => _instance ??= LayrzBlePigeonChannel._();

  final StreamController<BleEvent> _eventsController = StreamController<BleEvent>.broadcast();
  final StreamController<BleDevice> _scanController = StreamController<BleDevice>.broadcast();
  final StreamController<BleCharacteristicNotification> _notifyController =
      StreamController<BleCharacteristicNotification>.broadcast();

  @override
  Stream<BleEvent> get onEvent => _eventsController.stream;

  @override
  Stream<BleDevice> get onScan => _scanController.stream;

  @override
  Stream<BleCharacteristicNotification> get onNotify => _notifyController.stream;

  LayrzBlePigeonChannel._() {
    _setupListeners();
  }

  final _channel = LayrzBlePlatformChannel();

  @override
  Future<BleStatus> getStatuses() async {
    final status = await _channel.getStatuses();
    return BleStatus(
      advertising: status.advertising,
      scanning: status.scanning,
    );
  }

  @override
  Future<bool> checkCapabilities() => _channel.checkCapabilities();

  @override
  Future<bool> checkScanPermissions() => _channel.checkScanPermissions();

  @override
  Future<bool> checkAdvertisePermissions() => _channel.checkAdvertisePermissions();

  @override
  Future<bool> startScan({String? macAddress, List<String>? servicesUuids}) =>
      _channel.startScan(macAddress: macAddress, servicesUuids: servicesUuids);

  @override
  Future<bool> stopScan() => _channel.stopScan();

  @override
  Future<bool> connect({required String macAddress}) => _channel.connect(macAddress: macAddress);

  @override
  Future<bool> disconnect({String? macAddress}) => _channel.disconnect(macAddress: macAddress);

  @override
  Future<int?> setMtu({required String macAddress, required int newMtu}) =>
      _channel.setMtu(macAddress: macAddress, newMtu: newMtu);

  @override
  Future<List<BleService>> discoverServices({required String macAddress}) async {
    final services = await _channel.discoverServices(macAddress: macAddress);

    return services
        .map((service) {
          try {
            return BleService(
              uuid: service.uuid,
              characteristics: service.characteristics
                  .map((characteristic) {
                    try {
                      return BleCharacteristic(
                        uuid: characteristic.uuid,
                        properties: characteristic.properties
                            .map((property) {
                              return BleProperty.fromJson(property);
                            })
                            .nonNulls
                            .toList(),
                      );
                    } catch (_) {
                      return null;
                    }
                  })
                  .nonNulls
                  .toList(),
            );
          } catch (_) {
            return null;
          }
        })
        .nonNulls
        .toList();
  }

  @override
  Future<bool> writeCharacteristic({
    required String macAddress,
    required String serviceUuid,
    required String characteristicUuid,
    required Uint8List payload,
    required bool withResponse,
  }) =>
      _channel.writeCharacteristic(
        macAddress: macAddress,
        serviceUuid: serviceUuid,
        characteristicUuid: characteristicUuid,
        payload: payload,
        withResponse: withResponse,
      );

  @override
  Future<Uint8List> readCharacteristic({
    required String macAddress,
    required String serviceUuid,
    required String characteristicUuid,
  }) =>
      _channel.readCharacteristic(
        macAddress: macAddress,
        serviceUuid: serviceUuid,
        characteristicUuid: characteristicUuid,
      );

  @override
  Future<bool> startNotify({
    required String macAddress,
    required String serviceUuid,
    required String characteristicUuid,
  }) =>
      _channel.startNotify(
        macAddress: macAddress,
        serviceUuid: serviceUuid,
        characteristicUuid: characteristicUuid,
      );

  @override
  Future<bool> stopNotify({
    required String macAddress,
    required String serviceUuid,
    required String characteristicUuid,
  }) =>
      _channel.stopNotify(
        macAddress: macAddress,
        serviceUuid: serviceUuid,
        characteristicUuid: characteristicUuid,
      );

  void _setupListeners() {
    LayrzBleCallbackChannel.setUp(_LayrzBleCallbackHandler(
      eventController: _eventsController,
      scanController: _scanController,
      notifyController: _notifyController,
    ));
  }
}

class _LayrzBleCallbackHandler extends LayrzBleCallbackChannel {
  final StreamController<BleEvent> eventController;
  final StreamController<BleDevice> scanController;
  final StreamController<BleCharacteristicNotification> notifyController;

  _LayrzBleCallbackHandler({
    required this.eventController,
    required this.scanController,
    required this.notifyController,
  });

  @override
  void onBluetoothOff() {
    eventController.add(BleAdapterOff());
  }

  @override
  void onBluetoothOn() {
    eventController.add(BleAdapterOn());
  }

  @override
  void onCharacteristicUpdate(BtCharacteristicNotification notification) {
    notifyController.add(BleCharacteristicNotification(
      macAddress: notification.macAddress,
      serviceUuid: notification.serviceUuid,
      characteristicUuid: notification.characteristicUuid,
      value: notification.value,
    ));
  }

  @override
  void onConnected(BtDevice device) {
    eventController.add(BleConnected(macAddress: device.macAddress, name: device.name));
  }

  @override
  void onDisconnected(BtDevice device) {
    eventController.add(BleDisconnected(macAddress: device.macAddress));
  }

  @override
  void onScanResult(BtDevice device) {
    scanController.add(BleDevice(
      macAddress: device.macAddress,
      name: device.name,
      rssi: device.rssi,
      txPower: device.txPower,
      manufacturerData: device.manufacturerData.map((manufacturerData) {
        return BleManufacturerData(
          companyId: manufacturerData.companyId,
          data: manufacturerData.data,
        );
      }).toList(),
      serviceData: device.serviceData.map((serviceData) {
        return BleServiceData(
          uuid: serviceData.uuid,
          data: serviceData.data,
        );
      }).toList(),
    ));
  }

  @override
  void onScanStarted() {
    eventController.add(BleScanStarted());
  }

  @override
  void onScanStopped() {
    eventController.add(BleScanStopped());
  }
}
