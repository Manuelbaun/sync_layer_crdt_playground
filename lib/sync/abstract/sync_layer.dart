import 'dart:async';

import 'package:meta/meta.dart';
import 'package:sync_layer/basic/index.dart';
import 'package:sync_layer/sync/abstract/syncable_base.dart';
import 'package:sync_layer/types/abstract/atom_base.dart';

import 'syncable_object_container.dart';

/// This is the abstract [SyncLayer].
abstract class SyncLayer {
  SyncLayer(this.site);
  final int site;

  SyncableObjectContainer<T> getObjectContainer<T extends SyncableBase>({
    String typeName,
    int typeNumber,
  });

  SyncableObjectContainer<T> registerObjectType<T extends SyncableBase>(
    String typeId,
    SynableObjectFactory<T> objectFactory,
  );

  /// This Stream sends only changes/Atoms made locally, and does not contain any remote recieved
  /// changes or Atoms. This prevents from broadcast loops
  Stream<List<AtomBase>> get atomStream;

  String generateNewObjectIds();

  AtomBase createAtom(int typeId, String objectId, dynamic data);

  /// Function to add atoms
  /// This method is used for incoming/receiving atoms
  /// since the clock will be updated based on the incoming atoms
  void applyRemoteAtoms(List<AtomBase> atoms);

  /// [objRef] is used to trigger table
  void applyLocalAtoms(List<AtomBase> atoms);

  /// this is a workaround, and will be refactored later on
  List<AtomBase> getAtomsByReceivingState(MerkleTrie remoteState);

  MerkleTrie getState();

  /// when called, all updates insice [func] will be send once the is done
  void transaction(Function func);
}
