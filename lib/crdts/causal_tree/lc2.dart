/// Compare operator like [>, <, ==] consider only the time aspect of the clock
/// not the site.
///
/// To fully compare if two Logical clocks are equal, use the provides compare
/// methods [isLessWithSite], [isGreaterWithSite] etc
///
abstract class LogicalClockBase<T> implements Comparable<T> {
  final int logicalTime;

  factory LogicalClockBase.send(LogicalClockBase lc) {
    throw AssertionError('Abstract class factory');
  }

  factory LogicalClockBase.recv(LogicalClockBase lc) {
    throw AssertionError('Abstract class factory');
  }

  factory LogicalClockBase.parse(String ts) {
    throw AssertionError('Abstract class factory');
  }

  // radix time in minutes!
  String radixTime(int radix);

  /// This compares **without** site!
  @override
  int compareTo(T other);

  @override
  bool operator ==(other);

  /// This compares only the time and does not consider site comparision
  bool operator <(other);
  bool operator <=(other);

  /// This compares only the time and does not consider site comparisions
  bool operator >(other);
  bool operator >=(other);

  /// will get the time difference
  /// TODO: maybe container class?
  List<int> operator -(other);
}

void main() {
  final l1 = LogicalClock(0);
  final l2 = LogicalClock(0);
}

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
  List<int> operator -(other) {
    final o = other as LogicalClock;
    return [logicalTime - o.logicalTime];
  }

  @override
  String toString() => 'T$logicalTime';
}
