import 'package:sync_layer/timestamp/index.dart';
import 'package:test/test.dart';

var testHlc = Hlc(1579633503119, 42, 1234);

void main() {
  group('Comparison', () {
    test('Equality', () {
      var hlc = Hlc(1579633503119, 42, 1234);
      expect(testHlc, hlc);
    });

    test('Equality with different nodes', () {
      var hlc = Hlc(1579633503119, 42, 1234);
      expect(testHlc, hlc);
    });

    test('Less than millis', () {
      var hlc = Hlc(1579733503119, 42, 1234);
      expect(testHlc < hlc, isTrue);
    });

    test('Less than counter', () {
      var hlc = Hlc(1579633503119, 43, 1234);
      expect(testHlc < hlc, isTrue);
    });

    test('Fail less than if equals', () {
      var hlc = Hlc(1579633503119, 42, 1234);
      expect(testHlc < hlc, isFalse);
    });

    test('Fail less than if millis and counter disagree', () {
      var hlc = Hlc(1579533503119, 43, 1234);
      expect(testHlc < hlc, isFalse);
    });
  });

  group('Logical time representation', () {
    test('Hlc as logical time', () {
      expect(testHlc.logicalTime, 103522861260406826);
    });

    test('Hlc from logical time', () {
      expect(Hlc.fromLogicalTime(103522861260406826, 1234), testHlc);
    });
  });

  group('String operations', () {
    test('hlc to string', () {
      expect(testHlc.toString(), '16fc97e6b8f002a-4d2');
    });

    test('Parse hlc', () {
      expect(Hlc.parse('16fc97e6b8f002a-4d2'), testHlc);
    });
  });

  group('Send', () {
    test('Send before', () {
      var hlc = Hlc.send(testHlc, 1579633503110);

      final r = isNot(testHlc);
      expect(hlc, r);
      expect(hlc.toString(), '16fc97e6b8f002b-4d2');
    });

    test('Send simultaneous', () {
      var hlc = Hlc.send(testHlc, 1579633503119);
      expect(hlc, isNot(testHlc));
      expect(hlc.toString(), '16fc97e6b8f002b-4d2');
    });

    test('Send later', () {
      var hlc = Hlc.send(testHlc, 1579733503119);
      expect(hlc, Hlc(1579733503119, 0, 1234));
    });
  });

  group('Receive', () {
    test('Receive before', () {
      var remoteHlc = Hlc(1579633503110, 0, 1234);
      var hlc = Hlc.recv(testHlc, remoteHlc, 1579633503119);
      expect(hlc, isNot(equals(testHlc)));
    });

    test('Receive simultaneous', () {
      var remoteHlc = Hlc(1579633503119, 0, 1234);
      var hlc = Hlc.recv(testHlc, remoteHlc, 1579633503119);
      expect(hlc, isNot(testHlc));
    });

    test('Receive after', () {
      var remoteHlc = Hlc(1579633503119, 0, 1234);
      var hlc = Hlc.recv(testHlc, remoteHlc, 1579633503129);
      expect(hlc, isNot(testHlc));
    });
  });

  group('Clock drifts', () {
    final date1 = DateTime(2020, 3, 0);
    final date2 = DateTime(2020, 4, 0);
    final local = DateTime(2020, 5, 0);

    final hlcD1 = Hlc(date1.millisecondsSinceEpoch, 0, 1234);
    final hlcD2 = Hlc(date2.millisecondsSinceEpoch, 0, 1234);
    final hlcD3 = Hlc(local.millisecondsSinceEpoch, 0, 1234);

    test('Receive Ts in total time order', () {
      // init
      final hlc1 = Hlc.recv(hlcD1, hlcD1);
      // recieve first
      final hlc2 = Hlc.recv(hlc1, hlcD2);
      // recieves second
      final hlc3 = Hlc.recv(hlc2, hlcD3);

      expect(hlc1 < hlc2, isTrue);
      expect(hlc2 < hlc3, isTrue);
    });

    test('Receive ', () {
      // init

      final newLocal1 = Hlc.recv(hlcD1, hlcD1);
      // recieves second
      final newLocal2 = Hlc.recv(newLocal1, hlcD3);
      // recieve first
      final newLocal3 = Hlc.recv(newLocal2, hlcD2);

      expect(newLocal1 < newLocal2, isTrue);
      expect(newLocal1 < newLocal3, isTrue);
      expect(newLocal2 < newLocal3, isTrue);
    });

    test('impossibleTs', () {
      final localD = DateTime.now().millisecondsSinceEpoch;
      final localHlc = Hlc(localD, 0, 1111);

      final remoteD = DateTime.now().millisecondsSinceEpoch;
      final remoteHlc = Hlc(remoteD, 0, 9999);

      print(localHlc);
      print(remoteHlc);

      expect(localHlc == remoteHlc, isFalse);
      expect(localHlc.logicalTime == remoteHlc.logicalTime, isTrue);
    });
  });
}
