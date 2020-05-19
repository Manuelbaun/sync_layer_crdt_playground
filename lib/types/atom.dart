import 'abstract/atom_base.dart';
import 'id_atom.dart';

class Atom<T> implements AtomBase<T> {
  Atom(this.id, this.typeId, this.objectId, this.data);

  /// depending on the atom type, the id the hashcode of the atom or the clock
  // final IdBase id;
  @override
  final AtomId id;

  @override
  final int typeId;

  @override
  final String objectId;

  @override
  final T data;

  @override
  int compareTo(AtomBase other) => id.ts - other.id.ts;

  @override
  int compareToDESC(AtomBase other) => -(id.ts - other.id.ts);

  @override
  String toString() => 'Atom($id, type: $typeId, objectId: $objectId, data: $data)';

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;
    return o is Atom && o.hashCode == hashCode;
  }

  @override
  // should be enough!, since id, should be as unique as possible!
  // otherwise implement use objectType, etc
  int get hashCode => id.hashCode ^ objectId.hashCode ^ data.hashCode ^ typeId;
}
