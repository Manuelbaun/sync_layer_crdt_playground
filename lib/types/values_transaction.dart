import 'package:sync_layer/logical_clocks/index.dart';

import 'index.dart';

/// Importent Key and value cant be some custom class type!!!
/// unless encoding and decoding is implemented
/// in the  encoding_extent classes
///
class ValueTransaction {
  ValueTransaction();
  LogicalClock baseClock;

  /// Three maps nested! + List!!!
  var internal = <int, Map<String, Map<dynamic, List>>>{};

  Map<String, Map<dynamic, List>> type(int type) {
    return internal[type] ??= <String, Map<dynamic, List>>{};
  }

  Map<dynamic, List> id(int type_, String id) {
    return type(type_)[id] ??= <dynamic, List>{};
  }

  void value(Value val, List<int> diff) {
    id(val.typeId, val.id)[val.key] = [val.value, diff[0], diff[1]];
  }

  /// this has its limit!!!!
  /// do not use to many atoms!!  greate
  /// ! This does not work always!
  factory ValueTransaction.fromAtoms(List<Atom> atoms) {
    assert(atoms != null && atoms.isNotEmpty, 'Please provide some atoms');
    final v = ValueTransaction();
    v.baseClock = atoms.first.clock;

    for (var a in atoms) {
      if (a.data is Value) {
        // gets the ms and counter diff to base clock
        /// TODO: construct
        var d = a.clock - v.baseClock;

        // var d = diff[0] << 16 | (diff[1] & 0xffff);
        v.value(a.data, d);
      }
    }
    return v;
  }

  /// This still does not guarantie the right timestamp/clock!!!
  /// above from atoms factory takes only the counter,
  static List<Atom> transaction2Atoms(Hlc baseclock, Map<int, Map<String, Map<dynamic, List>>> v) {
    final atoms = <Atom>[];

    for (final m in v.entries) {
      final type = m.key;

      for (final m2 in m.value.entries) {
        final id = m2.key;

        for (final m3 in m2.value.entries) {
          final field = m3.key;
          final value = m3.value[0];

          final msDiff = m3.value[1];
          final counterDiff = m3.value[2];

          final clock = Hlc(baseclock.ms + msDiff, baseclock.counter + counterDiff, baseclock.site);

          atoms.add(Atom(clock, Value(type, id, field, value)));
        }
      }
    }
    atoms.sort();
    return atoms;
  }
}
