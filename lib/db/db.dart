import 'package:sync_layer/crdts/atom.dart';
import 'package:sync_layer/db/table.dart';

class DB {
  /// contains all received messages
  final Map<String, Table> _db = {};

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

  Table getTable(String table) => _db[table.toString()];
  bool tableExist(String table) => _db.containsKey(table.toLowerCase());
  void createTable(String table) => _db[table.toLowerCase()] ??= Table(table.toLowerCase());
  bool messageExistInLocalSet(Atom msg) => _allMessagesHashcodes.contains(msg.hashCode);

  List<Atom> getMessagesSince(int logicalTime) {
    final index = _allMessages.indexWhere((msg) => msg.ts.logicalTime < logicalTime);
    final endIndex = index < 0 ? _allMessages.length : index;
    return _allMessages.sublist(0, endIndex);
  }
}
