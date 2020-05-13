import 'dart:typed_data';

import 'package:msgpack_dart/msgpack_dart.dart';
import 'package:sync_layer/encoding_extent/endecode.dart';
import 'package:sync_layer/types/index.dart';
import 'package:sync_layer/logical_clocks/index.dart';

class ExtendetEncoder implements ExtEncoder {
  @override
  int extTypeForObject(dynamic o) {
    if (o is LogicalTime) return 1;
    if (o is Hlc) return 2;
    if (o is Value) return 3;
    if (o is Atom) return 4;
    if (o is CausalAtom) return 5;
    if (o is ObjectReference) {
      return 6;
    }

    return null;
  }

  @override
  Uint8List encodeObject(dynamic o) {
    if (o is LogicalTime) return msgpackEncode([o.counter, o.site]);
    if (o is Hlc) return msgpackEncode([o.ms, o.counter, o.site]);
    if (o is Value) return msgpackEncode([o.type, o.id, o.key, o.value]);
    if (o is CausalAtom) return msgpackEncode([o.cause, o.clock, o.data]);
    if (o is Atom) return msgpackEncode([o.clock, o.data]);
    if (o is ObjectReference) {
      return msgpackEncode([o.type, o.id]);
    }

    return null;
  }
}
