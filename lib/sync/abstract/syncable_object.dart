import 'package:sync_layer/types/abstract/atom_base.dart';
import 'package:sync_layer/types/abstract/logical_clock_base.dart';
import 'package:sync_layer/types/id.dart';
import 'package:sync_layer/types/index.dart';

abstract class SyncableObject<T> extends Comparable<SyncableObject> {
  /// Marks if the object is deleted!
  bool get tombstone;
  set tombstone(bool v);

  int get type;

  /// Object Id, Like RowId or Index in a Database, etc..
  String get id;

  /// gets the last Updated TS
  LogicalClockBase get lastUpdated;

  /// contains all Atoms received and inserted
  List<AtomBase<T>> get history;

  /// Returns the timestamp for that field
  Id getFieldOriginId(String key);

  /// applies atom and returns
  /// * returns [ 2] : if apply successfull
  /// * returns [ 1] : if atom clock is equal to current => same atom
  /// * returns [ 0] : if atom is older then current
  /// * returns [-1] : if nothing applied => should never happen
  int applyAtom(AtomBase<T> atom);

  dynamic operator [](key);

  /// set operator field value
  operator []=(key, value);
}
