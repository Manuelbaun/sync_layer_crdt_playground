import 'package:sync_layer/types/abstract/id_base.dart';

/// TODO
/// * getter to site!
/// * Fix hashcode!!
abstract class AtomBase<D> implements Comparable<AtomBase> {
  /// depending on the atom type, the id the hashcode of the atom or the clock
  // final IdBase id;
  final IdBase id;

  final int type;
  final String objectId;

  final D data;

  AtomBase(this.id, this.type, this.objectId, this.data);

  int compareToDESC(AtomBase other);
}
