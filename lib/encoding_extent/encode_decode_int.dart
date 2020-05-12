// this removes
// @pragma('vm:prefer-inline')
import 'dart:typed_data';

/// these function encodes int to Uint8List and back.
///
/// !!!! it does not work like reqular conversions
/// it removes not only the top zeros bytes but also the bottom..
/// ! its trimming on both sides
Uint8List encodeTrimmedInt(int number, [int size_]) {
  // Not handling negative numbers. Decide how you want to do that.
  if (number == 0) return Uint8List(0);

  // skip lower zeros
  var byte = number & 0xFF;
  while (byte == 0) {
    number = number >> 8;
    byte = number & 0xFF;
  }

  var size = size_ ?? (number.bitLength + 7) >> 3;
  var result = Uint8List(size);

  for (var i = size - 1; i >= 0; i--) {
    result[i] = number & 0xFF;
    number = number >> 8;
  }
  return result;
}

// BigEndien
/// `row` should be [Uint8List]
int decodeTrimmedInt(List<int> raw, [int lenght]) {
  // Not handling negative numbers. Decide how you want to do that.

  var result = 0;

  for (var b in raw) {
    result = result << 8 | (b ?? 0);
  }

  if (lenght != null) {
    for (var i = 0; i < lenght - raw.length; i++) {
      result = result << 8;
    }
  }
  return result;
}
