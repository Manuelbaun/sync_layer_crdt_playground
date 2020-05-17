import 'package:sync_layer/basic/murmur_hash.dart';

import 'abstract/id_base.dart';
import 'hybrid_logical_clock.dart';

/// Id has < >  == operator, they compare first te logical Clock
/// and then the site!
class AtomId implements IdBase, Comparable<AtomId> {
  AtomId(this.ts, this.site)
      : assert(ts != null, 'ts cant be null'),
        assert(site != null, 'site cant be null'),
        // ensure only 32 bits, ts hashcode is 32 bits
        // TODO: radixtime? or maybe just hashCode are enough?
        _hashCode = MurmurHashV3('${ts.logicalTime}-${site}');

  @override
  final HybridLogicalClock ts;

  @override
  final int site;
  final int _hashCode;

  @override
  String toString() => 'Id(ts: $ts, site: $site)';

  @override
  String toRONString() => 'S$site@T${ts}';

  /// Id compares first LogicalClock and then Site
  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;
    return _hashCode == o.hashCode;
  }

  /// Id compares first LogicalClock and then Site
  @override
  bool operator <(Object o) => (o is AtomId) && (ts == o.ts ? site < o.site : ts < o.ts);

  /// Id compares first LogicalClock and then Site
  @override
  bool operator >(Object o) => (o is AtomId) && (ts == o.ts ? site > o.site : ts > o.ts);

  /// hashCode is a [MurmurHashV3]  of the timestamp and the site converted into String
  /// then hashed
  @override
  int get hashCode => _hashCode;

  @override
  int compareTo(AtomId other) {
    final res = ts.compareTo(other.ts);
    if (res == 0) return site.compareTo(site);
    return res;
  }
}
