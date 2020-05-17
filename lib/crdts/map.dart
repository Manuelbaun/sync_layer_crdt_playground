import 'dart:convert';

import 'package:sync_layer/basic/index.dart';
import 'package:sync_layer/types/id_atom.dart';
import 'package:sync_layer/types/index.dart';

/// This CRDT map is currently not working!

class AtomMapValue<K, V> {
  final String objId;
  final K key;
  final V value;
  AtomMapValue(this.objId, this.key, this.value);
}

///
/// A CRDT Map implements the Last Writer Wins Strategy only
/// This map can be used to represent a Row in a database table
///
/// This is a general CRDT Map and can be standalone
///
class CRDTMap<K, V> {
  final String objId;
  int site;

  // stores the value
  final Map<K, V> _obj = <K, V>{};
  // stores the Hlc for each Key
  final Map<K, HybridLogicalClock> _objHlc = <K, HybridLogicalClock>{};

  final history = <Atom>[];
  final historySet = <int>{};

  // the highes of all _clocks!!
  HybridLogicalClock _timestamp;
  HybridLogicalClock get hlc => _timestamp;

  CRDTMap([String objId]) : objId = objId ?? newCuid();

  factory CRDTMap.fromMap(Map<String, V> map) {
    final obj = (map['obj'] as Map);
    final objHlc = (map['objHlc'] as Map);

    return CRDTMap(map['objId'] as String).._obj.addAll(obj).._objHlc.addAll(objHlc);
  }

  /// This funtion just overrides the map value
  void operator []=(K key, V value) => set(key, value);

  Atom set(K key, V value) {
    // Todo: form Atom
    _timestamp = HybridLogicalClock.send(_timestamp);
    _obj[key] = value;
    _objHlc[key] = _timestamp;

    final v = AtomMapValue<K, V>(objId, key, value);

    /// TODO: Fix me !!
    // return Atom(AtomId(_timestamp, 0000000), 0, '???????????????????', v);
    throw AssertionError('Fix me');
  }

  /// get value by key. Same property as the underlaying map
  V operator [](Object key) => get(key);
  V get(K key) => _obj[key];

  void mergeRemote(List<Atom> atoms) {
    for (final atom in atoms) {
      if (!historySet.contains(atom.hashCode)) {
        historySet.add(atom.hashCode);
        history.add(atom);

        /// only merge if Atom of remote > then local
        _timestamp = HybridLogicalClock.recv(_timestamp, atom.id.ts);

        for (var e in atom.data.entries) {
          final key = e.key as K;
          final value = e.value;

          // if localtime is smaller..
          if (_objHlc[key] < atom.id.ts) {
            _obj[key] = value;
            _objHlc[key] = atom.id.ts;
          } else if (_obj[key] == null) {
            // if no local entry exist
            _obj[key] = value;
            _objHlc[key] = atom.id.ts;
          } else if (_objHlc[key] == atom.id.ts) {
            // TODO: sort by nodeid

          } // else ignore
        }
      }
    }

    history.sort();
  }

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;
    return hashCode == (o as CRDTMap).hashCode;
  }

  static bool deepEqual(CRDTMap lhs, CRDTMap rhs) {
    return lhs.hashCode == rhs.hashCode;
  }

  @override
  int get hashCode {
    var hashcode = 0;

    for (final entry in _obj.entries) {
      hashcode ^= (entry.key.hashCode) ^ entry.value.hashCode;
    }

    return hashcode;
  }

  @override
  String toString() {
    final obj = {
      'id': objId,
      'obj': _obj,
      'objHlc': _objHlc,
    };
    return json.encode(obj);
  }
}
