import 'dart:async';

import 'package:sync_layer/crdts/causal_tree/causal_entry.dart';
import 'package:sync_layer/crdts/causal_tree/causal_tree.dart';
import 'package:sync_layer/types/abstract/atom_base.dart';
import 'package:sync_layer/types/abstract/id_base.dart';

import 'abstract/acess_proxy.dart';
import 'abstract/syncable_base.dart';

/// Actually, this is a syncable ordered list!!!
/// like it is implemented
///
/// The causal tree, handels its one entries ... => how to work with this??
///
/// At the moment [SyncableCausalTree] atom in creation order
/// no pending sync mechanism yet
///
///
/// TODO:
/// * Object reference
/// * Pending sync
/// * tombstone
/// * abstract causal tree
/// * rename in ordered list?
class SyncableCausalTree<T> implements SyncableBase {
  SyncableCausalTree(this.proxy, this.id)
      : assert(proxy != null, 'Accessor prop cannot be null'),
        assert(id != null, 'Id cannot be null') {
    tombstone = false;
    _internal = CausalTree(proxy.site, onChange: _onTreeChange);
  }

  void _onTreeChange(CausalEntry<T> entry) {
    _filteredEntries = _internal.value();

    /// THis here needs a revisit!!!
    final a = proxy.update(id, entry);
    _controller.add(values);
  }

  final StreamController _controller = StreamController();
  Stream<List<T>> get stream => _controller.stream;

  CausalTree<T> _internal;

  /// this is a workaround to get index and entries mapped
  List<CausalEntry<T>> _filteredEntries = <CausalEntry<T>>[];
  List<CausalEntry<T>> get entries => _filteredEntries;
  List<T> get values => _filteredEntries.map((e) => e.data).toList();

  final AccessProxy proxy;

  /// The object type
  @override
  int get type => proxy.type;

  /// Marks if the object is deleted!
  @override
  bool tombstone;

  /// Object Id, Like RowId or Index in a Database, etc..
  @override
  final String id;

  /// gets the last Updated TS and also site!
  @override
  IdBase get lastUpdated => _lastUpdated;
  IdBase _lastUpdated;

  /// will use an list
  @override
  void transact(void Function(SyncableBase ref) func) {
    throw AssertionError('not supported yet');
  }

  final _history = <AtomBase>{};
  List<AtomBase> get history => _history.toList(growable: false)..sort();

  /// applies atom and returns
  /// * returns [ 2] : if apply successfull
  /// * returns [ 1] : if atom clock is equal to current => same atom
  /// * returns [ 0] : if atom is older then current
  /// * returns [-1] : if nothing applied => should never happen

  @override
  int applyAtom(AtomBase atom) {
    print(id);
    final entries = (atom.data is List) ? atom.data as List<CausalEntry<T>> : <CausalEntry<T>>[atom.data];

    // if atom did not exist, add and merge
    if (_history.add(atom)) {
      // update time;
      if (_lastUpdated == null || _lastUpdated < atom.id) _lastUpdated = atom.id;
      // update causal tree
      _internal.mergeRemoteEntriees(entries);
      return 2;
    }
    return 0;
  }

  /// main functionality
  /// TODO: think
  bool insert(int index, value) {
    print(id);
    assert(index >= 0, 'cant insert negative index');
    assert(index <= _filteredEntries.length, 'greater then length ${_filteredEntries.length}');

    if (index <= 0) {
      _internal.insert(null, value);
    } else if (index == _filteredEntries.length) {
      _internal.push(value);
    } else {
      final parent = _filteredEntries[index - 1];
      _internal.insert(parent, value);
    }

    return false;
  }

  bool add(dynamic value) {
    print(id);
    _internal.push(value);
    return false;
  }

  void pop() {
    _internal.pop();
  }

  bool removeAt(int index) {
    print(id);
    final cause = _filteredEntries[index];
    _internal.delete(cause);
    return false;
  }

  dynamic getAtIndex(int index) {
    print(id);
    return _filteredEntries[index];
  }
}
