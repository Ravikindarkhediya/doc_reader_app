import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller/home_controller.dart';
import '../controller/theme_controller.dart';
import 'widgets/doc_card.dart';

// ─── ALL DOCUMENTS SCREEN ───────────────────────────────────────────────────
class AllDocumentsScreen extends GetView<HomeController> {
  const AllDocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColorExtension>()!;

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.card,
        title: Text("All Documents", style: TextStyle(color: c.textPrimary)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: c.textPrimary, size: 20),
          onPressed: Get.back,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.sort_rounded, color: c.textSecondary),
            onPressed: () => _showSort(c),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.allDocs.isEmpty) {
          return Center(child: Text("No documents", style: TextStyle(color: c.textSecondary)));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.allDocs.length,
          itemBuilder: (context, i) {
            final doc = controller.allDocs[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DocCard(
                doc: doc,
                isHorizontal: false,
                onTap: () => controller.openDocument(doc),
                onLike: () => controller.toggleLike(doc),
                onDelete: () => controller.deleteDoc(doc),
                onRename: () => _renameDialog(doc, c),
              ),
            );
          },
        );
      }),
    );
  }

  void _showSort(AppColorExtension c) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.access_time_rounded, color: c.primary),
              title: Text("Recent First", style: TextStyle(color: c.textPrimary)),
              onTap: () { controller.setSortMode(SortMode.recent); Get.back(); },
            ),
            ListTile(
              leading: Icon(Icons.sort_by_alpha_rounded, color: c.primary),
              title: Text("Name A–Z", style: TextStyle(color: c.textPrimary)),
              onTap: () { controller.setSortMode(SortMode.name); Get.back(); },
            ),
          ],
        ),
      ),
    );
  }
  void _renameDialog(doc, AppColorExtension c) {

    // 🔥 Extract extension
    final ext = doc.name.contains('.')
        ? doc.name.substring(doc.name.lastIndexOf('.'))
        : '';

    // 🔥 Remove extension for editing
    final baseName = doc.name.contains('.')
        ? doc.name.substring(0, doc.name.lastIndexOf('.'))
        : doc.name;

    final ctrl = TextEditingController(text: baseName);

    Get.dialog(
      AlertDialog(
        backgroundColor: c.card,
        title: Text("Rename", style: TextStyle(color: c.textPrimary)),

        content: Row(
          children: [
            Expanded(
              child: TextField(
                controller: ctrl,
                style: TextStyle(color: c.textPrimary),
                decoration: const InputDecoration(
                  hintText: "Enter file name",
                ),
              ),
            ),

            // 🔥 Extension show but not editable
            if (ext.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Text(
                  ext,
                  style: TextStyle(color: c.textSecondary),
                ),
              ),
          ],
        ),

        actions: [
          TextButton(
            onPressed: Get.back,
            child: Text("Cancel", style: TextStyle(color: c.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              controller.renameDoc(doc, ctrl.text);
              Get.back();
            },
            child: Text("Save", style: TextStyle(color: c.primary)),
          ),
        ],
      ),
    );
  }
}

// ─── BOOKMARKS SCREEN ────────────────────────────────────────────────────────
class BookmarksScreen extends GetView<HomeController> {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColorExtension>()!;

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.card,
        title: Text("Bookmarked", style: TextStyle(color: c.textPrimary)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: c.textPrimary, size: 20),
          onPressed: Get.back,
        ),
      ),
      body: Obx(() {
        final docs = controller.bookmarkedDocs;
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bookmark_border_rounded, size: 56, color: c.textLight),
                const SizedBox(height: 12),
                Text("No bookmarks yet", style: TextStyle(color: c.textSecondary, fontSize: 16)),
                const SizedBox(height: 6),
                Text("Long-press any sentence while reading\nto bookmark it",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: c.textLight, fontSize: 13)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final doc = docs[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DocCard(
                doc: doc,
                isHorizontal: false,
                onTap: () => controller.openDocument(doc),
                onLike: () => controller.toggleLike(doc),
                onDelete: () => controller.deleteDoc(doc),
                onRename: () {},
              ),
            );
          },
        );
      }),
    );
  }
}

// ─── LIKED SCREEN ─────────────────────────────────────────────────────────────
class LikedScreen extends GetView<HomeController> {
  const LikedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColorExtension>()!;

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.card,
        title: Text("Liked ❤️", style: TextStyle(color: c.textPrimary)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: c.textPrimary, size: 20),
          onPressed: Get.back,
        ),
      ),
      body: Obx(() {
        final docs = controller.likedDocs;
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.favorite_border_rounded, size: 56, color: c.textLight),
                const SizedBox(height: 12),
                Text("No liked documents", style: TextStyle(color: c.textSecondary, fontSize: 16)),
                const SizedBox(height: 6),
                Text("Tap the ❤️ on any document to like it",
                    style: TextStyle(color: c.textLight, fontSize: 13)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final doc = docs[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DocCard(
                doc: doc,
                isHorizontal: false,
                onTap: () => controller.openDocument(doc),
                onLike: () => controller.toggleLike(doc),
                onDelete: () => controller.deleteDoc(doc),
                onRename: () {},
              ),
            );
          },
        );
      }),
    );
  }
}
