import 'abstract/logical_clock_base.dart';

class LogicalClock implements LogicalClockBase<LogicalClock> {
  /// to be compatible to js, only 32 bits!
  @override
  final int logicalTime;

  LogicalClock(this.logicalTime) : assert(logicalTime != null && logicalTime >= 0);

  @override
  String radixTime(int radix) => logicalTime.toRadixString(radix);

  @override
  factory LogicalClock.send(LogicalClock lc) => LogicalClock(lc.logicalTime + 1);

  @override
  factory LogicalClock.recv(LogicalClock lc) => LogicalClock(lc.logicalTime + 1);

  @override
  factory LogicalClock.fromLogical(int ts) => LogicalClock(ts);

  @override
  factory LogicalClock.parse(String ts) {
    throw AssertionError('not clear, how this should be handeled');
  }

  @override
  int compareTo(LogicalClock o) => logicalTime.compareTo(o.logicalTime);

  @override
  int get hashCode => logicalTime;

  /// compares only counter/time!! not site!!
  @override
  bool operator ==(o) => o is LogicalClock && logicalTime == o.logicalTime;

  /// compares the time if less/smaller counter => its older!
  @override
  bool operator <(o) => o is LogicalClock && logicalTime < o.logicalTime;
  @override
  bool operator <=(o) => o is LogicalClock && logicalTime <= o.logicalTime;

  /// compares the time if greater/bigger counter => its newer!
  @override
  bool operator >(o) => o is LogicalClock && logicalTime > o.logicalTime;

  @override
  bool operator >=(o) => o is LogicalClock && logicalTime >= o.logicalTime;

  /// calculates only the diffes of the [counter]
  @override
  int operator -(other) {
    final o = other as LogicalClock;
    return logicalTime - o.logicalTime;
  }

  /// TODO: who should logical clock be printed! ??
  @override
  String toString() => '$logicalTime';
}
