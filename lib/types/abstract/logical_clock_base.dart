abstract class LogicalClockBase<T> implements Comparable<T> {
  int get logicalTime;
  final int counter;

  external factory LogicalClockBase.send(LogicalClockBase lc);
  external factory LogicalClockBase.recv(LogicalClockBase local, LogicalClockBase remote);
  external factory LogicalClockBase.parse(String ts);
  external factory LogicalClockBase.fromLogicalTimestamp(int ts);

  /// radix time from [minutes] in Case of [HLC] implementation
  /// otherwise from [logicalTime]
  String radixTime(int radix);

  @override
  bool operator ==(other);
  bool operator <(other);
  bool operator <=(other);
  bool operator >(other);
  bool operator >=(other);
  int operator -(other);
}
