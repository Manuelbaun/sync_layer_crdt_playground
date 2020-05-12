import 'dart:async';
import 'dart:typed_data';

import 'package:msgpack_dart/msgpack_dart.dart';
import 'package:sync_layer/timestamp/index.dart';
import 'package:sync_layer/crdts/atom.dart';

class CausalTree<T> {
  int owner;
  Hlc localClock;

  //! this Atom array has to be the same on all other sides.
  List<CausalAtom<T>> atoms = <CausalAtom<T>>[];

  final _controller = StreamController<Atom>();

  Stream<Atom> get stream => _controller.stream;

  // should we use deltedAtoms?
  Set<Hlc> deletedAtoms = {};
  Set<Hlc> allAtomIds = {};

  int get length => allAtomIds.length - deletedAtoms.length;
  int get deleteAtomsLength => deletedAtoms.length;
  int get allAtomsLength => allAtomIds.length;

  //! the local site cache, does not need to be the same in the cloud
  final yarns = <int, List<CausalAtom<T>>>{};

  /// SiteId -> TimeStamp, Kind of Version vector
  final weft = <int, int>{};

  CausalTree(this.owner) : localClock = Hlc(0, 0, owner);

  // importent, the timestamp needs to be overritten with the new one!
  // only this way, Hlc send is able to increment the counter field;
  Hlc _newID() {
    return localClock = Hlc(0, localClock.counter + 1, owner);
  }

  void _insert(CausalAtom atom, [int index]) {
    // Do not insert if already inserted
    if (allAtomIds.contains(atom.self)) return;
    allAtomIds.add(atom.self);

    // set cause index, if null, then search!
    var causeIndex = index;
    causeIndex ??= atoms.indexWhere((a) {
      return a.self == atom.cause;
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
    deletedAtoms.add(atom.self);
    _insert(atom, index);
  }

  void mergeRemoteAtoms(List<CausalAtom<T>> atoms) {
    for (final atom in atoms) {
      if (atom.value == null) {
        _delete(atom);
      } else {
        _insert(atom);
      }
    }
  }

  CausalAtom<T> insert(CausalAtom parent, T value) {
    final atom = CausalAtom<T>(
      self: _newID(),
      value: value,
      cause: parent?.self,
    );

    _insert(atom);
    return atom;
  }

  CausalAtom<T> push(T value) {
    final atom = CausalAtom<T>(
      self: _newID(),
      value: value,
      cause: atoms.isNotEmpty ? atoms.last.self : null,
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
      self: _newID(),
      value: null,
      cause: a?.self,
    );

    _delete(atom);
    return atom;
  }

  // TODO assert if no filter;
  static CausalTree filter(CausalTree tree, {int timestamp, Set<int> siteid}) {
    final newTree = CausalTree(tree.owner);
    var atoms = <CausalAtom>[];

    if (siteid != null) {
      Set ids = siteid.toSet();
      atoms.addAll(tree.atoms.where((a) => ids.contains(a.site)));
    }

    if (timestamp != null) {
      if (atoms.isNotEmpty) {
        atoms = atoms.where((a) => a.self.logicalTime <= timestamp).toList();
      } else {
        atoms.addAll(tree.atoms.where((a) => a.self.logicalTime <= timestamp));
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
    final newTree = CausalTree(tree.owner);
    var filteredYarns = <int, List<CausalAtom>>{};

    if (siteid != null) {
      for (final id in siteid) {
        filteredYarns[id] = tree.yarns[id];
      }
    }

    if (timestamp != null) {
      final yarns = siteid != null ? filteredYarns : tree.yarns;

      for (final atomList in yarns.values) {
        final index = atomList.indexWhere((a) => a.self.logicalTime == timestamp);
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
    return atoms.where((a) => !(a.value == null || deletedAtoms.contains(a.id))).map(((a) {
      return a.value;
    })).join('');
  }
}

/// TODO en/decode
/// T must be also en/decodeable!!!
class CausalAtom<T> extends Atom {
  final Hlc cause;
  Hlc get self => hlc;

  CausalAtom({this.cause, Hlc self, String type, String object_id, String key, T value})
      : super(self, type, object_id, key, value);

  /// Checks wheter Atom **lhs** is causal **`less`** then **rhs**.
  /// Less means it is **left** to the other atom in the array.
  ///
  /// `**Note**: you can use the < operator`
  ///
  /// Rules:
  /// 1. If Atoms are sequence of charactors, then it is sorted by the timestamp [ASC Order]
  /// 2. If two Atoms don't have the same cause, they are not either sequence nor related
  /// 3. If same cause (parent): Then the Atom with the highest timestamp is right next to the parent in the array.
  /// The highest timestamp means the youngest atom or the lastest edit.
  /// 4. if the times are equal, then it gets sorted by the site [DESC ORDER]
  static int compare(CausalAtom left, CausalAtom right) {
    // if cause is equal => siblings
    if (left.cause == right.cause) {
      if (left.hlc > right.hlc) {
        return -1;
      } else if (left.hlc == right.hlc) {
        // TODO: test if this comapre is correct!
        return right.site - left.site;
      }
    }

    return 0;
  }

  @override
  Uint8List toBytes() {
    final list = [cause?.logicalTime, cause?.site, self.logicalTime, self.site, type, id, key, value];
    return serialize(list);
  }

  @override
  factory CausalAtom.fromBytes(Uint8List buff) {
    final list = deserialize(buff) as List;

    return CausalAtom(
      cause: list[0] != null ? Hlc.fromLogicalTime(list[0], list[1]) : null,
      self: Hlc.fromLogicalTime(list[2], list[3]),
      type: list[4],
      object_id: list[5],
      key: list[6],
      value: list[7],
    );
  }

  static bool isSibling(CausalAtom a, CausalAtom b) => a.cause == b.cause;

  /// This function only to be used in the context when two atoms are siblings to the same cause.
  /// then a loop should call this function to compare if the atom on the left side
  /// is still
  static bool leftIsLeft(CausalAtom left, CausalAtom right) {
    if (left.hlc > right.hlc) {
      return true;
    } else if (left.hlc == right.hlc) {
      return left.site > right.site;
    }
    return false;
  }

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;
    return o is CausalAtom && cause == o.cause && hlc == o.hlc;
  }

  String get siteId => 'S${hlc.site?.toRadixString(16)}@T${hlc.logicalTime}';
  String get causeId => 'S${cause?.site?.toRadixString(16)}@T${cause?.logicalTime}';

  @override
  String toString() => '${siteId}-${causeId} : ${value}';
}
