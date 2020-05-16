import 'dart:async';

import 'package:sync_layer/types/index.dart';
import 'package:sync_layer/logical_clocks/index.dart';

class CausalTree<T> {
  int site;
  LogicalTime localClock;

  //! this Atom array has to be the same on all other sides.
  List<CausalAtom<T>> sequence = <CausalAtom<T>>[];

  /// TODO: sync is true
  final _controller = StreamController<CausalAtom>(sync: true);
  Stream<CausalAtom> get stream => _controller.stream;

  // should we use deltedAtoms?
  final Set<LogicalClock> _deletedAtoms = {};
  final Set<LogicalClock> _cache = {};

  // if atoms could not find the cause in this tree, but belong to this one
  final pendingAtoms = <CausalAtom>[];

  int get length => _cache.length - _deletedAtoms.length;
  int get deleteAtomsLength => _deletedAtoms.length;
  int get allAtomsLength => _cache.length;

  //! the local site cache, does not need to be the same in the cloud
  final yarns = <int, List<CausalAtom>>{};

  /// SiteId -> TimeStamp, Kind of Version vector
  final weft = <int, int>{};

  CausalTree(this.site) : localClock = LogicalTime(0, site);

  /// New LogicalTime will increase monotonically. Therefore, an Atoms of the
  /// same site cannot have the same counter.
  LogicalTime _newID() => localClock = LogicalTime(localClock.counter + 1, site);

  void _insert(CausalAtom atom, [int index]) {
    if (_cache.contains(atom.clock)) return;
    _cache.add(atom.clock);

    // set cause index, if null, then search!
    var causeIndex = index;
    causeIndex ??= sequence.indexWhere((a) => a.id == atom.causeId);

    if (sequence.isEmpty || causeIndex >= sequence.length - 1) {
      sequence.add(atom);
      // print('Add $atom  :: $causeIndex');
    } else

    /// insert after cause
    if (causeIndex >= 0) {
      causeIndex += 1;

      /// checks if atom to insert and atom at causeIndex are siblings
      if (atom.causeId == sequence[causeIndex].causeId) {
        /// increase causeIndex and check if atom at causeIndex is left of current atom
        while (causeIndex < sequence.length && sequence[causeIndex].isLeftOf(atom)) {
          causeIndex++;
        }
      }

      // print('insert $atom :: $causeIndex');
      sequence.insert(causeIndex, atom);
    } else if (causeIndex < 0 && sequence.isNotEmpty) {
      pendingAtoms.add(atom);

      /// TODO: mechanism to insert pending atom
      print('pending atom $atom');
      // throw AssertionError('Pending is not supported yet');
    }

    yarns[atom.site] ??= <CausalAtom<T>>[];
    yarns[atom.site].add(atom);

    _controller.add(atom);
  }

  // Add to deletedAtoms set
  void _delete(CausalAtom atom, [int index]) {
    _deletedAtoms.add(atom.cause);
    _deletedAtoms.add(atom.clock);
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
      sequence.isNotEmpty ? sequence.last.clock : null,
      value,
    );

    _insert(atom, sequence.length);
    // maybe just add here?
    return atom;
  }

  void pop() {
    _delete(sequence.last, sequence.length);
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

  /// [semantic] is set to [OR] by default, means either [ts] or [siteid] will be filterd by
  ///
  /// if set to **AND**: it is expected to use one or both [tsMin, tsMax] **and** the [siteid/s]
  ///
  /// When filter by time:  **tsMin <= ts < tsMax**
  /// [tsMin] is inclusive
  /// [tsMax] is not included anymore
  ///
  List<CausalAtom> filtering({
    int tsMin,
    int tsMax,
    Set<int> siteid,
    bool containsDeleted = false,
    semantic = FilterSemantic.OR,
  }) {
    assert(!(tsMax == null && tsMin == null && siteid == null), 'all filter are null, cannot filter by something');

    var atoms = <CausalAtom>[];

    for (var a in sequence) {
      var hasTs = _filterTimestamp(a, tsMin, tsMax);
      var hasId = _filterSiteIds(a, siteid);
      var isDeleted = _filterIsDelete(a);

      var should = false;
      if (semantic == FilterSemantic.OR) {
        should = (hasTs || hasId) && !isDeleted;
      } else {
        should = hasTs && hasId && !isDeleted;
      }

      // final aStr = a.toString().padRight(20);
      // final s = '$should'.padRight(10);
      // final ht = '$hasTs'.padRight(10);
      // final hID = '$hasId'.padRight(10);
      // final hD = '$isDeleted'.padRight(10);

      // print('$aStr => $s : TS: $ht : ID: $hID  D: $hD');

      if (should) atoms.add(a);
    }

    return atoms;
  }

  /// returns [false] if tsMin [AND] tsMax is [null], else check the time cases
  bool _filterTimestamp(CausalAtom a, int tsMin, int tsMax) {
    if (tsMin == null && tsMax == null) return false;

    if (tsMin != null && tsMax != null) {
      return tsMin <= a.counter && a.counter < tsMax;
    }

    if (tsMin != null) return tsMin <= a.clock.counter;
    if (tsMax != null) return a.clock.counter < tsMax;

    throw AssertionError('should never be reached');
  }

  /// returns true if data is null or the atom is deleted
  bool _filterIsDelete(CausalAtom a) {
    return a.data == null || _deletedAtoms.contains(a.clock);
  }

  /// returns false if siteid is null or does not contain the id
  bool _filterSiteIds(CausalAtom a, Set<int> siteid) {
    return siteid == null ? false : siteid.contains(a.site);
  }

  @override
  String toString() {
    return sequence.where((a) => !(a.data == null || _deletedAtoms.contains(a.clock))).map(((a) {
      return a.data;
    })).join('');
  }
}

enum FilterSemantic { AND, OR }

// class TimestampFilter {
//   final int min;
//   final int max;
//   TimestampFilter({this.max, this.min});
// }
