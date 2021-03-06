import 'package:sync_layer/basic/observable.dart';
import 'package:sync_layer/sync/abstract/syncable_base.dart';
import 'package:sync_layer/types/abstract/atom_base.dart';
import 'package:sync_layer/types/abstract/id_base.dart';

/// Specify the type [D] of the atoms data here
/// could be list, or map, this type will be used to transport
abstract class SyncableObject<Key> extends SyncableBase with Observable {
  /// contains all Atoms received and inserted
  List<AtomBase> get history;

  /// Returns the timestamp for that field
  IdBase getOriginIdOfKey(Key key);

  dynamic operator [](Key key);

  /// set operator field value
  operator []=(Key key, dynamic value);
}
