import 'dart:async';

import 'package:sync_layer/basic/index.dart';
import 'package:sync_layer/types/index.dart';

import 'syncable_object.dart';
import 'syncable_object_container.dart';

/// This is the abstract [SyncLayer].
abstract class SyncLayer {
  int site;

  SyncableObjectContainer<T> getObjectContainer<T extends SyncableObject>(String typeId);
  SyncableObjectContainer<T> registerObjectType<T extends SyncableObject>(
      String typeId, SynableObjectFactory<T> objectFactory);

  /// This Stream sends only changes/Atoms made locally, and does not contain any remote recieved
  /// changes or Atoms. This prevents from broadcast loops
  Stream<List<Atom>> get atomStream;

  void registerContainer(SyncableObjectContainer cont);
  String generateID();

  Atom createAtom(dynamic value);

  /// Function to add atoms
  void applyAtoms(List<Atom> atoms);

  /// This method is used for incoming/receiving atoms
  /// since the clock will be updated based on the incoming atoms
  void receiveAtoms(List<Atom> atoms);

  /// this is a workaround, and will be refactored later on
  List<Atom> getAtomsByReceivingState(MerkleTrie remoteState);

  void transaction(Function func);
  MerkleTrie getState();
}
