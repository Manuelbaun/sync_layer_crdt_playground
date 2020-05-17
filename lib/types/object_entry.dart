import 'abstract/sync_entry.dart';

/// Importent Key and value cant be some custom class type!!!
/// unless encoding and decoding is implemented
/// in the  encoding_extent classes
///

class SyncableEntry<K, V> implements SyncEntry {
  /// In context ob a Db it is the **[column]**
  final K key;

  /// In context of a Db its the **[value]** of the column
  final V value;

  SyncableEntry(this.key, this.value);

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is SyncableEntry && o.key == key && o.value == value;
  }

  @override
  int get hashCode {
    return key.hashCode ^ value.hashCode;
  }

  @override
  String toString() {
    return 'SyncableEntry(key: $key, value: $value)';
  }
}
