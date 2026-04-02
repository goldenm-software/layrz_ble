// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'types.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BleConnected _$BleConnectedFromJson(Map<String, dynamic> json) =>
    _BleConnected(
      macAddress: json['macAddress'] as String,
      name: json['name'] as String?,
    );

Map<String, dynamic> _$BleConnectedToJson(_BleConnected instance) =>
    <String, dynamic>{
      'macAddress': instance.macAddress,
      'name': instance.name,
    };

_BleDisconnected _$BleDisconnectedFromJson(Map<String, dynamic> json) =>
    _BleDisconnected(
      macAddress: json['macAddress'] as String,
    );

Map<String, dynamic> _$BleDisconnectedToJson(_BleDisconnected instance) =>
    <String, dynamic>{
      'macAddress': instance.macAddress,
    };

_BleCharacteristicNotification _$BleCharacteristicNotificationFromJson(
        Map<String, dynamic> json) =>
    _BleCharacteristicNotification(
      macAddress: json['macAddress'] as String,
      serviceUuid: json['serviceUuid'] as String,
      characteristicUuid: json['characteristicUuid'] as String,
      value: const UintListConverter().fromJson(json['value'] as List),
    );

Map<String, dynamic> _$BleCharacteristicNotificationToJson(
        _BleCharacteristicNotification instance) =>
    <String, dynamic>{
      'macAddress': instance.macAddress,
      'serviceUuid': instance.serviceUuid,
      'characteristicUuid': instance.characteristicUuid,
      'value': const UintListConverter().toJson(instance.value),
    };

_GattConnected _$GattConnectedFromJson(Map<String, dynamic> json) =>
    _GattConnected(
      macAddress: json['macAddress'] as String,
      name: json['name'] as String?,
    );

Map<String, dynamic> _$GattConnectedToJson(_GattConnected instance) =>
    <String, dynamic>{
      'macAddress': instance.macAddress,
      'name': instance.name,
    };

_GattDisconnected _$GattDisconnectedFromJson(Map<String, dynamic> json) =>
    _GattDisconnected(
      macAddress: json['macAddress'] as String,
    );

Map<String, dynamic> _$GattDisconnectedToJson(_GattDisconnected instance) =>
    <String, dynamic>{
      'macAddress': instance.macAddress,
    };

_GattReadRequest _$GattReadRequestFromJson(Map<String, dynamic> json) =>
    _GattReadRequest(
      macAddress: json['macAddress'] as String,
      requestId: (json['requestId'] as num).toInt(),
      offset: (json['offset'] as num).toInt(),
      serviceUuid: json['serviceUuid'] as String,
      characteristicUuid: json['characteristicUuid'] as String,
    );

Map<String, dynamic> _$GattReadRequestToJson(_GattReadRequest instance) =>
    <String, dynamic>{
      'macAddress': instance.macAddress,
      'requestId': instance.requestId,
      'offset': instance.offset,
      'serviceUuid': instance.serviceUuid,
      'characteristicUuid': instance.characteristicUuid,
    };

_GattWriteRequest _$GattWriteRequestFromJson(Map<String, dynamic> json) =>
    _GattWriteRequest(
      macAddress: json['macAddress'] as String,
      requestId: (json['requestId'] as num).toInt(),
      offset: (json['offset'] as num).toInt(),
      serviceUuid: json['serviceUuid'] as String,
      characteristicUuid: json['characteristicUuid'] as String,
      data: const UintListOrNullConverter().fromJson(json['data'] as List?),
      preparedWrite: json['preparedWrite'] as bool? ?? false,
      responseNeeded: json['responseNeeded'] as bool? ?? false,
    );

Map<String, dynamic> _$GattWriteRequestToJson(_GattWriteRequest instance) =>
    <String, dynamic>{
      'macAddress': instance.macAddress,
      'requestId': instance.requestId,
      'offset': instance.offset,
      'serviceUuid': instance.serviceUuid,
      'characteristicUuid': instance.characteristicUuid,
      'data': const UintListOrNullConverter().toJson(instance.data),
      'preparedWrite': instance.preparedWrite,
      'responseNeeded': instance.responseNeeded,
    };

_GattMtuChanged _$GattMtuChangedFromJson(Map<String, dynamic> json) =>
    _GattMtuChanged(
      macAddress: json['macAddress'] as String,
      mtu: (json['mtu'] as num).toInt(),
    );

Map<String, dynamic> _$GattMtuChangedToJson(_GattMtuChanged instance) =>
    <String, dynamic>{
      'macAddress': instance.macAddress,
      'mtu': instance.mtu,
    };

_BleStatus _$BleStatusFromJson(Map<String, dynamic> json) => _BleStatus(
      advertising: json['advertising'] as bool,
      scanning: json['scanning'] as bool,
      isEnabled: json['isEnabled'] as bool? ?? false,
    );

Map<String, dynamic> _$BleStatusToJson(_BleStatus instance) =>
    <String, dynamic>{
      'advertising': instance.advertising,
      'scanning': instance.scanning,
      'isEnabled': instance.isEnabled,
    };
