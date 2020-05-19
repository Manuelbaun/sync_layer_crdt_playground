import 'package:sync_layer/sync/abstract/syncable_base.dart';
import 'package:sync_layer/types/abstract/atom_base.dart';
import 'package:sync_layer/types/abstract/id_base.dart';

/// Specify the type [D] of the atoms data here
/// could be list, or map, this type will be used to transport
abstract class SyncableObject<Key> extends Comparable<SyncableObject> implements SyncableBase {
  /// contains all Atoms received and inserted
  List<AtomBase> get history;

  // fires when the object got updated!
  Stream<MapEntry<Key, dynamic>> get stream;

  /// Returns the timestamp for that field
  IdBase getOriginIdOfKey(Key key);

  dynamic operator [](Key key);

  /// set operator field value
  operator []=(Key key, dynamic value);
}

class IdValuePair {
  IdValuePair(this.id, this.value);
  final IdBase id;
  final dynamic value;

  @override
  String toString() => 'Entry(c: $id, v: $value)';

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is IdValuePair && o.id == id && o.value == value;
  }

  @override
  int get hashCode => id.hashCode ^ value.hashCode;
}
