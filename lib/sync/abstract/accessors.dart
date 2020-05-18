import 'package:sync_layer/types/abstract/atom_base.dart';
import 'package:sync_layer/types/index.dart';

import 'syncable_object.dart';

abstract class Accessor {
  int get type;
  int get site;

  AtomBase onUpdate(String id, dynamic value);
  String generateID();
  SyncableObject objectLookup(ObjectReference ref);
}
