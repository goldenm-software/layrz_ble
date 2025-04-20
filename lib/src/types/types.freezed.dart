// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'types.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BleConnected {
  /// [macAddress] is the MAC address of the device.
  String get macAddress;

  /// [name] is the name of the device.
  ///
  /// Can be `null` if the device does not advertise its name.
  String? get name;

  /// Create a copy of BleConnected
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $BleConnectedCopyWith<BleConnected> get copyWith =>
      _$BleConnectedCopyWithImpl<BleConnected>(
          this as BleConnected, _$identity);

  /// Serializes this BleConnected to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is BleConnected &&
            (identical(other.macAddress, macAddress) ||
                other.macAddress == macAddress) &&
            (identical(other.name, name) || other.name == name));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, macAddress, name);

  @override
  String toString() {
    return 'BleConnected(macAddress: $macAddress, name: $name)';
  }
}

/// @nodoc
abstract mixin class $BleConnectedCopyWith<$Res> {
  factory $BleConnectedCopyWith(
          BleConnected value, $Res Function(BleConnected) _then) =
      _$BleConnectedCopyWithImpl;
  @useResult
  $Res call({String macAddress, String? name});
}

/// @nodoc
class _$BleConnectedCopyWithImpl<$Res> implements $BleConnectedCopyWith<$Res> {
  _$BleConnectedCopyWithImpl(this._self, this._then);

  final BleConnected _self;
  final $Res Function(BleConnected) _then;

  /// Create a copy of BleConnected
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? macAddress = null,
    Object? name = freezed,
  }) {
    return _then(_self.copyWith(
      macAddress: null == macAddress
          ? _self.macAddress
          : macAddress // ignore: cast_nullable_to_non_nullable
              as String,
      name: freezed == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _BleConnected extends BleConnected {
  const _BleConnected({required this.macAddress, this.name}) : super._();
  factory _BleConnected.fromJson(Map<String, dynamic> json) =>
      _$BleConnectedFromJson(json);

  /// [macAddress] is the MAC address of the device.
  @override
  final String macAddress;

  /// [name] is the name of the device.
  ///
  /// Can be `null` if the device does not advertise its name.
  @override
  final String? name;

  /// Create a copy of BleConnected
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$BleConnectedCopyWith<_BleConnected> get copyWith =>
      __$BleConnectedCopyWithImpl<_BleConnected>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$BleConnectedToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _BleConnected &&
            (identical(other.macAddress, macAddress) ||
                other.macAddress == macAddress) &&
            (identical(other.name, name) || other.name == name));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, macAddress, name);

  @override
  String toString() {
    return 'BleConnected(macAddress: $macAddress, name: $name)';
  }
}

/// @nodoc
abstract mixin class _$BleConnectedCopyWith<$Res>
    implements $BleConnectedCopyWith<$Res> {
  factory _$BleConnectedCopyWith(
          _BleConnected value, $Res Function(_BleConnected) _then) =
      __$BleConnectedCopyWithImpl;
  @override
  @useResult
  $Res call({String macAddress, String? name});
}

/// @nodoc
class __$BleConnectedCopyWithImpl<$Res>
    implements _$BleConnectedCopyWith<$Res> {
  __$BleConnectedCopyWithImpl(this._self, this._then);

  final _BleConnected _self;
  final $Res Function(_BleConnected) _then;

  /// Create a copy of BleConnected
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? macAddress = null,
    Object? name = freezed,
  }) {
    return _then(_BleConnected(
      macAddress: null == macAddress
          ? _self.macAddress
          : macAddress // ignore: cast_nullable_to_non_nullable
              as String,
      name: freezed == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
mixin _$BleDisconnected {
  /// [macAddress] is the MAC address of the device.
  String get macAddress;

  /// Create a copy of BleDisconnected
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $BleDisconnectedCopyWith<BleDisconnected> get copyWith =>
      _$BleDisconnectedCopyWithImpl<BleDisconnected>(
          this as BleDisconnected, _$identity);

  /// Serializes this BleDisconnected to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is BleDisconnected &&
            (identical(other.macAddress, macAddress) ||
                other.macAddress == macAddress));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, macAddress);

  @override
  String toString() {
    return 'BleDisconnected(macAddress: $macAddress)';
  }
}

/// @nodoc
abstract mixin class $BleDisconnectedCopyWith<$Res> {
  factory $BleDisconnectedCopyWith(
          BleDisconnected value, $Res Function(BleDisconnected) _then) =
      _$BleDisconnectedCopyWithImpl;
  @useResult
  $Res call({String macAddress});
}

/// @nodoc
class _$BleDisconnectedCopyWithImpl<$Res>
    implements $BleDisconnectedCopyWith<$Res> {
  _$BleDisconnectedCopyWithImpl(this._self, this._then);

  final BleDisconnected _self;
  final $Res Function(BleDisconnected) _then;

  /// Create a copy of BleDisconnected
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? macAddress = null,
  }) {
    return _then(_self.copyWith(
      macAddress: null == macAddress
          ? _self.macAddress
          : macAddress // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _BleDisconnected extends BleDisconnected {
  const _BleDisconnected({required this.macAddress}) : super._();
  factory _BleDisconnected.fromJson(Map<String, dynamic> json) =>
      _$BleDisconnectedFromJson(json);

  /// [macAddress] is the MAC address of the device.
  @override
  final String macAddress;

  /// Create a copy of BleDisconnected
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$BleDisconnectedCopyWith<_BleDisconnected> get copyWith =>
      __$BleDisconnectedCopyWithImpl<_BleDisconnected>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$BleDisconnectedToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _BleDisconnected &&
            (identical(other.macAddress, macAddress) ||
                other.macAddress == macAddress));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, macAddress);

  @override
  String toString() {
    return 'BleDisconnected(macAddress: $macAddress)';
  }
}

/// @nodoc
abstract mixin class _$BleDisconnectedCopyWith<$Res>
    implements $BleDisconnectedCopyWith<$Res> {
  factory _$BleDisconnectedCopyWith(
          _BleDisconnected value, $Res Function(_BleDisconnected) _then) =
      __$BleDisconnectedCopyWithImpl;
  @override
  @useResult
  $Res call({String macAddress});
}

/// @nodoc
class __$BleDisconnectedCopyWithImpl<$Res>
    implements _$BleDisconnectedCopyWith<$Res> {
  __$BleDisconnectedCopyWithImpl(this._self, this._then);

  final _BleDisconnected _self;
  final $Res Function(_BleDisconnected) _then;

  /// Create a copy of BleDisconnected
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? macAddress = null,
  }) {
    return _then(_BleDisconnected(
      macAddress: null == macAddress
          ? _self.macAddress
          : macAddress // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
mixin _$BleCharacteristicNotification {
  /// [macAddress] is the MAC address of the device.
  String get macAddress;

  /// [serviceUuid] is the UUID of the service.
  String get serviceUuid;

  /// [characteristicUuid] is the UUID of the characteristic.
  String get characteristicUuid;

  /// [payload] is the data received from the characteristic.
  @UintListConverter()
  Uint8List get value;

  /// Create a copy of BleCharacteristicNotification
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $BleCharacteristicNotificationCopyWith<BleCharacteristicNotification>
      get copyWith => _$BleCharacteristicNotificationCopyWithImpl<
              BleCharacteristicNotification>(
          this as BleCharacteristicNotification, _$identity);

  /// Serializes this BleCharacteristicNotification to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is BleCharacteristicNotification &&
            (identical(other.macAddress, macAddress) ||
                other.macAddress == macAddress) &&
            (identical(other.serviceUuid, serviceUuid) ||
                other.serviceUuid == serviceUuid) &&
            (identical(other.characteristicUuid, characteristicUuid) ||
                other.characteristicUuid == characteristicUuid) &&
            const DeepCollectionEquality().equals(other.value, value));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, macAddress, serviceUuid,
      characteristicUuid, const DeepCollectionEquality().hash(value));

  @override
  String toString() {
    return 'BleCharacteristicNotification(macAddress: $macAddress, serviceUuid: $serviceUuid, characteristicUuid: $characteristicUuid, value: $value)';
  }
}

/// @nodoc
abstract mixin class $BleCharacteristicNotificationCopyWith<$Res> {
  factory $BleCharacteristicNotificationCopyWith(
          BleCharacteristicNotification value,
          $Res Function(BleCharacteristicNotification) _then) =
      _$BleCharacteristicNotificationCopyWithImpl;
  @useResult
  $Res call(
      {String macAddress,
      String serviceUuid,
      String characteristicUuid,
      @UintListConverter() Uint8List value});
}

/// @nodoc
class _$BleCharacteristicNotificationCopyWithImpl<$Res>
    implements $BleCharacteristicNotificationCopyWith<$Res> {
  _$BleCharacteristicNotificationCopyWithImpl(this._self, this._then);

  final BleCharacteristicNotification _self;
  final $Res Function(BleCharacteristicNotification) _then;

  /// Create a copy of BleCharacteristicNotification
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? macAddress = null,
    Object? serviceUuid = null,
    Object? characteristicUuid = null,
    Object? value = null,
  }) {
    return _then(_self.copyWith(
      macAddress: null == macAddress
          ? _self.macAddress
          : macAddress // ignore: cast_nullable_to_non_nullable
              as String,
      serviceUuid: null == serviceUuid
          ? _self.serviceUuid
          : serviceUuid // ignore: cast_nullable_to_non_nullable
              as String,
      characteristicUuid: null == characteristicUuid
          ? _self.characteristicUuid
          : characteristicUuid // ignore: cast_nullable_to_non_nullable
              as String,
      value: null == value
          ? _self.value
          : value // ignore: cast_nullable_to_non_nullable
              as Uint8List,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _BleCharacteristicNotification extends BleCharacteristicNotification {
  const _BleCharacteristicNotification(
      {required this.macAddress,
      required this.serviceUuid,
      required this.characteristicUuid,
      @UintListConverter() required this.value})
      : super._();
  factory _BleCharacteristicNotification.fromJson(Map<String, dynamic> json) =>
      _$BleCharacteristicNotificationFromJson(json);

  /// [macAddress] is the MAC address of the device.
  @override
  final String macAddress;

  /// [serviceUuid] is the UUID of the service.
  @override
  final String serviceUuid;

  /// [characteristicUuid] is the UUID of the characteristic.
  @override
  final String characteristicUuid;

  /// [payload] is the data received from the characteristic.
  @override
  @UintListConverter()
  final Uint8List value;

  /// Create a copy of BleCharacteristicNotification
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$BleCharacteristicNotificationCopyWith<_BleCharacteristicNotification>
      get copyWith => __$BleCharacteristicNotificationCopyWithImpl<
          _BleCharacteristicNotification>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$BleCharacteristicNotificationToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _BleCharacteristicNotification &&
            (identical(other.macAddress, macAddress) ||
                other.macAddress == macAddress) &&
            (identical(other.serviceUuid, serviceUuid) ||
                other.serviceUuid == serviceUuid) &&
            (identical(other.characteristicUuid, characteristicUuid) ||
                other.characteristicUuid == characteristicUuid) &&
            const DeepCollectionEquality().equals(other.value, value));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, macAddress, serviceUuid,
      characteristicUuid, const DeepCollectionEquality().hash(value));

  @override
  String toString() {
    return 'BleCharacteristicNotification(macAddress: $macAddress, serviceUuid: $serviceUuid, characteristicUuid: $characteristicUuid, value: $value)';
  }
}

/// @nodoc
abstract mixin class _$BleCharacteristicNotificationCopyWith<$Res>
    implements $BleCharacteristicNotificationCopyWith<$Res> {
  factory _$BleCharacteristicNotificationCopyWith(
          _BleCharacteristicNotification value,
          $Res Function(_BleCharacteristicNotification) _then) =
      __$BleCharacteristicNotificationCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String macAddress,
      String serviceUuid,
      String characteristicUuid,
      @UintListConverter() Uint8List value});
}

/// @nodoc
class __$BleCharacteristicNotificationCopyWithImpl<$Res>
    implements _$BleCharacteristicNotificationCopyWith<$Res> {
  __$BleCharacteristicNotificationCopyWithImpl(this._self, this._then);

  final _BleCharacteristicNotification _self;
  final $Res Function(_BleCharacteristicNotification) _then;

  /// Create a copy of BleCharacteristicNotification
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? macAddress = null,
    Object? serviceUuid = null,
    Object? characteristicUuid = null,
    Object? value = null,
  }) {
    return _then(_BleCharacteristicNotification(
      macAddress: null == macAddress
          ? _self.macAddress
          : macAddress // ignore: cast_nullable_to_non_nullable
              as String,
      serviceUuid: null == serviceUuid
          ? _self.serviceUuid
          : serviceUuid // ignore: cast_nullable_to_non_nullable
              as String,
      characteristicUuid: null == characteristicUuid
          ? _self.characteristicUuid
          : characteristicUuid // ignore: cast_nullable_to_non_nullable
              as String,
      value: null == value
          ? _self.value
          : value // ignore: cast_nullable_to_non_nullable
              as Uint8List,
    ));
  }
}

/// @nodoc
mixin _$GattConnected {
  /// [macAddress] is the ID of the device.
  String get macAddress;

  /// [name] is the name of the device.
  /// Can be null if not available.
  String? get name;

  /// Create a copy of GattConnected
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $GattConnectedCopyWith<GattConnected> get copyWith =>
      _$GattConnectedCopyWithImpl<GattConnected>(
          this as GattConnected, _$identity);

  /// Serializes this GattConnected to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is GattConnected &&
            (identical(other.macAddress, macAddress) ||
                other.macAddress == macAddress) &&
            (identical(other.name, name) || other.name == name));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, macAddress, name);

  @override
  String toString() {
    return 'GattConnected(macAddress: $macAddress, name: $name)';
  }
}

/// @nodoc
abstract mixin class $GattConnectedCopyWith<$Res> {
  factory $GattConnectedCopyWith(
          GattConnected value, $Res Function(GattConnected) _then) =
      _$GattConnectedCopyWithImpl;
  @useResult
  $Res call({String macAddress, String? name});
}

/// @nodoc
class _$GattConnectedCopyWithImpl<$Res>
    implements $GattConnectedCopyWith<$Res> {
  _$GattConnectedCopyWithImpl(this._self, this._then);

  final GattConnected _self;
  final $Res Function(GattConnected) _then;

  /// Create a copy of GattConnected
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? macAddress = null,
    Object? name = freezed,
  }) {
    return _then(_self.copyWith(
      macAddress: null == macAddress
          ? _self.macAddress
          : macAddress // ignore: cast_nullable_to_non_nullable
              as String,
      name: freezed == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _GattConnected extends GattConnected {
  const _GattConnected({required this.macAddress, this.name}) : super._();
  factory _GattConnected.fromJson(Map<String, dynamic> json) =>
      _$GattConnectedFromJson(json);

  /// [macAddress] is the ID of the device.
  @override
  final String macAddress;

  /// [name] is the name of the device.
  /// Can be null if not available.
  @override
  final String? name;

  /// Create a copy of GattConnected
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$GattConnectedCopyWith<_GattConnected> get copyWith =>
      __$GattConnectedCopyWithImpl<_GattConnected>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$GattConnectedToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _GattConnected &&
            (identical(other.macAddress, macAddress) ||
                other.macAddress == macAddress) &&
            (identical(other.name, name) || other.name == name));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, macAddress, name);

  @override
  String toString() {
    return 'GattConnected(macAddress: $macAddress, name: $name)';
  }
}

/// @nodoc
abstract mixin class _$GattConnectedCopyWith<$Res>
    implements $GattConnectedCopyWith<$Res> {
  factory _$GattConnectedCopyWith(
          _GattConnected value, $Res Function(_GattConnected) _then) =
      __$GattConnectedCopyWithImpl;
  @override
  @useResult
  $Res call({String macAddress, String? name});
}

/// @nodoc
class __$GattConnectedCopyWithImpl<$Res>
    implements _$GattConnectedCopyWith<$Res> {
  __$GattConnectedCopyWithImpl(this._self, this._then);

  final _GattConnected _self;
  final $Res Function(_GattConnected) _then;

  /// Create a copy of GattConnected
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? macAddress = null,
    Object? name = freezed,
  }) {
    return _then(_GattConnected(
      macAddress: null == macAddress
          ? _self.macAddress
          : macAddress // ignore: cast_nullable_to_non_nullable
              as String,
      name: freezed == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
mixin _$GattDisconnected {
  /// [macAddress] is the ID of the device.
  String get macAddress;

  /// Create a copy of GattDisconnected
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $GattDisconnectedCopyWith<GattDisconnected> get copyWith =>
      _$GattDisconnectedCopyWithImpl<GattDisconnected>(
          this as GattDisconnected, _$identity);

  /// Serializes this GattDisconnected to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is GattDisconnected &&
            (identical(other.macAddress, macAddress) ||
                other.macAddress == macAddress));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, macAddress);

  @override
  String toString() {
    return 'GattDisconnected(macAddress: $macAddress)';
  }
}

/// @nodoc
abstract mixin class $GattDisconnectedCopyWith<$Res> {
  factory $GattDisconnectedCopyWith(
          GattDisconnected value, $Res Function(GattDisconnected) _then) =
      _$GattDisconnectedCopyWithImpl;
  @useResult
  $Res call({String macAddress});
}

/// @nodoc
class _$GattDisconnectedCopyWithImpl<$Res>
    implements $GattDisconnectedCopyWith<$Res> {
  _$GattDisconnectedCopyWithImpl(this._self, this._then);

  final GattDisconnected _self;
  final $Res Function(GattDisconnected) _then;

  /// Create a copy of GattDisconnected
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? macAddress = null,
  }) {
    return _then(_self.copyWith(
      macAddress: null == macAddress
          ? _self.macAddress
          : macAddress // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _GattDisconnected extends GattDisconnected {
  const _GattDisconnected({required this.macAddress}) : super._();
  factory _GattDisconnected.fromJson(Map<String, dynamic> json) =>
      _$GattDisconnectedFromJson(json);

  /// [macAddress] is the ID of the device.
  @override
  final String macAddress;

  /// Create a copy of GattDisconnected
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$GattDisconnectedCopyWith<_GattDisconnected> get copyWith =>
      __$GattDisconnectedCopyWithImpl<_GattDisconnected>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$GattDisconnectedToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _GattDisconnected &&
            (identical(other.macAddress, macAddress) ||
                other.macAddress == macAddress));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, macAddress);

  @override
  String toString() {
    return 'GattDisconnected(macAddress: $macAddress)';
  }
}

/// @nodoc
abstract mixin class _$GattDisconnectedCopyWith<$Res>
    implements $GattDisconnectedCopyWith<$Res> {
  factory _$GattDisconnectedCopyWith(
          _GattDisconnected value, $Res Function(_GattDisconnected) _then) =
      __$GattDisconnectedCopyWithImpl;
  @override
  @useResult
  $Res call({String macAddress});
}

/// @nodoc
class __$GattDisconnectedCopyWithImpl<$Res>
    implements _$GattDisconnectedCopyWith<$Res> {
  __$GattDisconnectedCopyWithImpl(this._self, this._then);

  final _GattDisconnected _self;
  final $Res Function(_GattDisconnected) _then;

  /// Create a copy of GattDisconnected
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? macAddress = null,
  }) {
    return _then(_GattDisconnected(
      macAddress: null == macAddress
          ? _self.macAddress
          : macAddress // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
mixin _$GattReadRequest {
  /// [macAddress] is the ID of the device.
  String get macAddress;

  /// [requestId] is the ID of the request.
  int get requestId;

  /// [offset] is the offset of the data to be read.
  int get offset;

  /// [serviceUuid] is the UUID of the service.
  String get serviceUuid;

  /// [characteristicUuid] is the UUID of the characteristic.
  String get characteristicUuid;

  /// Create a copy of GattReadRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $GattReadRequestCopyWith<GattReadRequest> get copyWith =>
      _$GattReadRequestCopyWithImpl<GattReadRequest>(
          this as GattReadRequest, _$identity);

  /// Serializes this GattReadRequest to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is GattReadRequest &&
            (identical(other.macAddress, macAddress) ||
                other.macAddress == macAddress) &&
            (identical(other.requestId, requestId) ||
                other.requestId == requestId) &&
            (identical(other.offset, offset) || other.offset == offset) &&
            (identical(other.serviceUuid, serviceUuid) ||
                other.serviceUuid == serviceUuid) &&
            (identical(other.characteristicUuid, characteristicUuid) ||
                other.characteristicUuid == characteristicUuid));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, macAddress, requestId, offset,
      serviceUuid, characteristicUuid);

  @override
  String toString() {
    return 'GattReadRequest(macAddress: $macAddress, requestId: $requestId, offset: $offset, serviceUuid: $serviceUuid, characteristicUuid: $characteristicUuid)';
  }
}

/// @nodoc
abstract mixin class $GattReadRequestCopyWith<$Res> {
  factory $GattReadRequestCopyWith(
          GattReadRequest value, $Res Function(GattReadRequest) _then) =
      _$GattReadRequestCopyWithImpl;
  @useResult
  $Res call(
      {String macAddress,
      int requestId,
      int offset,
      String serviceUuid,
      String characteristicUuid});
}

/// @nodoc
class _$GattReadRequestCopyWithImpl<$Res>
    implements $GattReadRequestCopyWith<$Res> {
  _$GattReadRequestCopyWithImpl(this._self, this._then);

  final GattReadRequest _self;
  final $Res Function(GattReadRequest) _then;

  /// Create a copy of GattReadRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? macAddress = null,
    Object? requestId = null,
    Object? offset = null,
    Object? serviceUuid = null,
    Object? characteristicUuid = null,
  }) {
    return _then(_self.copyWith(
      macAddress: null == macAddress
          ? _self.macAddress
          : macAddress // ignore: cast_nullable_to_non_nullable
              as String,
      requestId: null == requestId
          ? _self.requestId
          : requestId // ignore: cast_nullable_to_non_nullable
              as int,
      offset: null == offset
          ? _self.offset
          : offset // ignore: cast_nullable_to_non_nullable
              as int,
      serviceUuid: null == serviceUuid
          ? _self.serviceUuid
          : serviceUuid // ignore: cast_nullable_to_non_nullable
              as String,
      characteristicUuid: null == characteristicUuid
          ? _self.characteristicUuid
          : characteristicUuid // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _GattReadRequest extends GattReadRequest {
  const _GattReadRequest(
      {required this.macAddress,
      required this.requestId,
      required this.offset,
      required this.serviceUuid,
      required this.characteristicUuid})
      : super._();
  factory _GattReadRequest.fromJson(Map<String, dynamic> json) =>
      _$GattReadRequestFromJson(json);

  /// [macAddress] is the ID of the device.
  @override
  final String macAddress;

  /// [requestId] is the ID of the request.
  @override
  final int requestId;

  /// [offset] is the offset of the data to be read.
  @override
  final int offset;

  /// [serviceUuid] is the UUID of the service.
  @override
  final String serviceUuid;

  /// [characteristicUuid] is the UUID of the characteristic.
  @override
  final String characteristicUuid;

  /// Create a copy of GattReadRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$GattReadRequestCopyWith<_GattReadRequest> get copyWith =>
      __$GattReadRequestCopyWithImpl<_GattReadRequest>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$GattReadRequestToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _GattReadRequest &&
            (identical(other.macAddress, macAddress) ||
                other.macAddress == macAddress) &&
            (identical(other.requestId, requestId) ||
                other.requestId == requestId) &&
            (identical(other.offset, offset) || other.offset == offset) &&
            (identical(other.serviceUuid, serviceUuid) ||
                other.serviceUuid == serviceUuid) &&
            (identical(other.characteristicUuid, characteristicUuid) ||
                other.characteristicUuid == characteristicUuid));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, macAddress, requestId, offset,
      serviceUuid, characteristicUuid);

  @override
  String toString() {
    return 'GattReadRequest(macAddress: $macAddress, requestId: $requestId, offset: $offset, serviceUuid: $serviceUuid, characteristicUuid: $characteristicUuid)';
  }
}

/// @nodoc
abstract mixin class _$GattReadRequestCopyWith<$Res>
    implements $GattReadRequestCopyWith<$Res> {
  factory _$GattReadRequestCopyWith(
          _GattReadRequest value, $Res Function(_GattReadRequest) _then) =
      __$GattReadRequestCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String macAddress,
      int requestId,
      int offset,
      String serviceUuid,
      String characteristicUuid});
}

/// @nodoc
class __$GattReadRequestCopyWithImpl<$Res>
    implements _$GattReadRequestCopyWith<$Res> {
  __$GattReadRequestCopyWithImpl(this._self, this._then);

  final _GattReadRequest _self;
  final $Res Function(_GattReadRequest) _then;

  /// Create a copy of GattReadRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? macAddress = null,
    Object? requestId = null,
    Object? offset = null,
    Object? serviceUuid = null,
    Object? characteristicUuid = null,
  }) {
    return _then(_GattReadRequest(
      macAddress: null == macAddress
          ? _self.macAddress
          : macAddress // ignore: cast_nullable_to_non_nullable
              as String,
      requestId: null == requestId
          ? _self.requestId
          : requestId // ignore: cast_nullable_to_non_nullable
              as int,
      offset: null == offset
          ? _self.offset
          : offset // ignore: cast_nullable_to_non_nullable
              as int,
      serviceUuid: null == serviceUuid
          ? _self.serviceUuid
          : serviceUuid // ignore: cast_nullable_to_non_nullable
              as String,
      characteristicUuid: null == characteristicUuid
          ? _self.characteristicUuid
          : characteristicUuid // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
mixin _$GattWriteRequest {
  /// [macAddress] is the ID of the device.
  String get macAddress;

  /// [requestId] is the ID of the request.
  int get requestId;

  /// [offset] is the offset of the data to be read.
  int get offset;

  /// [serviceUuid] is the UUID of the service.
  String get serviceUuid;

  /// [characteristicUuid] is the UUID of the characteristic.
  String get characteristicUuid;

  /// [data] is the data to be written.
  @UintListOrNullConverter()
  Uint8List? get data;

  /// [preparedWrite] is true if the request is a prepared write request.
  bool get preparedWrite;

  /// [responseNeeded] is true if the request needs a response.
  bool get responseNeeded;

  /// Create a copy of GattWriteRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $GattWriteRequestCopyWith<GattWriteRequest> get copyWith =>
      _$GattWriteRequestCopyWithImpl<GattWriteRequest>(
          this as GattWriteRequest, _$identity);

  /// Serializes this GattWriteRequest to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is GattWriteRequest &&
            (identical(other.macAddress, macAddress) ||
                other.macAddress == macAddress) &&
            (identical(other.requestId, requestId) ||
                other.requestId == requestId) &&
            (identical(other.offset, offset) || other.offset == offset) &&
            (identical(other.serviceUuid, serviceUuid) ||
                other.serviceUuid == serviceUuid) &&
            (identical(other.characteristicUuid, characteristicUuid) ||
                other.characteristicUuid == characteristicUuid) &&
            const DeepCollectionEquality().equals(other.data, data) &&
            (identical(other.preparedWrite, preparedWrite) ||
                other.preparedWrite == preparedWrite) &&
            (identical(other.responseNeeded, responseNeeded) ||
                other.responseNeeded == responseNeeded));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      macAddress,
      requestId,
      offset,
      serviceUuid,
      characteristicUuid,
      const DeepCollectionEquality().hash(data),
      preparedWrite,
      responseNeeded);

  @override
  String toString() {
    return 'GattWriteRequest(macAddress: $macAddress, requestId: $requestId, offset: $offset, serviceUuid: $serviceUuid, characteristicUuid: $characteristicUuid, data: $data, preparedWrite: $preparedWrite, responseNeeded: $responseNeeded)';
  }
}

/// @nodoc
abstract mixin class $GattWriteRequestCopyWith<$Res> {
  factory $GattWriteRequestCopyWith(
          GattWriteRequest value, $Res Function(GattWriteRequest) _then) =
      _$GattWriteRequestCopyWithImpl;
  @useResult
  $Res call(
      {String macAddress,
      int requestId,
      int offset,
      String serviceUuid,
      String characteristicUuid,
      @UintListOrNullConverter() Uint8List? data,
      bool preparedWrite,
      bool responseNeeded});
}

/// @nodoc
class _$GattWriteRequestCopyWithImpl<$Res>
    implements $GattWriteRequestCopyWith<$Res> {
  _$GattWriteRequestCopyWithImpl(this._self, this._then);

  final GattWriteRequest _self;
  final $Res Function(GattWriteRequest) _then;

  /// Create a copy of GattWriteRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? macAddress = null,
    Object? requestId = null,
    Object? offset = null,
    Object? serviceUuid = null,
    Object? characteristicUuid = null,
    Object? data = freezed,
    Object? preparedWrite = null,
    Object? responseNeeded = null,
  }) {
    return _then(_self.copyWith(
      macAddress: null == macAddress
          ? _self.macAddress
          : macAddress // ignore: cast_nullable_to_non_nullable
              as String,
      requestId: null == requestId
          ? _self.requestId
          : requestId // ignore: cast_nullable_to_non_nullable
              as int,
      offset: null == offset
          ? _self.offset
          : offset // ignore: cast_nullable_to_non_nullable
              as int,
      serviceUuid: null == serviceUuid
          ? _self.serviceUuid
          : serviceUuid // ignore: cast_nullable_to_non_nullable
              as String,
      characteristicUuid: null == characteristicUuid
          ? _self.characteristicUuid
          : characteristicUuid // ignore: cast_nullable_to_non_nullable
              as String,
      data: freezed == data
          ? _self.data
          : data // ignore: cast_nullable_to_non_nullable
              as Uint8List?,
      preparedWrite: null == preparedWrite
          ? _self.preparedWrite
          : preparedWrite // ignore: cast_nullable_to_non_nullable
              as bool,
      responseNeeded: null == responseNeeded
          ? _self.responseNeeded
          : responseNeeded // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _GattWriteRequest extends GattWriteRequest {
  const _GattWriteRequest(
      {required this.macAddress,
      required this.requestId,
      required this.offset,
      required this.serviceUuid,
      required this.characteristicUuid,
      @UintListOrNullConverter() this.data,
      this.preparedWrite = false,
      this.responseNeeded = false})
      : super._();
  factory _GattWriteRequest.fromJson(Map<String, dynamic> json) =>
      _$GattWriteRequestFromJson(json);

  /// [macAddress] is the ID of the device.
  @override
  final String macAddress;

  /// [requestId] is the ID of the request.
  @override
  final int requestId;

  /// [offset] is the offset of the data to be read.
  @override
  final int offset;

  /// [serviceUuid] is the UUID of the service.
  @override
  final String serviceUuid;

  /// [characteristicUuid] is the UUID of the characteristic.
  @override
  final String characteristicUuid;

  /// [data] is the data to be written.
  @override
  @UintListOrNullConverter()
  final Uint8List? data;

  /// [preparedWrite] is true if the request is a prepared write request.
  @override
  @JsonKey()
  final bool preparedWrite;

  /// [responseNeeded] is true if the request needs a response.
  @override
  @JsonKey()
  final bool responseNeeded;

  /// Create a copy of GattWriteRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$GattWriteRequestCopyWith<_GattWriteRequest> get copyWith =>
      __$GattWriteRequestCopyWithImpl<_GattWriteRequest>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$GattWriteRequestToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _GattWriteRequest &&
            (identical(other.macAddress, macAddress) ||
                other.macAddress == macAddress) &&
            (identical(other.requestId, requestId) ||
                other.requestId == requestId) &&
            (identical(other.offset, offset) || other.offset == offset) &&
            (identical(other.serviceUuid, serviceUuid) ||
                other.serviceUuid == serviceUuid) &&
            (identical(other.characteristicUuid, characteristicUuid) ||
                other.characteristicUuid == characteristicUuid) &&
            const DeepCollectionEquality().equals(other.data, data) &&
            (identical(other.preparedWrite, preparedWrite) ||
                other.preparedWrite == preparedWrite) &&
            (identical(other.responseNeeded, responseNeeded) ||
                other.responseNeeded == responseNeeded));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      macAddress,
      requestId,
      offset,
      serviceUuid,
      characteristicUuid,
      const DeepCollectionEquality().hash(data),
      preparedWrite,
      responseNeeded);

  @override
  String toString() {
    return 'GattWriteRequest(macAddress: $macAddress, requestId: $requestId, offset: $offset, serviceUuid: $serviceUuid, characteristicUuid: $characteristicUuid, data: $data, preparedWrite: $preparedWrite, responseNeeded: $responseNeeded)';
  }
}

/// @nodoc
abstract mixin class _$GattWriteRequestCopyWith<$Res>
    implements $GattWriteRequestCopyWith<$Res> {
  factory _$GattWriteRequestCopyWith(
          _GattWriteRequest value, $Res Function(_GattWriteRequest) _then) =
      __$GattWriteRequestCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String macAddress,
      int requestId,
      int offset,
      String serviceUuid,
      String characteristicUuid,
      @UintListOrNullConverter() Uint8List? data,
      bool preparedWrite,
      bool responseNeeded});
}

/// @nodoc
class __$GattWriteRequestCopyWithImpl<$Res>
    implements _$GattWriteRequestCopyWith<$Res> {
  __$GattWriteRequestCopyWithImpl(this._self, this._then);

  final _GattWriteRequest _self;
  final $Res Function(_GattWriteRequest) _then;

  /// Create a copy of GattWriteRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? macAddress = null,
    Object? requestId = null,
    Object? offset = null,
    Object? serviceUuid = null,
    Object? characteristicUuid = null,
    Object? data = freezed,
    Object? preparedWrite = null,
    Object? responseNeeded = null,
  }) {
    return _then(_GattWriteRequest(
      macAddress: null == macAddress
          ? _self.macAddress
          : macAddress // ignore: cast_nullable_to_non_nullable
              as String,
      requestId: null == requestId
          ? _self.requestId
          : requestId // ignore: cast_nullable_to_non_nullable
              as int,
      offset: null == offset
          ? _self.offset
          : offset // ignore: cast_nullable_to_non_nullable
              as int,
      serviceUuid: null == serviceUuid
          ? _self.serviceUuid
          : serviceUuid // ignore: cast_nullable_to_non_nullable
              as String,
      characteristicUuid: null == characteristicUuid
          ? _self.characteristicUuid
          : characteristicUuid // ignore: cast_nullable_to_non_nullable
              as String,
      data: freezed == data
          ? _self.data
          : data // ignore: cast_nullable_to_non_nullable
              as Uint8List?,
      preparedWrite: null == preparedWrite
          ? _self.preparedWrite
          : preparedWrite // ignore: cast_nullable_to_non_nullable
              as bool,
      responseNeeded: null == responseNeeded
          ? _self.responseNeeded
          : responseNeeded // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
mixin _$GattMtuChanged {
  /// [macAddress] is the ID of the device.
  String get macAddress;

  /// [mtu] is the new MTU size.
  int get mtu;

  /// Create a copy of GattMtuChanged
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $GattMtuChangedCopyWith<GattMtuChanged> get copyWith =>
      _$GattMtuChangedCopyWithImpl<GattMtuChanged>(
          this as GattMtuChanged, _$identity);

  /// Serializes this GattMtuChanged to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is GattMtuChanged &&
            (identical(other.macAddress, macAddress) ||
                other.macAddress == macAddress) &&
            (identical(other.mtu, mtu) || other.mtu == mtu));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, macAddress, mtu);

  @override
  String toString() {
    return 'GattMtuChanged(macAddress: $macAddress, mtu: $mtu)';
  }
}

/// @nodoc
abstract mixin class $GattMtuChangedCopyWith<$Res> {
  factory $GattMtuChangedCopyWith(
          GattMtuChanged value, $Res Function(GattMtuChanged) _then) =
      _$GattMtuChangedCopyWithImpl;
  @useResult
  $Res call({String macAddress, int mtu});
}

/// @nodoc
class _$GattMtuChangedCopyWithImpl<$Res>
    implements $GattMtuChangedCopyWith<$Res> {
  _$GattMtuChangedCopyWithImpl(this._self, this._then);

  final GattMtuChanged _self;
  final $Res Function(GattMtuChanged) _then;

  /// Create a copy of GattMtuChanged
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? macAddress = null,
    Object? mtu = null,
  }) {
    return _then(_self.copyWith(
      macAddress: null == macAddress
          ? _self.macAddress
          : macAddress // ignore: cast_nullable_to_non_nullable
              as String,
      mtu: null == mtu
          ? _self.mtu
          : mtu // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _GattMtuChanged extends GattMtuChanged {
  const _GattMtuChanged({required this.macAddress, required this.mtu})
      : super._();
  factory _GattMtuChanged.fromJson(Map<String, dynamic> json) =>
      _$GattMtuChangedFromJson(json);

  /// [macAddress] is the ID of the device.
  @override
  final String macAddress;

  /// [mtu] is the new MTU size.
  @override
  final int mtu;

  /// Create a copy of GattMtuChanged
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$GattMtuChangedCopyWith<_GattMtuChanged> get copyWith =>
      __$GattMtuChangedCopyWithImpl<_GattMtuChanged>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$GattMtuChangedToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _GattMtuChanged &&
            (identical(other.macAddress, macAddress) ||
                other.macAddress == macAddress) &&
            (identical(other.mtu, mtu) || other.mtu == mtu));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, macAddress, mtu);

  @override
  String toString() {
    return 'GattMtuChanged(macAddress: $macAddress, mtu: $mtu)';
  }
}

/// @nodoc
abstract mixin class _$GattMtuChangedCopyWith<$Res>
    implements $GattMtuChangedCopyWith<$Res> {
  factory _$GattMtuChangedCopyWith(
          _GattMtuChanged value, $Res Function(_GattMtuChanged) _then) =
      __$GattMtuChangedCopyWithImpl;
  @override
  @useResult
  $Res call({String macAddress, int mtu});
}

/// @nodoc
class __$GattMtuChangedCopyWithImpl<$Res>
    implements _$GattMtuChangedCopyWith<$Res> {
  __$GattMtuChangedCopyWithImpl(this._self, this._then);

  final _GattMtuChanged _self;
  final $Res Function(_GattMtuChanged) _then;

  /// Create a copy of GattMtuChanged
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? macAddress = null,
    Object? mtu = null,
  }) {
    return _then(_GattMtuChanged(
      macAddress: null == macAddress
          ? _self.macAddress
          : macAddress // ignore: cast_nullable_to_non_nullable
              as String,
      mtu: null == mtu
          ? _self.mtu
          : mtu // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
mixin _$BleStatus {
  /// [advertising] is the status of the advertising.
  bool get advertising;

  /// [scanning] is the status of the scanning.
  bool get scanning;

  /// Create a copy of BleStatus
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $BleStatusCopyWith<BleStatus> get copyWith =>
      _$BleStatusCopyWithImpl<BleStatus>(this as BleStatus, _$identity);

  /// Serializes this BleStatus to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is BleStatus &&
            (identical(other.advertising, advertising) ||
                other.advertising == advertising) &&
            (identical(other.scanning, scanning) ||
                other.scanning == scanning));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, advertising, scanning);

  @override
  String toString() {
    return 'BleStatus(advertising: $advertising, scanning: $scanning)';
  }
}

/// @nodoc
abstract mixin class $BleStatusCopyWith<$Res> {
  factory $BleStatusCopyWith(BleStatus value, $Res Function(BleStatus) _then) =
      _$BleStatusCopyWithImpl;
  @useResult
  $Res call({bool advertising, bool scanning});
}

/// @nodoc
class _$BleStatusCopyWithImpl<$Res> implements $BleStatusCopyWith<$Res> {
  _$BleStatusCopyWithImpl(this._self, this._then);

  final BleStatus _self;
  final $Res Function(BleStatus) _then;

  /// Create a copy of BleStatus
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? advertising = null,
    Object? scanning = null,
  }) {
    return _then(_self.copyWith(
      advertising: null == advertising
          ? _self.advertising
          : advertising // ignore: cast_nullable_to_non_nullable
              as bool,
      scanning: null == scanning
          ? _self.scanning
          : scanning // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _BleStatus extends BleStatus {
  const _BleStatus({required this.advertising, required this.scanning})
      : super._();
  factory _BleStatus.fromJson(Map<String, dynamic> json) =>
      _$BleStatusFromJson(json);

  /// [advertising] is the status of the advertising.
  @override
  final bool advertising;

  /// [scanning] is the status of the scanning.
  @override
  final bool scanning;

  /// Create a copy of BleStatus
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$BleStatusCopyWith<_BleStatus> get copyWith =>
      __$BleStatusCopyWithImpl<_BleStatus>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$BleStatusToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _BleStatus &&
            (identical(other.advertising, advertising) ||
                other.advertising == advertising) &&
            (identical(other.scanning, scanning) ||
                other.scanning == scanning));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, advertising, scanning);

  @override
  String toString() {
    return 'BleStatus(advertising: $advertising, scanning: $scanning)';
  }
}

/// @nodoc
abstract mixin class _$BleStatusCopyWith<$Res>
    implements $BleStatusCopyWith<$Res> {
  factory _$BleStatusCopyWith(
          _BleStatus value, $Res Function(_BleStatus) _then) =
      __$BleStatusCopyWithImpl;
  @override
  @useResult
  $Res call({bool advertising, bool scanning});
}

/// @nodoc
class __$BleStatusCopyWithImpl<$Res> implements _$BleStatusCopyWith<$Res> {
  __$BleStatusCopyWithImpl(this._self, this._then);

  final _BleStatus _self;
  final $Res Function(_BleStatus) _then;

  /// Create a copy of BleStatus
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? advertising = null,
    Object? scanning = null,
  }) {
    return _then(_BleStatus(
      advertising: null == advertising
          ? _self.advertising
          : advertising // ignore: cast_nullable_to_non_nullable
              as bool,
      scanning: null == scanning
          ? _self.scanning
          : scanning // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

// dart format on
