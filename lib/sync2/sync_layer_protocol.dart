import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:msgpack_dart/msgpack_dart.dart';
import 'package:sync_layer/basic/index.dart';
import 'package:sync_layer/crdts/atom.dart';
import 'package:sync_layer/sync2/abstract/sync_layer.dart';

import 'package:logger/logger.dart';

var logger = Logger(
    printer: PrettyPrinter(
        methodCount: 1, // number of method calls to be displayed
        errorMethodCount: 8, // number of method calls if stacktrace is provided
        lineLength: 120, // width of the output
        colors: true, // Colorful log messages
        printEmojis: true, // Print an emoji for each log message
        printTime: false // Should each log print contain a timestamp
        ));

enum MessageEnum {
  STATE,
  STATE_REQUEST,
  STATE_RESPONSE,
  ATOMS,
  NODE_NAME,
}

class EnDecoder {
  static Uint8List encodeAtoms(List<Atom> atoms, [MessageEnum msg = MessageEnum.ATOMS]) {
    final updateBytes = atoms.map((a) => a.toBytes()).toList();
    final buff = serialize(updateBytes);
    return Uint8List.fromList([msg.index, ...buff]);
  }

  static Uint8List encodeState(MerkleTrie state) {
    final buff = serialize(state.toMap());
    return Uint8List.fromList([MessageEnum.STATE.index, ...buff]);
  }

  static List<Atom> decodeAtoms(Uint8List buff) {
    List atomsBuff = deserialize(buff);
    return atomsBuff.map((b) => Atom.fromBytes(b)).toList();
  }

  static MerkleTrie decodeState(Uint8List buff) {
    Map trieMap = (deserialize(buff) as Map).cast<int, dynamic>();
    return MerkleTrie.fromMap(trieMap);
  }
}

class SyncLayerProtocol {
  final SyncLayer syn;
  final websockets = <WebSocket>{};
  final websocketsNames = <WebSocket, String>{};

  StreamSubscription atomSub;
  SyncLayerProtocol(this.syn) {
    // setup broadcast

    atomSub = syn.atomStream.listen((atoms) => broadCastAtoms(atoms));
  }

  void registerConnection(WebSocket ws) {
    websockets.add(ws);

    ws.listen(
      (rawData) => receiveBuffer(rawData, ws),
      onDone: () => unregisterConnection(ws),
      onError: (err) {
        unregisterConnection(ws);
        logger.e('[!]Error -- ${err.toString()}');
      },
      cancelOnError: true,
    );

    // Start sync process => send local State

    ws.add(Uint8List.fromList([MessageEnum.NODE_NAME.index, ...syn.nodeId.codeUnits]));
    ws.add(EnDecoder.encodeState(syn.getState()));
  }

  void unregisterConnection(WebSocket ws) {
    logger.d('Unregister Connection');
    websockets.remove(ws);
    websocketsNames.remove(ws);
  }

  void broadCastAtoms(List<Atom> atoms) {
    logger.d('broadCast Atoms');
    print('>>>>>>>>>>>>>>>> broadcast');
    print(atoms);
    final data = EnDecoder.encodeAtoms(atoms);

    for (final ws in websockets) {
      ws.add(data);
    }
  }

  void relayMessage(Uint8List data, WebSocket ws) {
    for (final _ws in websockets) {
      if (_ws != ws) {
        print('Relay DATA: ${websocketsNames[ws]} >>> ${websocketsNames[_ws]}');
        _ws.add(data);
      }
    }
  }

  void receiveBuffer(dynamic rawData, WebSocket ws) {
    if (rawData is Uint8List) {
      final msgType = rawData[0];
      final data = rawData.sublist(1);

      // if atoms
      if (msgType == MessageEnum.ATOMS.index) {
        logger.d(MessageEnum.ATOMS);

        final atoms = EnDecoder.decodeAtoms(data);
        print('<<<<<<<<<<<<<<<<<<<');
        print(atoms);
        syn.receiveAtoms(atoms);
        relayMessage(rawData, ws);
      } else

      /// if it is just an state reponse, add receiving atoms to SyncLayer
      /// but do not relay to all other connections..
      if (msgType == MessageEnum.STATE_RESPONSE.index) {
        logger.d(MessageEnum.STATE_RESPONSE);

        final atoms = EnDecoder.decodeAtoms(data);
        syn.receiveAtoms(atoms);
      } else

      // if a state incoming is send => send back the diffs
      if (msgType == MessageEnum.STATE.index) {
        logger.d(MessageEnum.STATE);
        final state = EnDecoder.decodeState(data);

        // syn.receiveState(state);
        final atoms = syn.getAtomsByReceivingState(state);

        ws.add(EnDecoder.encodeAtoms(atoms, MessageEnum.STATE_RESPONSE));
      } else

      // is a state request is issued
      if (msgType == MessageEnum.STATE_REQUEST.index) {
        logger.d(MessageEnum.STATE_REQUEST);

        final stateData = EnDecoder.encodeState(syn.getState());
        ws.add(stateData);
      } else
      // give name of node
      if (msgType == MessageEnum.NODE_NAME.index) {
        websocketsNames[ws] = String.fromCharCodes(rawData.sublist(1));
      }

      //
      else {
        logger.e('UNKOWN type $msgType');
      }
    } else {
      logger.e('incorrect type');
    }
  }
}
