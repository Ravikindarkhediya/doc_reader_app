import 'dart:io';
import 'package:doc_reader/controller/reader_controller.dart';
import 'package:doc_reader/view/home_view.dart';
import 'package:doc_reader/view/settings_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import '../data/model/document_model.dart';
import '../services/file_service.dart';
import '../services/pdf_service.dart';
import '../view/reader_view.dart';

class HomeController extends GetxController {

  // 📦 Lists
  var allDocs = <DocumentModel>[].obs;
  var recentDocs = <DocumentModel>[].obs;
  var likedDocs = <DocumentModel>[].obs;
  var currentIndex = 0.obs;
  var originalDocs = <DocumentModel>[];
  final FileService _fileService = FileService();

  @override
  void onInit() {
    super.onInit();
    loadDocuments();
  }

  final List<Widget> pages = [
    const HomeView(),
    const ReaderView(),
    const SettingsView(),
  ];

  void changeTab(int index) {
    currentIndex.value = index;
  }

  void loadDocuments() {
    final box = Hive.box<DocumentModel>('docs');

    originalDocs = box.values.toList();
    allDocs.value = originalDocs;
    recentDocs.value = originalDocs.reversed.toList();

  }


  void search(String query) {
    if (query.isEmpty) {
      allDocs.value = originalDocs;
    } else {
      allDocs.value = originalDocs
          .where((doc) =>
          doc.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
  }

  // ❤️ Toggle Like
  void toggleLike(DocumentModel doc) {
    doc.isLiked = !doc.isLiked;
    likedDocs.value =
        allDocs.where((e) => e.isLiked).toList();
  }

  // 📂 Open Document
  void openDocument(DocumentModel doc) {
    final readerController = Get.find<ReaderController>();

    readerController.setDocument(doc);

    currentIndex.value = 1;
  }

  void renameDoc(DocumentModel doc, String newName) {
    doc.name = newName;
    doc.save();

    loadDocuments();
  }

  // ➕ Pick Document (temporary)
  Future<void> pickDocument() async {
    try {
      final result = await _fileService.pickDocument();
      final box = Hive.box<DocumentModel>('docs');

      if (result == null || result.files.isEmpty) {
        Get.snackbar("Info", "File selection cancelled");
        return;
      }

      final file = result.files.single;

      if (file.path == null && file.bytes == null) {
        Get.snackbar("Error", "Invalid file");
        return;
      }

      final pdfService = PdfService();
      String extractedText;

      if (file.path != null) {
        extractedText =
        await pdfService.extractText(File(file.path!));
      } else {
        extractedText =
        await pdfService.extractTextFromBytes(file.bytes!);
      }

      final doc = DocumentModel(
        name: file.name,
        path: file.path ?? "",
        extractedText: extractedText,
      );

      allDocs.insert(0, doc);
      recentDocs.insert(0, doc);
      await box.add(doc);
      openDocument(doc);
      loadDocuments();
      Get.snackbar("Success", "Document added");

    } catch (e) {
      print("ERROR: $e");
      Get.snackbar("Error", "Something went wrong");
    }
  }

  void deleteDoc(DocumentModel doc) async {
    await doc.delete();
    loadDocuments();

    Get.snackbar("Deleted", "Document removed");
  }

  void sortByName() {
    allDocs.sort((a, b) => a.name.compareTo(b.name));
  }

  void sortByRecent() {
    allDocs.value = allDocs.reversed.toList();
  }
}