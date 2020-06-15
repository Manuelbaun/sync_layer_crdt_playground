import 'dart:async';

import 'package:sync_layer/basic/cuid.dart';
import 'package:sync_layer/basic/merkle_tire.dart';
import 'package:sync_layer/types/abstract/atom_base.dart';

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

class SynchronizerImpl implements Synchronizer {
  SynchronizerImpl(this.site, [MerkleTrie trie])
      : _clock = Clock(site),
        _trie = trie ?? MerkleTrie();

  final SyncLayerAtomCache atomCache = SyncLayerAtomCache();
  final Map<int, SyncableObjectContainer> containers = <int, SyncableObjectContainer>{};

  @override
  final int site;
  final Clock _clock;

  /// only for sending Atoms => Network, not internally!
  /// This steams the atoms, to all websockets
  @override
  Stream<List<AtomBase>> get atomStream => _atomStreamController.stream;
  final _atomStreamController = StreamController<List<AtomBase>>.broadcast();

  @override
  MerkleTrie getState() => _trie;
  final MerkleTrie _trie;

  /// this registers a syncable type and returns the container for it
  /// which provides basic crud
  StringNumberMapper mapper = StringNumberMapper();

  /// accessors and utils use either typeName [OR] typeNumber
  /// in case of both, it throws a conflict
  @override
  SyncableObjectContainer<T> getObjectContainer<T extends SyncableBase>({
    String typeName,
    int typeNumber,
  }) {
    if (typeName != null && typeName.isNotEmpty && typeNumber != null) {
      throw AssertionError('Unclear intention. '
          'TypeName $typeName and TypeNumber $typeNumber are set.');
    }

    if (typeName != null && typeName.isNotEmpty) {
      typeNumber = mapper.getTypeNumber(typeName);
    }

    return containers[typeNumber] as SyncableObjectContainer<T>;
  }

  @override
  SyncableObjectContainer<T> registerObjectType<T extends SyncableBase>(
    String typeName,
    SynableObjectFactory<T> objectFactory, [
    int customNumberId,
  ]) {
    SyncableObjectContainer container;

    if (!mapper.containsTypeName(typeName)) {
      final typeNumber = mapper.registerNewTypeName(typeName);

      AccessProxy proxy = SynclayerAccessor(this, typeNumber);
      container = SyncableObjectContainerImpl<T>(proxy, objectFactory);
      containers[typeNumber] = container;
    } else {
      throw SyncLayerError('Container with typeName $typeName already exist.');
    }

    return container;
  }

  /// generated new Object Ids
  @pragma('vm:prefer-inline')
  @override
  String generateNewObjectIds() => newCuid();

  /// merge remote Atoms
  void _applyRemoteAtoms(List<AtomBase> atoms) {
    for (final atom in atoms) {
      /// can just add to cache and returns true/false depending if exist or not
      if (!atomCache.exist(atom)) {
        // test if table exits
        final container = getObjectContainer(typeNumber: atom.type);

        if (container != null) {
          // if row does not exist, new row will be added
          var obj = container.read(atom.objectId);
          obj ??= container.create(atom.objectId);

          final res = obj.applyRemoteAtom(atom);

          // if successfull applied, => trigger!
          if (res == 2) _setContainerEvent(atom.type, atom.objectId);

          // in any case,
          atomCache.add(atom);
          _trie.build([atom.id]);
        } else {
          throw AssertionError('unsupported ObjectContainer of type : ${atom.type}');
        }
      } // else skip that message
    }

    // Tigger the changed happend in synclayer
    _triggerAllEvents();
  }

  final _toUpdateContainerAndObjId = <int, Set<String>>{};

  void _setContainerEvent(int type, String objectId) {
    _toUpdateContainerAndObjId[type] ??= <String>{};
    _toUpdateContainerAndObjId[type].add(objectId);
  }

  void _triggerAllEvents() {
    for (final e in _toUpdateContainerAndObjId.entries) {
      final container = getObjectContainer(typeNumber: e.key);

      for (final id in e.value) {
        container.setUpdatedObject(id);
      }

      container.triggerUpdateChange();
    }

    _toUpdateContainerAndObjId.clear();
  }

  /// ### [applyLocalAtoms]
  ///
  /// Handles local atoms:
  /// 1. adds the atoms to the atomCache
  /// 2. and builds the trie
  /// 3. triggers which tables and OBject ids changed
  /// 4. sends all atoms via the Stream
  /// then
  @override
  void applyLocalAtoms(List<AtomBase> atoms) {
    // check if transation is active
    if (_transactionActive) {
      _transationList.addAll(atoms);
    } else {
      for (final atom in atoms) {
        // can just add to cache and returns true/false depending if exist or not
        if (atomCache.add(atom)) {
          _trie.build([atom.id]);
          _setContainerEvent(atom.type, atom.objectId);
        } else {
          logger.error('two messages in apply local Atoms?');
        }
      }

      // Send to the network!
      _triggerAllEvents();

      if (atoms.isEmpty) {
        logger.warning(
            '==> Empty Atom list! This happens, when transaction function result in no atoms. Sending is not happening');
      } else {
        // Send to the network!
        _atomStreamController.add(atoms);
      }
    }
  }

  @override
  AtomBase createAtom(int typeId, String objectId, dynamic data) {
    final atomId = Id(_clock.getForSend(), site);
    return Atom(atomId, typeId, objectId, data);
  }

  /// [applyRemoteAtoms] should only be called for the remote incoming atoms
  @override
  void applyRemoteAtoms(List<AtomBase> atoms) {
    for (var atom in atoms) {
      _clock.fromReceive(atom.id.ts);
    }

    _applyRemoteAtoms(atoms);
  }

  // Optimizers
  final _transationList = <AtomBase>[];
  bool _transactionActive = false;

  @override
  void transation(Function func) {
    _transactionActive = true;
    func();
    _transactionActive = false;

    applyLocalAtoms([..._transationList]);
    _transationList.clear();
  }

  /// Network communication

  List<AtomBase> getAtomsSinceMs(HybridLogicalClock clock) {
    return atomCache.getSince(clock);
  }

  /// These are workarounds
  /// get ts diff and send it back to requestee
  /// TODO: check siteid of '0' => what site idee should be there?
  @override
  List<AtomBase> getAtomsByReceivingState(MerkleTrie remoteState) {
    final tsKey = _trie.diff(remoteState);
    if (tsKey != null) {
      final ms = _clock.getClockFromTSKey(tsKey, 0);
      logger.verbose(ms.toString());
      return atomCache.getSince(ms);
    }
    // send empty
    return [];
  }
}
