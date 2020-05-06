import 'dart:async';

import 'package:sync_layer/basic/hlc.dart';
import 'package:sync_layer/crdts/atom.dart';

abstract class SyncableTable<T> {
  final int tableId;
  final String name;
  Map<String, T> _table;

  Map<String, T> get table => _table;

  SyncableTable(this.tableId, this.name)
      : assert(tableId != null || tableId != 0),
        assert(name != null || name.isEmpty);

  final _stream = StreamController<T>();

  /// for application layer
  Stream<T> get stream => _stream.stream;

  /// only for synclayer
  ///
  final _streamMessage = StreamController<Atom>();
  Stream<Atom> get streamMessage => _streamMessage.stream;

  /// only for synclayer
  void setDbTable(Map<String, dynamic> db_table) {
    if (_table == null) {
      _table = db_table;
    } else {
      throw AssertionError('Db Table in class $runtimeType is already set');
    }
  }

  /// Here the Strategy LWW of CRDT!
  void applyMessage(Atom atom);

  void emitMessage(Atom update);
}

abstract class SynableObject {
  final String id;
  SynableObject(this.id) : assert(id == null || id.isEmpty);
}

abstract class SyncLayer {
  void registerTable<T>(SyncableTable<T> obj);
  void addMessage(Atom atom);
  List<Atom> getAtomsSince(Hlc hypelogicalClock);

  Hlc compareTries(String trieJson);
  String getTrieJson();
}
