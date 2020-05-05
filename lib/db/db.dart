import 'package:sync_layer/crdts/atom.dart';
import 'package:sync_layer/db/table.dart';
import 'package:sync_layer/sync/sync_imple.dart';

class DB {
  /// contains all received messages
  final Map<String, Table> _db = {};

  /// TODO:  Change that!!! I do not like the sync layer here
  final SyncLayerImpl syn;

  DB(this.syn);

  /// for quick access and sync between client
  /// _allMessages is sorted [DESC]!!
  final List<Atom> _allMessages = [];
  List<Atom> get allMessages => _allMessages;

  // remembers if messages already exits
  final Set<int> _allMessagesHashcodes = {};

  void addToAllMessage(Atom msg) {
    _allMessages.add(msg);
    _allMessagesHashcodes.add(msg.hashCode);

    _allMessages.sort((a, b) => b.ts.logicalTime - a.ts.logicalTime); // DESC
  }

  Table getTable(String table) => _db[table.toLowerCase()];
  bool tableExist(String table) => _db.containsKey(table.toLowerCase());

  /// TODO: but the sync layer is needed here! in the table... :(
  void createTable(String table) => _db[table.toLowerCase()] ??= Table(table.toLowerCase(), syn);

  Table registerTable(Table table) {
    _db[table.name.toLowerCase()] ??= table;
    // todo: notify when try to override table!!
    return _db[table.name];
  }

  bool messageExistInLocalSet(Atom msg) => _allMessagesHashcodes.contains(msg.hashCode);

  List<Atom> getMessagesSince(int logicalTime) {
    final index = _allMessages.indexWhere((msg) => msg.ts.logicalTime < logicalTime);
    final endIndex = index < 0 ? _allMessages.length : index;
    return _allMessages.sublist(0, endIndex);
  }
}
