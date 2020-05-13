import 'package:sync_layer/basic/hashing.dart';
import 'package:test/test.dart';

void main() {
  group('hashing', () {
    test('nested set', () {
      final s1 = {
        3,
        4,
        5,
        {2, 3, 4}
      };

      final s2 = {
        3,
        4,
        5,
        {2, 3, 4}
      };

      expect(s1 == s2, isFalse);
      expect(nestedHashing(s1), nestedHashing(s2));
    });

    test('nested map', () {
      final s1 = {
        'h': {1: 'hello'},
        3: {2: 4}
      };

      final s2 = {
        'h': {1: 'hello'},
        3: {2: 4}
      };

      expect(s1 == s2, isFalse);

      expect(nestedHashing(s1), nestedHashing(s2));
    });

    test('nested list', () {
      final s1 = [
        1,
        2,
        3,
        [
          'hello',
          ['world']
        ]
      ];

      final s2 = [
        1,
        2,
        3,
        [
          'hello',
          ['world']
        ]
      ];

      expect(s1 == s2, isFalse);

      expect(nestedHashing(s1), nestedHashing(s2));
    });
  });
}
