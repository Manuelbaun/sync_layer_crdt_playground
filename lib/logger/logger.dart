import 'package:logger/logger.dart';

class CustomOutput implements LogOutput {
  @override
  void init() {}

  @override
  void output(OutputEvent event) {
    final trace = StackTrace.current.toString().split('\n');
    final origin = trace[4];
    final index = origin.indexOf('(');
    var path = origin.substring(index, origin.length);

    var prefix = '';
    if (event.level != Level.debug && event.level != Level.verbose) {
      prefix = event.lines[0].substring(0, 19);
    }

    event.lines.forEach((line) {
      final subl = line.split('\n');

      print('#0 ${subl[0].trim()} ${path.trim()}');

      for (var i = 1; i < subl.length; i++) {
        final l = prefix + subl[i];

        print('#$i $l ');
      }
    });
  }

  @override
  void destroy() {}
}

class CustomLogger {
  final logger = Logger(
    printer: SimplePrinter(),
    level: Level.verbose,
    output: CustomOutput(),
  );

  CustomLogger();
  void debug(String message) => logger.d(message);
  void verbose(String message) => logger.v(message);
  void info(String message) => logger.i(message);
  void fine(String message) => logger.v(message);
  void warning(String message) => logger.w(message);
  void error(String message) => logger.e(message);
}

final logger = CustomLogger();
