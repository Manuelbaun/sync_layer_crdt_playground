import 'package:logger/logger.dart';

class CustomOutput implements LogOutput {
  @override
  void init() {}

  @override
  void output(OutputEvent event) {
    if (event.level != Level.error && event.level != Level.warning && event.level != Level.wtf) {
      event.lines.forEach(print);

      // final cause = event.lines[2];
      // final msgStart = cause.substring(0, 12);
      // var message = event.lines.sublist(4, event.lines.length-1);
      // print(cause);
      // final msg = [cause];

      // final width = 100;
      // final width2 = width - msgStart.length;

      // final length = message.length < width ? message.length : width;
      // final sub = message.substring(0, length);
      // message = message.substring(length);

      // msg.add(sub);

      // // set message width
      // while (message.isNotEmpty) {
      //   final nextLength = message.length < width2 ? message.length : width2;
      //   final sub = message.substring(0, nextLength);
      //   message = message.substring(nextLength);
      //   msg.add(msgStart + sub);
      // }

      // msg.forEach(print);

    } else {
      event.lines.forEach((line) {
        print(line);
      });
    }
  }

  @override
  void destroy() {}
}

class CustomLogger {
  final logger = Logger(
      // printer: LogfmtPrinter(),
      printer: SimplePrinter(),
      // printer: PrettyPrinter(
      //     methodCount: 2, // number of method calls to be displayed
      //     errorMethodCount: 8, // number of method calls if stacktrace is provided
      //     lineLength: 120, // width of the output
      //     colors: true, // Colorful log messages
      //     printEmojis: true, // Print an emoji for each log message
      //     printTime: false // Should each log print contain a timestamp
      //     ),
      level: Level.info
      // output: CustomOutput(),
      );

  CustomLogger();
  void debug(String message) => logger.d(message);
  void info(String message) => logger.i(message);
  void fine(String message) => logger.v(message);
  void warning(String message) => logger.w(message);
  void error(String message) => logger.e(message);
}

final logger = CustomLogger();
