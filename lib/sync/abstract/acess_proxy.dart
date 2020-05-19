import 'package:sync_layer/sync/abstract/syncable_base.dart';
import 'package:sync_layer/types/abstract/atom_base.dart';
import 'package:sync_layer/types/index.dart';

import 'syncable_object.dart';

/// TODO: Rename to proxy ??
abstract class AccessProxy {
  int get type;
  int get site;

  AtomBase update(String id, dynamic value);
  String generateID();
  SyncableBase objectLookup(ObjectReference ref);
}
