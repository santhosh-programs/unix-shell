import 'dart:io';

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
}

class UnixShellOutput {
  List<Process> currentJobs = [];
  void runShell() async {
    while (true) {
      stdout.write('my_shell>');
      String? out = stdin.readLineSync();
      if (out != null && out.isNotEmpty) {
        final splitInput = out.split(' ');

        switch (splitInput[0]) {
          case 'pwd':
            stdout.write(Process.runSync('pwd', []).stdout);
          case 'exit':
            break;
          case 'echo':
            stdout.writeln(splitInput.length == 2 ? splitInput[1] : '');
          case 'clear': // TODO
            Process.runSync('clear', []);
          case 'ls':
            stdout.writeln(Process.runSync(
                    'ls', splitInput.length > 1 ? [splitInput[1]] : [])
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
            stdout
                .writeln(process.stdout.toString() + process.stderr.toString());
          case 'jobs':
            stdout.writeln(Process.runSync('jobs', []).stdout);
          case 'sleep':
            Process process = await Process.start('sleep', [splitInput[1]]);
            currentJobs.add(process);
          case 'fg':
            stdout.addStream(currentJobs.first.stdout);
            stderr.addStream(currentJobs.first.stderr);
        }
      }
    }
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
