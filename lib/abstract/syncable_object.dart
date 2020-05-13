import 'package:sync_layer/crdts/atom.dart';
import 'package:sync_layer/logical_clocks/index.dart';

abstract class SyncableObject<T> extends Comparable<SyncableObject> {
  /// Marks if the object is deleted!
  bool get tombstone;
  set tombstone(bool v);

  String get id;
  String get type;
  Hlc get lastUpdated;
  List<Atom<T>> get history;

  /// Returns the timestamp for that field
  Hlc getFieldClock(String key);

  /// applies atom and returns
  /// * returns [ 2] : if apply successfull
  /// * returns [ 1] : if atom clock is equal to current => same atom
  /// * returns [ 0] : if atom is older then current
  /// * returns [-1] : if nothing applied => should never happen
  /// if -1 it throws an error
  ///
  /// TODO: should case of Atom beeing 'null' be handeled?
  int applyAtom(Atom<T> atom);

  dynamic operator [](key);

  /// set operator field value
  operator []=(key, value);
}
