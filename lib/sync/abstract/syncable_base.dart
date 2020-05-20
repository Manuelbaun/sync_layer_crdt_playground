import 'package:sync_layer/types/abstract/atom_base.dart';
import 'package:sync_layer/types/abstract/id_base.dart';
import 'package:sync_layer/types/object_reference.dart';

import 'acess_proxy.dart';

/// todo:
/// *  Method instead of [tombstone]
abstract class SyncableBase extends Comparable<SyncableBase> {
  /// Marks if the object is deleted!
  bool get tombstone;

  /// Object Id, Like RowId or Index in a Database, etc..
  String get id;

  /// The object type
  int get type;

  /// gets the last Updated TS and also site!
  IdBase get lastUpdated;

  /// the Access Proxy object, to decouple synclayer and SyncableBase
  AccessProxy get proxy;

  /// fires when the object got updated!
  ///
  /// TODO: should something be transported?
  ///
  Stream get onChange;

  SyncableObjectRef toObjectRef() => SyncableObjectRef(type, id);

  @override
  int compareTo(SyncableBase other) => id.compareTo(other.id);

  /// will delete the object
  void delete();

  /// With subtransaction, assigning multiple values to the object,
  /// no update is triggered until function is finished
  /// then all changes as send in one Atom
  ///
  /// *Note: Changes are stored in a Map, therefor, appling the same Key, will result in the
  /// last writer wins
  void transact(void Function(SyncableBase ref) func);

  /// applies atom and returns
  /// * returns [ 2] : if apply successfull
  /// * returns [ 1] : if atom clock is equal to current => same atom
  /// * returns [ 0] : if atom is older then current
  /// * returns [-1] : if nothing applied => should never happen
  int applyRemoteAtom(AtomBase atom);
}
