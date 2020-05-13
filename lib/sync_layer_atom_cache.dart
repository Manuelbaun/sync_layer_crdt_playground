import 'package:sync_layer/crdts/atom.dart';

class SyncLayerAtomCache {
  /// for quick access and sync between client
  /// _allAtoms is sorted [DESC]!!
  final List<Atom> _allAtoms = [];
  // List<Atom> get allAtoms => _allAtoms;

  // remembers if atom already exits
  final Set<int> _allAtomsHashcodes = {};

  void add(Atom atom) {
    _allAtoms.add(atom);
    _allAtomsHashcodes.add(atom.hashCode);
    _allAtoms.sort((a, b) => b.clock.counter - a.clock.counter); // DESC
  }

  bool exist(Atom atom) => _allAtomsHashcodes.contains(atom.hashCode);

  List<Atom> getSince(int logicalTime) {
    final index = _allAtoms.indexWhere((atom) => atom.clock.counter < logicalTime);
    final endIndex = index < 0 ? _allAtoms.length : index;
    return _allAtoms.sublist(0, endIndex);
  }
}
