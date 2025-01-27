import 'dart:async';
import 'dart:typed_data';

import 'package:layrz_ble/src/types.dart';
import 'package:layrz_models/layrz_models.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'method_channel.dart';

abstract class LayrzBlePlatform extends PlatformInterface {
  LayrzBlePlatform() : super(token: _token);

  static final Object _token = Object();
  static LayrzBlePlatform _instance = LayrzBleNative();
  static LayrzBlePlatform get instance => _instance;

  static set instance(LayrzBlePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// [onScan] is a stream of BLE devices detected during a scan.
  Stream<BleDevice> get onScan => throw UnimplementedError('_scanSubscription has not been implemented.');

  /// [onEvent] is a stream of BLE events.
  Stream<BleEvent> get onEvent => throw UnimplementedError('_eventSubscription has not been implemented.');

  /// [onNotify] is a stream of BLE notifications.
  /// To add a new notification listener, use [startNotify] method.
  /// This stream will emit the raw bytes of the notification.
  Stream<BleCharacteristicNotification> get onNotify =>
      throw UnimplementedError('_notifySubscription has not been implemented.');

  /// [startScan] starts scanning for BLE devices.
  ///
  /// To get the results, you need to set a callback function using [onScanResult].
  Future<bool?> startScan({
    /// [macAddress] is the MAC address or UUID of the device to scan.
    /// If this value is not provided, the scan will search for all devices.
    ///
    /// On Web platform, this property is ignored.
    String? macAddress,

    /// [servicesUuids] is a list of service UUIDs to filter the services to be discovered.
    /// This property is only working on Web, other platforms will be ignored.
    List<String>? servicesUuids,
  }) =>
      throw UnimplementedError('startScan() has not been implemented.');

  /// [stopScan] stops scanning for BLE devices.
  ///
  /// This method will stop the streaming of BLE devices.
  Future<bool?> stopScan() => throw UnimplementedError('stopScan() has not been implemented.');

  /// [checkCapabilities] checks if the device supports BLE.
  Future<BleCapabilities> checkCapabilities() =>
      throw UnimplementedError('checkCapabilities() has not been implemented.');

  /// [setMtu] sets the MTU size for the BLE connection.
  /// The MTU size is the maximum number of bytes that can be sent in a single packet, also, MTU means
  /// Maximum Transmission Unit and it is the maximum size of a packet that can be sent in a single transmission.
  ///
  /// The return value is the new MTU size, after a negotion with the peripheral.
  Future<int?> setMtu({required int newMtu}) => throw UnimplementedError('setMtu() has not been implemented.');

  /// [connect] connects to a BLE device.
  Future<bool?> connect({
    /// [macAddress] is the MAC address or UUID of the device to connect.
    required String macAddress,
  }) =>
      throw UnimplementedError('connect() has not been implemented.');

  /// [disconnect] disconnects from any connected BLE device.
  Future<bool?> disconnect() => throw UnimplementedError('disconnect() has not been implemented.');

  /// [discoverServices] discovers the services of a BLE device.
  Future<List<BleService>?> discoverServices({
    /// [timeout] is the duration to wait for the services to be discovered.
    Duration timeout = const Duration(seconds: 30),
  }) =>
      throw UnimplementedError('discoverServices() has not been implemented.');

  /// [writeCharacteristic] sends a payload to a BLE characteristic.
  ///
  /// The return value is `true` if the payload was sent successfully.
  Future<bool> writeCharacteristic({
    /// [serviceUuid] is the UUID of the service.
    required String serviceUuid,

    /// [characteristicUuid] is the UUID of the characteristic.
    required String characteristicUuid,

    /// [payload] is the data to send to the characteristic.
    required Uint8List payload,

    /// [timeout] is the duration to wait for the characteristic to be written.
    Duration timeout = const Duration(seconds: 30),

    /// [withResponse] is a flag to indicate if the write should be with response or not.
    required bool withResponse,
  }) =>
      throw UnimplementedError('writeCharacteristic() has not been implemented.');

  /// [readCharacteristic] reads the value of a BLE characteristic.
  /// The return value is the raw bytes of the characteristic.
  ///
  /// If the characteristic is not readable, this method will return null.
  Future<Uint8List?> readCharacteristic({
    /// [serviceUuid] is the UUID of the service.
    required String serviceUuid,

    /// [characteristicUuid] is the UUID of the characteristic.
    required String characteristicUuid,

    /// [timeout] is the duration to wait for the characteristic to be read.
    Duration timeout = const Duration(seconds: 30),
  }) =>
      throw UnimplementedError('readCharacteristic() has not been implemented.');

  /// [startNotify] starts listening to notifications from a BLE characteristic.
  /// To stop listening, use [stopNotify] method and to get the notifications, use [onNotify] stream.
  Future<bool?> startNotify({
    /// [serviceUuid] is the UUID of the service.
    required String serviceUuid,

    /// [characteristicUuid] is the UUID of the characteristic.
    required String characteristicUuid,
  }) =>
      throw UnimplementedError('startNotify() has not been implemented.');

  /// [stopNotify] stops listening to notifications from a BLE characteristic.
  Future<bool?> stopNotify({
    /// [serviceUuid] is the UUID of the service.
    required String serviceUuid,

    /// [characteristicUuid] is the UUID of the characteristic.
    required String characteristicUuid,
  }) =>
      throw UnimplementedError('stopNotify() has not been implemented.');

  /// [guessParser] guesses the parser for a BLE device based on a list of parsers provided.
  BleParser? guessParser(List<BleParser> parsers, BleDevice device) {
    for (final parser in parsers) {
      final can = _evalConditions(conditions: parser.config.conditions, device: device);
      if (can) return parser;
    }

    return null;
  }

  /// [parseData] parses the data from a BLE device using a parser.
  Map<String, dynamic> parseData(BleParser parser, BleDevice device) {
    final Map<String, dynamic> output = {
      'parser.identifier': parser.identifier,
      'device.name': device.name ?? 'Unknown',
    };

    bool can = _evalConditions(conditions: parser.config.conditions, device: device);

    if (!can) return output;

    for (final property in parser.config.properties) {
      final result = _parseProperty(property, device);
      if (result != null) output[property.parameter] = result;
    }

    return output;
  }

  /// [_evalConditions] evaluates a list of conditions to check if a device matches the conditions.
  static bool _evalConditions({
    required List<BleCondition> conditions,
    required BleDevice device,
    List<int>? serviceData,
  }) {
    if (conditions.isEmpty) return false;

    bool can = false;
    for (final condition in conditions) {
      can = _evalCondition(condition: condition, device: device, serviceData: serviceData);
      if (!can) break;
    }

    return can;
  }

  /// [_evalCondition] evaluates a single condition to check if a device matches the condition.
  static bool _evalCondition({
    required BleCondition condition,
    required BleDevice device,
    List<int>? serviceData,
  }) {
    if (condition.operation == BleOperation.trueValue) return true;
    if (condition.operation == BleOperation.falseValue) return false;

    dynamic value;
    switch (condition.watch) {
      case BleWatch.name:
        value = device.name;
        break;
      case BleWatch.servicesList:
        value = (device.serviceData ?? []).map((e) {
          return int.tryParse(e.uuid, radix: 16) ?? 0;
        }).toList();
        break;
      case BleWatch.serviceData:
        value = serviceData;
        break;
      case BleWatch.companyIdentifier:
        final companyId = (device.manufacturerData?.sublist(0, 2) ?? [0, 0]);
        final inversed = [companyId[1], companyId[0]].map((e) => e.toRadixString(16).padLeft(2, '0')).join('');
        value = int.tryParse(inversed, radix: 16);
        break;
      case BleWatch.manufacturerData:
        value = device.manufacturerData ?? [];
        break;
      case BleWatch.none:
      default:
        value = null;
        break;
    }

    bool can = false;
    switch (condition.operation) {
      case BleOperation.contains:
        if (value is String && condition.expected is String) {
          can = value.contains(condition.expected);
        } else if (value is List && condition.expected is List) {
          can = value.any((element) => condition.expected.contains(element));
        }
        break;
      case BleOperation.equals:
        if (value is List) {
          can = value.length > condition.expected;
        } else if (value.runtimeType == condition.expected.runtimeType) {
          can = value == condition.expected;
        }
        break;
      case BleOperation.notEquals:
        if (value is List) {
          can = value.length > condition.expected;
        } else if (value.runtimeType == condition.expected.runtimeType) {
          can = value != condition.expected;
        }
        break;
      case BleOperation.greaterThan:
        if (value is List) {
          can = value.length > condition.expected;
        } else if (value is num && condition.expected is num) {
          can = value > condition.expected;
        }
        break;
      case BleOperation.lessThan:
        if (value is List) {
          can = value.length > condition.expected;
        } else if (value is num && condition.expected is num) {
          can = value < condition.expected;
        }
        break;
      case BleOperation.greaterThanOrEqual:
        if (value is List) {
          can = value.length > condition.expected;
        } else if (value is num && condition.expected is num) {
          can = value >= condition.expected;
        }
        break;
      case BleOperation.lessThanOrEqual:
        if (value is List) {
          can = value.length > condition.expected;
        } else if (value is num && condition.expected is num) {
          can = value <= condition.expected;
        }
        break;
      case BleOperation.length:
        if (value is List || value is String || value is Map) {
          can = value.length == condition.expected;
        }
      default:
        can = false;
        break;
    }

    return can;
  }

  /// [_parseProperty] parses a property from a BLE device.
  static dynamic _parseProperty(BleParserProperty property, BleDevice device) {
    List<int> serviceData = property.service != null
        ? _extractServiceDataFromAdv(
            expected: property.service!,
            device: device,
          )
        : [];
    final can = _evalConditions(conditions: property.conditions, device: device, serviceData: serviceData);
    if (!can) return null;

    dynamic value;
    if (property.source == BleParserSource.serviceData) value = serviceData;
    if (property.source == BleParserSource.manufacturerData) value = device.manufacturerData ?? [];

    for (final entry in property.run.asMap().entries) {
      final run = entry.value;

      switch (run.operation) {
        case BleOperation.equals:
          if (value.runtimeType == run.operand.runtimeType) {
            value = value == run.operand;
          }
          break;
        case BleOperation.notEquals:
          if (value.runtimeType == run.operand.runtimeType) {
            value = value != run.operand;
          }
          break;
        case BleOperation.greaterThan:
          if (value is num && run.operand is num) {
            value = value > run.operand;
          }
          break;
        case BleOperation.greaterThanOrEqual:
          if (value is num && run.operand is num) {
            value = value >= run.operand;
          }
          break;
        case BleOperation.lessThan:
          if (value is num && run.operand is num) {
            value = value < run.operand;
          }
          break;
        case BleOperation.lessThanOrEqual:
          if (value is num && run.operand is num) {
            value = value <= run.operand;
          }
          break;
        case BleOperation.add:
          if (value is num && run.operand is num) {
            value = value + run.operand;
          } else if (value is String) {
            value = value + run.operand.toString();
          }
          break;
        case BleOperation.subtract:
          if (value is num && run.operand is num) {
            value = value - run.operand;
          }
          break;
        case BleOperation.multiply:
          if (value is num && run.operand is num) {
            value = value * run.operand;
          }
          break;
        case BleOperation.divide:
          if (value is num && run.operand is num) {
            value = value / run.operand;
          }
          break;
        case BleOperation.littleToBigEndian:
          if (value is List<int>) {
            value = value.reversed.toList();
          }
          break;
        case BleOperation.bigToLittleEndian:
          if (value is List<int>) {
            value = value.reversed.toList();
          }
          break;
        case BleOperation.toBitArray:
          if (value is int) {
            value = value.toRadixString(2).padLeft(run.zFill, '0').toLowerCase();
          }
          break;
        case BleOperation.contains:
          if (value is String && run.operand is String) {
            value = value.contains(run.operand);
          }
          break;
        case BleOperation.trueValue:
          value = true;
          break;
        case BleOperation.falseValue:
          value = false;
          break;
        case BleOperation.length:
          if (value is List || value is String || value is Map) {
            value = value.length;
          }
          break;
        case BleOperation.bytesToInt:
          if (value is List<int>) {
            value = int.tryParse(value.map((e) => e.toRadixString(16).padLeft(2, '0')).join(''), radix: 16);
          }
          break;
        case BleOperation.sublist:
          if (value is List) {
            value = value.sublist(run.operand[0], run.operand[1]);
          }
          break;
        case BleOperation.bytesToString:
          if (value is List<int>) {
            value = value.map((e) => e.toRadixString(16).padLeft(run.zFill, '0')).join('').toUpperCase();
          }
          break;
        case BleOperation.bytesToBits:
          if (value is List) {
            value = value.map((e) => e.toRadixString(2)).join('').padLeft(run.zFill, '0').toUpperCase();
            value = value.split('').map((e) => int.parse(e)).toList();
          }
          break;
        case BleOperation.pick:
          if (value is List) {
            try {
              value = value[run.operand];
            } catch (e) {
              value = null;
            }
          } else {
            value = null;
          }
          break;
        case BleOperation.bitsToInt:
          if (value is List) {
            value = int.tryParse(value.map((e) => e.toString()).join(''), radix: 2);
          }
          break;
        case BleOperation.unknown:
        default:
          value = null;
          break;
      }

      // debugPrint('Property ${property.parameter} run ${entry.key} ${run.operation}: $value');
    }
    return value;
  }

  /// [_extractServiceDataFromAdv] extracts the service data from the advertisement.
  static List<int> _extractServiceDataFromAdv({
    required int expected,
    required BleDevice device,
  }) {
    String source = _standarizeServiceUuid(expected);
    return device.serviceDataMap[source] ?? [];
  }

  /// [_standarizeServiceUuid] converts a service data to a standard UUID format.
  static String _standarizeServiceUuid(int serviceData) {
    return serviceData.toRadixString(16).padLeft(4, '0').toLowerCase();
  }
}
