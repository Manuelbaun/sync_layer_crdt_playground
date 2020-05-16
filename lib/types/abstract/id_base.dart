import 'logical_clock_base.dart';

abstract class IdBase {
  IdBase(this.ts, this.site);
  final LogicalClockBase ts;
  final int site;

  String toRONString();

  /// Id compares first LogicalClock and then Site
  @override
  bool operator ==(Object o);

  /// Id compares first LogicalClock and then Site
  bool operator <(Object o);

  /// Id compares first LogicalClock and then Site
  bool operator >(Object o);
}
