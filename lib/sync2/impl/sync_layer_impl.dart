import 'package:sync_layer/basic/cuid.dart';
import 'package:sync_layer/basic/merkle_tire_node.dart';
import 'package:sync_layer/crdts/atom.dart';
import 'package:sync_layer/crdts/clock.dart';
import 'package:sync_layer/sync2/abstract/index.dart';
import 'package:sync_layer/sync2/errors/index.dart';
import 'package:sync_layer/sync2/impl/syncable_object_container_impl.dart';

import '../sync_layer_atom_cache.dart';
import '../sync_layer_protocol.dart';

class SyncLayerImpl implements SyncLayer {
  final Map<String, SyncableObjectContainer> containers = <String, SyncableObjectContainer>{};
  final SyncLayerAtomCache atomCache = SyncLayerAtomCache();
  final SyncLayerProtocol protocol;

  final String nodeId;
  final Clock clock;
  final MerkleTrie trie;

  SyncLayerImpl(this.nodeId, this.protocol, [MerkleTrie trie])
      : clock = Clock(nodeId),
        trie = trie ?? MerkleTrie() {
    //setup listeners
    protocol.incomingNetworkStream.listen(_incomingStream);
  }

  void _incomingStream(MessageType msg) {
    switch (msg.type) {
      case MessageEnum.ATOMS:
        _receiveAtoms(msg.values);
        break;
      case MessageEnum.STATE:
        _receiveState(msg.values);
        break;
      default:
        print("unknown type");
    }
  }

  /// accessors and utils

  @override
  SyncableObjectContainer<T> getObjectContainer<T extends SyncableObject>(String typeId) =>
      containers[typeId.toLowerCase()] as SyncableObjectContainer<T>;

  /// this registers a syncable type and returns the container for it
  /// which provides basic crud
  @override
  SyncableObjectContainer<T> registerObjectType<T extends SyncableObject>(
      String typeId, SynableObjectFactory<T> objectFactory) {
    final container = SyncableObjectContainerImpl<T>(this, typeId, objectFactory);

    _setContainer(container);
    return container;
  }

  /// This function registers a container
  @override
  void registerContainer(SyncableObjectContainer cont) {
    _setContainer(cont);
  }

  void _setContainer(SyncableObjectContainer cont) {
    if (containers[cont.typeId] == null) {
      containers[cont.typeId] = cont;
    } else {
      throw SyncLayerError('Container with typeId ${cont.typeId} already exist $cont');
    }
  }

  ///
  @override
  String generateID() => newCuid();

  /// Work with Atoms

  void _applyAtoms(List<Atom> atoms) {
    for (final atom in atoms) {
      if (!atomCache.exist(atom)) {
        // test if table exits
        final container = getObjectContainer(atom.type);

        if (container != null) {
          // if row does not exist, new row will be added
          final obj = container.read(atom.id);
          final res = obj.applyAtom(atom);

          // based on the result..
          if (res > 0) {
            if (res == 2) {
              // todo trigger!
            }

            atomCache.add(atom);
            trie.build([atom.ts]);
          } else {
            print('Two Timestamps have the exact same logicaltime on two different nodes! $atom');
          }
        } else {
          print('Table does not exist');
          // Todo: Throw error

        }
      } // else skip that message
    }
  }

  @override
  Atom createAtom(String typeId, String objectId, String fieldId, dynamic value) {
    return Atom(clock.getForSend(), typeId, objectId, fieldId, value);
  }

  @override
  void applyAtoms(List<Atom> atoms) {
    _applyAtoms(atoms);
    _sendAtoms(atoms);
  }

  // Optimizers
  final transationList = <Atom>[];

  @override
  void transaction(Function func) {
    // so something
    func();
    // revert something
    // send transationList
  }

  /// Network communication
  /// update local clock and apply atoms
  void _receiveAtoms(List<Atom> atoms) {
    for (var atom in atoms) {
      clock.fromReveive(atom.ts);
    }

    _applyAtoms(atoms);
  }

  /// send via network
  void _sendAtoms(List<Atom> atoms, [int sinceInMilliseconds]) async {
    var _atoms = atoms ?? [];

    if (sinceInMilliseconds != null && sinceInMilliseconds != 0) {
      var ts = clock.getHlc(sinceInMilliseconds, 0, nodeId);
      _atoms = atomCache.getSince(ts.logicalTime);
    }

    if (_atoms.isNotEmpty) {
      protocol.sendAtoms(_atoms);
    }
  }

  /// get ts diff and send it back to requestee
  void _receiveState(Map<int, dynamic> remoteState) {
    final remoteTrie = MerkleTrie.fromMap(remoteState);

    final tsKey = trie.diff(remoteTrie);
    final ms = clock.tsKeyToMillisecond(tsKey);
    _sendAtoms(null, ms);
  }
}
