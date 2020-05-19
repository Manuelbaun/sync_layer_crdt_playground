import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:sync_layer/basic/index.dart';
import 'package:sync_layer/sync/abstract/index.dart';
import 'package:sync_layer/types/abstract/atom_base.dart';

import 'package:sync_layer/encoding_extent/index.dart';
import 'package:sync_layer/logger/index.dart';

import 'logger/index.dart';

enum _ProtocolHeaders {
  STATE,
  STATE_REQUEST,
  STATE_RESPONSE,
  ATOMS,
  NODE_NAME,
  NO_ATOMS,
}

class _EnDecoder {
  static Uint8List encodeAtoms(List<AtomBase> atoms) {
    final buff = msgpackEncode(atoms);
    final zipped = zlib.encode(buff);
    logger.verbose('⏫ send Atoms::: ${atoms.length} ::  b:${buff.length} => z:${zipped.length}');
    return zipped;
  }

  static List<AtomBase> decodeAtoms(Uint8List buff) {
    final unzipped = zlib.decode(buff);
    final atoms = msgpackDecode(unzipped);
    logger.verbose('🔻 recv Atom: ${atoms.length}:: z:${buff.length} =>  b:${unzipped.length}');
    return List<AtomBase>.from(atoms);
  }

  static Uint8List encodeState(MerkleTrie state) {
    final buff = msgpackEncode(state);
    final zipped = zlib.encode(buff);
    logger.verbose('⏫ send State:::  b:${buff.length} => z:${zipped.length}');
    return zipped;
  }

  static MerkleTrie decodeState(Uint8List buff) {
    final unzipped = zlib.decode(buff);
    logger.verbose('🔻 recv State::: z:${buff.length} =>  b:${unzipped.length} ');
    MerkleTrie trie = msgpackDecode(unzipped);
    return trie;
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
    logger.info('---------------------------------\n'
        ' <<< Register Websocket >>> \n'
        '---------------------------------');

    ws.listen(
      (rawData) => receiveBuffer(rawData, ws),
      onDone: () => unregisterConnection(ws),
      onError: (err) {
        unregisterConnection(ws);
        logger.error(err.toString());
      },
      cancelOnError: true,
    );

    // Start sync process => send local State
    logger.info('send:MessageEnum.NODE_NAME');
    ws.add(Uint8List.fromList([_ProtocolHeaders.NODE_NAME.index, syn.site]));

    logger.info('send:MessageEnum.STATE');

    final buff = _EnDecoder.encodeState(syn.getState());
    ws.add([_ProtocolHeaders.STATE.index, ...buff]);
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

  void broadCastAtoms(List<AtomBase> atoms) {
    final data = _EnDecoder.encodeAtoms(atoms);
    logger.info('send:MessageEnum.ATOMS Broadcast');

    for (final ws in websockets) {
      ws.add([_ProtocolHeaders.ATOMS.index, ...data]);
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
      final header = _ProtocolHeaders.values[rawData[0]];
      logger.info('🔻 ${header}');

      final data = rawData.sublist(1);

      switch (header) {
        case _ProtocolHeaders.STATE:
          final state = _EnDecoder.decodeState(data);
          final atoms = syn.getAtomsByReceivingState(state);

          if (atoms.isNotEmpty) {
            logger.info('⏫ :MessageEnum.STATE_RESPONSE');
            final msg = [_ProtocolHeaders.STATE_RESPONSE.index, ..._EnDecoder.encodeAtoms(atoms)];
            ws.add(msg);
          } else {
            logger.info('⏫ MessageEnum.NO_ATOMS');
            ws.add([_ProtocolHeaders.NO_ATOMS.index]);
          }
          break;
        case _ProtocolHeaders.STATE_REQUEST:
          final buff = _EnDecoder.encodeState(syn.getState());
          logger.info('⏫ MessageEnum.STATE');
          ws.add([_ProtocolHeaders.STATE.index, ...buff]);
          break;
        case _ProtocolHeaders.STATE_RESPONSE:
          final atoms = _EnDecoder.decodeAtoms(data);
          syn.receiveAtoms(atoms);

          /// normally state response should not be relayed
          /// send to all online people, there are news online!
          relayMessage(rawData, ws);
          break;
        case _ProtocolHeaders.ATOMS:
          final atoms = _EnDecoder.decodeAtoms(data);
          syn.receiveAtoms(atoms);
          logger.info('⏫ MessageEnum.ATOMS relay');
          relayMessage(rawData, ws);
          break;
        case _ProtocolHeaders.NODE_NAME:
          websocketsNames[ws] = String.fromCharCodes(rawData.sublist(1));
          break;
        case _ProtocolHeaders.NO_ATOMS:
          // todo?
          break;
        default:
          logger.error('UNKOWN type $header');
      }
    } else {
      logger.error('incorrect type');
    }
  }
}
