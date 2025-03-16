import 'dart:collection';

import 'package:collection/collection.dart';

import 'custom_process.dart';

enum ReplacementAlgo {
  fifo,
  lru,
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
  Paging({
    this.virtualMemSize = 64,
    this.physicalMemSize = 32,
    required this.runningProcesses,
  }) : mmu = {} {
    DateTime now = DateTime.now();
    for (int i = 0; i < virtualMemSize; i++) {
      mmu[i] = VirtualPageInfo(
          virtualPage: i,
          physicalMemoryAddress: i < physicalMemSize ? i : null,
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

  void startProcessAtSpecificPage(
      int virtualPageId, ReplacementAlgo replacementAlgo) {
    final pageInfo = mmu[virtualPageId];
    if (pageInfo == null) {
      print('invalid page number $virtualPageId');
      return;
    }
    if (pageInfo.physicalMemoryAddress == null) {
      print('page fault occured, performing $replacementAlgo to free frame');
      if (replacementAlgo == ReplacementAlgo.fifo) {
        fifo(virtualPageId);
      } else {
        lru(virtualPageId);
      }
    }
  }

  void startProcessAnyPage(ReplacementAlgo replacementAlgo) {
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
    PagingProcess pagingProcess = PagingProcess(
      assignedVirtualPage: freePages.first,
      pid: pidTracker,
      burstTime: 3,
    );
    pidTracker++;
    DateTime now = DateTime.now();
    mmu[freePages.first]!.processPid = pagingProcess.pid;
    mmu[freePages.first]!.lastAccessTimeStamp = now;
    runningProcesses[pagingProcess.pid] = pagingProcess;
    print(
        'started process: ${pagingProcess.pid} in page: ${pagingProcess.assignedVirtualPage}');
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

  MapEntry<int, VirtualPageInfo> fifo(int? virtualPageId) {
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
    return removedPageInfo;
  }

  MapEntry<int, VirtualPageInfo> lru(int? virtualPageId) {
    final sortedVirtualPages = mmu.entries
        .where((element) => element.value.physicalMemoryAddress != null)
        .sorted((a, b) =>
            a.value.lastAccessTimeStamp.compareTo(b.value.lastAccessTimeStamp));
    final removedPageInfo = sortedVirtualPages.first;

    if (removedPageInfo.value.processPid != null) {
      final runningProcess =
          runningProcesses[removedPageInfo.value.processPid]!;
      mmu[runningProcess.assignedVirtualPage]!.processPid = null;
      print('Freed page frame: ${runningProcess.assignedVirtualPage} using LRU'
          ' (timestamp: ${mmu[runningProcess.assignedVirtualPage]!.lastAccessTimeStamp})');
      runningProcesses.remove(runningProcess);
      print('killed process: ${runningProcess.pid}');
    }
    if (virtualPageId != null) {
      int? physicalAddress = mmu[removedPageInfo.key]?.physicalMemoryAddress;
      mmu[removedPageInfo.key]?.physicalMemoryAddress = null;
      mmu[virtualPageId]?.physicalMemoryAddress = physicalAddress;
    }
    if (virtualPageId != null) {
      print('after LRU: ${mmu[virtualPageId]}');
    } else {
      print('freed page: ${mmu[removedPageInfo.key]}');
    }
    return removedPageInfo;
  }
}
