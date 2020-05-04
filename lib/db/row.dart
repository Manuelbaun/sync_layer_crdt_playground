import 'dart:convert';

import 'package:sync_layer/crdts/atom.dart';

class Row {
  String id;
  // the actual object data
  final Map<String, dynamic> obj;
  // history just for fast lookup!
  final List<Atom> history;

  Row(this.id)
      : history = [],
        obj = {};

  // only add messages!!!
  void add(Atom msg) {
    obj[msg.column] = msg.value;
    history.add(msg);
    history.sort(); // ASC
  }

  String prettyJson() {
    var encoder = JsonEncoder.withIndent('  ');
    return encoder.convert({'_id': id, ...obj});
  }

  /// gets the latest column sync message if exist. else null
  Atom getLastestColumnUpdate(Atom msg) {
    // search reversed
    for (var i = history.length - 1; i >= 0; i--) {
      final m = history[i];
      if (m.column == msg.column) return m;
    }
    return null;
  }

  @override
  String toString() {
    return 'Row(id: $id : history-length: ${history.length})';
  }
}
