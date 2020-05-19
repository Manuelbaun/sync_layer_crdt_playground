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
class SyncableCausalTree<Key> implements SyncableBase {
  SyncableCausalTree(this.proxy, this.id)
      : assert(proxy != null, 'Accessor prop cannot be null'),
        assert(id != null, 'Id cannot be null') {
    _internal = CausalTree(proxy.site);

    /// TODO: needs to do some meta updates on this one! set tombstone to true => how?
    tombstone = false;

    _init();
  }

  void _init() {
    _internal.stream.listen((entry) {
      _entriesAccess = _internal.value();

      /// THis here needs a revisit!!!
      proxy.update(id, entry);
    });
  }

  // controller.add('');
  StreamController controller = StreamController.broadcast();
  Stream get stream => controller.stream;
  CausalTree _internal;

  /// this is a workaround to get index and entries mapped
  List<CausalEntry> _entriesAccess = <CausalEntry>[];
  List<CausalEntry> get entries => _entriesAccess;
  List<dynamic> get values => _entriesAccess.map((e) => e.data).toList();

  final AcessProxy proxy;

  /// Marks if the object is deleted!
  @override
  bool tombstone;

  /// The object type
  @override
  int get type => proxy.type;

  /// Object Id, Like RowId or Index in a Database, etc..
  @override
  // String get id => _id;
  final String id;

  /// gets the last Updated TS and also site!
  @override
  IdBase get lastUpdated => _lastUpdated;
  IdBase _lastUpdated;

  /// will use an list
  @override
  void transact(void Function(SyncableBase ref) func) {}

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
    var entries;
    if (atom.data is List) {
      entries = atom.data as List<CausalEntry>;
    } else {
      entries = <CausalEntry>[atom.data];
    }

    if (_history.add(atom)) {
      // update time;
      if (_lastUpdated == null || _lastUpdated < atom.id) _lastUpdated = atom.id;
      // update causal tree
      _internal.mergeRemoteAtoms(entries);
      return 2;
    }
    return 0;
  }

  /// main functionality

  /// TODO: think
  bool insert(int index, value) {
    print(id);
    assert(index >= 0, 'cant insert negative index');
    assert(index <= _entriesAccess.length, 'greater then length ${_entriesAccess.length}');

    if (index <= 0) {
      _internal.insert(null, value);
    } else if (index == _entriesAccess.length) {
      _internal.push(value);
    } else {
      final parent = _entriesAccess[index - 1];
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
    final cause = _entriesAccess[index];
    _internal.delete(cause);
    return false;
  }

  dynamic getAtIndex(int index) {
    print(id);
    return _entriesAccess[index];
  }
}
