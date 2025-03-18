import 'dart:async';

const int NUM_PHILOSOPHERS = 5;
const int NUM_MEALS = 1;

class Semaphore {
  int _count;
  final _queue = <Completer<void>>[];

  Semaphore(this._count);

  Future<void> acquire() {
    if (_count > 0) {
      _count--;
      return Future.value();
    } else {
      final completer = Completer<void>();
      _queue.add(completer);
      return completer.future;
    }
  }

  void release() {
    if (_queue.isNotEmpty) {
      _queue.removeAt(0).complete();
    } else {
      _count++;
    }
  }
}

final Semaphore waiter = Semaphore(NUM_PHILOSOPHERS - 1);
final List<Semaphore> forks =
    List.generate(NUM_PHILOSOPHERS, (_) => Semaphore(1));

Future<void> philosopher(int id) async {
  int leftFork = id;
  int rightFork = (id + 1) % NUM_PHILOSOPHERS;

  for (int meal = 0; meal < NUM_MEALS; meal++) {
    print("Philosopher $id is thinking.");
    await Future.delayed(Duration(milliseconds: 500));

    await waiter.acquire();

    await forks[leftFork].acquire();
    await forks[rightFork].acquire();

    print("Philosopher $id is eating meal ${meal + 1}.");
    await Future.delayed(Duration(milliseconds: 1000));

    forks[leftFork].release();
    forks[rightFork].release();

    waiter.release();

    print("Philosopher $id finished meal ${meal + 1} and put down forks.");
    await Future.delayed(Duration(milliseconds: 500));
  }

  print("Philosopher $id is done eating.");
}
