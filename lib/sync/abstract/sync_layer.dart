import 'dart:async';

import 'package:sync_layer/basic/index.dart';
import 'package:sync_layer/types/abstract/atom_base.dart';

import 'syncable_object.dart';
import 'syncable_object_container.dart';

/// This is the abstract [SyncLayer].
abstract class SyncLayer {
  int site;

  SyncableObjectContainer<T> getObjectContainer<T extends SyncableObject>({
    String typeName,
    int typeNumber,
  });

  SyncableObjectContainer<T> registerObjectType<T extends SyncableObject>(
      String typeId, SynableObjectFactory<T> objectFactory);

  /// This Stream sends only changes/Atoms made locally, and does not contain any remote recieved
  /// changes or Atoms. This prevents from broadcast loops
  Stream<List<AtomBase>> get atomStream;

  // void registerContainer(SyncableObjectContainer cont);
  String generateID();

  AtomBase createAtom(String objectId, int typeId, dynamic data);

  /// Function to add atoms
  void applyAtoms(List<AtomBase> atoms);

  /// This method is used for incoming/receiving atoms
  /// since the clock will be updated based on the incoming atoms
  void receiveAtoms(List<AtomBase> atoms);

  /// this is a workaround, and will be refactored later on
  List<AtomBase> getAtomsByReceivingState(MerkleTrie remoteState);

  void transaction(Function func);
  MerkleTrie getState();
}
