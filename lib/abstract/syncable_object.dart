import 'package:sync_layer/crdts/atom.dart';
import 'package:sync_layer/logical_clocks/index.dart';

abstract class SyncableObject extends Comparable<SyncableObject> {
  /// Marks if the object is deleted!
  bool get tombstone;
  set tombstone(bool v);

  String get id;
  String get type;
  Hlc get lastUpdated;
  List<Atom> get history;

  /// Returns the timestamp for that field
  Hlc getFieldClock(String key);

  /// applies atom:
  /// * if successfull => returns [2]
  /// * if atom is older then current value => returns [1] :
  /// * else => returns [-1]
  ///
  int applyAtom(Atom atom);

  dynamic operator [](key);

  /// set operator field value
  operator []=(key, value);
}
