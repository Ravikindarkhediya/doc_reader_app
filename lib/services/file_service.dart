import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class FileService {

  Future<bool> _requestPermission() async {
    if (Platform.isAndroid) {

      // ✅ Android 13+
      if (await Permission.photos.isGranted ||
          await Permission.videos.isGranted ||
          await Permission.audio.isGranted) {
        return true;
      }

      final status = await Permission.photos.request();

      if (status.isGranted) return true;

      if (status.isPermanentlyDenied) {
        openAppSettings();
      }

      return false;
    }

    return true;
  }

  /// 📂 Pick Document
  Future<FilePickerResult?> pickDocument() async {
    bool hasPermission = await _requestPermission();

    if (!hasPermission) {
      print("Permission denied");
      return null;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
      withData: true, // 🔥 MUST
    );

    print("Picked result: $result");

    return result;
  }

}