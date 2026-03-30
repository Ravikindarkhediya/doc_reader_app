import 'dart:io';
import 'package:path_provider/path_provider.dart';

class StorageService {
  Future<String> saveFile(File file) async {
    final dir = await getApplicationDocumentsDirectory();

    final newPath = "${dir.path}/${file.path.split('/').last}";

    final newFile = await file.copy(newPath);

    return newFile.path;
  }
}