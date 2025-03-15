class RoundRobinProcess extends CustomProcess {
  /// Duration left to complete the process after each run
  int remainingTime;

  /// Allocated CPU time
  int timeSlice;

  RoundRobinProcess({
    required this.remainingTime,
    required this.timeSlice,
    required super.pid,
    required super.burstTime,
  }) : assert(remainingTime == burstTime);

  @override
  String toString() =>
      'RoundRobinProcess(remainingTime: $remainingTime, timeSlice: $timeSlice, ${super.processInfo()})';
}

class PriorityProcess extends CustomProcess {
  int priority;

  /// Tracks the order of entry
  int addSequence;
  PriorityProcess({
    required this.priority,
    required super.pid,
    required this.addSequence,
    required super.burstTime,
  });

  @override
  String toString() =>
      'PriorityProcess(priority: $priority, ${super.processInfo()})';
}

/// All times are measured in seconds
class CustomProcess {
  CustomProcess({
    required this.pid,
    this.arrivalTime = 0,
    required this.burstTime,
    this.completionTime,
    this.turnaroundTime,
    this.waitingTime,
    this.startTime,
  });
  int pid;
  int arrivalTime;

  /// When the execution starts
  int? startTime;

  /// When
  int? responseTime;

  /// Duration of execution, also known as execution time
  int burstTime;

  int? completionTime;

  /// Since the process arrived till its completion
  int? turnaroundTime;

  /// when it spends in the ready queue;
  int? waitingTime;

  @override
  String toString() {
    return 'CustomProcess(pid: $pid, arrivalTime: $arrivalTime, burstTime: $burstTime, completionTime: $completionTime, turnaroundTime: $turnaroundTime, waitingTime: $waitingTime)';
  }

  String processInfo() {
    return 'start time: $startTime, arrival time: $arrivalTime, burstTime: $burstTime, completionTime:'
        ' $completionTime, turnaroundTime: $turnaroundTime, responseTime: $responseTime, '
        'waitingTime: $waitingTime';
  }
}
