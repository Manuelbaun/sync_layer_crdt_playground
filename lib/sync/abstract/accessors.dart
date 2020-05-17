import 'package:sync_layer/types/abstract/atom_base.dart';
import 'package:sync_layer/types/index.dart';

import 'syncable_object.dart';

/// [V] is not for a syncable object,
/// it should describe the type of the value, which is then updated
abstract class Accessor {
  Accessor(this.type);
  final int type;

  AtomBase onUpdate<V>(String id, V value);
  String generateID();
  SyncableObject objectLookup(ObjectReference ref);
}
