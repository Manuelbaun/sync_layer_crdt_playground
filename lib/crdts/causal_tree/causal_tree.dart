import 'dart:async';

import 'causal_entry.dart';
import 'id.dart';
import 'lc2.dart';

enum FilterSemantic { AND, OR }

class CausalTree<T> {
  CausalTree(this.site) : localClock = LogicalClock(0);
  int site;

  //! this Atom array has to be the same on all other sides.
  List<CausalEntry<T>> sequence = <CausalEntry<T>>[];

  /// TODO: sync is true
  final _controller = StreamController<CausalEntry>(sync: true);
  Stream<CausalEntry> get stream => _controller.stream;

  // should we use deltedAtoms?
  final Set<Id> _deletedAtoms = {};
  final Set<Id> _cache = {};

  // if atoms could not find the cause in this tree, but belong to this one
  final pendingAtoms = <CausalEntry>[];

  int get length => _cache.length - _deletedAtoms.length;
  int get deleteAtomsLength => _deletedAtoms.length;
  int get allAtomsLength => _cache.length;

  //! the local site cache, does not need to be the same in the cloud
  final yarns = <int, List<CausalEntry>>{};

  /// SiteId -> TimeStamp, Kind of Version vector
  final weft = <int, int>{};

  /// New LogicalTime will increase monotonically. Therefore, an Atoms of the
  /// same site cannot have the same counter.
  LogicalClockBase localClock;

  Id _newID() {
    localClock = LogicalClock.send(localClock);
    return Id(localClock, site);
  }

  void _insert(CausalEntry entry, [int index]) {
    if (_cache.contains(entry.id)) return;
    _cache.add(entry.id);

    // set cause index, if null, then search!
    var causeIndex = index;
    causeIndex ??= sequence.indexWhere((e) => e.id == entry.cause);

    if (sequence.isEmpty || causeIndex >= sequence.length - 1) {
      sequence.add(entry);
      // print('Add $atom  :: $causeIndex');
    } else

    /// insert after cause
    if (causeIndex >= 0) {
      causeIndex += 1;

      /// checks if atom to insert and atom at causeIndex are siblings
      if (entry.cause == sequence[causeIndex].cause) {
        /// increase causeIndex and check if atom at causeIndex is left of current atom
        while (causeIndex < sequence.length && sequence[causeIndex].isLeftOf(entry)) {
          causeIndex++;
        }
      }

      // print('insert $atom :: $causeIndex');
      sequence.insert(causeIndex, entry);
    } else if (causeIndex < 0 && sequence.isNotEmpty) {
      pendingAtoms.add(entry);

      /// TODO: mechanism to insert pending atom
      print('pending atom $entry');
      // throw AssertionError('Pending is not supported yet');
    }

    yarns[entry.site] ??= <CausalEntry<T>>[];
    yarns[entry.site].add(entry);

    _controller.add(entry);
  }

  // Add to deletedAtoms set
  void _delete(CausalEntry entry, [int index]) {
    _deletedAtoms.add(entry.cause);
    _deletedAtoms.add(entry.id);
    _insert(entry, index);
  }

  void mergeRemoteAtoms(List<CausalEntry<T>> entries) {
    for (final atom in entries) {
      if (atom.data == null) {
        _delete(atom);
      } else {
        _insert(atom);
      }
    }
  }

  CausalEntry<T> insert(CausalEntry parent, T value) {
    final atom = CausalEntry<T>(
      _newID(),
      cause: parent?.id,
      data: value,
    );

    _insert(atom);
    return atom;
  }

  CausalEntry<T> push(T value) {
    final atom = CausalEntry<T>(
      _newID(),
      cause: sequence.isNotEmpty ? sequence.last.id : null,
      data: value,
    );

    _insert(atom, sequence.length);
    // maybe just add here?
    return atom;
  }

  void pop() {
    _delete(sequence.last, sequence.length);
  }

  CausalEntry<T> delete(CausalEntry entry) {
    final atom = CausalEntry<T>(
      _newID(),
      cause: entry?.id,
      data: null,
    );

    _delete(atom);
    return atom;
  }

  /// [semantic] is set to [OR] by default, means either [logicalTime] or [siteid] will be filterd by
  ///
  /// if set to **AND**: it is expected to use one or both [tsMin, tsMax] **and** the [siteid/s]
  ///
  /// When filter by time:  **tsMin <= ts < tsMax**
  /// [tsMin] is inclusive
  /// [tsMax] is not included anymore
  ///
  List<CausalEntry> filtering({
    LogicalClockBase tsMin,
    LogicalClockBase tsMax,
    Set<int> siteid,
    bool containsDeleted = false,
    semantic = FilterSemantic.OR,
  }) {
    assert(
      !(tsMax == null && tsMin == null && siteid == null),
      'all filter are null, cannot filter by something',
    );

    /// test, that tsMin/Max and _localClock are of same logical clock type!
    /// cant compare Hlc with LogicalClock
    if (tsMin != null) assert(tsMin.runtimeType == localClock.runtimeType);
    if (tsMax != null) assert(tsMax.runtimeType == localClock.runtimeType);

    var atoms = <CausalEntry>[];

    for (var entry in sequence) {
      var hasTs = _filterTimestamp(entry, tsMin, tsMax);
      var hasId = _filterSiteIds(entry, siteid);
      var isDeleted = _filterIsDelete(entry);

      var should = false;
      if (semantic == FilterSemantic.OR) {
        should = (hasTs || hasId) && !isDeleted;
      } else {
        should = hasTs && hasId && !isDeleted;
      }

      if (should) atoms.add(entry);
    }

    return atoms;
  }

  /// returns [false] if tsMin [AND] tsMax is [null], else check the time cases
  bool _filterTimestamp(CausalEntry entry, LogicalClockBase tsMin, LogicalClockBase tsMax) {
    if (tsMin == null && tsMax == null) return false;

    if (tsMin != null && tsMax != null) {
      return tsMin <= entry.ts && entry.ts < tsMax;
    }

    if (tsMin != null) return tsMin <= entry.ts;
    if (tsMax != null) return entry.ts < tsMax;

    throw AssertionError('should never be reached');
  }

  /// returns true if data is null or the atom is deleted
  bool _filterIsDelete(CausalEntry entry) {
    return entry.data == null || _deletedAtoms.contains(entry.id);
  }

  /// returns false if siteid is null or does not contain the id
  bool _filterSiteIds(CausalEntry entry, Set<int> siteid) {
    return siteid == null ? false : siteid.contains(entry.site);
  }

  @override
  String toString() {
    return sequence.where((entry) => !(entry.data == null || _deletedAtoms.contains(entry.id))).map(((a) {
      return a.data;
    })).join('');
  }
}
