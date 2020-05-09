import 'package:sync_layer/crdts/atom.dart';

import 'syncable_object.dart';
import 'syncable_container.dart';

abstract class SyncLayer {
  SyncableObjectContainer<T> getObjectContainer<T extends SyncableObject>(String typeId);
  SyncableObjectContainer<T> registerObjectType<T extends SyncableObject>(
      String typeId, SynableObjectFactory<T> objectFactory);

  void registerContainer(SyncableObjectContainer cont);
  String generateID();

  Atom createAtom(String typeId, String objectId, String fieldId, dynamic value);
  void applyAtoms(List<Atom> atoms);

  // void _receiveAtoms(List<Atom> atoms);
  // void sendAtoms(List<Atom> atoms);

  void transaction(Function func);
}
