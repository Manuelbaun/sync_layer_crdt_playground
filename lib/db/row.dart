import 'dart:convert';

import 'package:sync_layer/basic/hlc.dart';
import 'package:sync_layer/crdts/atom.dart';

import 'table.dart';

class Row {
  /// Row id
  final String id;

  /// Ref to the Table
  final Table table;

  /// the actual object data
  final Map<String, dynamic> obj = {};
  final Map<String, Hlc> objHlc = {};

  Row(this.id, this.table)
      : assert(id != null && id.isNotEmpty, 'Row Id needs a valid ID!'),
        assert(table != null, 'Table prop cant be null');

  /// gets the latest column sync message if exist. else null
  Hlc getColumnHlc(Atom msg) => objHlc[msg.key];

  void setColumnValueBySyncLayer(Atom msg) {
    obj[msg.key] = msg.value;
    objHlc[msg.key] = msg.ts;
  }

  Hlc get lastUpdated => objHlc.values.reduce((a, b) => a > b ? a : b);

  dynamic operator [](key) => obj[key];

  operator []=(key, value) {
    final a = table.syn.createAtom(table.name, id, key, value);
    table.syn.sendMessages([a]);
  }

  String prettyJson() {
    var encoder = JsonEncoder.withIndent('  ');
    return encoder.convert({'_id': id, ...obj});
  }

  @override
  String toString() => 'id: $id, $obj';

  @override
  int get hashCode {
    var hashcode = 0;

    for (final entry in obj.entries) {
      hashcode ^= (entry.key.hashCode) ^ entry.value.hashCode;
    }

    return hashcode;
  }
}
