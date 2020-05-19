import 'package:sync_layer/types/abstract/id_base.dart';

/// TODO getter to site!
abstract class AtomBase<D> implements Comparable<AtomBase> {
  /// depending on the atom type, the id the hashcode of the atom or the clock
  // final IdBase id;
  final IdBase id;

  final int typeId;
  final String objectId;

  final D data;

  AtomBase(this.id, this.typeId, this.objectId, this.data);

  int compareToDESC(AtomBase other);
}
