abstract class LogicalClock<T> implements Comparable<T> {
  final int counter;
  final int site;

  /// the id is the [hashCode] just for better reasoning!
  // int get id;

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
  String toStringRON();
  String toStringHuman();

  /// This compares **without** site!
  @override
  int compareTo(T other);

  /// This compares **without** site!
  int compareToDESC(T other);

  /// this compares with Site considered
  int compareWithSiteASC(T other);

  /// this compares with Site considered
  int compareWithSiteDESC(T other);

  bool isLessWithSite(T o);

  bool isGreaterWithSite(T o);

  // compares the two hashcodes
  bool deepEqual(T o);

  /// compares only if logical time/counter/ms ar equal and not if Logical Clock is
  /// equal with site to another logical clock. for this use hashCode!
  @override
  bool operator ==(other);

  /// This compares only the time and does not consider site comparision
  bool operator <(other);

  /// This compares only the time and does not consider site comparisions
  bool operator >(other);

  /// will get the time difference
  /// TODO: maybe container class?
  List<int> operator -(other);
}
