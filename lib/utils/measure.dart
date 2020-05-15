//  returns [elapsedMicroseconds]
int measureExecution(String name, Function func, {skipLog = false}) {
  final s = Stopwatch();
  s.start();
  func();
  s.stop();

  if (!skipLog) {
    final time = '${s.elapsedMicroseconds / 1000}'.padLeft(12);
    print('${name.padRight(30)} : $time  ms');
  }
  return s.elapsedMicroseconds;
}
