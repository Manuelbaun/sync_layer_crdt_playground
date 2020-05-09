import 'dart:async';
import 'dart:typed_data';

import 'package:msgpack_dart/msgpack_dart.dart';
import 'package:sync_layer/crdts/atom.dart';

enum MessageEnum {
  STATE,
  ATOMS,
}

class MessageType {
  final MessageEnum type;
  final dynamic values;
  MessageType(this.type, this.values);
}

class SyncLayerProtocol {
  final _incomingController = StreamController<MessageType>();
  Stream<MessageType> get incomingNetworkStream => _incomingController.stream;



  Uint8List _serializeAtoms(List<Atom> atoms) {
    final updateBytes = atoms.map((a) => a.toBytes()).toList();
    final buff = serialize(updateBytes);
    return Uint8List.fromList([MessageEnum.ATOMS.index, ...buff]);
  }

  List<Atom> _deserializeAtoms(Uint8List buff) {
    List<Uint8List> atomsBuff = deserialize(buff);
    return atomsBuff.map((b) => Atom.fromBytes(b)).toList();
  }

  Uint8List _serializeState(List<Atom> atoms) {
    // final updateBytes = atoms.map((a) => a.toBytes()).toList();
    // final buff = serialize(updateBytes);
    // return Uint8List.fromList([MessageType.ATOMS.index, ...buff]);
  }

  List<Atom> _deserializeState(Uint8List buff) {
    // List atomsBuff = deserialize(buff);
    // return atomsBuff.map((b) => Atom.fromBytes(b)).toList();
  }

  void sendAtoms(List<Atom> atoms) {
    final buff = _serializeAtoms(atoms);
    sendBuffer(buff);
  }

  void sendBuffer(Uint8List buff) {
    /// tODO: send
  }

  receiveBuffer(Uint8List buff) {
    final msgType = buff[0];
    final data = buff.sublist(1);

    if (msgType == MessageEnum.ATOMS.index) {
      final atoms = _deserializeAtoms(data);
      _incomingController.add(MessageType(MessageEnum.ATOMS, atoms));
    }

    if (msgType == MessageEnum.STATE.index) {
      final state = _deserializeState(data);
      _incomingController.add(MessageType(MessageEnum.STATE, state));
    }
  }
}
