library;

import 'dart:typed_data';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'types.freezed.dart';
part 'types.g.dart';

part 'src/event.dart';
part 'src/characteristic_notification.dart';
part 'src/gatt_server.dart';
part 'src/ble_status.dart';

class UintListConverter implements JsonConverter<Uint8List, List<dynamic>> {
  const UintListConverter();

  @override
  Uint8List fromJson(List<dynamic> json) {
    return Uint8List.fromList(json.cast<int>());
  }

  @override
  List<dynamic> toJson(Uint8List object) {
    return object.toList();
  }
}

class UintListOrNullConverter implements JsonConverter<Uint8List?, List<dynamic>?> {
  const UintListOrNullConverter();

  @override
  Uint8List? fromJson(List<dynamic>? json) {
    if (json == null) return null;
    return Uint8List.fromList(json.cast<int>());
  }

  @override
  List<dynamic>? toJson(Uint8List? object) {
    if (object == null) return null;
    return object.toList();
  }
}
