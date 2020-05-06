import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';

import 'package:messagepack/messagepack.dart';
import 'package:sync_layer/basic/cuid.dart';

import 'package:sync_layer/basic/hlc.dart';
import 'package:sync_layer/crdts/atom.binar.dart';
import 'package:sync_layer/crdts/atom.dart';
import 'package:sync_layer/crdts/atom2.dart';

import 'package:sync_layer/utils/measure.dart';

import 'atom.binar2.dart';
import 'atombin/atom.pb.dart';

void simple() {
  final p = Packer();
  p.packInt(1);
  p.packInt(2);
  final bytes = p.takeBytes(); //Uint8List
  print(bytes);

  final u = Unpacker(bytes);
  final n1 = u.unpackInt();
  final n2 = u.unpackInt();
  print('unpacked n1=$n1 n2=$n2');
}

void differentTypesSimple() {
  final p = Packer();
  p.packInt(1);
  p.packBool(true);
  final bytes = p.takeBytes(); //Uint8List
  print(bytes);

  final u = Unpacker(bytes);
  print(u.unpackInt());
  print(u.unpackBool());
}

void iterableAndMap() {
  final list = ['i1', 'i2'];
  final map = {'k1': 11, 'k2': 22};
  final p = Packer();
  p.packListLength(list.length);
  list.forEach(p.packString);
  p.packMapLength(map.length);
  map.forEach((key, v) {
    p.packString(key);
    p.packInt(v);
  });
  final bytes = p.takeBytes();

  final u = Unpacker(bytes);
  final listLength = u.unpackListLength();
  for (int i = 0; i < listLength; i++) {
    print(u.unpackString());
  }
  final mapLength = u.unpackMapLength();
  for (int i = 0; i < listLength; i++) {
    print(u.unpackString());
    print(u.unpackInt());
  }
}

void differentTypesComplex() {
  final p = Packer()
    ..packInt(99)
    ..packBool(true)
    ..packString('hi')
    ..packNull()
    ..packString(null)
    ..packBinary(<int>[104, 105]) // hi codes
    ..packListLength(2) // pack 2 elements list ['elem1',3.14]
    ..packString('elem1')
    ..packDouble(3.14)
    ..packString('continue to pack other elements')
    ..packMapLength(2) //map {'key1':false, 'key2',3.14}
    ..packString('key1') //pack key1
    ..packBool(false) //pack value1
    ..packString('key12') //pack key1
    ..packDouble(3.13); //pack value1

  final bytes = p.takeBytes();
  final u = Unpacker(bytes);
  print(bytes);
  //Unpack the same sequential/streaming way
}

final ts = Hlc().logicalTime;
final id = newCuid();
final value = 'Hello world';
final nodeID = 12345667;
final type = 1;
final key = 1;

void measureProto() {
  print('-------------------');
  print('measureProto');
  AtomBin atom;
  AtomBin atomCopy;
  Uint8List buff;
  measureExecution('To Atom', () {
    atom = AtomBin()
      ..ts = Int64(ts)
      ..node = nodeID
      ..id = id
      ..type = type
      ..key = key
      ..s = value;
  });

  measureExecution('Proto toByte', () {
    buff = atom.writeToBuffer();
  });

  measureExecution('Proto from bytes', () {
    atomCopy = AtomBin.fromBuffer(buff);
  });

  print(atom);
  print(atomCopy);
  print(buff.length);

  measureExecution('Complete', () {
    atom = AtomBin()
      ..ts = Int64(ts)
      ..node = nodeID
      ..id = id
      ..type = type
      ..key = key
      ..s = value;

    buff = atom.writeToBuffer();

    atomCopy = AtomBin.fromBuffer(buff);
  });
}

void measureAtomBinar1() {
  print('-------------------');
  print('measureAtomBinar1');
  AtomBinary atom;
  AtomBinary atomCopy;
  Uint8List buff;

  final val = value;
  measureExecution('To Atom', () {
    atom = AtomBinary(ts, nodeID, type, id, key, val);
  });

  measureExecution('toBytes', () {
    buff = atom.toByte();
  });

  measureExecution('from bytes', () {
    atomCopy = AtomBinary.from(buff);
  });

  print(atom);
  print(atomCopy);
  print(buff.length);

  measureExecution('Complete', () {
    atom = AtomBinary(ts, nodeID, type, id, key, val);
    buff = atom.toByte();
    atomCopy = AtomBinary.from(buff);
  });
}

void measureAtomBinar2() {
  print('-------------------');
  print('measureAtomBinar2');
  AtomBinary2 atom;
  AtomBinary2 atomCopy;
  Uint8List buff;
  measureExecution('To Atom', () {
    atom = AtomBinary2(ts: ts, node: nodeID, type: type, id: id, key: key, value: value);
  });

  measureExecution('toBytes', () {
    buff = atom.toByte();
  });

  measureExecution('from bytes', () {
    atomCopy = AtomBinary2.fromBytes(buff);
  });

  print(atom);
  print(atomCopy);
  print(buff.length);

  measureExecution('Complete', () {
    atom = AtomBinary2(ts: ts, node: nodeID, type: type, id: id, key: key, value: value);
    buff = atom.toByte();
    atomCopy = AtomBinary2.fromBytes(buff);
  });
}

void measureAtomAtom() {
  print('-------------------');
  print('measureAtomAtom');
  Atom2 atom;
  Atom2 atomCopy;
  Uint8List buff;

  var hlc = Hlc.fromLogicalTime(ts, nodeID.toString());
  measureExecution('To Atom', () {
    atom = Atom2(ts: hlc, type: type, id: id, key: key, value: value);
  });

  measureExecution('toBytes', () {
    buff = atom.toBytes();
  });

  measureExecution('from bytes', () {
    atomCopy = Atom2.fromBytes(buff);
  });

  print(atom);
  print(atomCopy);
  print(buff.length);

  hlc = Hlc.fromLogicalTime(ts, nodeID.toString());
  measureExecution('Complete', () {
    atom = Atom2(ts: hlc, type: type, id: id, key: key, value: value);
    buff = atom.toBytes();
    atomCopy = Atom2.fromBytes(buff);
  });
}

void main() {
  measureProto();
  measureAtomBinar1();
  measureAtomBinar2();
  measureAtomAtom();
}
