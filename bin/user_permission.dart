import 'dart:io';

import 'unix_shell.dart';

extension A on UnixShellOutput {
  bool hasPermission(String path, FilePermission permission) {
    if (!files.containsKey(path)) {
      stdout.writeln('Error: File not found');
      return false;
    }
    var file = files[path];
    if (currentUser!.role == 'admin') return true; // Admin has all access

    if (file!['owner'] != currentUser!.role) {
      stdout.writeln('Permission Denied: You are not the owner of $path');
      return false;
    }

    String perms = file['permissions'];
    if ((permission == FilePermission.read && perms[0] != 'r') ||
        (permission == FilePermission.write && perms[1] != 'w') ||
        (permission == FilePermission.execute && perms[2] != 'x')) {
      stdout.writeln('Permission Denied: Insufficient permissions');
      return false;
    }
    return true;
  }
}
