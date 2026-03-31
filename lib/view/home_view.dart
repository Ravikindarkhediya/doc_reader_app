import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller/home_controller.dart';
import '../controller/theme_controller.dart';
import '../data/model/document_model.dart';
import 'widgets/doc_card.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColorExtension>()!;

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ─── Header ───
            SliverToBoxAdapter(child: _buildHeader(context, c)),

            // ─── Search ───
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: _buildSearch(context, c),
              ),
            ),

            // ─── Content ───
            SliverToBoxAdapter(
              child: Obx(() {
                // if (controller.isLoading.value) {
                //   return const _SkeletonSection();
                // }
                if (controller.allDocs.isEmpty &&
                    controller.searchQuery.value.isEmpty) {
                  return _EmptyState(colors: c);
                }
                return _buildSections(context, c);
              }),
            ),
          ],
        ),
      ),
      floatingActionButton: Obx(
        () => AnimatedScale(
          scale: controller.isLoading.value ? 0 : 1,
          duration: const Duration(milliseconds: 200),
          child: FloatingActionButton.extended(
            backgroundColor: c.primary,
            onPressed: controller.pickDocument,
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: const Text(
              "Import",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppColorExtension c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "My Library",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: c.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Sort button
          _iconBtn(
            icon: Icons.sort_rounded,
            c: c,
            onTap: () => _showSortSheet(c),
          ),
          const SizedBox(width: 8),
          // Theme toggle
          GetBuilder<ThemeController>(
            builder: (tc) => _iconBtn(
              icon: tc.isDark
                  ? Icons.wb_sunny_rounded
                  : Icons.auto_fix_high_rounded,
              c: c,
              onTap: () => _cycleTheme(tc),
            ),
          ),
        ],
      ),
    );
  }

  void _cycleTheme(ThemeController tc) {
    if (tc.isLight)
      tc.setTheme(AppThemeMode.dark);
    else
      tc.setTheme(AppThemeMode.light);
  }

  void _showSortSheet(AppColorExtension c) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Sort By",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _sortTile(
              "Recent First",
              Icons.access_time_rounded,
              SortMode.recent,
              c,
            ),
            _sortTile(
              "Name A–Z",
              Icons.sort_by_alpha_rounded,
              SortMode.name,
              c,
            ),
            _sortTile(
              "Oldest First",
              Icons.history_rounded,
              SortMode.oldest,
              c,
            ),
          ],
        ),
      ),
    );
  }

  Widget _sortTile(
    String label,
    IconData icon,
    SortMode mode,
    AppColorExtension c,
  ) {
    return Obx(() {
      final isSelected = controller.sortMode.value == mode;
      return ListTile(
        leading: Icon(icon, color: isSelected ? c.primary : c.textSecondary),
        title: Text(
          label,
          style: TextStyle(
            color: c.textPrimary,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
          ),
        ),
        trailing: isSelected
            ? Icon(Icons.check_circle_rounded, color: c.primary)
            : null,
        onTap: () {
          controller.setSortMode(mode);
          Get.back();
        },
      );
    });
  }

  Widget _iconBtn({
    required IconData icon,
    required AppColorExtension c,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: c.shadow,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: c.textSecondary, size: 20),
      ),
    );
  }

  Widget _buildSearch(BuildContext context, AppColorExtension c) {
    return Container(
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: c.shadow,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        onChanged: controller.search,
        style: TextStyle(color: c.textPrimary),
        decoration: InputDecoration(
          hintText: "Search documents...",
          hintStyle: TextStyle(color: c.textLight),
          prefixIcon: Icon(Icons.search_rounded, color: c.textSecondary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 12,
          ),
          suffixIcon: Obx(
            () => controller.searchQuery.value.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear_rounded, color: c.textSecondary),
                    onPressed: () => controller.search(''),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }

  Widget _buildSections(BuildContext context, AppColorExtension c) {
    return Obx(() {
      // Show search results
      if (controller.searchQuery.value.isNotEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              _sectionHeader(
                "Results for \"${controller.searchQuery.value}\"",
                null,
                c,
              ),
              if (controller.filteredDocs.isEmpty)
                _noResults(c)
              else
                _verticalList(controller.filteredDocs, c),
            ],
          ),
        );
      }

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recent
            if (controller.recentDocs.isNotEmpty) ...[
              const SizedBox(height: 4),
              _sectionHeader("Recent", null, c),
              _horizontalDocList(controller.recentDocs.take(6).toList(), c),
              const SizedBox(height: 24),
            ],

            // Liked
            if (controller.likedDocs.isNotEmpty) ...[
              _sectionHeader("Liked ❤️", controller.goToLiked, c),
              _horizontalDocList(controller.likedDocs.take(5).toList(), c),
              const SizedBox(height: 24),
            ],

            // Bookmarked
            if (controller.bookmarkedDocs.isNotEmpty) ...[
              _sectionHeader("Bookmarked 🔖", controller.goToBookmarks, c),
              _horizontalDocList(controller.bookmarkedDocs.take(5).toList(), c),
              const SizedBox(height: 24),
            ],

            // All Documents
            _sectionHeader("All Documents", controller.goToAllDocs, c),
            if (controller.allDocs.isEmpty)
              _noResults(c)
            else
              _verticalList(controller.allDocs, c),

            const SizedBox(height: 100),
          ],
        ),
      );
    });
  }

  Widget _sectionHeader(
    String title,
    VoidCallback? onSeeAll,
    AppColorExtension c,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: c.textPrimary,
            ),
          ),
          const Spacer(),
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: c.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "See all",
                  style: TextStyle(
                    fontSize: 12,
                    color: c.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _horizontalDocList(List<DocumentModel> docs, AppColorExtension c) {
    return SizedBox(
      height: 155,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: docs.length,
        itemBuilder: (context, i) {
          return Padding(
            padding: EdgeInsets.only(right: i < docs.length - 1 ? 12 : 0),
            child: DocCard(
              doc: docs[i],
              isHorizontal: true,
              onTap: () => controller.openDocument(docs[i]),
              onLike: () => controller.toggleLike(docs[i]),
              onDelete: () => controller.deleteDoc(docs[i]),
              onRename: () => _renameDialog(docs[i], c),
            ),
          );
        },
      ),
    );
  }

  Widget _verticalList(List<DocumentModel> docs, AppColorExtension c) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: docs.length,
      itemBuilder: (context, i) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: DocCard(
            doc: docs[i],
            isHorizontal: false,
            onTap: () => controller.openDocument(docs[i]),
            onLike: () => controller.toggleLike(docs[i]),
            onDelete: () => controller.deleteDoc(docs[i]),
            onRename: () => _renameDialog(docs[i], c),
          ),
        );
      },
    );
  }

  Widget _noResults(AppColorExtension c) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Icon(Icons.search_off_rounded, size: 48, color: c.textLight),
            const SizedBox(height: 8),
            Text(
              "No results found",
              style: TextStyle(color: c.textSecondary, fontSize: 16),
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

// class _SkeletonSection extends StatelessWidget {
//   const _SkeletonSection();
//
//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const SkeletonBox(width: 120, height: 20, radius: 8),
//           const SizedBox(height: 12),
//           Row(
//             children: List.generate(3, (_) => const Padding(
//               padding: EdgeInsets.only(right: 12),
//               child: SkeletonBox(width: 150, height: 155, radius: 18),
//             )),
//           ),
//           const SizedBox(height: 24),
//           const SkeletonBox(width: 100, height: 20, radius: 8),
//           const SizedBox(height: 12),
//           ...List.generate(3, (_) => const Padding(
//             padding: EdgeInsets.only(bottom: 12),
//             child: SkeletonBox(width: double.infinity, height: 80, radius: 16),
//           )),
//         ],
//       ),
//     );
//   }
// }

class _EmptyState extends StatelessWidget {
  final AppColorExtension colors;
  const _EmptyState({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: colors.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.auto_stories_rounded,
                size: 64,
                color: colors.primary.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Your Library is Empty",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Tap the Import button to\nadd your first document",
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textSecondary, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
