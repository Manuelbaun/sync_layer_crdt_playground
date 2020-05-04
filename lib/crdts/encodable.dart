import 'dart:typed_data';

abstract class Encodable {
  ByteBuffer toBuffer();
  factory Encodable.fromBytes(ByteBuffer buffer) {}
}
