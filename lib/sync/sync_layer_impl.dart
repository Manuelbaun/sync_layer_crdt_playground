import 'dart:async';

import 'package:sync_layer/basic/cuid.dart';
import 'package:sync_layer/basic/merkle_tire_node.dart';
import 'package:sync_layer/logical_clocks/index.dart';
import 'package:sync_layer/types/index.dart';
import 'package:sync_layer/errors/index.dart';
import 'package:sync_layer/logger/index.dart';
import 'package:sync_layer/sync_layer_atom_cache.dart';
import 'abstract/index.dart';
import 'syncable_object_container_impl.dart';

class SynclayerAccessor implements Accessor {
  SynclayerAccessor(this.synclayer, this.type);

  final SyncLayer synclayer;

  @override
  final int type;

  @override
  void onUpdate<V>(List<V> values) {
    final atoms = values.map((v) => synclayer.createAtom(v)).toList();
    synclayer.applyAtoms(atoms);
  }

  @override
  String generateID() {
    return synclayer.generateID();
  }

  @override
  SyncableObject objectLookup(ObjectReference ref, [bool shouldCreateIfNull = true]) {
    final container = synclayer.getObjectContainer(typeNumber: ref.type);

    // TODO: check if container Exists
    var obj = container.read(ref.id);

    if (shouldCreateIfNull && obj == null) {
      obj = container.create(ref.id);
    }
    return obj;
  }
}

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
  final _atomStreamController = StreamController<List<Atom>>.broadcast();

  @override
  Stream<List<Atom>> get atomStream => _atomStreamController.stream;

  @override
  MerkleTrie getState() => trie;

  SyncLayerImpl(this.site, [MerkleTrie trie])
      : clock = Clock(site),
        trie = trie ?? MerkleTrie();

  /// accessors and utils
  /// use either typeName or typeNumber
  /// in case of both, it throws a conflict
  @override
  SyncableObjectContainer<T> getObjectContainer<T extends SyncableObject>({String typeName, int typeNumber}) {
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
  ///
  StringNumberMapper mapper = StringNumberMapper();

  @override
  SyncableObjectContainer<T> registerObjectType<T extends SyncableObject>(
    String typeName,
    SynableObjectFactory<T> objectFactory, [
    int customNumberId,
  ]) {
    SyncableObjectContainer container;

    if (!mapper.containsTypeName(typeName)) {
      final typeNumber = mapper.registerNewTypeName(typeName);
      final accessor = SynclayerAccessor(this, typeNumber);

      container = SyncableObjectContainerImpl<T>(
        accessor,
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
  void _applyAtoms(List<Atom> atoms) {
    final changedContainer = <SyncableObjectContainer>{};

    for (final atom in atoms) {
      if (!atomCache.exist(atom)) {
        // test if table exits
        final container = getObjectContainer(typeNumber: atom.data.typeId);

        if (container != null) {
          // if row does not exist, new row will be added
          var obj = container.read(atom.data.id);
          obj ??= container.create(atom.data.id);

          final res = obj.applyAtom(atom);

          // if successfull applied, => trigger!
          if (res == 2) {
            // todo trigger! container /object update
            container.setUpdatedObject(obj);
            changedContainer.add(container);
          }
          // in any case,
          atomCache.add(atom);
          trie.build([atom.clock]);
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

    /// TODO: should it be copying the refs
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

  List<Atom> getAtomsSinceMs(Hlc clock) {
    return atomCache.getSince(clock);
  }

  /// These are workarounds
  /// get ts diff and send it back to requestee
  /// TODO: check siteid of '0' => what site idee should be there?
  @override
  List<Atom> getAtomsByReceivingState(MerkleTrie remoteState) {
    final tsKey = trie.diff(remoteState);
    if (tsKey != null) {
      final ms = clock.getClockFromTSKey(tsKey, 0);
      print(ms.toStringHuman());
      return getAtomsSinceMs(ms);
    }
    // send empty
    return [];
  }
}
