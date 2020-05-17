import 'package:sync_layer/types/index.dart';

import 'types/abstract/atom_base.dart';

/// TODO: Abstract class
class SyncLayerAtomCache {
  /// for quick access and sync between client
  /// _allAtoms is sorted [DESC]!!
  final List<AtomBase> _allAtoms = [];

  // remembers if atom already exits
  final Set<int> _allAtomsHashcodes = {};

  void add(AtomBase atom) {
    _allAtoms.add(atom);
    _allAtomsHashcodes.add(atom.hashCode);

    // _allAtoms.sort((a, b) => b.clock.counter - a.clock.counter); // DESC
    _allAtoms.sort((a, b) => a.compareToDESC(b)); // DESC
  }

  bool exist(AtomBase atom) => _allAtomsHashcodes.contains(atom.hashCode);

  /// todo: Fix me!! Hlc is extra used
  List<AtomBase> getSince(HybridLogicalClock clock) {
    final index = _allAtoms.indexWhere((atom) => atom.id.ts < clock);
    final endIndex = index < 0 ? _allAtoms.length : index;
    return _allAtoms.sublist(0, endIndex);
  }
}
