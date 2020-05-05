import 'package:sync_layer/utils/measure.dart';

void main() {
  final ob1 = <String, dynamic>{};
  final ob2 = <int, dynamic>{};
  final l = List<dynamic>(1);

  final run = 1000000;

  final func = (i) => i;

  measureExecution('Map Key [String] set Value', () {
    for (var i = 0; i < run; i++) {
      ob1['hans'] = func(i);
    }
  });

  measureExecution('Map Key [String] read Value', () {
    for (var i = 0; i < run; i++) {
      final v = ob1['hans'];
    }
  });

  measureExecution('Map Key [int] set Value', () {
    for (var i = 0; i < run; i++) {
      ob2[0] = func(i);
    }
  });

  measureExecution('Map Key [int] read Value', () {
    for (var i = 0; i < run; i++) {
      final v = ob2[0];
    }
  });

  measureExecution('List [int] set Value', () {
    for (var i = 0; i < run; i++) {
      l[0] = func(i);
    }
  });

  measureExecution('List [int] read Value', () {
    for (var i = 0; i < run; i++) {
      final v = l[0];
    }
  });

  var text;
  measureExecution('Variable set Value', () {
    for (var i = 0; i < run; i++) {
      text = func(i);
    }
  });

  measureExecution('Variable read Value', () {
    for (var i = 0; i < run; i++) {
      final v = text;
    }
  });
}
