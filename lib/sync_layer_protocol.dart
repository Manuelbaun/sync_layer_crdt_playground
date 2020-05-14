import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:sync_layer/basic/index.dart';
import 'package:sync_layer/sync/abstract/index.dart';
import 'package:sync_layer/types/index.dart';

import 'package:sync_layer/encoding_extent/endecode.dart';
import 'package:sync_layer/logger/index.dart';

import 'logger/index.dart';

enum MessageEnum { STATE, STATE_REQUEST, STATE_RESPONSE, ATOMS, NODE_NAME, NO_ATOMS }

void sendMsg(dynamic msg) {
  print('send: $msg');
}

void recvMsg(dynamic msg) {
  print('recv: $msg');
}

class SyncLayerProtocolEnDecoder {
  static Uint8List encodeAtoms(List<Atom> atoms, [MessageEnum msg = MessageEnum.ATOMS]) {
    final buff = msgpackEncode(atoms);
    final zipped = zlib.encode(buff);
    sendMsg('* Atoms: ${atoms.length} ::  b:${buff.length} => z:${zipped.length}');
    return Uint8List.fromList([msg.index, ...zipped]);
  }

  static Uint8List encodeState(MerkleTrie state) {
    final buff = msgpackEncode(state.toMap());
    final zipped = zlib.encode(buff);
    sendMsg('* State:::  b:${buff.length} => z:${zipped.length}');
    return Uint8List.fromList([MessageEnum.STATE.index, ...zipped]);
  }

  static List<Atom> decodeAtoms(Uint8List buff) {
    final unzipped = zlib.decode(buff);
    final atoms = msgpackDecode(unzipped);

    print('* recv Atom: ${atoms.length}:: z:${buff.length} =>  b:${unzipped.length}');

    return List<Atom>.from(atoms);
  }

  static MerkleTrie decodeState(Uint8List buff) {
    final unzipped = zlib.decode(buff);
    print('* recv State::: z:${buff.length} =>  b:${unzipped.length} ');
    Map trieMap = (msgpackDecode(unzipped) as Map).cast<int, dynamic>();
    return MerkleTrie.fromMap(trieMap);
  }
}

class SyncLayerProtocol {
  final SyncLayer syn;
  final websockets = <WebSocket>{};
  final websocketsNames = <WebSocket, String>{};

  StreamSubscription atomSub;
  SyncLayerProtocol(this.syn) {
    atomSub = syn.atomStream.listen((atoms) => broadCastAtoms(atoms));
  }

  void dispose() async {
    await atomSub.cancel();
  }

  void registerConnection(WebSocket ws) {
    websockets.add(ws);
    print('\n---------------------------------');
    print('<<<recv: >> Register Websocket');
    print('---------------------------------');

    ws.listen(
      (rawData) => receiveBuffer(rawData, ws),
      onDone: () => unregisterConnection(ws),
      onError: (err) {
        unregisterConnection(ws);
        logger.error('[!]Error -- ${err.toString()}');
      },
      cancelOnError: true,
    );

    // Start sync process => send local State
    sendMsg('MessageEnum.NODE_NAME');
    ws.add(Uint8List.fromList([MessageEnum.NODE_NAME.index, syn.site]));

    sendMsg('MessageEnum.STATE');
    ws.add(SyncLayerProtocolEnDecoder.encodeState(syn.getState()));
  }

  void unregisterConnection(WebSocket ws) {
    logger.debug('Unregister Connection');
    ws.close();
    websockets.remove(ws);
    websocketsNames.remove(ws);
  }

  void disconnectFromAll() {
    websockets.forEach((ws) {
      ws.close();
    });

    websockets.clear();
  }

  void broadCastAtoms(List<Atom> atoms) {
    final data = SyncLayerProtocolEnDecoder.encodeAtoms(atoms);
    sendMsg('MessageEnum.ATOMS Broadcast');

    for (final ws in websockets) {
      ws.add(data);
    }
  }

  void relayMessage(Uint8List data, WebSocket ws) {
    for (final _ws in websockets) {
      if (_ws != ws) {
        _ws.add(data);
      }
    }
  }

  void receiveBuffer(dynamic rawData, WebSocket ws) {
    if (rawData is Uint8List) {
      final msgType = rawData[0];
      final data = rawData.sublist(1);

      if (msgType == MessageEnum.NO_ATOMS.index) {
        recvMsg('MessageEnum.NO_ATOMS');
      } else

      // if atoms
      if (msgType == MessageEnum.ATOMS.index) {
        recvMsg('MessageEnum.ATOMS');
        final atoms = SyncLayerProtocolEnDecoder.decodeAtoms(data);
        syn.receiveAtoms(atoms);
        sendMsg('MessageEnum.ATOMS relay');

        relayMessage(rawData, ws);
      } else

      /// if it is just an state reponse, add receiving atoms to SyncLayer
      /// but do not relay to all other connections..
      if (msgType == MessageEnum.STATE_RESPONSE.index) {
        recvMsg('MessageEnum.STATE_RESPONSE');

        final atoms = SyncLayerProtocolEnDecoder.decodeAtoms(data);
        syn.receiveAtoms(atoms);

        /// normally state response should not be relayed
        /// send to all online people, there are news online!
        relayMessage(rawData, ws);
      } else

      // if a state incoming is send recv:  send back the diffs
      if (msgType == MessageEnum.STATE.index) {
        recvMsg('MessageEnum.STATE');

        final state = SyncLayerProtocolEnDecoder.decodeState(data);
        final atoms = syn.getAtomsByReceivingState(state);

        if (atoms.isNotEmpty) {
          sendMsg('MessageEnum.STATE_RESPONSE');
          ws.add(SyncLayerProtocolEnDecoder.encodeAtoms(atoms, MessageEnum.STATE_RESPONSE));
        } else {
          sendMsg('MessageEnum.NO_ATOMS');
          ws.add([MessageEnum.NO_ATOMS.index]);
        }
      } else

      // is a state request is issued
      if (msgType == MessageEnum.STATE_REQUEST.index) {
        recvMsg('MessageEnum.STATE_REQUEST');

        final stateData = SyncLayerProtocolEnDecoder.encodeState(syn.getState());
        sendMsg('MessageEnum.STATE');
        ws.add(stateData);
      } else
      // give name of node
      if (msgType == MessageEnum.NODE_NAME.index) {
        recvMsg('MessageEnum.NODE_NAME');

        websocketsNames[ws] = String.fromCharCodes(rawData.sublist(1));
      }

      //
      else {
        logger.error('UNKOWN type $msgType');
      }
    } else {
      logger.error('incorrect type');
    }
  }
}
