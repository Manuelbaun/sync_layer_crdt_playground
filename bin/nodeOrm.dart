import 'dart:typed_data';

import 'package:msgpack_dart/msgpack_dart.dart';
import 'package:sync_layer/db/db.dart';
import 'package:sync_layer/sync/sync_imple.dart';

import 'tables/index.dart';

class NodeORM {
  DB db;
  SyncLayerImpl syn;

  // Define getters
  TodoTable get todo => db.getTable('todo') as TodoTable;
  AssigneeTable get assignee => db.getTable('assingee') as AssigneeTable;

  NodeORM(String name) {
    db = DB();
    syn = SyncLayerImpl(name, db);

    // register tabels
    db.registerTable(TodoTable('todo', syn));
    db.registerTable(AssigneeTable('assingee', syn));
  }

  ///
  /// Takes buff as Uint8List of [Atoms] and applies it to local state
  void applyUpdate(Uint8List buff) => syn.receivingUpdates(buff);

  ///
  /// Returns the different [Atoms] as Uint8List
  /// when [state] (merkle trie) as Uint8List is supplied
  Uint8List getDiff(Uint8List state) => syn.computeDiffsToState(state);

  /// Returns the state of then of the sync layer
  Uint8List getState() => syn.getState();
}
