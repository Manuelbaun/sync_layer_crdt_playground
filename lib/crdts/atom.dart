import 'dart:convert';
import 'package:sync_layer/basic/hlc.dart';

class Atom implements Comparable<Atom> {
  final Hlc ts;
  final String table; // 32 Bit
  final String row; // cuid id!
  final String column;
  final dynamic value;

  Atom(
    this.ts,
    this.table,
    this.row,
    this.column,
    this.value,
  );

  @override
  int compareTo(Atom other) {
    // return other.ts.logicalTime - ts.logicalTime; // DESC
    return ts.logicalTime - other.ts.logicalTime; //ASC
  }

  Atom copyWith({
    Hlc ts,
    String tableId,
    String rowId,
    String column,
    dynamic value,
  }) {
    return Atom(
      ts ?? this.ts,
      tableId ?? table,
      rowId ?? row,
      column ?? this.column,
      value ?? this.value,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ts': ts.toString(),
      'tableId': table,
      'rowId': row,
      'column': column,
      'value': value,
    };
  }

  static Atom fromMap(Map<String, dynamic> map) {
    if (map == null) return null;

    return Atom(
      Hlc.parse(map['ts']),
      map['tableId'],
      map['rowId'],
      map['column'],
      map['value'],
    );
  }

  String toJson() => json.encode(toMap());

  static Atom fromJson(String source) => fromMap(json.decode(source));

  @override
  String toString() {
    return 'SyncMessage(ts: $ts, tableId: $table, rowId: $row, column: $column, value: $value)';
  }

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is Atom && o.ts == ts && o.table == table && o.row == row && o.column == column && o.value == value;
  }

  @override
  int get hashCode {
    return ts.hashCode ^ table.hashCode ^ row.hashCode ^ column.hashCode ^ value.hashCode;
  }
}
