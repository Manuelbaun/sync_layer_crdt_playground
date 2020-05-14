import 'package:sync_layer/logical_clocks/index.dart';

const TS = [
  '2020-04-23T07:16:20.605Z-0000-9543e0e1f9d5ee5b',
  '2020-04-23T07:16:20.605Z-0001-9543e0e1f9d5ee5b',
  '2020-04-23T07:16:20.607Z-0000-9543e0e1f9d5ee5b',
  '2020-04-23T07:16:20.607Z-0001-9543e0e1f9d5ee5b',
  '2020-04-23T07:16:20.608Z-0000-9543e0e1f9d5ee5b',
  '2020-04-23T07:16:20.608Z-0001-9543e0e1f9d5ee5b',
  '2020-04-23T07:16:20.610Z-0000-9543e0e1f9d5ee5b',
  '2020-04-23T07:16:20.610Z-0001-9543e0e1f9d5ee5b',
  '2020-04-23T07:30:08.189Z-0000-bcd99f065ea9df0d',
  '2020-04-23T07:30:08.189Z-0001-bcd99f065ea9df0d',
  '2020-04-23T07:30:08.192Z-0000-bcd99f065ea9df0d',
  '2020-04-23T07:30:08.192Z-0001-bcd99f065ea9df0d',
  '2020-04-23T07:30:23.326Z-0000-adffe0da9d9d5b5e',
  '2020-04-23T07:30:23.326Z-0001-adffe0da9d9d5b5e',
  '2020-04-23T07:30:23.330Z-0000-adffe0da9d9d5b5e',
  '2020-04-23T07:30:23.330Z-0001-adffe0da9d9d5b5e',
  '2020-04-23T14:08:35.179Z-0000-a1f9e6b460fe9351',
  '2020-04-23T14:08:35.180Z-0000-a1f9e6b460fe9351',
  '2020-04-23T14:08:35.180Z-0001-a1f9e6b460fe9351',
  '2020-04-23T14:08:50.567Z-0000-9cfd011f3d495287',
  '2020-04-23T14:08:50.567Z-0001-9cfd011f3d495287',
  '2020-04-23T14:08:50.567Z-0002-9cfd011f3d495287',
  '2020-04-23T14:08:59.715Z-0000-a456a19d06bb842a',
  '2020-04-23T14:08:59.715Z-0001-a456a19d06bb842a',
  '2020-04-23T14:08:59.718Z-0000-a456a19d06bb842a',
  '2020-04-23T14:08:59.718Z-0001-a456a19d06bb842a',
  '2020-04-23T14:09:08.681Z-0000-9c47832e4da7e7a9',
  '2020-04-23T14:09:08.681Z-0001-9c47832e4da7e7a9',
  '2020-04-23T14:09:08.681Z-0002-9c47832e4da7e7a9',
  '2020-04-23T14:10:29.181Z-0000-9819a0db4d4eb7aa',
  '2020-04-23T14:10:29.181Z-0001-9819a0db4d4eb7aa',
  '2020-04-23T14:10:29.181Z-0002-9819a0db4d4eb7aa',
  '2020-04-23T14:11:52.644Z-0000-ba684f6b8ee22d57',
  '2020-04-23T14:11:52.644Z-0001-ba684f6b8ee22d57',
  '2020-04-23T14:11:52.644Z-0002-ba684f6b8ee22d57',
  '2020-04-23T14:13:04.678Z-0000-a4fae62ac3edb535',
  '2020-04-23T14:13:04.678Z-0001-a4fae62ac3edb535',
  '2020-04-23T14:13:04.678Z-0002-a4fae62ac3edb535',
  '2020-04-23T14:17:12.278Z-0000-a722c176509597e5',
  '2020-04-23T14:17:49.950Z-0000-a4b850763f81f0f9',
  '2020-04-23T14:17:49.950Z-0001-a4b850763f81f0f9',
  '2020-04-23T14:17:49.950Z-0002-a4b850763f81f0f9',
  '2020-04-23T14:17:26.562Z-0000-a4b850763f81f0f9',
  '2020-04-23T14:17:34.713Z-0000-a4b850763f81f0f9',
  '2020-04-23T14:17:56.079Z-0000-8ee34b85744f4b59',
  '2020-04-23T14:17:56.079Z-0001-8ee34b85744f4b59',
  '2020-04-23T14:17:56.079Z-0002-8ee34b85744f4b59',
  '2020-04-23T14:22:46.367Z-0000-ad5d12fb06f65120',
  '2020-04-23T14:22:53.719Z-0000-ad645bcad53e3658',
  '2020-04-23T14:25:38.038Z-0000-938f25d9e9e81b25',
  '2020-04-23T14:26:28.910Z-0000-bd471f3de6f13665',
  '2020-04-23T14:26:28.910Z-0001-bd471f3de6f13665',
  '2020-04-23T14:26:28.910Z-0002-bd471f3de6f13665',
  '2020-04-24T10:57:49.198Z-0000-97f6c8ef1e121379',
  '2020-04-24T10:57:49.198Z-0001-97f6c8ef1e121379',
  '2020-04-24T10:57:49.198Z-0002-97f6c8ef1e121379',
];

class FakeDb {
  List<Hlc> _db;

  List<Hlc> getHlcs() {
    _db ??= TS.map((ts) {
      final parts = ts.split('-');
      final dateobj = parts.sublist(0, 3).join('-');
      var ms = DateTime.parse(dateobj).millisecondsSinceEpoch;
      var counter = int.parse(parts[3], radix: 16);
      var site = int.parse(parts[4].substring(0, 5), radix: 16);

      return Hlc(ms, counter, site);
    }).toList();
    return _db;
  }

  List<Hlc> getHlcs2() {
    if (_db == null) {
      final startDate = DateTime(2020, 2, 25);
      final endDate = DateTime(2020, 4, 26);
      var ts = startDate.millisecondsSinceEpoch;
      final hlcs = <Hlc>[];

      /// sorted_list for lookup;s
      while (ts < endDate.millisecondsSinceEpoch) {
        hlcs.add(Hlc(ts, 0));
        ts += 10000;
      }
      _db = hlcs;
    }

    return _db;
  }

  List<Hlc> getByTime(int tsInMinutes) {
    return _db.where((h) => h.minutes == tsInMinutes).toList();
  }

  List<Hlc> filterAfterTime(int tsInMinutes) {
    return _db.where((h) => tsInMinutes <= h.minutes).toList();
  }

  List<Hlc> filterByKeyStrings(List<String> keyStrings, int radix) {
    final diffs = <Hlc>[];

    for (var k in keyStrings) {
      var tsInMinutes = int.parse(k, radix: radix);
      final hlcs = getByTime(tsInMinutes);
      diffs.addAll(hlcs);
    }
    return diffs;
  }
}
