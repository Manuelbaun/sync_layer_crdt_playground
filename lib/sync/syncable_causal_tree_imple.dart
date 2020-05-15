import 'dart:async';

import 'package:sync_layer/types/index.dart';
import 'package:sync_layer/logical_clocks/index.dart';

class CausalTree<T> {
  int site;
  LogicalTime localClock;

  //! this Atom array has to be the same on all other sides.
  List<CausalAtom<T>> atoms = <CausalAtom<T>>[];
  final _controller = StreamController<CausalAtom>();
  Stream<CausalAtom> get stream => _controller.stream;

  // should we use deltedAtoms?
  Set<LogicalTime> deletedAtoms = {};
  Set<LogicalTime> allAtomIds = {};

  int get length => allAtomIds.length - deletedAtoms.length;
  int get deleteAtomsLength => deletedAtoms.length;
  int get allAtomsLength => allAtomIds.length;

  //! the local site cache, does not need to be the same in the cloud
  final yarns = <int, List<CausalAtom>>{};

  /// SiteId -> TimeStamp, Kind of Version vector
  final weft = <int, int>{};

  CausalTree(this.site) : localClock = LogicalTime(0, site);

  // importent, the timestamp needs to be overritten with the new one!
  // only this way, LogicalTime send is able to increment the counter field;
  LogicalTime _newID() {
    return localClock = LogicalTime.send(localClock);
  }

  void _insert(CausalAtom atom, [int index]) {
    // Do not insert if already inserted
    if (allAtomIds.contains(atom.clock)) return;
    allAtomIds.add(atom.clock);

    // set cause index, if null, then search!
    var causeIndex = index;
    causeIndex ??= atoms.indexWhere((a) {
      return a.clock == atom.cause;
    });

    // checks wether it should be inserted or just added
    if ((causeIndex >= (atoms.length - 1)) || causeIndex < 0) {
      atoms.add(atom);
    } else {
      causeIndex += 1;

      if (CausalAtom.isSibling(atom, atoms[causeIndex])) {
        // increase [index] as long as atom is not left/less of atoms[index]
        // Note: operator < is overwritten and means causal 'less'/left

        while (causeIndex < atoms.length && !CausalAtom.leftIsLeft(atom, atoms[causeIndex])) {
          causeIndex++;
        }
      }

      atoms.insert(causeIndex, atom);
    }

    // if (yarns[atom.id.site] == null) {
    //   yarns[atom.id.site] = <CausalAtom<T>>[];
    // }

    // yarns[atom.id.site].add(atom);

    _controller.add(atom);
  }

  // Add to deletedAtoms set
  void _delete(CausalAtom atom, [int index]) {
    deletedAtoms.add(atom.cause);
    deletedAtoms.add(atom.clock);
    _insert(atom, index);
  }

  void mergeRemoteAtoms(List<CausalAtom<T>> atoms) {
    for (final atom in atoms) {
      if (atom.data == null) {
        _delete(atom);
      } else {
        _insert(atom);
      }
    }
  }

  CausalAtom<T> insert(CausalAtom parent, T value) {
    final atom = CausalAtom<T>(
      _newID(),
      parent?.clock,
      value,
    );

    _insert(atom);
    return atom;
  }

  CausalAtom<T> push(T value) {
    final atom = CausalAtom<T>(
      _newID(),
      atoms.isNotEmpty ? atoms.last.clock : null,
      value,
    );

    _insert(atom, atoms.length);
    // maybe just add here?
    return atom;
  }

  void pop() {
    _delete(atoms.last, atoms.length);
  }

  CausalAtom<T> delete(CausalAtom a) {
    final atom = CausalAtom<T>(
      _newID(),
      a?.clock,
      null,
    );

    _delete(atom);
    return atom;
  }

  // TODO assert if no filter;
  static CausalTree filter(CausalTree tree, {int timestamp, Set<int> siteid}) {
    final newTree = CausalTree(tree.site);
    var atoms = <CausalAtom>[];

    if (siteid != null) {
      Set ids = siteid.toSet();
      atoms.addAll(tree.atoms.where((a) => ids.contains(a.site)));
    }

    if (timestamp != null) {
      if (atoms.isNotEmpty) {
        atoms = atoms.where((a) => a.clock.counter <= timestamp).toList();
      } else {
        atoms.addAll(tree.atoms.where((a) => a.clock.counter <= timestamp));
      }
    }

    newTree.mergeRemoteAtoms(atoms);

    return newTree;
  }

  ///
  /// What happens if the ref points/parent are filted out????
  /// CausalLink breaks?
  // TODO assert if no filter;
  static CausalTree filter2(CausalTree tree, {int timestamp, Set<int> siteid}) {
    final newTree = CausalTree(tree.site);
    var filteredYarns = <int, List<CausalAtom>>{};

    if (siteid != null) {
      for (final id in siteid) {
        filteredYarns[id] = tree.yarns[id];
      }
    }

    if (timestamp != null) {
      final yarns = siteid != null ? filteredYarns : tree.yarns;

      for (final atomList in yarns.values) {
        final index = atomList.indexWhere((a) => a.clock.counter == timestamp);
        newTree.mergeRemoteAtoms(atomList.sublist(0, index + 1));
      }
    } else {
      // apply filterd yarns
      for (final yarn in filteredYarns.values) {
        newTree.mergeRemoteAtoms(yarn);
      }
    }

    return newTree;
  }

  @override
  String toString() {
    return atoms.where((a) => !(a.data == null || deletedAtoms.contains(a.clock))).map(((a) {
      return a.data;
    })).join('');
  }
}
