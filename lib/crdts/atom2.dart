import 'dart:convert';
import 'dart:typed_data';
import 'package:msgpack_dart/msgpack_dart.dart';
import 'package:sync_layer/basic/hlc.dart';

class KeyValue<K, V> {
  final K key;
  final V value;
  KeyValue(this.key, this.value);
}

/// TODO: could probably be optimized
class Atom2<K, V> implements Comparable<Atom2> {
  final Hlc ts;
  String get node => ts.node;

  /// In Context  of a Db, it's the **[Table]** id
  final int type;

  /// in Context of  a Db, its the **[Row]** id could be cuid id or any other
  final String id;

  /// In context ob a Db it is the **[column]**
  final int key;

  /// In context of a Db its the **[value]** of the column
  final V value;

  Atom2({
    this.ts,
    this.type,
    this.id,
    this.key,
    this.value,
  });

  @override
  int compareTo(Atom2 other) {
    // return other.ts.logicalTime - ts.logicalTime; // DESC
    return ts.logicalTime - other.ts.logicalTime; //ASC
  }

  Atom2 copyWith({
    Hlc ts,
    String type,
    String id,
    K key,
    V value,
  }) {
    return Atom2<K, V>(
      ts: ts ?? this.ts,
      type: type ?? this.type,
      id: id ?? this.id,
      key: key ?? this.key,
      value: value ?? this.value,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ts': ts.toString(),
      'type': type,
      'id': id,
      'key': key,
      'value': value,
    };
  }

  static Atom2 fromMap(Map<String, dynamic> map) {
    if (map == null) return null;

    return Atom2(
      ts: Hlc.parse(map['ts']),
      type: map['type'],
      id: map['id'],
      key: map['key'],
      value: map['value'],
    );
  }

  Uint8List toBytes() {
    final list = [ts.logicalTime, ts.node, type, id, key, value];
    return serialize(list);
  }

  factory Atom2.fromBytes(Uint8List buff) {
    final list = deserialize(buff);

    return Atom2(
      ts: Hlc.fromLogicalTime(list[0], list[1]),
      type: list[2],
      id: list[3],
      key: list[4],
      value: list[5],
    );
  }

  String toJson() => json.encode(toMap());
  static Atom2 fromJson(String source) => fromMap(json.decode(source));

  @override
  String toString() {
    return 'Atom(ts: $ts, type: $type, id: $id, key: $key, value: $value)';
  }

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is Atom2 && o.ts == ts && o.type == type && o.id == id && o.key == key && o.value == value;
  }

  @override
  int get hashCode {
    return ts.hashCode ^ type.hashCode ^ id.hashCode ^ key.hashCode ^ value.hashCode;
  }
}
