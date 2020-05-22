import 'dart:math';

import 'abstract/logical_clock_base.dart';

/// now, logical clock can be made more general with HLC!
/// TODO:
/// * match the Hybrid Logical Clock implements with logical clock!
/// or extend from logical clock
class LogicalClock implements LogicalClockBase<LogicalClock> {
  /// to be compatible to js, only 32 bits!
  @override
  int get logicalTime => counter;
  @override
  final int counter;

  LogicalClock(this.counter) : assert(counter != null && counter >= 0);

  @override
  @pragma('vm:prefer-inline')
  String radixTime(int radix) => logicalTime.toRadixString(radix);

  /// when called will increase the logicalTime by 1
  @override
  @pragma('vm:prefer-inline')
  factory LogicalClock.send(LogicalClock lc) => LogicalClock(lc.logicalTime + 1);

  /// Takes the maximum of both clocks /// Think again, should it increase too,
  /// like in HLC??? since send increase it
  @override
  @pragma('vm:prefer-inline')
  factory LogicalClock.recv(LogicalClock local, LogicalClock remote) {
    return LogicalClock.fromLogical(max(local.logicalTime, remote.logicalTime) + 1);
  }

  @override
  @pragma('vm:prefer-inline')
  factory LogicalClock.fromLogical(int ts) => LogicalClock(ts);

  @override
  factory LogicalClock.parse(String ts) {
    throw AssertionError('not clear, how this should be handeled');
  }

  @override
  @pragma('vm:prefer-inline')
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
