abstract class LogicalClockBase<T> implements Comparable<T> {
  final int logicalTime;

  external factory LogicalClockBase.send(LogicalClockBase lc);
  external factory LogicalClockBase.recv(LogicalClockBase lc);
  external factory LogicalClockBase.parse(String ts);
  external factory LogicalClockBase.fromLogicalTimestamp(int ts);

  // radix time in minutes!
  String radixTime(int radix);

  /// This compares **without** site!
  @override
  int compareTo(T other);

  @override
  bool operator ==(other);
  bool operator <(other);
  bool operator <=(other);
  bool operator >(other);
  bool operator >=(other);
  int operator -(other);
}
