import 'dart:async';
import 'package:synchronized/synchronized.dart';

void main() {
  final a = ProducerConsumer(arrayLength: 5);

  Timer.periodic(Duration(milliseconds: 500), (timer) {
    int item = DateTime.now().millisecondsSinceEpoch % 100; // Random item
    a.produce(item);
  });

  Timer.periodic(Duration(seconds: 1), (timer) {
    a.consume();
  });
}

class ProducerConsumer {
  final int arrayLength;
  final Lock _lock = Lock();
  Completer<void> _notFull =
      Completer<void>(); // Completer to signal when space is available
  late List<int?> sharedBuffer;

  ProducerConsumer({required this.arrayLength}) {
    sharedBuffer = [];
    _notFull.complete(); // Initially, buffer is not full
  }

  void produce(int value) async {
    while (true) {
      await _notFull.future;

      await _lock.synchronized(() {
        if (sharedBuffer.length < arrayLength) {
          sharedBuffer.add(value);
          print('produced: $value | buffer: $sharedBuffer');

          if (sharedBuffer.length >= arrayLength) {
            _notFull = Completer<void>();
          }
        }
      });

      await Future.delayed(Duration(milliseconds: 100));
    }
  }

  void consume() async {
    await _lock.synchronized(() {
      if (sharedBuffer.isNotEmpty) {
        int? removedItem = sharedBuffer.removeAt(0);
        print('Consumed: $removedItem | Buffer: $sharedBuffer');

        if (sharedBuffer.length < arrayLength && !_notFull.isCompleted) {
          _notFull.complete();
        }
      } else {
        print('Buffer is empty. Nothing to consume.');
      }
    });
  }
}
