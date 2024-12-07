library layrz_ble;

import 'package:layrz_ble/src/types.dart';
import 'package:layrz_models/layrz_models.dart';
import 'src/layrz_ble_platform_interface.dart';

export 'src/layrz_ble_platform_interface.dart';
export 'src/layrz_ble_method_channel.dart';
export 'src/types.dart';
export 'package:layrz_models/layrz_models.dart' show BleDevice;

class LayrzBle {
  /// [onScan] is a stream of BLE devices detected during a scan.
  Stream<BleDevice> get onScan => LayrzBlePlatform.instance.onScan;

  /// [onEvent] is a stream of BLE events.
  Stream<BleEvent> get onEvent => LayrzBlePlatform.instance.onEvent;

  /// [startScan] starts scanning for BLE devices.
  ///
  /// To get the results, you need to set a callback function using [onScanResult].
  Future<bool?> startScan() => LayrzBlePlatform.instance.startScan();

  /// [stopScan] stops scanning for BLE devices.
  ///
  /// This method will stop the streaming of BLE devices.
  Future<bool?> stopScan() => LayrzBlePlatform.instance.stopScan();

  /// [checkCapabilities] checks if the device supports BLE.
  Future<BleCapabilities> checkCapabilities() => LayrzBlePlatform.instance.checkCapabilities();
}
