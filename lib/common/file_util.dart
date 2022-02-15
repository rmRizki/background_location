import 'dart:io';

import 'package:path_provider/path_provider.dart';

class FileUtil {
  Future<String> getDirectory({String folder = 'media'}) async {
    final extDir = await getApplicationDocumentsDirectory();
    await Directory('${extDir.path}/$folder').create(recursive: true);
    return '${extDir.path}/$folder';
  }

  Future<String> getFilePath({
    required String format,
    required String folder,
  }) async {
    final dirPath = await getDirectory(folder: folder);
    return '$dirPath/${getFileName()}$format';
  }

  Future<void> deleteAllFile({
    required String folder,
  }) async {
    final dirPath = await getDirectory(folder: folder);
    final dir = Directory(dirPath);
    dir.deleteSync(recursive: true);
  }

  Future<List<FileSystemEntity>> getFileList({required String folder}) async {
    final dirPath = await getDirectory(folder: folder);
    final myDir = Directory(dirPath);
    List<FileSystemEntity> fileList;
    fileList = myDir.listSync(recursive: true, followLinks: false);
    fileList.sort((a, b) {
      return b.path.compareTo(a.path);
    });
    return fileList;
  }

  String getFileName() => DateTime.now().millisecondsSinceEpoch.toString();
}
