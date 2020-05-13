import 'dart:typed_data';

import 'package:msgpack_dart/msgpack_dart.dart';
import 'package:sync_layer/crdts/index.dart';
import 'package:sync_layer/encoding_extent/endecode.dart';
import 'package:sync_layer/logical_clocks/index.dart';

class ExtendetDecoder implements ExtDecoder {
  @override
  dynamic decodeObject(int extType, Uint8List data) {
    if (extType == 1) {
      var v = List<int>.from(msgpackDecode(data));
      return LogicalTime(v[0], v[1]);
    }
    if (extType == 2) {
      var v = List<int>.from(msgpackDecode(data));
      return Hlc(v[0], v[1], v[2]);
    }

    if (extType == 3) {
      final v = msgpackDecode(data);
      return Value(v[0], v[1], v[2], v[3]);
    }

    if (extType == 4) {
      final v = msgpackDecode(data);
      return Atom(v[0], v[1]);
    }

    if (extType == 5) {
      final v = msgpackDecode(data);
      return CausalAtom(v[0], v[1], v[2]);
    }

    if (extType == 6) {
      final v = msgpackDecode(data);
      return ObjectReference(v[0], v[1]);
    }

    return null;
  }
}
