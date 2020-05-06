import 'dart:convert';
import 'dart:typed_data';

import 'package:messagepack/messagepack.dart';

enum Types { STRING, UINT32, UINT64, FLOAT32, FLOAT64, BOOL }

class AtomBinary {
  int ts;
  int node;
  String id;
  int classType;
  int key;
  dynamic value;

  AtomBinary(
    this.ts,
    this.node,
    this.classType,
    this.id,
    this.key,
    this.value,
  );

  Uint8List toByte() {
    final p = Packer()
      ..packListLength(6)
      ..packInt(ts)
      ..packInt(node)
      ..packInt(classType)
      ..packString(id)
      ..packInt(key);

    packDyamicType(p, value);

    return p.takeBytes();
  }

  factory AtomBinary.from(Uint8List bytes) {
    final u = Unpacker(bytes);
    final l = u.unpackList();

    // final logTime = u.unpackInt();
    // final nodeId = u.unpackInt();
    // final classType = u.unpackInt();
    // final id = u.unpackString();
    // final key = u.unpackInt();
    // final value = u.unpackString();

    final logTime = l[0];
    final nodeId = l[1];
    final classType = l[2];
    final id = l[3];
    final key = l[4];
    final value = l[5];

    return AtomBinary(logTime, nodeId, classType, id, key, value);
  }

  static void packDyamicType(Packer p, dynamic v) {
    if (v is String) {
      p.packString(v);
    } else if (v is int) {
      p.packInt(v);
    } else if (v is double) {
      p.packDouble(v);
    } else if (v is bool) {
      p.packBool(v);
    } else {
      throw ArgumentError.value(v, 'Type', 'Type is not supported yet, todo:');
    }
  }

  @override
  String toString() {
    return 'AtomBinary(ts: $ts, classType: $classType, id: $id, key: $key, value: $value)';
  }

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is AtomBinary && o.ts == ts && o.classType == classType && o.id == id && o.key == key && o.value == value;
  }

  @override
  int get hashCode {
    return ts.hashCode ^ classType.hashCode ^ id.hashCode ^ key.hashCode ^ value.hashCode;
  }

  Map<String, dynamic> toMap() {
    return {
      'ts': ts,
      'nodeid': node,
      'classType': classType,
      'id': id,
      'key': key,
      'value': value,
    };
  }

  static AtomBinary fromMap(Map<String, dynamic> map) {
    if (map == null) return null;

    return AtomBinary(
      map['ts'],
      map['nodeid'],
      map['classType'],
      map['id'],
      map['key'],
      map['value'],
    );
  }

  String toJson() => json.encode(toMap());

  static AtomBinary fromJson(String source) => fromMap(json.decode(source));
}
