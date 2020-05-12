import 'dart:convert';
import 'dart:typed_data';
import 'package:msgpack_dart/msgpack_dart.dart';
import 'package:sync_layer/timestamp/index.dart';

class Atom implements Comparable<Atom> {
  final Hlc hlc;
  int get site => hlc.site;

  /// In Context  of a Db, it's the **[Table]** id
  final String type;

  /// in Context of  a Db, its the **[Row]** id could be cuid id or any other
  final String id;

  /// In context ob a Db it is the **[column]**
  final dynamic key;

  /// In context of a Db its the **[value]** of the column
  final dynamic value;

  Atom(
    this.hlc,
    this.type,
    this.id,
    this.key,
    this.value,
  );

  @override
  int compareTo(Atom other) {
    // return other.ts.logicalTime - ts.logicalTime; // DESC
    return hlc.logicalTime - other.hlc.logicalTime; //ASC
  }

  Atom copyWith({
    Hlc hlc,
    String type,
    String id,
    dynamic key,
    dynamic value,
  }) {
    return Atom(
      hlc ?? this.hlc,
      type ?? this.type,
      id ?? this.id,
      key ?? this.key,
      value ?? this.value,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ts': hlc.toString(),
      'type': type,
      'id': id,
      'key': key,
      'value': value,
    };
  }

  static Atom fromMap(Map<String, dynamic> map) {
    if (map == null) return null;

    return Atom(
      Hlc.parse(map['ts']),
      map['type'],
      map['id'],
      map['key'],
      map['value'],
    );
  }

  Uint8List toBytes() {
    final list = [hlc.logicalTime, hlc.site, type, id, key, value];

    return serialize(list);
  }

  factory Atom.fromBytes(Uint8List buff) {
    final list = deserialize(buff);

    return Atom(
      Hlc.fromLogicalTime(list[0], list[1]),
      list[2],
      list[3],
      list[4],
      list[5],
    );
  }

  String toJson() => json.encode(toMap());
  static Atom fromJson(String source) => fromMap(json.decode(source));

  @override
  String toString() {
    return 'Atom(ts: ${hlc.toRON()}, type: $type, id: $id, key: $key, value: $value)';
  }

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is Atom && o.hlc == hlc && o.type == type && o.id == id && o.key == key && o.value == value;
  }

  @override
  int get hashCode {
    return hlc.hashCode ^ type.hashCode ^ id.hashCode ^ key.hashCode ^ value.hashCode;
  }
}
