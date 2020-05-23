typedef Unsubscribe = void Function();
typedef Subscription<T> = void Function(T value);

/// TODO: proper API for listen on event keys!
class Observable<T> {
  final Map<String, Set<Subscription<T>>> _subscribers = {};
  final Map<String, Set<Subscription<T>>> _onceSubscribers = {};

  /// Subscribes to [Observable] notification and returns
  /// an unsubscription function
  Unsubscribe subscribe(String key, Subscription<T> func) {
    _subscribers[key] ??= <Subscription<T>>{};
    _subscribers[key].add(func);

    return () => unsubscribe(key, func);
  }

  bool unsubscribe(String key, Subscription<T> func) {
    return _subscribers[key]?.remove(func);
  }

  void notify(String key, T value) {
    if (_subscribers[key] != null) {
      for (final sub in _subscribers[key]) {
        sub(value);
      }
    }

    if (_onceSubscribers[key] != null) {
      for (final sub in _onceSubscribers[key]) {
        sub(value);
      }

      _onceSubscribers[key].clear();
    }
  }

  void once(String key, Subscription<T> func) {
    _onceSubscribers[key] ??= <Subscription<T>>{};
    _onceSubscribers[key]?.add(func);
  }
}
