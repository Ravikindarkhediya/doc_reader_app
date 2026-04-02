import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import 'file_service.dart';

class PdfService {
  /// Extract text from a File — page by page so one bad page won't crash all.
  Future<String> extractText(File file) async {
    final bytes = await file.readAsBytes();
    return extractTextFromBytes(bytes);
  }

  /// Extract text from raw bytes — resilient to non-English and malformed PDFs.
  Future<String> extractTextFromBytes(Uint8List bytes) async {
    PdfDocument? document;
    try {
      document = PdfDocument(inputBytes: bytes);
      final buffer = StringBuffer();
      final pageCount = document.pages.count;
      final extractor = PdfTextExtractor(document);

      for (int i = 0; i < pageCount; i++) {
        try {
          // Extract one page at a time — isolates encoding failures per page
          final pageText = extractor.extractText(
            startPageIndex: i,
            endPageIndex: i,
          );
          if (pageText.trim().isNotEmpty) {
            buffer.write(pageText);
            if (!pageText.endsWith('\n')) buffer.write('\n');
          }
        } catch (e) {
          debugPrint("PdfService: skipping page $i — $e");
          // Continue with next page instead of crashing
        }
      }

      final result = buffer.toString();

      // If Syncfusion returned garbage bytes (common with some encodings),
      // try re-decoding the raw bytes through our FileService decoder.
      if (_looksGarbled(result)) {
        debugPrint("PdfService: extracted text looks garbled, trying raw decode");
        return FileService.decodeBytes(bytes);
      }

      return result.trim().isEmpty ? '' : result;
    } catch (e) {
      debugPrint("PdfService.extractTextFromBytes error: $e");
      return '';
    } finally {
      document?.dispose();
    }
  }

  /// Heuristic: if >40% of chars are replacement characters the text is garbled.
  bool _looksGarbled(String text) {
    if (text.length < 50) return false;
    final sample = text.substring(0, text.length.clamp(0, 500));
    final garbage = sample.runes.where((r) => r == 0xFFFD || r < 0x20 && r != 0x0A && r != 0x0D && r != 0x09).length;
    return garbage / sample.length > 0.4;
  }
}