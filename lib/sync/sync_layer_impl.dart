import 'dart:async';

import 'package:sync_layer/basic/cuid.dart';
import 'package:sync_layer/basic/merkle_tire.dart';
import 'package:sync_layer/types/abstract/atom_base.dart';
import 'package:sync_layer/types/id_atom.dart';

import 'package:sync_layer/types/index.dart';
import 'package:sync_layer/errors/index.dart';
import 'package:sync_layer/logger/index.dart';
import 'package:sync_layer/sync_layer_atom_cache.dart';
import 'abstract/index.dart';
import 'abstract/syncable_base.dart';
import 'sync_accessor_impl.dart';
import 'sync_clock_impl.dart';
import 'syncable_object_container_impl.dart';

class StringNumberMapper {
  final type2Id = <String, int>{};
  final id2type = <int, String>{};
  var containerCounter = 0;

  /// converts all to lower case
  int registerNewTypeName(String typeName, [int customNumber]) {
    final name = typeName.toLowerCase();
    if (type2Id[name] == null) {
      var number = customNumber ?? containerCounter;
      type2Id[name] = number;
      id2type[number] = name;
      containerCounter++;
      return number;
    } else {
      throw AssertionError('The type $typeName is already registered');
    }
  }

  String getTypeName(int type) {
    return id2type[type];
  }

  int getTypeNumber(String typeName) {
    return type2Id[typeName.toLowerCase()];
  }

  bool containsTypeName(String typeName) => type2Id.containsKey(typeName);
  bool containsNumber(String typeNumber) => id2type.containsKey(typeNumber);
}

class SyncLayerImpl implements SyncLayer {
  final SyncLayerAtomCache atomCache = SyncLayerAtomCache();
  final Map<int, SyncableObjectContainer> containers = <int, SyncableObjectContainer>{};

  @override
  int site;

  final Clock clock;
  final MerkleTrie trie;

  /// only for sending Atoms => Network, not internally!
  final _atomStreamController = StreamController<List<AtomBase>>.broadcast();

  @override
  Stream<List<AtomBase>> get atomStream => _atomStreamController.stream;

  @override
  MerkleTrie getState() => trie;

  SyncLayerImpl(this.site, [MerkleTrie trie])
      : clock = Clock(site),
        trie = trie ?? MerkleTrie();

  /// accessors and utils
  /// use either typeName or typeNumber
  /// in case of both, it throws a conflict
  @override
  SyncableObjectContainer<T> getObjectContainer<T extends SyncableBase>({String typeName, int typeNumber}) {
    if (typeName != null && typeName.isNotEmpty && typeNumber != null) {
      throw AssertionError('Unclear intention. TypeName $typeName and TypeNumber $typeNumber are set.');
    }

    var n = typeNumber;

    if (typeName != null && typeName.isNotEmpty) {
      n = mapper.getTypeNumber(typeName);
    }

    return containers[n] as SyncableObjectContainer<T>;
  }

  /// this registers a syncable type and returns the container for it
  /// which provides basic crud
  StringNumberMapper mapper = StringNumberMapper();

  @override
  SyncableObjectContainer<T> registerObjectType<T extends SyncableBase>(
      String typeName, SynableObjectFactory<T> objectFactory,
      [int customNumberId]) {
    SyncableObjectContainer container;

    if (!mapper.containsTypeName(typeName)) {
      final typeNumber = mapper.registerNewTypeName(typeName);

      AccessProxy proxy = SynclayerAccessor(this, typeNumber);

      container = SyncableObjectContainerImpl<T>(
        proxy,
        objectFactory,
      );

      containers[typeNumber] = container;
    } else {
      throw SyncLayerError('Container with typeName $typeName already exist.');
    }

    return container;
  }

  ///
  @override
  String generateID() => newCuid();

  /// Work with Atoms
  ///
  void _applyAtoms(List<AtomBase> atoms) {
    final changedContainer = <SyncableObjectContainer>{};

    for (final atom in atoms) {
      /// can just add to cache and returns true/false depending if exist or not
      if (!atomCache.exist(atom)) {
        // test if table exits
        final container = getObjectContainer(typeNumber: atom.typeId);

        if (container != null) {
          // if row does not exist, new row will be added
          var obj = container.read(atom.objectId);
          obj ??= container.create(atom.objectId);

          final res = obj.applyAtom(atom);

          // if successfull applied, => trigger!
          if (res == 2) {
            // todo trigger! container /object update
            container.setUpdatedObject(obj);
            changedContainer.add(container);
          }
          // in any case,
          atomCache.add(atom);
          trie.build([atom.id]);
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

  /// Todo: think again: Work with local Atoms
  ///
  // void _applyLocalAtom(List<AtomBase> atoms) {
  //   final changedContainer = <SyncableObjectContainer>{};

  //   for (final atom in atoms) {
  //     /// can just add to cache and returns true/false depending if exist or not
  //     if (atomCache.add(atom)) {
  //       // test if table exits
  //       // final container = getObjectContainer(typeNumber: atom.typeId);
  //       trie.build([atom.id]);
  //       // if (res == 2) {
  //       //   // todo trigger! container /object update
  //       //   container.setUpdatedObject(obj);
  //       //   changedContainer.add(container);
  //       // }

  //     } // else skip that message
  //   }

  //   // Tigger the changed happend in synclayer
  //   for (final con in changedContainer) {
  //     con.triggerUpdateChange();
  //   }
  // }

  @override
  AtomBase createAtom(String objectId, int typeId, dynamic data) {
    final id = AtomId(clock.getForSend(), site);
    return Atom(id, typeId, objectId, data);
  }

  /// [applyAtoms] should only be called from the local application.
  /// So do changes by adding apply Atoms,
  /// use Transaction to apply first, which then applies all made changes and
  /// sends via network
  @override
  void applyAtoms(List<AtomBase> atoms) {
    if (_transactionActive) {
      _transationList.addAll(atoms);
    } else {
      // could be changed?
      _applyAtoms(atoms);
      _atomStreamController.add(atoms);
    }
  }

  // Optimizers
  final _transationList = <AtomBase>[];
  bool _transactionActive = false;

  @override
  void transaction(Function func) {
    _transactionActive = true;
    func();
    // send transationList
    _transactionActive = false;

    /// TODO: should it be copying the refs
    _applyAtoms([..._transationList]);
    _transationList.clear();
  }

  /// Network communication
  ///

  /// update local clock and apply atoms
  @override
  void receiveAtoms(List<AtomBase> atoms) {
    for (var atom in atoms) {
      clock.fromReceive(atom.id.ts);
    }

    _applyAtoms(atoms);
  }

  List<AtomBase> getAtomsSinceMs(HybridLogicalClock clock) {
    return atomCache.getSince(clock);
  }

  /// These are workarounds
  /// get ts diff and send it back to requestee
  /// TODO: check siteid of '0' => what site idee should be there?
  @override
  List<AtomBase> getAtomsByReceivingState(MerkleTrie remoteState) {
    final tsKey = trie.diff(remoteState);
    if (tsKey != null) {
      final ms = clock.getClockFromTSKey(tsKey, 0);
      logger.verbose(ms.toString());
      return getAtomsSinceMs(ms);
    }
    // send empty
    return [];
  }
}
