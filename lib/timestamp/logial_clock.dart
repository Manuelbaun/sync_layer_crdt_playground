abstract class LogicalClock {
  final int logicalTime;
  final int site;

  // LogicalClock(this.logicalTime, this.site);

  factory LogicalClock.send(LogicalClock lc) {
    throw AssertionError('Abstract class factory');
  }

  factory LogicalClock.recv(LogicalClock lc) {
    throw AssertionError('Abstract class factory');
  }

  factory LogicalClock.parse(String ts) {
    throw AssertionError('Abstract class factory');
  }

  factory LogicalClock.fromLogicalTime(int logicalTime, int site) {
    throw AssertionError('Abstract class factory');
  }

  // radix time in minutes!
  String radixTime(int radix);

  /// a format : S(site)@T(time)
  String toRON();

  @override
  bool operator ==(other) => other is LogicalClock && logicalTime == other.logicalTime && site == other.site;

  bool operator <(other) {
    final o = other as LogicalClock;

    if (logicalTime < o.logicalTime) {
      return true;
    } else if (logicalTime == o.logicalTime) return site < o.site;

    return false;
  }

  bool operator >(other) {
    final o = other as LogicalClock;

    if (logicalTime > o.logicalTime) {
      return true;
    } else if (logicalTime == o.logicalTime) return site > o.site;

    return false;
  }
}
