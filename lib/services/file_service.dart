import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class FileService {
  Future<bool> _requestPermission() async {
    if (kIsWeb) return true;

    if (Platform.isAndroid) {
      // Android 13+ uses granular media permissions
      if (await Permission.photos.isGranted ||
          await Permission.storage.isGranted ||
          await Permission.manageExternalStorage.isGranted) {
        return true;
      }

      // Try storage first (Android < 13)
      var status = await Permission.storage.request();
      if (status.isGranted) return true;

      // Android 13+
      status = await Permission.photos.request();
      if (status.isGranted) return true;

      if (status.isPermanentlyDenied) {
        await openAppSettings();
        return false;
      }

      return false;
    }

    if (Platform.isIOS) {
      return true; // iOS handles via file picker natively
    }

    return true;
  }

  /// Pick PDF, DOC, DOCX or TXT
  Future<FilePickerResult?> pickDocument() async {
    try {
      final hasPermission = await _requestPermission();
      if (!hasPermission) {
        debugPrint("FileService: Permission denied");
        return null;
      }

      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        // allowedExtensions: ['pdf', 'txt'],
        withData: true, // Required for bytes access
        allowMultiple: false,
      );

      return result;
    } catch (e) {
      debugPrint("FileService.pickDocument error: $e");
      return null;
    }
  }

  /// Read plain text from TXT file
  static Future<String> readTxtFile(File file) async {
    try {
      return await file.readAsString();
    } catch (e) {
      debugPrint("FileService.readTxtFile error: $e");
      return '';
    }
  }

  /// Read TXT from bytes
  static String readTxtFromBytes(List<int> bytes) {
    try {
      return String.fromCharCodes(bytes);
    } catch (e) {
      debugPrint("FileService.readTxtFromBytes error: $e");
      return '';
    }
  }
}
