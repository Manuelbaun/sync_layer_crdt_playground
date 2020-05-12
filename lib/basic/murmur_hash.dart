import 'dart:typed_data';

/**
  * JS Implementation of MurmurHash3 (r136) (as of May 20, 2011)
  *
  * @author <a href="mailto:gary.court@gmail.com">Gary Court</a>
  * @see http://github.com/garycourt/murmurhash-js
  * @author <a href="mailto:aappleby@gmail.com">Austin Appleby</a>
  * @see http://sites.google.com/site/murmurhash/
  *
  * @param {string} key ASCII only
  * @param {number} seed Positive integer only
  * @return {number} 32-bit positive integer hash
  */
int MurmurHashV3(String key, [int seed = 0]) {
  int remainder, bytes, h1, h1b, c1, c1b, c2, c2b, k1, i;

  remainder = key.length & 3; // key.length % 4
  bytes = key.length - remainder;
  h1 = seed;
  c1 = 0xcc9e2d51;
  c2 = 0x1b873593;
  i = 0;

  while (i < bytes) {
    k1 = ((key.codeUnitAt(i) & 0xff)) |
        ((key.codeUnitAt(++i) & 0xff) << 8) |
        ((key.codeUnitAt(++i) & 0xff) << 16) |
        ((key.codeUnitAt(++i) & 0xff) << 24);
    ++i;

    k1 = ((((k1 & 0xffff) * c1) + ((((k1 >> 16) * c1) & 0xffff) << 16))) & 0xffffffff;
    k1 = (k1 << 15) | (k1 >> 17);
    k1 = ((((k1 & 0xffff) * c2) + ((((k1 >> 16) * c2) & 0xffff) << 16))) & 0xffffffff;

    h1 ^= k1;
    var h1_a = h1 << 13;
    var h1_b = (h1 >> 19);
    h1 = h1_a | h1_b;
    h1b = ((((h1 & 0xffff) * 5) + ((((h1 >> 16) * 5) & 0xffff) << 16))) & 0xffffffff;
    h1 = (((h1b & 0xffff) + 0x6b64) + ((((h1b >> 16) + 0xe654) & 0xffff) << 16));
  }

  k1 = 0;

  if (remainder == 3) k1 ^= (key.codeUnitAt(i + 2) & 0xff) << 16;
  if (remainder == 2 || remainder == 3) {
    k1 ^= (key.codeUnitAt(i + 1) & 0xff) << 8;
  }
  if (remainder == 1 || remainder == 2 || remainder == 3) {
    k1 ^= (key.codeUnitAt(i) & 0xff);
  }

  k1 = (((k1 & 0xffff) * c1) + ((((k1 >> 16) * c1) & 0xffff) << 16)) & 0xffffffff;
  k1 = (k1 << 15) | (k1 >> 17);
  k1 = (((k1 & 0xffff) * c2) + ((((k1 >> 16) * c2) & 0xffff) << 16)) & 0xffffffff;
  h1 ^= k1;

  h1 ^= key.length;

  h1 ^= h1 >> 16;
  h1 = (((h1 & 0xffff) * 0x85ebca6b) + ((((h1 >> 16) * 0x85ebca6b) & 0xffff) << 16)) & 0xffffffff;
  h1 ^= h1 >> 13;
  h1 = ((((h1 & 0xffff) * 0xc2b2ae35) + ((((h1 >> 16) * 0xc2b2ae35) & 0xffff) << 16))) & 0xffffffff;
  h1 ^= h1 >> 16;

  // this is needed to use only murmurhash for 32 bit.
  // var v = ByteData(8)..setUint64(0, h1);
  // var v2 = v.getUint32(4);
  var res = h1 & 0xFFFFFFFFFFFFFFFF;

  return res;
}

int MurmurHashV3Bytes(Uint8List key, [int seed = 0]) {
  int remainder, bytes, h1, h1b, c1, c1b, c2, c2b, k1, i;

  remainder = key.length & 3; // key.length % 4
  bytes = key.length - remainder;
  h1 = seed;
  c1 = 0xcc9e2d51;
  c2 = 0x1b873593;
  i = 0;

  while (i < bytes) {
    k1 = ((key.elementAt(i) & 0xff)) |
        ((key.elementAt(++i) & 0xff) << 8) |
        ((key.elementAt(++i) & 0xff) << 16) |
        ((key.elementAt(++i) & 0xff) << 24);
    ++i;

    k1 = ((((k1 & 0xffff) * c1) + ((((k1 >> 16) * c1) & 0xffff) << 16))) & 0xffffffff;
    k1 = (k1 << 15) | (k1 >> 17);
    k1 = ((((k1 & 0xffff) * c2) + ((((k1 >> 16) * c2) & 0xffff) << 16))) & 0xffffffff;

    h1 ^= k1;
    var h1_a = h1 << 13;
    var h1_b = (h1 >> 19);
    h1 = h1_a | h1_b;
    h1b = ((((h1 & 0xffff) * 5) + ((((h1 >> 16) * 5) & 0xffff) << 16))) & 0xffffffff;
    h1 = (((h1b & 0xffff) + 0x6b64) + ((((h1b >> 16) + 0xe654) & 0xffff) << 16));
  }

  k1 = 0;

  if (remainder == 3) k1 ^= (key.elementAt(i + 2) & 0xff) << 16;
  if (remainder == 2 || remainder == 3) {
    k1 ^= (key.elementAt(i + 1) & 0xff) << 8;
  }
  if (remainder == 1 || remainder == 2 || remainder == 3) {
    k1 ^= (key.elementAt(i) & 0xff);
  }

  k1 = (((k1 & 0xffff) * c1) + ((((k1 >> 16) * c1) & 0xffff) << 16)) & 0xffffffff;
  k1 = (k1 << 15) | (k1 >> 17);
  k1 = (((k1 & 0xffff) * c2) + ((((k1 >> 16) * c2) & 0xffff) << 16)) & 0xffffffff;
  h1 ^= k1;

  h1 ^= key.length;

  h1 ^= h1 >> 16;
  h1 = (((h1 & 0xffff) * 0x85ebca6b) + ((((h1 >> 16) * 0x85ebca6b) & 0xffff) << 16)) & 0xffffffff;
  h1 ^= h1 >> 13;
  h1 = ((((h1 & 0xffff) * 0xc2b2ae35) + ((((h1 >> 16) * 0xc2b2ae35) & 0xffff) << 16))) & 0xffffffff;
  h1 ^= h1 >> 16;

  // this is needed to use only murmurhash for 32 bit.
  // var v = ByteData(8)..setUint64(0, h1);
  // var v2 = v.getUint32(4);
  var res = h1 & 0xFFFFFFFFFFFFFFFF;

  return res;
}
