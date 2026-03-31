import 'dart:async';

import 'package:flutter/foundation.dart';
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
  final StreamController<BleGattEvent> _gattController = StreamController<BleGattEvent>.broadcast();

  bool _advertising = false;
  @override
  bool get isAdvertising => _advertising;
  bool _scanning = false;
  @override
  bool get isScanning => _scanning;

  final StreamController<bool> _bluetoothStateController = StreamController<bool>.broadcast();
  @override
  Stream<bool> get onBluetoothStateChanged => _bluetoothStateController.stream;

  @override
  Stream<BleEvent> get onEvent => _eventsController.stream;

  @override
  Stream<BleDevice> get onScan => _scanController.stream;

  @override
  Stream<BleCharacteristicNotification> get onNotify => _notifyController.stream;

  @override
  Stream<BleGattEvent> get onGattUpdate => _gattController.stream;

  LayrzBlePigeonChannel._() {
    _setupListeners();
  }

  final _channel = LayrzBlePlatformChannel();

  @override
  Future<BleStatus> getStatuses() async {
    final status = await _channel.getStatuses();
    // Emit state to stream so UI can react
    _bluetoothStateController.add(status.isEnabled);
    return BleStatus(
      advertising: status.advertising,
      scanning: status.scanning,
      isEnabled: status.isEnabled,
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

  @override
  Future<bool> startAdvertise({
    List<BleManufacturerData> manufacturerData = const [],
    List<BleServiceData> serviceData = const [],
    bool canConnect = false,
    List<BleService> servicesSpecs = const [],
    bool allowBluetooth5 = true,
    String? name,
  }) =>
      _channel.startAdvertise(
        manufacturerData: manufacturerData.map((mf) {
          return BtManufacturerData(
            companyId: mf.companyId,
            data: Uint8List.fromList(mf.data ?? []),
          );
        }).toList(),
        serviceData: serviceData.map((sd) {
          return BtServiceData(
            uuid: sd.uuid,
            data: Uint8List.fromList(sd.data ?? []),
          );
        }).toList(),
        canConnect: canConnect,
        servicesSpecs: servicesSpecs.map((service) {
          return BtService(
            uuid: service.uuid,
            characteristics: (service.characteristics ?? []).map((characteristic) {
              return BtCharacteristic(
                uuid: characteristic.uuid,
                properties: characteristic.properties.map((property) {
                  return property.toJson();
                }).toList(),
              );
            }).toList(),
          );
        }).toList(),
        allowBluetooth5: allowBluetooth5,
        name: name,
      );

  @override
  Future<bool> stopAdvertise() => _channel.stopAdvertise();

  @override
  Future<bool> respondReadRequest({
    required int requestId,
    required String macAddress,
    required int offset,
    Uint8List? data,
  }) =>
      _channel.respondReadRequest(
        requestId: requestId,
        macAddress: macAddress,
        offset: offset,
        data: data,
      );

  @override
  Future<bool> respondWriteRequest({
    required int requestId,
    required String macAddress,
    required int offset,
    required bool success,
  }) =>
      _channel.respondWriteRequest(
        requestId: requestId,
        macAddress: macAddress,
        offset: offset,
        success: success,
      );

  @override
  Future<bool> sendNotification({
    required String serviceUuid,
    required String characteristicUuid,
    required Uint8List payload,
    bool requestConfirmation = false,
  }) =>
      _channel.sendNotification(
        serviceUuid: serviceUuid,
        characteristicUuid: characteristicUuid,
        payload: payload,
        requestConfirmation: requestConfirmation,
      );

  @override
  Future<bool> openBluetoothSettings() => _channel.openBluetoothSettings();

  void _setupListeners() {
    LayrzBleCallbackChannel.setUp(_LayrzBleCallbackHandler(
      eventController: _eventsController,
      scanController: _scanController,
      notifyController: _notifyController,
      gattController: _gattController,
      bluetoothStateController: _bluetoothStateController,
      onScanChanged: (isScanning) => _scanning = isScanning,
      onAdvertiseChanged: (isAdvertising) => _advertising = isAdvertising,
    ));
  }
}

class _LayrzBleCallbackHandler extends LayrzBleCallbackChannel {
  final StreamController<BleEvent> eventController;
  final StreamController<BleDevice> scanController;
  final StreamController<BleCharacteristicNotification> notifyController;
  final StreamController<BleGattEvent> gattController;
  final StreamController<bool> bluetoothStateController;
  final ValueChanged<bool> onScanChanged;
  final ValueChanged<bool> onAdvertiseChanged;

  _LayrzBleCallbackHandler({
    required this.eventController,
    required this.scanController,
    required this.notifyController,
    required this.gattController,
    required this.bluetoothStateController,
    required this.onScanChanged,
    required this.onAdvertiseChanged,
  });

  @override
  void onBluetoothOff() {
    bluetoothStateController.add(false);
    onScanChanged.call(false);
    onAdvertiseChanged.call(false);
    eventController.add(BleAdapterOff());
  }

  @override
  void onBluetoothOn() {
    bluetoothStateController.add(true);
    onScanChanged.call(false);
    onAdvertiseChanged.call(false);
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
      macAddress: device.macAddress.toUpperCase(),
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
    onScanChanged.call(true);
    eventController.add(BleScanStarted());
  }

  @override
  void onScanStopped() {
    onScanChanged.call(false);
    eventController.add(BleScanStopped());
  }

  @override
  void onGattConnected(BtDevice device) {
    gattController.add(GattConnected(macAddress: device.macAddress, name: device.name));
  }

  @override
  void onGattDisconnected(BtDevice device) {
    gattController.add(GattDisconnected(macAddress: device.macAddress));
  }

  @override
  void onGattMtuChanged(String macAddress, int newMtu) {
    gattController.add(GattMtuChanged(macAddress: macAddress, mtu: newMtu));
  }

  @override
  void onGattReadRequest(BtGattReadRequest request) {
    gattController.add(GattReadRequest(
      macAddress: request.macAddress,
      requestId: request.requestId,
      offset: request.offset,
      serviceUuid: request.serviceUuid,
      characteristicUuid: request.characteristicUuid,
    ));
  }

  @override
  void onGattWriteRequest(BtGattWriteRequest request) {
    gattController.add(GattWriteRequest(
      macAddress: request.macAddress,
      requestId: request.requestId,
      offset: request.offset,
      serviceUuid: request.serviceUuid,
      characteristicUuid: request.characteristicUuid,
    ));
  }

  @override
  void onAdvertiseStarted() {
    onAdvertiseChanged.call(true);
    gattController.add(GattStarted());
  }

  @override
  void onAdvertiseStopped() {
    onAdvertiseChanged.call(false);
    gattController.add(GattStopped());
  }
}
