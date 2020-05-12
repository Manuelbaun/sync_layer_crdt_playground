class LogicalClockBasic {
  final int counter;
  LogicalClockBasic(this.counter);

  factory LogicalClockBasic.send(LogicalClockBasic lc) {
    return LogicalClockBasic(lc.counter + 1);
  }
}
