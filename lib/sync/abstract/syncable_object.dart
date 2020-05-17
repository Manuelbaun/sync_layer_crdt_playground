import 'package:sync_layer/sync/abstract/accessors.dart';
import 'package:sync_layer/types/abstract/atom_base.dart';
import 'package:sync_layer/types/abstract/id_base.dart';

/// Specify the type [D] of the atoms data here
/// could be list, or map, this type will be used to transport
abstract class SyncableObject<Key> extends Comparable<SyncableObject> {
  /// Marks if the object is deleted!
  bool tombstone;

  /// Should this be part of the public api?
  // Accessor get accessor;

  int get type;

  /// Object Id, Like RowId or Index in a Database, etc..
  String get objectId;

  /// gets the last Updated TS and also site!
  IdBase get lastUpdated;

  /// contains all Atoms received and inserted
  List<AtomBase> get history;

  /// Returns the timestamp for that field
  IdBase getFieldOriginId(Key key);

  /// applies atom and returns
  /// * returns [ 2] : if apply successfull
  /// * returns [ 1] : if atom clock is equal to current => same atom
  /// * returns [ 0] : if atom is older then current
  /// * returns [-1] : if nothing applied => should never happen
  int applyAtom(AtomBase atom);

  dynamic operator [](Key key);

  /// set operator field value
  operator []=(Key key, dynamic value);
}
