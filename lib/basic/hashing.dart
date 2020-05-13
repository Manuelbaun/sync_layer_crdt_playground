/// This function will be called recursivly only on [Map], [Set], [List]
int nestedHashing(dynamic o) {
  var h = 0;
  if (o is Set) {
    o.forEach((i) => h ^= nestedHashing(i));
  } else if (o is List) {
    (o as List).forEach((i) => h ^= nestedHashing(i));
  } else if (o is Map) {
    (o as Map).entries.forEach((e) => h ^= e.key.hashCode ^ nestedHashing(e.value));
  } else {
    h ^= o.hashCode;
  }

  return h;
}
