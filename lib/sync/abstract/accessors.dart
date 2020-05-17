import 'package:sync_layer/types/abstract/atom_base.dart';
import 'package:sync_layer/types/index.dart';

import 'syncable_object.dart';

/// [T] is not for a syncable object,
/// <AtomDataType>

abstract class Accessor {
  Accessor(this.type);
  final int type;

  AtomBase onUpdate(String id, dynamic value);
  String generateID();
  SyncableObject objectLookup(ObjectReference ref);
}
