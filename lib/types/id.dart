import 'package:sync_layer/basic/murmur_hash.dart';

import 'abstract/id_base.dart';
import 'abstract/logical_clock_base.dart';

/// Id has < >  == operator, they compare first te logical Clock
/// and then the site!
class Id implements IdBase, Comparable<Id> {
  Id(this.ts, this.site)
      : assert(ts != null, 'ts cant be null'),
        assert(site != null, 'site cant be null') {
    // ensure only 32 bits, ts hashcode is 32 bits
    // TODO: radixtime? or maybe just hashCode are enough?

    _string = '${site}-${ts.logicalTime}';
    _hashCode = MurmurHashV3(_string);
  }

  @override
  final LogicalClockBase ts;

  @override
  final int site;
  int _hashCode;
  String _string;

  @override
  String toString() => 'Id($_string)';
  
  String toStringPretty() => 'Id(ts: $ts, site: $site)';

  @override
  String toRONString() => 'S' + '$site'.padLeft(2, '0') + '@T' + '$ts'.padLeft(2, '0');

  /// Id compares first LogicalClock and then Site
  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;
    return _hashCode == o.hashCode;
  }

  /// Id compares first LogicalClock and then Site
  @override
  bool operator <(Object o) => (o is Id) && (ts == o.ts ? site < o.site : ts < o.ts);

  /// Id compares first LogicalClock and then Site
  @override
  bool operator >(Object o) => (o is Id) && (ts == o.ts ? site > o.site : ts > o.ts);

  /// hashCode is a [MurmurHashV3]  of the timestamp and the site converted into String
  /// then hashed
  @override
  int get hashCode => _hashCode;

  @override
  int compareTo(Id other) {
    final res = ts.compareTo(other.ts);
    if (res == 0) return site.compareTo(site);
    return res;
  }
}
