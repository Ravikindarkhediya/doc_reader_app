import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class FileService {
  static const _supportedExtensions = {
    'pdf', 'txt', 'md', 'markdown', 'html', 'htm',
    'csv', 'rtf', 'log', 'xml', 'json', 'epub',
    'doc', 'docx', 'odt',
  };

  Future<bool> _requestPermission() async {
    if (kIsWeb) return true;
    if (Platform.isIOS) return true;

    if (Platform.isAndroid) {
      if (await Permission.photos.isGranted ||
          await Permission.storage.isGranted ||
          await Permission.manageExternalStorage.isGranted) {
        return true;
      }
      var status = await Permission.storage.request();
      if (status.isGranted) return true;
      status = await Permission.photos.request();
      if (status.isGranted) return true;
      if (status.isPermanentlyDenied) {
        await openAppSettings();
        return false;
      }
      return false;
    }
    return true;
  }

  Future<FilePickerResult?> pickDocument() async {
    try {
      final hasPermission = await _requestPermission();
      if (!hasPermission) {
        debugPrint("FileService: Permission denied");
        return null;
      }
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: true,
        allowMultiple: false,
      );
      return result;
    } catch (e) {
      debugPrint("FileService.pickDocument error: $e");
      return null;
    }
  }

  static bool isSupported(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    return _supportedExtensions.contains(ext);
  }

  /// Read plain text file — tries UTF-8 first, falls back to Latin-1
  static Future<String> readTxtFile(File file) async {
    try {
      final bytes = await file.readAsBytes();
      return decodeBytes(bytes);
    } catch (e) {
      debugPrint("FileService.readTxtFile error: $e");
      return '';
    }
  }

  /// Decode bytes with graceful fallback: UTF-8 → Latin-1 → ASCII-only
  static String decodeBytes(List<int> bytes) {
    // Try UTF-8 first
    try {
      return utf8.decode(bytes, allowMalformed: false);
    } catch (_) {}

    // Try Latin-1 (ISO-8859-1)
    try {
      return latin1.decode(bytes);
    } catch (_) {}

    // Last resort: keep only printable ASCII
    return String.fromCharCodes(
      bytes.where((b) => b >= 0x20 || b == 0x0A || b == 0x0D || b == 0x09),
    );
  }

  static String readTxtFromBytes(List<int> bytes) {
    return decodeBytes(bytes);
  }
}