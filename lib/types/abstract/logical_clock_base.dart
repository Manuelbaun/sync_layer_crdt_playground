abstract class LogicalClockBase<T> implements Comparable<T> {
  final int logicalTime;

  external factory LogicalClockBase.send(LogicalClockBase lc);
  external factory LogicalClockBase.recv(LogicalClockBase lc);
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
