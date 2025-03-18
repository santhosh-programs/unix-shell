import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:math';

import 'package:collection/collection.dart';

import 'custom_process.dart';
import 'dining_philosopher.dart';
import 'paging.dart';
import 'producer_consumer.dart';

void main(List<String> arguments) async {
  UnixShellOutput unixShellOutput = UnixShellOutput();
  // Process process =
  //     await Process.start('sleep', ['100'], mode: ProcessStartMode.detached);
  // print('Started process with PID: ${process.pid}');

  // Process process = await Process.start('sleep', ['5']);
  // print('Started process with PID: ${process.pid}');

  // // Bring it to the foreground (attach to stdout/stderr)

  // // Wait for it to complete
  // int exitCode = await process.exitCode;
  // print('Process exited with code: $exitCode');

  unixShellOutput.runShell();
  // final pc = ProducerConsumer(arrayLength: 20);
}

class UnixShellOutput {
  List<Process> currentJobs = [];
  void runShell() async {
    while (true) {
      stdout.write('my_shell>');
      String? out = stdin.readLineSync();
      if (out != null && out.isNotEmpty) {
        final splitInput = out.split(' ');

        int? exitCode = await executeCommand(splitInput);
        if (exitCode != null) {
          break;
        }
      }
    }
  }

  Future<int?> executeCommand(List<String> splitInput) async {
    switch (splitInput[0]) {
      case 'pwd':
        stdout.write(Process.runSync('pwd', []).stdout);
      case 'q':
        return -1;
      case 'echo':
        stdout.writeln(splitInput.length == 2 ? splitInput[1] : '');
      case 'clear':
        stdout.write('\x1B[2J\x1B[0;0H');
      case 'ls':
        stdout.writeln(
            Process.runSync('ls', splitInput.length > 1 ? [splitInput[1]] : [])
                .stdout);
      case 'cat':
        fileOperations(splitInput);
      case 'mkdir':
        directoryOperation(splitInput);
      case 'rmdir':
        directoryOperation(splitInput);
      case 'rm':
        fileOperations(splitInput);
      case 'touch':
        fileOperations(splitInput, shouldCheckExistence: false);
      case 'kill':
        final process = Process.runSync(
            'kill', splitInput.length > 1 ? [splitInput[1]] : []);
        stdout.writeln(process.stdout.toString() + process.stderr.toString());
      case 'jobs':
        stdout.writeln(currentJobs.map((e) => 'PID: ${e.pid} running'));
      case 'sleep':
        if (splitInput.length < 2) {
          stdout.writeln('please provide the duration as well');
        } else {
          if (splitInput.length == 3) {
            if (splitInput[2] != '&') {
              stdout.writeln('please provide a valid command');
            } else {
              Process process = await Process.start('sleep', [splitInput[1]]);
              currentJobs.add(process);
              stdout.writeln('Started process ${process.pid} in background.');
            }
          } else {
            Process process = await Process.start('sleep', [splitInput[1]]);
            await Future.wait([
              stdout.addStream(process.stdout),
              stderr.addStream(process.stderr)
            ]);
            int exitCode = await process.exitCode;
            stdout.writeln('Process ${process.pid} exited with code $exitCode');
          }
        }
        break;
      case 'fg':
        if (currentJobs.isNotEmpty) {
          Process process = currentJobs.removeAt(0);
          stdout.writeln('Bringing process ${process.pid} to foreground...');
          await Future.wait([
            stdout.addStream(process.stdout),
            stderr.addStream(process.stderr)
          ]);
          int exitCode = await process.exitCode;
          stdout.writeln('Process ${process.pid} exited with code $exitCode');
        } else {
          stdout.writeln('No background jobs to bring to foreground.');
        }
        break;

      // case 'sleep':
      //   Process process = await Process.start('sleep', [splitInput[1]]);
      //   currentJobs.add(process);
      // case 'fg':
      //   stdout.addStream(currentJobs.first.stdout);
      //   stderr.addStream(currentJobs.first.stderr);
      case 'roundrobin':
        if (splitInput.length <= 2) {
          stdout.writeln(
              'Please enter all input ex. : >roundrobin [count] [timeslice]');
        } else {
          int? count = int.tryParse(splitInput[1]);
          int? timeSlice = int.tryParse(splitInput[2]);
          if (count != null && timeSlice != null) {
            await roundRobin(count, timeSlice);
          } else {
            stdout.writeln('Please enter a valid count');
          }
        }
      case 'priority':
        if (splitInput.length <= 1) {
          stdout.writeln(
              'Please enter the number of processes ex. : >priority 5');
        } else {
          int? count = int.tryParse(splitInput[1]);
          if (count != null) {
            await priority(count);
          } else {
            stdout.writeln('Please enter a valid count');
          }
        }
      case 'paging':
        if (splitInput.length <= 1) {
          stdout.writeln(
              'please enter a valid entry, ex. paging fifo or paging lru');
        } else {
          paging(ReplacementAlgo.getValue(splitInput[1].toLowerCase()));
        }
        break;
      case 'producerconsumer':
        producerConsumer();
      case 'dining':
      default:
        stdout.writeln('Please enter a valid command');
    }
    return null;
  }

  void diningPhilosopher() async {
    List<Future<void>> philosophers = [];

    for (int i = 0; i < NUM_PHILOSOPHERS; i++) {
      philosophers.add(philosopher(i));
    }

    await Future.wait(philosophers);

    print("All philosophers finished eating.");
  }

  void producerConsumer() {
    int counter = 0;
    ProducerConsumer pc = ProducerConsumer(arrayLength: 5);
    Timer.periodic(Duration(milliseconds: 500), (timer) {
      int item = DateTime.now().millisecondsSinceEpoch % 100; // Random item
      pc.produce(item);
      counter++;
      if (counter >= 15) {
        timer.cancel();
      }
    });

    Timer.periodic(Duration(seconds: 1), (timer) {
      counter++;
      pc.consume();
      if (counter >= 15) {
        timer.cancel();
      }
    });
  }

  void paging(ReplacementAlgo replacementAlgo) {
    Paging paging =
        Paging(runningProcesses: {}, replacementAlgo: replacementAlgo);
    for (int i = 0; i < 33; i++) {
      paging.startProcessAnyPage();
    }
    int? pid = paging.startProcessAtSpecificPage(0);
    if (pid != null) {
      paging.completeProcess(pid);
    }
    paging.startProcessAtSpecificPage(0);
  }

  Future<void> priority(int processCount) async {
    int currentTime = 0;
    PriorityQueue<PriorityProcess> priorityQueue = PriorityQueue((a, b) {
      return a.priority != b.priority
          ? b.priority.compareTo(a.priority)
          : a.addSequence.compareTo(b.addSequence);
    });
    for (int i = 0; i < processCount; i++) {
      priorityQueue.add(PriorityProcess(
          pid: i + 1, priority: 1, burstTime: 3, addSequence: i));
    }
    bool addedHighPriorityProcess = false;
    while (priorityQueue.isNotEmpty) {
      final process = priorityQueue.removeFirst();
      print('Process ${process.pid} with priority:${process.priority}'
          ' started at $currentTime...');
      process.startTime ??= currentTime;
      await Future.delayed(Duration(seconds: process.burstTime));
      currentTime += process.burstTime;
      process.completionTime = currentTime;
      process.turnaroundTime = process.completionTime! - process.arrivalTime;
      process.waitingTime = process.turnaroundTime! - process.startTime!;
      process.responseTime = process.startTime! - process.arrivalTime;
      stdout.writeln(
          'Process ${process.pid} completed with the following times: $process');
      if (!addedHighPriorityProcess) {
        print(
            'Adding a high priority(priority: ${processCount + 1}) process with '
            'pid: ${processCount + 1} inbetween');
        priorityQueue.add(PriorityProcess(
            priority: processCount + 1,
            pid: processCount + 1,
            burstTime: 3,
            addSequence: processCount + 1));
        addedHighPriorityProcess = true;
      }
    }
    stdout.writeln('All $processCount processes completed at $currentTime');
  }

  Future<void> roundRobin(int processCount, int timeSlice) async {
    print('Round robin started...');
    int currentTime = 0;
    Queue<RoundRobinProcess> readyQueue = Queue();

    for (int i = 0; i < processCount; i++) {
      readyQueue.add(RoundRobinProcess(
          pid: i + 1, timeSlice: timeSlice, remainingTime: 3, burstTime: 3));
    }
    while (readyQueue.isNotEmpty) {
      final process = readyQueue.removeFirst();
      print('Process ${process.pid} started at $currentTime...');
      final allowedToExecute = min(process.remainingTime, process.timeSlice);
      process.startTime ??= currentTime;
      await Future.delayed(Duration(seconds: allowedToExecute));
      currentTime += allowedToExecute;
      process.remainingTime -= allowedToExecute;
      if (process.remainingTime <= 0) {
        process.completionTime = currentTime;
        process.turnaroundTime = process.completionTime! - process.arrivalTime;
        process.waitingTime = process.turnaroundTime! - process.startTime!;
        process.responseTime = process.startTime! - process.arrivalTime;
        stdout.writeln(
            'Process ${process.pid} completed with the following times: $process');
      } else {
        readyQueue.add(process);
      }
    }
    stdout.writeln('All $processCount processes completed at $currentTime');
  }

  void memoryOperations(List<String> splitInput) {
    final process = Process.runSync(
        splitInput[0], splitInput.length > 1 ? [splitInput[1]] : []);
    stdout.writeln(process.stdout.toString() + process.stderr.toString());
  }

  void directoryOperation(List<String> splitInput) {
    if (splitInput.length > 2) {
      stdout.writeln('Please provide the entire path inside double quotes');
    } else if (splitInput.length == 1) {
      stdout.writeln('Please provide the folder path');
    } else {
      final strippedPath = splitInput[1].replaceAll(RegExp('"'), '');
      stdout.writeln(Process.runSync(splitInput[0], [strippedPath]).stdout);
    }
  }

  void fileOperations(List<String> splitInput,
      {bool shouldCheckExistence = true}) {
    if (splitInput.length > 2) {
      stdout.writeln('Please provide the entire path inside double quotes');
    } else if (splitInput.length == 1) {
      stdout.writeln('Please provide the file path');
    } else {
      final strippedPath = splitInput[1].replaceAll(RegExp('"'), '');
      File file = File(strippedPath);
      if (shouldCheckExistence && !file.existsSync()) {
        stdout.writeln('Provided file path does not exist');
      } else {
        stdout.writeln(Process.runSync(splitInput[0], [strippedPath]).stdout);
      }
    }
  }
}
