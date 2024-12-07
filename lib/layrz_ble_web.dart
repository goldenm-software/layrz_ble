import 'dart:async';

import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:layrz_ble/src/types.dart';
import 'package:layrz_models/layrz_models.dart';

import 'src/layrz_ble_platform_interface.dart';

/// A web implementation of the LayrzBlePlatform of the LayrzBle plugin.
class LayrzBleWeb extends LayrzBlePlatform {
  /// Constructs a LayrzBleWeb
  LayrzBleWeb();

  static void registerWith(Registrar registrar) {
    LayrzBlePlatform.instance = LayrzBleWeb();
  }

  final StreamController<BleDevice> _scanController = StreamController<BleDevice>.broadcast();
  final StreamController<BleEvent> _eventController = StreamController<BleEvent>.broadcast();

  /// [onScan] is a stream of BLE devices detected during a scan.
  @override
  Stream<BleDevice> get onScan => _scanController.stream;

  /// [onEvent] is a stream of BLE events.
  @override
  Stream<BleEvent> get onEvent => _eventController.stream;

  /// [startScan] starts scanning for BLE devices.
  ///
  /// To get the results, you need to set a callback function using [onScanResult].
  @override
  Future<bool?> startScan() => throw UnimplementedError('startScan() has not been implemented.');

  /// [stopScan] stops scanning for BLE devices.
  ///
  /// This method will stop the streaming of BLE devices.
  @override
  Future<bool?> stopScan() => throw UnimplementedError('stopScan() has not been implemented.');

  /// [checkCapabilities] checks if the browser supports BLE.
  @override
  Future<BleCapabilities> checkCapabilities() =>
      throw UnimplementedError('checkCapabilities() has not been implemented.');
}
