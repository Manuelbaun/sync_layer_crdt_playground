import 'package:sync_layer/crdts/atom.dart';
import 'package:sync_layer/db/table.dart';

class DB {
  /// contains the "database tables"
  final Map<String, Table> _db = {};

  /// for quick access and sync between client
  /// _allAtoms is sorted [DESC]!!
  final List<Atom> _allAtoms = [];
  List<Atom> get allAtoms => _allAtoms;

  // remembers if atom already exits
  final Set<int> _allAtomsHashcodes = {};

  void addToAllMessage(Atom atom) {
    _allAtoms.add(atom);
    _allAtomsHashcodes.add(atom.hashCode);
    _allAtoms.sort((a, b) => b.ts.logicalTime - a.ts.logicalTime); // DESC
  }

  Table getTable(String table) => _db[table.toLowerCase()];
  bool tableExist(String table) => _db.containsKey(table.toLowerCase());

  Table registerTable(Table table) {
    _db[table.name.toLowerCase()] ??= table;
    // todo: notify when try to override table!!
    return _db[table.name];
  }

  bool messageExistInLocalSet(Atom atom) => _allAtomsHashcodes.contains(atom.hashCode);

  List<Atom> getAtomsSince(int logicalTime) {
    final index = _allAtoms.indexWhere((atom) => atom.ts.logicalTime < logicalTime);
    final endIndex = index < 0 ? _allAtoms.length : index;
    return _allAtoms.sublist(0, endIndex);
  }
}
