import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '../core/chunk_engine.dart';
import '../data/model/document_model.dart';
import '../services/file_service.dart';
import '../services/pdf_service.dart';
import '../view/all_documents_screen.dart';
import '../view/reader_view.dart';
import 'reader_controller.dart';

enum SortMode { recent, name, oldest }

class HomeController extends GetxController {
  var allDocs = <DocumentModel>[].obs;
  var recentDocs = <DocumentModel>[].obs;
  var likedDocs = <DocumentModel>[].obs;
  var filteredDocs = <DocumentModel>[].obs;
  var originalDocs = <DocumentModel>[];

  var isLoading = false.obs;
  var searchQuery = ''.obs;
  var sortMode = SortMode.recent.obs;
  var currentTabIndex = 0.obs;

  final FileService _fileService = FileService();

  @override
  void onInit() {
    super.onInit();
    loadDocuments();
  }

  void loadDocuments() {
    final box = Hive.box<DocumentModel>('docs');
    originalDocs = box.values.toList();
    _applySort();
    _refreshFilteredLists();
  }

  void _refreshFilteredLists() {
    likedDocs.value = originalDocs.where((d) => d.isLiked).toList();
    recentDocs.value = List.from(originalDocs.reversed);
    if (searchQuery.value.isNotEmpty) {
      search(searchQuery.value);
    } else {
      allDocs.value = List.from(originalDocs);
      filteredDocs.value = List.from(originalDocs);
    }
  }

  void _applySort() {
    switch (sortMode.value) {
      case SortMode.name:
        originalDocs.sort((a, b) => a.name.compareTo(b.name));
        break;
      case SortMode.oldest:
        originalDocs.sort((a, b) =>
            (a.addedAt ?? DateTime(2000)).compareTo(b.addedAt ?? DateTime(2000)));
        break;
      case SortMode.recent:
      default:
        originalDocs.sort((a, b) =>
            (b.addedAt ?? DateTime(2000)).compareTo(a.addedAt ?? DateTime(2000)));
    }
    allDocs.value = List.from(originalDocs);
    filteredDocs.value = List.from(originalDocs);
  }

  void setSortMode(SortMode mode) {
    sortMode.value = mode;
    _applySort();
  }

  void search(String query) {
    searchQuery.value = query;
    if (query.isEmpty) {
      allDocs.value = List.from(originalDocs);
      filteredDocs.value = List.from(originalDocs);
    } else {
      final q = query.toLowerCase();
      final results =
      originalDocs.where((doc) => doc.name.toLowerCase().contains(q)).toList();
      allDocs.value = results;
      filteredDocs.value = results;
    }
  }

  void toggleLike(DocumentModel doc) {
    doc.isLiked = !doc.isLiked;
    doc.save();
    _refreshFilteredLists();
  }

  void openDocument(DocumentModel doc) {
    final readerController = Get.find<ReaderController>();
    readerController.setDocument(doc);
    Get.to(() => const ReaderView(), transition: Transition.cupertino);
  }

  Future<void> pickDocument() async {
    try {
      isLoading.value = true;
      final result = await _fileService.pickDocument();

      if (result == null || result.files.isEmpty) return;

      final file = result.files.single;
      if (file.path == null && file.bytes == null) {
        _showError("Invalid file: could not read data");
        return;
      }

      // Size check (50 MB)
      final size = file.bytes?.length ?? await File(file.path!).length();
      if (size > 50 * 1024 * 1024) {
        _showError("File too large. Maximum size is 50 MB.");
        return;
      }

      // Duplicate check
      final box = Hive.box<DocumentModel>('docs');
      if (box.values.any((d) => d.name == file.name)) {
        Get.snackbar(
          "Already Imported",
          '"${file.name}" is already in your library',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.shade700,
          colorText: Colors.white,
          margin: const EdgeInsets.all(12),
        );
        return;
      }

      final ext = (file.name.split('.').last).toLowerCase();
      String rawText = '';

      if (ext == 'pdf') {
        // ── PDF ──────────────────────────────────────────────────────────────
        try {
          final pdfService = PdfService();
          rawText = file.bytes != null
              ? await pdfService.extractTextFromBytes(file.bytes!)
              : await pdfService.extractText(File(file.path!));
        } catch (e) {
          debugPrint("PDF extraction failed: $e");
        }
      } else {
        // ── All other readable formats (txt, md, html, csv, etc.) ────────────
        try {
          rawText = file.bytes != null
              ? FileService.readTxtFromBytes(file.bytes!)
              : await FileService.readTxtFile(File(file.path!));
        } catch (e) {
          debugPrint("Text read failed: $e");
        }
      }

      if (rawText.trim().isEmpty) {
        Get.snackbar(
          "⚠️ No Text Found",
          "This may be a scanned PDF or unsupported format. TTS won't work.",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.shade700,
          colorText: Colors.white,
          margin: const EdgeInsets.all(12),
          duration: const Duration(seconds: 4),
        );
        // Still import with empty text so user can see the file
      }

      final cleanedText = ChunkEngine.cleanText(rawText);
      final wordCount =
      cleanedText.isNotEmpty ? ChunkEngine.wordCount(cleanedText) : 0;

      final doc = DocumentModel(
        name: file.name,
        path: file.path ?? '',
        extractedText: cleanedText,
        addedAt: DateTime.now(),
        mimeType: ext,
        wordCount: wordCount,
      );

      await box.add(doc);
      loadDocuments();

      Get.snackbar(
        "✅ Imported",
        '"${file.name}" added to your library',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade700,
        colorText: Colors.white,
        margin: const EdgeInsets.all(12),
      );

      openDocument(doc);
    } catch (e) {
      _showError("Import failed: ${e.toString()}");
    } finally {
      isLoading.value = false;
    }
  }

  void renameDoc(DocumentModel doc, String newName) {
    if (newName.trim().isEmpty) return;
    final ext = doc.name.contains('.')
        ? doc.name.substring(doc.name.lastIndexOf('.'))
        : '';
    String cleanName = newName.trim();
    if (cleanName.contains('.')) {
      cleanName = cleanName.substring(0, cleanName.lastIndexOf('.'));
    }
    doc.name = cleanName + ext;
    doc.save();
    loadDocuments();
  }

  String getNameWithoutExtension(String name) =>
      name.contains('.') ? name.substring(0, name.lastIndexOf('.')) : name;

  Future<void> deleteDoc(DocumentModel doc) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text("Delete Document"),
        content: Text('Delete "${doc.name}"? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text("Cancel")),
          TextButton(
            onPressed: () => Get.back(result: true),
            child:
            const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await doc.delete();
      loadDocuments();
      Get.snackbar("Deleted", "Document removed",
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  void _showError(String msg) {
    isLoading.value = false;
    Get.snackbar(
      "Error",
      msg,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.withOpacity(0.9),
      colorText: Colors.white,
    );
  }

  void goToAllDocs() =>
      Get.to(() => const AllDocumentsScreen(), transition: Transition.rightToLeft);

  void goToLiked() =>
      Get.to(() => const LikedScreen(), transition: Transition.rightToLeft);
}