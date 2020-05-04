class Formatter {
  static String micro2Ms(int us) {
    final s = (us / 1000).toString().split('.');
    s.first.padLeft(6, ' ');
    s.last.padRight(3, '0');

    return s.join('.');
  }
}
