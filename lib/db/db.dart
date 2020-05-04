import 'package:sync_layer/db/table.dart';
import 'package:sync_layer/sync/message.dart';

String formatMicro(int us) {
  final s = (us / 1000).toString().split('.');
  s.first.padLeft(6, ' ');
  s.last.padRight(3, '0');

  return s.join('.');
}

class DB {
  /// contains all received messages
  final Map<String, Table> _db = {};

  // for quick access and sync between client
  final List<SyncMessage> _allMessages = [];
  List<SyncMessage> get allMessages => _allMessages;

  // remembers if messages already exits
  final Set<int> _allMessagesHashcodes = {};

  void addToAllMessage(SyncMessage msg) {
    _allMessages.add(msg);
    _allMessagesHashcodes.add(msg.hashCode);

    // reversed??
    final s = Stopwatch()..start();
    _allMessages.sort();
    s.stop();

    print('Sorting: ${formatMicro(s.elapsedMicroseconds)} ms - ${_allMessages.length}');
  }

  Table getTable(String table) => _db[table.toString()];
  bool tableExist(String table) => _db.containsKey(table.toLowerCase());

  void createTable(String table) => _db[table.toLowerCase()] ??= Table(table.toLowerCase());

  bool messageExistInLocalSet(SyncMessage msg) => _allMessagesHashcodes.contains(msg.hashCode);

  List<SyncMessage> getMessagesSince(int logicalTime) {
    return _allMessages.where((msg) => msg.ts.logicalTime > logicalTime).toList();
  }
}
