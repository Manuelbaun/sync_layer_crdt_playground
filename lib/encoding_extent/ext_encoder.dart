import 'dart:typed_data';

import 'package:msgpack_dart/msgpack_dart.dart';
import 'package:sync_layer/crdts/atom.dart';
import 'package:sync_layer/crdts/atom_causal.dart';
import 'package:sync_layer/crdts/values.dart';
import 'package:sync_layer/encoding_extent/endecode.dart';
import 'package:sync_layer/timestamp/index.dart';

class ExtendetEncoder implements ExtEncoder {
  @override
  int extTypeForObject(dynamic object) {
    if (object is Hlc) return 2;
    if (object is LogicalTime) return 1;
    if (object is Value) return 3;
    if (object is CausalAtom) return 5;
    if (object is Atom) return 4;

    return null;
  }

  @override
  Uint8List encodeObject(dynamic object) {
    if (object is Hlc) return serialize([object.ms, object.counter, object.site]);
    if (object is LogicalTime) return serialize([object.counter, object.site]);
    if (object is Value) return serialize([object.type, object.id, object.key, object.value]);
    if (object is CausalAtom) return msgpackEncode([object.cause, object.clock, object.value]);
    if (object is Atom) return msgpackEncode([object.clock, object.value]);

    return null;
  }
}
