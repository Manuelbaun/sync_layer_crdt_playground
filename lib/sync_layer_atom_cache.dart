import 'package:sync_layer/types/index.dart';

import 'types/abstract/atom_base.dart';

/// TODO: Abstract class
/// This implementation is flawed, since
/// the current hashCode is not collsion resistent!.
/// TODO: fix.
class SyncLayerAtomCache {
  /// for quick access and sync between client
  /// _allAtoms is sorted [DESC]!!
  final List<AtomBase> _allAtoms = [];

  // remembers if atom already exits
  final Set<String> _allAtomsHashcodes = {};

  List<AtomBase> get allAtoms => _allAtoms;

  /// returns true, if atom did not exist in the cache
  bool add(AtomBase atom) {
    final str = atom.id.toString();
    if (_allAtomsHashcodes.add(str)) {
      _allAtoms.add(atom);
      return true;
    }
    return false;
  }

  bool exist(AtomBase atom) => _allAtomsHashcodes.contains(atom.hashCode);

  /// todo: Fix me!! Hlc is extra used
  List<AtomBase> getSince(HybridLogicalClock clock) {
    _allAtoms.sort((a, b) => a.compareToDESC(b)); // DESC
    final index = _allAtoms.indexWhere((atom) => atom.id.ts < clock);
    final endIndex = index < 0 ? _allAtoms.length : index;

    ///  get from DESC and sort ACS
    final atoms = _allAtoms.sublist(0, endIndex);
    atoms.sort();
    return atoms;
  }
}
