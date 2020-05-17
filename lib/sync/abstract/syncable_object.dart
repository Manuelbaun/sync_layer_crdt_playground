import 'package:sync_layer/types/abstract/atom_base.dart';
import 'package:sync_layer/types/abstract/id_base.dart';

abstract class SyncableObject extends Comparable<SyncableObject> {
  /// Marks if the object is deleted!
  bool get tombstone;
  set tombstone(bool v);

  int get type;

  /// Object Id, Like RowId or Index in a Database, etc..
  String get objectId;

  /// gets the last Updated TS and also site!
  IdBase get lastUpdated;

  /// contains all Atoms received and inserted
  List<AtomBase> get history;

  /// Returns the timestamp for that field
  IdBase getFieldOriginId(int key);

  /// applies atom and returns
  /// * returns [ 2] : if apply successfull
  /// * returns [ 1] : if atom clock is equal to current => same atom
  /// * returns [ 0] : if atom is older then current
  /// * returns [-1] : if nothing applied => should never happen
  int applyAtom(AtomBase atom);

  dynamic operator [](int key);

  /// set operator field value
  operator []=(int key, dynamic value);
}
