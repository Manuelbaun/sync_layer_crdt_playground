import 'dart:convert';

import 'package:sync_layer/basic/hlc.dart';

class SyncMessage implements Comparable<SyncMessage> {
  final Hlc ts;
  final String table; // 32 Bit
  final String row; // cuid id!
  final String column;
  final dynamic value;

  SyncMessage(
    this.ts,
    this.table,
    this.row,
    this.column,
    this.value,
  );

  @override
  int compareTo(SyncMessage other) {
    // return other.ts.logicalTime - ts.logicalTime; // DESC
    return ts.logicalTime - other.ts.logicalTime; //ASC
  }
  // byteEncoded() {}
  // SyncMessage.fromBytes(ByteData bytes) {}

  SyncMessage copyWith({
    Hlc ts,
    String tableId,
    String rowId,
    String column,
    dynamic value,
  }) {
    return SyncMessage(
      ts ?? this.ts,
      tableId ?? this.table,
      rowId ?? this.row,
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

  static SyncMessage fromMap(Map<String, dynamic> map) {
    if (map == null) return null;

    return SyncMessage(
      Hlc.parse(map['ts']),
      map['tableId'],
      map['rowId'],
      map['column'],
      map['value'],
    );
  }

  String toJson() => json.encode(toMap());

  static SyncMessage fromJson(String source) => fromMap(json.decode(source));

  @override
  String toString() {
    return 'SyncMessage(ts: $ts, tableId: $table, rowId: $row, column: $column, value: $value)';
  }

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is SyncMessage && o.ts == ts && o.table == table && o.row == row && o.column == column && o.value == value;
  }

  @override
  int get hashCode {
    return ts.hashCode ^ table.hashCode ^ row.hashCode ^ column.hashCode ^ value.hashCode;
  }
}

void main() {
  List<SyncMessage> msgs = [
    SyncMessage(Hlc(DateTime(2020, 1).millisecondsSinceEpoch), 'list', 'row', 'prise', 50),
    SyncMessage(Hlc(DateTime(2019, 1).millisecondsSinceEpoch), 'list', 'row', 'prise', 20),
  ];

  List<SyncMessage> msgs2 = [];

  msgs2.add(msgs.first);

  msgs.forEach(print);
  msgs.sort();
  msgs.forEach(print);
}
