import 'dart:async';
import 'dart:typed_data';

import 'package:msgpack_dart/msgpack_dart.dart';

import 'package:sync_layer/basic/merkle_tire_node.dart';
import 'package:sync_layer/crdts/atom.dart';
import 'package:sync_layer/crdts/clock.dart';
import 'package:sync_layer/db/index.dart';

enum MessageType {
  STATE,
  UPDATE,
}

class DataSetChange {
  String table;
  String rowId;
  DataSetChange({
    this.table,
    this.rowId,
  });

  @override
  String toString() => 'DataSetChange(table: $table, id: $rowId)';

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is DataSetChange && o.table == table && o.rowId == rowId;
  }

  @override
  int get hashCode => table.hashCode ^ rowId.hashCode;
}

class SyncLayerImpl {
  final DB _db;
  DB get db => _db;

  final String nodeId;

  final _changeStreamCrtl = StreamController<Set<DataSetChange>>();
  final _atomsStreamController = StreamController<List<Atom>>();

  Stream<List<Atom>> get atomStream => _atomsStreamController.stream;

  /// [onChanges] should only be called, when there are some changes
  /// either locally or remote happend to the data
  /// it will be called in the function [_applyAtoms]
  Stream<Set<DataSetChange>> get onChanges => _changeStreamCrtl.stream;

  final _updatesStreamCrtl = StreamController<Uint8List>();

  /// On updates should only be triggered, when the method
  /// [applyAndSendAtoms] or when [synchronize] gets called and atoms are not empty!
  /// :: [applyAndSendAtoms] calls [synchronize]
  Stream<Uint8List> get onUpdates => _updatesStreamCrtl.stream;

  // Time Related
  final Clock clock;
  final MerkleTrie trie;

  SyncLayerImpl(this.nodeId, this._db, [MerkleTrie trie])
      : clock = Clock(nodeId),
        trie = trie ?? MerkleTrie(),
        assert(_db != null, 'DB cannot be null');

  ///
  /// Applies the atoms to the tables and rows.
  /// if an atom is resent in the dataSet it gets not applied again!
  ///
  /// TODO: This function needs refactor
  /// db.applyAtom ?
  void _applyAtoms(List<Atom> atoms) {
    final changes = <DataSetChange>{};
    final mapTableID = <Table, Set<String>>{};

    for (final atom in atoms) {
      if (!_db.messageExistInLocalSet(atom)) {
        // test if table exits
        final table = _db.getTable(atom.type);

        if (table != null) {
          mapTableID[table] ??= <String>{};
          // if row does not exist, new row will be added
          final row = table.getRow(atom.id);

          mapTableID[table].add(row.id);

          final hlc = row.getColumnHlc(atom);

          // Add value to row
          if (hlc == null || hlc < atom.ts) {
            row.setColumnValueBySyncLayer(atom);
            changes.add(DataSetChange(table: table.name, rowId: row.id));
          }

          /// stores message in db
          if (hlc == null || hlc != atom.ts) {
            _db.addToAllMessage(atom);
            // addes Atoms to trie
            trie.build([atom.ts]);
          } else {
            /// is it possible for two atoms from different note to have the same ts?
            if (hlc.node != atom.ts.node) {
              // what should happen now?
              // TODO: sort by node?
              print('Two Timestamps have the exact same logicaltime on two different nodes! $hlc - $atom');
            }
          }
        } else {
          print('Table does not exist');
          // Todo: Throw error

        }
      } // else skip that message
    }

    // update Table
    for (var e in mapTableID.entries) {
      e.key.triggerIdUpdate(e.value);
    }

    if (changes.isNotEmpty && _changeStreamCrtl.hasListener) {
      _changeStreamCrtl.add(changes);
    }

    if (atoms.isNotEmpty && _atomsStreamController.hasListener) {
      print('send atoms ${atoms.length}');
      _atomsStreamController.add(atoms);
    }
  }

  void receivingUpdates(Uint8List buff) {
    final atoms = _buffToAtoms(buff);

    for (var atom in atoms) {
      clock.fromReveive(atom.ts);
    }

    _applyAtoms(atoms);
  }

  ///
  void applyAndSendAtoms(List<Atom> atoms) {
    _applyAtoms(atoms);
    synchronize(atoms);
  }

  /// [since] in millisecond
  /// This functions sends the atoms, either since or the provided
  /// via the stream controller...
  void synchronize(List<Atom> atoms, [int since]) async {
    if (since != null && since != 0) {
      var ts = clock.getHlc(since, 0, nodeId);
      atoms = _db.getAtomsSince(ts.logicalTime);
    }

    if (atoms.isNotEmpty && _updatesStreamCrtl.hasListener) {
      final buff = _atomsToBuff(atoms);
      // send for example via network!
      _updatesStreamCrtl.add(buff);
    }
  }

  Atom createAtom(String type, String id, String key, dynamic value) {
    return Atom(clock.getForSend(), type, id, key, value);
  }

  void applyChange(String type, String id, dynamic key, dynamic value) {
    final a = Atom(clock.getForSend(), type, id, key, value);
    applyAndSendAtoms([a]);
  }

  Uint8List computeDiffsToState(Uint8List state) {
    Map remoteMerkle = deserialize(state).cast<int, dynamic>();
    final atoms = getDiffAtomsFromIncomingMerkleTrie(remoteMerkle);
    return _atomsToBuff(atoms);
  }

  List<Atom> getDiffAtomsFromIncomingMerkleTrie(Map<int, dynamic> remoteMerkle) {
    final remote = MerkleTrie.fromMap(remoteMerkle, 36);
    final tsString = trie.diff(remote);

    if (tsString != null) {
      // minutes to ms
      final ts = int.parse(tsString, radix: 36) * 60000;
      // minutes to logicalTime
      return _db.getAtomsSince(ts << 16);
    }
    return [];
  }

  Uint8List getState() {
    final buff = serialize(trie.toMap());
    return Uint8List.fromList([MessageType.STATE.index, ...buff]);
  }

  // TODO: do something better
  Uint8List _atomsToBuff(List<Atom> atoms) {
    final updateBytes = atoms.map((a) => a.toBytes()).toList();
    final buff = serialize(updateBytes);
    return Uint8List.fromList([MessageType.UPDATE.index, ...buff]);
  }

  List<Atom> _buffToAtoms(Uint8List buff) {
    List atomsBuff = deserialize(buff);
    return atomsBuff.map((b) => Atom.fromBytes(b)).toList();
  }
}

// @override
// void registerTable<T>(SyncableTable<T> obj) {
//   if (_db[obj.tableId] == null) {
//     // add Table to _db
//     _db[obj.tableId] = <String, T>{};
//     _tableMapper[obj.name] = obj;
//     final table = _db[obj.tableId];

//     obj.setDbTable(table);

//     obj.streamMessage.listen((atom) {});
//   } else {
//     throw AssertionError('Table with id: ${obj.tableId} already registere#');
//   }
// }

// @override
// void addMessage(SyncMessage atom) {
//   if (!_allAtoms.containsKey(atom)) {
//     _allAtoms[atom.id] = atom.atom;
//     _trieRoot.build([Hlc.fromLogicalTime(atom.id.ts)]);

//     _tableMapper[atom.atom.table].applyMessage(atom);
//   }
// }

// @override
// List<SyncMessage> getAtomsSince(int hypelogicalClock) {
//   throw AssertionError('Please implement me!');
// }

// @override
// int compareTries(String trieMap) {
//   throw AssertionError('Please implement me!');
// }

// @override
// String getTrieJson() {
//   return _trieRoot.toJson();
// }
