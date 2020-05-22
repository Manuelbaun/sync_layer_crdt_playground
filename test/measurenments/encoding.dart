import 'dart:io';
import 'dart:typed_data';

import 'package:sync_layer/basic/cuid.dart';
import 'package:sync_layer/crdts/causal_tree/causal_entry.dart';
import 'package:sync_layer/encoding_extent/index.dart';
import 'package:sync_layer/types/id.dart';
import 'package:sync_layer/types/index.dart';
import 'package:sync_layer/utils/measure.dart';

final data = 'Hallo';
final cuid = newCuid();
final type = 1;

final id = Id(LogicalClock(1), 20);
final cause = Id(LogicalClock(0), 20);
final entry = CausalEntry(id, cause: cause, data: data);
final atomId = Id(LogicalClock(20), 20);
final atomLC = Atom(atomId, type, cuid, entry);

final hlc = HybridLogicalClock(DateTime(2020).millisecondsSinceEpoch, 0);
final atomIdHlc = Id(hlc, 20);
final atomHlc = Atom(atomIdHlc, type, cuid, entry);

/// compare msg vs own implementation.. 
/// => conclusion: messages could be smaller, 
/// when manually encoded, but a lot of work to be done.
/// 

/// xxx notes, that is only encodes , but not properly decodes
void main() {
  // radix36Int();

  encodeCausalEntryManually();
  encodeAtomWithoutMSGSubTypes();
  encodeCausalEntryMinEncoding();

  print('+++++++++++++++++++++++++++++++++++');

  encodeCausalEntry();
  encodeCausalEntryWithAtom_HLC();
  encodeCausalEntryWithAtomLC_Only();
  encodeCausalEntryWithAtomLC_Only_Manually();
}

void radix36Int() {
  for (var i = 0; i < 0xfff; i++) {
    var rad = i.toRadixString(36);
    print('$i:' + rad);
  }
}

@pragma('vm:prefer-inline')
int getByteLength(int data) {
  var l = data.bitLength;
  if (l > 24) return 4;
  if (l > 16) return 3;
  if (l > 8) return 2;
  return 1;
}

@pragma('vm:prefer-inline')
final minByte = (ByteData bd, int offset, int val) {
  if (val > 0xffffff) {
    bd.setUint32(offset, val);
    return 4;
  } else if (val > 0xffff) {
    bd.setUint16(offset++, val >> 8);
    bd.setUint8(offset, val & 0x0000ff);
    return 3;
  } else if (val > 0xff) {
    bd.setUint16(offset, val);
    return 2;
  }
  bd.setUint8(offset++, val);
  return 1;
};

void encodeCausalEntry() {
  var bytes;
  var copy;
  measureExecution('*** MSG *** Entry', () {
    bytes = msgpackEncode(entry);
    copy = msgpackDecode(bytes);
  });

  print(bytes.length);
}

void encodeCausalEntryWithAtom_HLC() {
  var bytes;
  var atomCopy;

  measureExecution('*** MSG ***  Entry/Atom_HLC', () {
    bytes = msgpackEncode(atomHlc);
    atomCopy = msgpackDecode(bytes);
  });

  print(bytes.length);
}

void encodeCausalEntryWithAtomLC_Only() {
  var bytes;
  var copy;

  measureExecution('*** MSG *** Entry With Atom LC', () {
    bytes = msgpackEncode(atomLC);
    copy = msgpackDecode(bytes);
  });

  print(bytes.length);
}

void encodeCausalEntryWithAtomLC_Only_Manually() {
  var bytes, copy;

  // only values
  measureExecution('*** ints *** Entry With Atom LC', () {
    bytes = msgpackEncode([
      atomId.ts.logicalTime,
      atomId.site,
      type,
      cuid,
      id.ts.logicalTime,
      id.site,
      cause.ts.logicalTime,
      cause.site,
      data
    ]);
    copy = msgpackDecode(bytes);
  });

  print(bytes.length);
}

void encodeCausalEntryManually() {
  var length;
  Uint8List ulist;

  measureExecution('xxx manually Entry', () {
    var itl = getByteLength(id.ts.counter);
    var isl = getByteLength(id.site);

    var ctl = getByteLength(id.ts.counter);
    var csl = getByteLength(id.site);

    final idl = itl << 6 | isl << 4 | ctl << 2 | csl;

    final dataBytes = msgpackEncode(data);
    length = 1 + itl + isl + ctl + csl + dataBytes.length;

    ulist = Uint8List(length);
    var i = 0;
    ulist[i++] = idl;

    /// encode
  });

  print(ulist.length);
}

void encodeAtomWithoutMSGSubTypes() {
  var msgBytes, length, msg, copy;

  ByteData bd;

  /// only encode
  measureExecution('--- Atom Without MSG Sub Types ', () {
    msgBytes = msgpackEncode(data);
    length = 8 + 2 + 2 + cuid.length + msgBytes.length;

    bd = ByteData(length);

    bd.setUint64(0, atomIdHlc.ts.logicalTime);
    bd.setUint16(8, atomIdHlc.site);
    bd.setUint16(10, atomHlc.type);
    bd.buffer.asUint8List().setAll(12, cuid.codeUnits);
    bd.buffer.asUint8List().setAll(12 + cuid.length, msgBytes);

    msg = bd.buffer.asUint8List().sublist(12 + cuid.length);
    copy = msgpackDecode(msg);
  });

  print(bd.buffer.lengthInBytes);
}

void encodeCausalEntryMinEncoding() {
  /// max header size
  final bd = ByteData(64);
  var bytes;

  var offset = 3;
  measureExecution('--- encodeCausalEntryMinEncoding', () {
    /// atom id
    var l = minByte(bd, offset, atomLC.id.ts.counter);
    offset += l;
    final l2 = minByte(bd, offset, atomLC.id.site);
    offset += l2;

    final tl = minByte(bd, offset, atomLC.type);
    offset += tl;

    /// type
    // define length of each section of the atom id
    var code0 = (l - 1) << 6 | (l2 - 1) << 4 | tl - 1;
    bd.setInt8(0, code0);

    /// causalentry id
    var cl = minByte(bd, offset, id.ts.counter);
    offset += cl;
    final cl2 = minByte(bd, offset, id.site);
    offset += cl2;
    var code1;
    if (cause != null) {
      var cl3 = minByte(bd, offset, cause.ts.counter);
      offset += cl3;
      final cl4 = minByte(bd, offset, cause.site);
      offset += cl4;
      // define the cause ids size
      code1 = (cl - 1) << 6 | (cl2 - 1) << 4 | (cl3 - 1) << 2 | (cl4 - 1);
      bd.setInt8(1, code1);
    } else {
      code1 = (cl - 1) << 6 | (cl2 - 1) << 4;
      bd.setInt8(1, code1);
    }

    /// set cuid
    bd.setInt8(2, cuid.length);
    bd.buffer.asUint8List(offset).setAll(0, cuid.codeUnits);
    offset += cuid.length;
  });

  bytes = [offset] + bd.buffer.asUint8List(0, offset) + msgpackEncode(data);
  print(bytes.length);
}
