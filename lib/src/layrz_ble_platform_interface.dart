import 'dart:async';

import 'package:layrz_ble/src/types.dart';
import 'package:layrz_models/layrz_models.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'layrz_ble_method_channel.dart';

abstract class LayrzBlePlatform extends PlatformInterface {
  LayrzBlePlatform() : super(token: _token);

  static final Object _token = Object();

  static LayrzBlePlatform _instance = MethodChannelLayrzBle();

  static LayrzBlePlatform get instance => _instance;

  Stream<BleDevice> get onScan => throw UnimplementedError('_scanSubscription has not been implemented.');

  Stream<BleEvent> get onEvent => throw UnimplementedError('_eventSubscription has not been implemented.');

  static set instance(LayrzBlePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<bool?> startScan() {
    throw UnimplementedError('startScan() has not been implemented.');
  }

  Future<bool?> stopScan() {
    throw UnimplementedError('stopScan() has not been implemented.');
  }

  Future<BleCapabilities> checkCapabilities() {
    throw UnimplementedError('checkCapabilities() has not been implemented.');
  }
}
