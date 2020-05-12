import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';
import 'package:sync_layer/timestamp/index.dart';
import 'package:sync_layer/basic/index.dart';
import 'package:sync_layer/utils/measure.dart';

import 'atom.binar2.dart';
import 'atombin/atom.pb.dart';

final ts = Hlc(null, 0, 1234).logicalTime;
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

void main() {
  measureProto();
  measureAtomBinar2();
}
