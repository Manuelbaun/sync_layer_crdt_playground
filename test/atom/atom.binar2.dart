import 'dart:convert';
import 'dart:typed_data';

import 'package:sync_layer/basic/index.dart';
import 'package:sync_layer/timestamp/index.dart';

enum Types { STRING, UINT32, UINT64, FLOAT32, FLOAT64, BOOL }

class AtomBinary2 {
  Uint8List _id;
  ByteData ints;
  ByteData _value;

  int get ts => ints.getUint64(0);
  int get node => ints.getUint32(2);
  int get type => ints.getUint32(3);
  int get key => ints.getUint32(4);
  String get id => String.fromCharCodes(_id);

  dynamic get value {
    switch (_value?.getUint8(0)) {
      case 0:
        return String.fromCharCodes(_value.buffer.asUint8List(1));
    }
  }

// [0, 220, 106, 152, 189, 128, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
// [0, 220, 106, 152, 189, 128, 0, 0, 188, 97, 78, 0, 0, 0, 0, 0, 0, 0, 0, 0]
  AtomBinary2({String id, int ts, int node, int type, int key, dynamic value}) {
    if (ts != null && node != null && type != null && key != null) {
      ints = ByteData(8 + 4 + 4 + 4)
        ..setUint64(0, ts)
        ..setUint32(8, node)
        ..setUint32(12, type)
        ..setUint32(16, key);
      //128bits => 16 bytes!

      print(ints.buffer.asUint8List());
    }

    if (id != null) {
      _id = Uint8List.fromList(id.codeUnits);
      print(_id);
    }

    if (value != null) {
      if (value is String) {
        final l = Uint8List.fromList([Types.STRING.index, ...value.codeUnits]);
        _value = ByteData.view(l.buffer);
      } else if (value is int) {
        final length = value.bitLength >> 3;
        _value = ByteData(1 + length);

        if (length <= 4) {
          _value.setInt8(0, Types.UINT32.index);
          _value.setUint32(1, value);
        } else {
          _value.setInt8(0, Types.UINT64.index);
          _value.setUint64(1, value);
        }
      } else if (value is double) {
        _value = ByteData(1 + 8);
        _value.setInt8(0, Types.FLOAT64.index);
        _value.setFloat64(1, value);
      } else {
        print('what a value $value');
      }
    }
  }

  Uint8List toByte() {
    return Uint8List.fromList([
      ...ints.buffer.asUint8List(),
      ..._id,
      ..._value.buffer.asUint8List(),
    ]);
  }

  factory AtomBinary2.fromBytes(Uint8List buf) {
    final a = AtomBinary2()
      ..ints = ByteData.view(buf.sublist(0, 20).buffer)
      .._id = buf.sublist(20, 45)
      .._value = ByteData.view(buf.sublist(45).buffer);

    return a;
  }

  @override
  String toString() {
    var encoder = JsonEncoder.withIndent('  ');
    return encoder.convert({'ts': ts, 'node': node, 'type': type, 'key': key, 'id': id, 'value': value});
  }
}

void main() {
  final ts = Hlc(DateTime(2000).millisecondsSinceEpoch, 0, 1234).logicalTime;
  final id = newCuid();
  print(id);

  final a = AtomBinary2(key: 0, node: 12345678, id: id, ts: ts, type: 20, value: 'hans Peter');
  print(a);
  final buff = a.toByte();
  print(buff);
  final a2 = AtomBinary2.fromBytes(buff);
  print(a2);
}
