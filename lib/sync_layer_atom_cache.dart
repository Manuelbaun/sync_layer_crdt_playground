import 'package:sync_layer/types/index.dart';

import 'logical_clocks/hybrid_logical_clock.dart';

class SyncLayerAtomCache {
  /// for quick access and sync between client
  /// _allAtoms is sorted [DESC]!!
  final List<Atom> _allAtoms = [];

  // remembers if atom already exits
  final Set<int> _allAtomsHashcodes = {};

  void add(Atom atom) {
    _allAtoms.add(atom);
    _allAtomsHashcodes.add(atom.hashCode);

    /// TODO. Logical Clock needs a compare method abstracted
    // _allAtoms.sort((a, b) => b.clock.counter - a.clock.counter); // DESC
    _allAtoms.sort((a, b) => a.compareToDESC(b)); // DESC
  }

  bool exist(Atom atom) => _allAtomsHashcodes.contains(atom.hashCode);

  /// todo: Fix me!! Hlc is extra used
  List<Atom> getSince(Hlc clock) {
    final index = _allAtoms.indexWhere((atom) => atom.clock < clock);
    final endIndex = index < 0 ? _allAtoms.length : index;
    return _allAtoms.sublist(0, endIndex);
  }
}
