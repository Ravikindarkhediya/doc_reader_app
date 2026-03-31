import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class PdfService {
  Future<String> extractText(File file) async {
    try {
      final Uint8List bytes = await file.readAsBytes();
      return _extractFromBytes(bytes);
    } catch (e) {
      debugPrint("PdfService.extractText error: $e");
      return '';
    }
  }

  Future<String> extractTextFromBytes(Uint8List bytes) async {
    try {
      return _extractFromBytes(bytes);
    } catch (e) {
      debugPrint("PdfService.extractTextFromBytes error: $e");
      return '';
    }
  }

  String _extractFromBytes(Uint8List bytes) {
    if (bytes.isEmpty) return '';

    try {
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      final String text = PdfTextExtractor(document).extractText();
      document.dispose();
      return text;
    } catch (e) {
      debugPrint("PDF extraction failed: $e");
      return '';
    }
  }
}
