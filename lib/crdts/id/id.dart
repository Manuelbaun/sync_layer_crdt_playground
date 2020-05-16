import 'package:sync_layer/basic/index.dart';
import 'package:sync_layer/crdts/id/logical_clock_base.dart';

/// At the moment Id is only used within Causal Tree!!!!
class Id {
  final LogicalClockBase ts;
  final int site;
  final int _hashCode;
  Id(this.ts, this.site)
      : assert(ts != null, 'ts cant be null'),
        assert(site != null, 'site cant be null'),

        /// ensure only 32 bits, ts hashcode is 32 bits
        // TODO: radixtime? or maybe just hashCode are enough?

        _hashCode = MurmurHashV3('${ts.logicalTime}-${site}');

  @override
  String toString() => 'Id(ts: $ts, site: $site)';

  String toRON() => 'S$site@T${ts}';

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;
    return _hashCode == o.hashCode;

    // /// Or hashcode!
    // return o is Id && o.ts == ts && o.site == site;
  }

  @override
  int get hashCode => _hashCode;
}
