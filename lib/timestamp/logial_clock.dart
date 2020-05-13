abstract class LogicalClock {
  final int counter;
  final int site;

  factory LogicalClock.send(LogicalClock lc) {
    throw AssertionError('Abstract class factory');
  }

  factory LogicalClock.recv(LogicalClock lc) {
    throw AssertionError('Abstract class factory');
  }

  factory LogicalClock.parse(String ts) {
    throw AssertionError('Abstract class factory');
  }

  // radix time in minutes!
  String radixTime(int radix);

  /// a format : S(site)@T(time)
  String toRON();

  @override
  bool operator ==(other);

  bool operator <(other);

  bool operator >(other);
}
