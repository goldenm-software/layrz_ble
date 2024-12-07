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
  final StreamController<List<int>> _notifyController = StreamController<List<int>>.broadcast();

  @override
  Stream<BleDevice> get onScan => _scanController.stream;

  @override
  Stream<BleEvent> get onEvent => _eventController.stream;

  @override
  Stream<List<int>> get onNotify => _notifyController.stream;
}
