import 'dart:io';
import 'dart:typed_data';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class PdfService {
  Future<String> extractText(File file) async {
    try {
      // Convert File → Bytes
      final Uint8List bytes = await file.readAsBytes();

      // Load PDF
      final PdfDocument document = PdfDocument(inputBytes: bytes);

      // Extract text
      final String text =
      PdfTextExtractor(document).extractText();

      document.dispose();

      if (text.trim().isNotEmpty) {
        return text;
      } else {
        return await _extractWithOCR(file);
      }
    } catch (e) {
      return await _extractWithOCR(file);
    }
  }

  Future<String> _extractWithOCR(File file) async {
    // TODO: Implement OCR
    return "OCR not implemented yet";
  }


  Future<String> extractTextFromBytes(Uint8List bytes) async {
    try {
      final document = PdfDocument(inputBytes: bytes);

      final text = PdfTextExtractor(document).extractText();

      document.dispose();

      return text;
    } catch (e) {
      return "Failed to read file";
    }
  }
}