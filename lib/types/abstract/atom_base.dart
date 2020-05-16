import 'package:sync_layer/types/abstract/id_base.dart';

abstract class AtomBase<T> implements Comparable<AtomBase<T>> {
  /// depending on the atom type, the id the hashcode of the atom or the clock
  final IdBase id;
  final T data;
  AtomBase(this.id, this.data);

  int compareToDESC(AtomBase<T> other);
}
