import 'package:sync_layer/basic/index.dart';
import 'package:sync_layer/crdts/atom.dart';

import 'syncable_object_container.dart';

abstract class SyncableObject extends Comparable<SyncableObject> {
  String get id;

  /// Marks if the object is deleted!
  bool tombstone;
  SyncableObjectContainer get container;

  /// Returns the timestamp for that field
  Hlc getCurrentHLCOfField(String field);
  Hlc get lastUpdated;

  /// applies atom:
  /// * if successfull => returns [2]
  /// * if atom is older then current value => returns [1] :
  /// * else => returns [-1]
  ///
  int applyAtom(Atom atom);

  dynamic operator [](key);

  /// should create shortcut to update the field directly???
  operator []=(field, value);
}
