import 'package:sync_layer/basic/index.dart';

void main() {
  var h = 0;
  var i = 0;

  final ts = <String>[];

  final l = (DateTime(2020, 1, 1, 1, i).millisecondsSinceEpoch);
  final s = 9999;
  final ss = '$l-$s';
  print(ss);
  MurmurHashV3(ss);

  print(0xffffffff);

  // for (var i = 0; i < 1; i++) {
  //   final ms = DateTime(2020, 1, 1, 1, i).millisecondsSinceEpoch;
  //   final h = Hlc(ms, i, 1234);
  //   ts.add(h.toString());
  // }

  // for (final s in ts) {
  //   final ss = MurmurHashV3(s);
  //   h ^= ss;
  //   final b = (ByteData(4)..setInt32(0, h)).getInt32(0);
  //   // final b = h & 0xFFFFFFFF;

  //   final m = Hlc.parse(s);
  //   var rad = (m.millis / 1000 / 60).ceil().toRadixString(3);

  //   print('${rad} $ss $b');
  // }
}
