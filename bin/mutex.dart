import 'dart:async';

class Mutex {
  Completer<void>? _lock;
  Future<void> acquire() async {
    while (_lock != null) {
      await _lock!.future;
    }
    _lock = Completer<void>();
  }

  void release() {
    _lock?.complete();
    _lock = null;
  }
}
