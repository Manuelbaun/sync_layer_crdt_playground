//  returns [elapsedMicroseconds]
int measureExecution(String name, Function func, {skipLog = false, useticks = false}) {
  final s = Stopwatch();
  s.start();
  func();
  s.stop();

  if (!skipLog) {
    final time = '${s.elapsedMicroseconds / 1000}'.split('.');
    final ticks = '${s.elapsedTicks}';

    time[0] = time[0].padLeft(5, ' ');
    time[1] = time[1].padRight(3, '0');

    final ts = time.join('.');

    print('${name.padRight(30)} : $ts  ms : $ticks ticks');
  }

  return useticks ? s.elapsedTicks : s.elapsedMicroseconds;
}
