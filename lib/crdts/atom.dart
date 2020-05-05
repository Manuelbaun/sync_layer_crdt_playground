import 'dart:convert';
import 'package:sync_layer/basic/hlc.dart';

class KeyValue<K, V> {
  final K key;
  final V value;
  KeyValue(this.key, this.value);
}

/// TODO: could probably be optimized
class Atom<K, V> implements Comparable<Atom> {
  final Hlc ts;

  /// In Context  of a Db, it's the **[Table]** id
  final String classType;

  /// in Context of  a Db, its the **[Row]** id could be cuid id or any other
  final String id;

  /// In context ob a Db it is the **[column]**
  final K key;

  /// In context of a Db its the **[value]** of the column
  final V value;

  Atom(
    this.ts,
    this.classType,
    this.id,
    this.key,
    this.value,
  );

  @override
  int compareTo(Atom other) {
    // return other.ts.logicalTime - ts.logicalTime; // DESC
    return ts.logicalTime - other.ts.logicalTime; //ASC
  }

  Atom copyWith({
    Hlc ts,
    String classType,
    String id,
    K key,
    V value,
  }) {
    return Atom<K, V>(
      ts ?? this.ts,
      classType ?? this.classType,
      id ?? this.id,
      key ?? this.key,
      value ?? this.value,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ts': ts.toString(),
      'class': classType,
      'id': id,
      'key': key,
      'value': value,
    };
  }

  static Atom fromMap(Map<String, dynamic> map) {
    if (map == null) return null;

    return Atom(
      Hlc.parse(map['ts']),
      map['class'],
      map['id'],
      map['key'],
      map['value'],
    );
  }

  String toJson() => json.encode(toMap());
  static Atom fromJson(String source) => fromMap(json.decode(source));

  @override
  String toString() {
    return 'SyncMessage(ts: $ts, class: $classType, id: $id, key: $key, value: $value)';
  }

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is Atom && o.ts == ts && o.classType == classType && o.id == id && o.key == key && o.value == value;
  }

  @override
  int get hashCode {
    return ts.hashCode ^ classType.hashCode ^ id.hashCode ^ key.hashCode ^ value.hashCode;
  }
}
