import 'dart:collection';

import 'package:collection/collection.dart';

import 'custom_process.dart';

enum ReplacementAlgo {
  fifo,
  lru;

  static ReplacementAlgo getValue(String input) {
    switch (input) {
      case 'fifo':
        return ReplacementAlgo.fifo;
      case 'lru':
        return ReplacementAlgo.lru;
      default:
        print('invalid replacement algorithm provided: $input, choosing FIFO');
        return ReplacementAlgo.fifo;
    }
  }
}

class VirtualPageInfo {
  int? physicalMemoryAddress;

  /// If the page is currently used, then PID would be present
  int? processPid;

  DateTime lastAccessTimeStamp;

  int virtualPage;

  VirtualPageInfo({
    this.physicalMemoryAddress,
    this.processPid,
    required this.lastAccessTimeStamp,
    required this.virtualPage,
  });

  VirtualPageInfo copyWith({
    int? physicalMemoryAddress,
    int? processPid,
    DateTime? lastAccessTimeStamp,
    int? virtualPage,
  }) {
    return VirtualPageInfo(
      physicalMemoryAddress:
          physicalMemoryAddress ?? this.physicalMemoryAddress,
      processPid: processPid ?? this.processPid,
      lastAccessTimeStamp: lastAccessTimeStamp ?? this.lastAccessTimeStamp,
      virtualPage: virtualPage ?? this.virtualPage,
    );
  }

  @override
  String toString() {
    return 'Virtual page: $virtualPage, physical page address:'
        ' $physicalMemoryAddress, Process ID: $processPid';
  }
}

class Paging {
  int virtualMemSize = 64;
  int physicalMemSize = 32;
  Map<int, VirtualPageInfo> mmu;
  Map<int, PagingProcess> runningProcesses = {};
  int pidTracker = 0;
  Queue<int> pageQueue = Queue();
  ReplacementAlgo replacementAlgo;
  Paging({
    this.virtualMemSize = 64,
    this.physicalMemSize = 32,
    required this.runningProcesses,
    required this.replacementAlgo,
  }) : mmu = {} {
    DateTime now = DateTime.now();
    for (int i = 0; i < virtualMemSize; i++) {
      mmu[i] = VirtualPageInfo(
          virtualPage: i,

          /// Virtual pages 0->31 are unmapped, starting mapping on virtual page32
          /// 32 maps to physical page frame 0 and so on. This is to show
          /// differences
          physicalMemoryAddress:
              i >= physicalMemSize ? i - physicalMemSize : null,
          lastAccessTimeStamp: now);
      if (i < physicalMemSize) {
        pageQueue.add(i);
      }
    }
  }

  List<int> findAvailableFreeFrames() {
    List<int> freePages = [];
    mmu.forEach((key, value) {
      if (value.processPid == null && value.physicalMemoryAddress != null) {
        freePages.add(key);
      }
    });
    return freePages;
  }

  /// Returns the process ID if succesfull
  int? startProcessAtSpecificPage(int virtualPageId) {
    final pageInfo = mmu[virtualPageId];
    if (pageInfo == null) {
      print('invalid page number $virtualPageId');
      return null;
    }
    if (pageInfo.physicalMemoryAddress == null) {
      print('page fault occured, performing $replacementAlgo to free frame');
      if (replacementAlgo == ReplacementAlgo.fifo) {
        return fifo(virtualPageId).processPid;
      } else {
        return lru(virtualPageId).processPid;
      }
    } else {
      return runProcess(virtualPageId);
    }
  }

  void startProcessAnyPage() {
    List<int> freePages = findAvailableFreeFrames();
    if (freePages.isEmpty) {
      print('memory is full, allocating pages using $replacementAlgo');
      switch (replacementAlgo) {
        case ReplacementAlgo.fifo:
          fifo(null);
          break;
        case ReplacementAlgo.lru:
          lru(null);
          break;
      }
      freePages = findAvailableFreeFrames();
    }
    runProcess(freePages.first);
    if (findAvailableFreeFrames().isEmpty) {
      print('memory is full, allocating pages using $replacementAlgo');
      switch (replacementAlgo) {
        case ReplacementAlgo.fifo:
          fifo(null);
          break;
        case ReplacementAlgo.lru:
          lru(null);
          break;
      }
    }
  }

  int runProcess(int virtualPageId) {
    PagingProcess pagingProcess = PagingProcess(
      assignedVirtualPage: virtualPageId,
      pid: pidTracker,
      burstTime: 3,
    );
    pidTracker++;
    DateTime now = DateTime.now();
    mmu[virtualPageId]!.processPid = pagingProcess.pid;
    mmu[virtualPageId]!.lastAccessTimeStamp = now;
    runningProcesses[pagingProcess.pid] = pagingProcess;
    print('started process: ${pagingProcess.pid} in virtual page: '
        '${pagingProcess.assignedVirtualPage}. physical page frame: ${mmu[virtualPageId]?.physicalMemoryAddress}');
    return pagingProcess.pid;
  }

  VirtualPageInfo fifo(int? virtualPageId) {
    if (virtualPageId != null) {
      print('before FIFO: ${mmu[virtualPageId]}');
    }

    final firstArrivedPage = pageQueue.removeFirst();

    final removedPageInfo = mmu.entries.firstWhere(
        (element) => element.value.physicalMemoryAddress == firstArrivedPage);
    if (removedPageInfo.value.processPid != null) {
      runningProcesses.remove(removedPageInfo.value.processPid);
      print('killed process: ${removedPageInfo.value.processPid}');
      mmu[removedPageInfo.key]!.processPid = null;
    }
    if (virtualPageId != null) {
      mmu[removedPageInfo.key]?.physicalMemoryAddress = null;
      mmu[virtualPageId]?.physicalMemoryAddress = firstArrivedPage;
    }
    pageQueue.add(firstArrivedPage);
    if (virtualPageId != null) {
      print('after FIFO: ${mmu[virtualPageId]}');
    } else {
      print('freed page: ${mmu[removedPageInfo.key]}');
    }
    return mmu[removedPageInfo.key]!;
  }

  void completeProcess(int processPid, {bool isKilled = false}) {
    if (runningProcesses[processPid] == null) {
      print('there is no running process with PID:$processPid');
      return;
    }
    final process = runningProcesses[processPid];
    mmu[process?.assignedVirtualPage]?.processPid = null;
    runningProcesses.remove(processPid);

    print('${isKilled ? 'killed' : 'completed'} process: $processPid');
  }

  VirtualPageInfo lru(int? virtualPageId) {
    final sortedVirtualPages = mmu.entries
        .where((element) => element.value.physicalMemoryAddress != null)
        .sorted((a, b) =>
            a.value.lastAccessTimeStamp.compareTo(b.value.lastAccessTimeStamp));
    final removedPageInfo = sortedVirtualPages.first;

    if (removedPageInfo.value.processPid != null) {
      completeProcess(removedPageInfo.value.processPid!, isKilled: true);
      print(
          'Freed physical page frame: ${removedPageInfo.value.physicalMemoryAddress} using LRU'
          ' (timestamp: ${mmu[removedPageInfo.key]!.lastAccessTimeStamp})');
    }
    if (virtualPageId != null) {
      int? physicalAddress = mmu[removedPageInfo.key]?.physicalMemoryAddress;
      mmu[removedPageInfo.key]?.physicalMemoryAddress = null;
      mmu[virtualPageId]?.physicalMemoryAddress = physicalAddress;
      mmu[virtualPageId]?.lastAccessTimeStamp = DateTime.now();
    }
    if (virtualPageId != null) {
      print('after LRU: ${mmu[virtualPageId]}');
      return mmu[virtualPageId]!;
    } else {
      print('freed page: ${mmu[removedPageInfo.key]}');
      return mmu[removedPageInfo.key]!;
    }
  }
}
