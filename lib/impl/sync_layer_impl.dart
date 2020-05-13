import 'dart:async';

import 'package:sync_layer/basic/cuid.dart';
import 'package:sync_layer/basic/merkle_tire_node.dart';
import 'package:sync_layer/crdts/atom.dart';
import 'package:sync_layer/crdts/clock.dart';
import 'package:sync_layer/abstract/index.dart';

import 'package:sync_layer/errors/index.dart';
import 'package:sync_layer/impl/syncable_object_container_impl.dart';
import 'package:sync_layer/logger/index.dart';
import 'package:sync_layer/sync_layer_atom_cache.dart';

class SyncLayerImpl implements SyncLayer {
  final Map<String, SyncableObjectContainer> containers = <String, SyncableObjectContainer>{};
  final SyncLayerAtomCache atomCache = SyncLayerAtomCache();

  final containerAccessor = <String, ContainerAccessor>{};

  @override
  int site;

  final Clock clock;
  final MerkleTrie trie;

  // only for sending Atoms => Network, not internally!
  final _atomStreamController = StreamController<List<Atom>>.broadcast();

  @override
  Stream<List<Atom>> get atomStream => _atomStreamController.stream;

  @override
  MerkleTrie getState() => trie;

  SyncLayerImpl(this.site, [MerkleTrie trie])
      : clock = Clock(site),
        trie = trie ?? MerkleTrie();

  /// accessors and utils

  @override
  SyncableObjectContainer<T> getObjectContainer<T extends SyncableObject>(String typeId) =>
      containers[typeId.toLowerCase()] as SyncableObjectContainer<T>;

  /// this registers a syncable type and returns the container for it
  /// which provides basic crud
  @override
  SyncableObjectContainer<T> registerObjectType<T extends SyncableObject>(
      String typeId, SynableObjectFactory<T> objectFactory) {
    SyncableObjectContainer container = SyncableObjectContainerImpl<T>(this, typeId, objectFactory);

    containerAccessor[container.typeId] = ContainerAccessorImpl(this, container);

    _setContainer(container);
    return container;
  }

  /// This function registers a container
  @override
  void registerContainer(SyncableObjectContainer cont) {
    _setContainer(cont);
  }

  void _setContainer(SyncableObjectContainer container) {
    if (containers[container.typeId] == null) {
      containers[container.typeId] = container;
    } else {
      throw SyncLayerError('Container with typeId ${container.typeId} already exist $container');
    }
  }

  ///
  @override
  String generateID() => newCuid();

  /// Work with Atoms
  ///
  void _applyAtoms(List<Atom> atoms) {
    final changedContainer = <SyncableObjectContainer>{};

    for (final atom in atoms) {
      if (!atomCache.exist(atom)) {
        // test if table exits
        final container = getObjectContainer(atom.value.type);

        if (container != null) {
          // if row does not exist, new row will be added
          var obj = container.read(atom.value.id);
          obj ??= container.create(atom.value.id);

          final res = obj.applyAtom(atom);

          // based on the result..
          if (res > 0) {
            if (res == 2) {
              // todo trigger! container /object update
              container.setUpdatedObject(obj);
              changedContainer.add(container);
            } else {
              // do not trigger, because those are older values
            }

            atomCache.add(atom);
            trie.build([atom.clock]);
          } else {
            logger.error('Two Timestamps have the exact same logicaltime on two different nodes! $atom');
          }
        } else {
          logger.error('Table does not exist');
        }
      } // else skip that message
    }

    // Tigger the changed happend in synclayer
    for (final con in changedContainer) {
      con.triggerUpdateChange();
    }
  }

  @override
  Atom createAtom(dynamic value) {
    return Atom(clock.getForSend(), value);
  }

  /// [applyAtoms] should only be called from the local application.
  /// So do changes by adding apply Atoms,
  /// use Transaction to apply first, which then applies all made changes and
  /// sends via network
  @override
  void applyAtoms(List<Atom> atoms) {
    if (transactionActive) {
      transationList.addAll(atoms);
    } else {
      // could be changed?
      _applyAtoms(atoms);
      _atomStreamController.add(atoms);
    }
  }

  // Optimizers
  final transationList = <Atom>[];
  bool transactionActive = false;
  @override
  void transaction(Function func) {
    transactionActive = true;
    func();
    // send transationList
    transactionActive = false;
    applyAtoms([...transationList]);
    transationList.clear();
  }

  /// Network communication
  ///

  /// update local clock and apply atoms
  @override
  void receiveAtoms(List<Atom> atoms) {
    for (var atom in atoms) {
      clock.fromReveive(atom.clock);
    }

    _applyAtoms(atoms);
  }

  List<Atom> getAtomsSinceMs(int ms) {
    if (ms != null && ms != 0) {
      var ts = clock.getHlc(ms, 0, site);
      return atomCache.getSince(ts.counter);
    }
    return [];
  }

  /// These are workarounds
  /// get ts diff and send it back to requestee
  @override
  List<Atom> getAtomsByReceivingState(MerkleTrie remoteState) {
    final tsKey = trie.diff(remoteState);
    if (tsKey != null) {
      final ms = clock.tsKeyToMillisecond(tsKey);
      return getAtomsSinceMs(ms);
    }
    return [];
  }
}
