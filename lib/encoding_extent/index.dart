import 'dart:typed_data';

import 'package:msgpack_dart/msgpack_dart.dart';
import 'package:sync_layer/basic/index.dart';
import 'package:sync_layer/crdts/causal_tree/causal_entry.dart';

import 'package:sync_layer/types/index.dart';

/// encodes into bytes
Uint8List msgpackEncode(dynamic v) => serialize(v, extEncoder: _valueEncoder);

/// decodes bytes into object/types
dynamic msgpackDecode(dynamic v) => deserialize(v, extDecoder: _valueDecoder);

final _valueEncoder = _ExtendetEncoder();
final _valueDecoder = _ExtendetDecoder();

/// Todo: add types
/// * causal entry
/// * etc....
class _ExtendetEncoder implements ExtEncoder {
  @override
  int extTypeForObject(dynamic o) {
    if (o is LogicalClock) return 1;
    if (o is HybridLogicalClock) return 2;
    if (o is SyncableEntry) return 3;
    if (o is Atom) return 4;
    if (o is CausalEntry) return 5;
    if (o is ObjectReference) return 6;
    if (o is MerkleTrie) return 8;
    if (o is Id) return 9;

    return null;
  }

  @override
  Uint8List encodeObject(dynamic o) {
    if (o is LogicalClock) return msgpackEncode(o.logicalTime);
    if (o is HybridLogicalClock) return msgpackEncode([o.ms, o.counter]);
    if (o is SyncableEntry) return msgpackEncode([o.key, o.value]);
    if (o is Atom) {
      /// Knowing ts clock is HLC!
      final ts = (o.id.ts as HybridLogicalClock);
      return msgpackEncode([
        ts.ms,
        ts.counter,
        o.id.site,
        o.type,
        o.objectId,
        o.data,
      ]);
    }
    if (o is CausalEntry) {
      return msgpackEncode([
        o.id.ts.logicalTime,
        o.id.site,
        o.cause?.ts?.logicalTime,
        o.cause?.site,
        o.data,
      ]);
    }

    if (o is ObjectReference) return msgpackEncode([o.type, o.id]);
    if (o is MerkleTrie) return msgpackEncode(o.toMap());
    if (o is Id) return msgpackEncode([o.ts, o.site]);

    return null;
  }
}

class _ExtendetDecoder implements ExtDecoder {
  @override
  dynamic decodeObject(int extType, Uint8List data) {
    if (extType == 1) {
      var v = msgpackDecode(data);
      return LogicalClock(v);
    }

    if (extType == 2) {
      var v = List<int>.from(msgpackDecode(data));
      return HybridLogicalClock(v[0], v[1]);
    }

    if (extType == 3) {
      final v = msgpackDecode(data);
      return SyncableEntry(v[0], v[1]);
    }

    if (extType == 4) {
      final v = msgpackDecode(data);
      final id = Id(HybridLogicalClock(v[0], v[1]), v[2]);
      return Atom(id, v[3], v[4], v[5]);
    }

    if (extType == 5) {
      final v = msgpackDecode(data);
      final id = Id(LogicalClock(v[0]), v[1]);
      final cause = v[2] != null ? Id(LogicalClock(v[2]), v[3]) : null;
      return CausalEntry(id, cause: cause, data: v[4]);
    }

    if (extType == 6) {
      final v = msgpackDecode(data);
      return ObjectReference(v[0], v[1]);
    }

    if (extType == 8) {
      final v = (msgpackDecode(data) as Map).cast<int, dynamic>();
      return MerkleTrie.fromMap(v);
    }

    if (extType == 9) {
      final v = msgpackDecode(data);
      return Id(v[0], v[1]);
    }

    return null;
  }
}
