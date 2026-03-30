import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/home_controller.dart';
import '../core/app_color.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    int crossAxisCount = width > 900
        ? 4
        : width > 600
        ? 3
        : 2;

    return Scaffold(
      backgroundColor: AppColors.background,

      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: controller.pickDocument,
        child: const Icon(Icons.add, color: Colors.white),
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [

              // 🔝 Header
              _buildHeader(),

              const SizedBox(height: 16),

              // 🔍 Search
              _buildSearch(),

              const SizedBox(height: 16),

              Expanded(
                child: Obx(() {
                  if (controller.allDocs.isEmpty) {
                    return _emptyState();
                  }

                  return ListView(
                    children: [

                      // 📄 Recent
                      _sectionTitle("Recent"),
                      _horizontalList(controller.recentDocs),

                      const SizedBox(height: 20),

                      // ❤️ Liked
                      _sectionTitle("Liked"),
                      _horizontalList(controller.likedDocs),

                      const SizedBox(height: 20),

                      // 📚 All Docs
                      _sectionTitle("All Documents"),
                      _grid(controller.allDocs, crossAxisCount),
                    ],
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Welcome 👋",
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "My Documents",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.notifications_none,
              color: AppColors.textSecondary),
        ),
      ],
    );
  }

  // 🔍 Search Bar
  Widget _buildSearch() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
          )
        ],
      ),
      child: TextField(
        onChanged: controller.search,
        decoration: InputDecoration(
          hintText: "Search documents...",
          prefixIcon: Icon(Icons.search),
          border: InputBorder.none,
          contentPadding:
          const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
  // 📌 Section Title
  Widget _sectionTitle(String title) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const Spacer(),
        Text(
          "See all",
          style: TextStyle(
            fontSize: 13,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
  // 📄 Horizontal List
  Widget _horizontalList(RxList docs) {
    return SizedBox(
      height: 130,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: docs.length,
        itemBuilder: (context, index) {
          final doc = docs[index];
          return _docCard(doc, isHorizontal: true);
        },
      ),
    );
  }

  // 📚 Grid
  Widget _grid(RxList docs, int crossAxisCount) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: docs.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemBuilder: (context, index) {
        final doc = docs[index];
        return _docCard(doc);
      },
    );
  }

  // 📦 Document Card
  Widget _docCard(doc, {bool isHorizontal = false}) {
    return GestureDetector(
      onTap: () => controller.openDocument(doc),
      child: Container(
        width: isHorizontal ? 160 : null,
        padding: const EdgeInsets.all(14),
        margin: isHorizontal
            ? const EdgeInsets.only(right: 12)
            : null,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.card,
              AppColors.card.withOpacity(0.9),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Icon + Like
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.picture_as_pdf,
                      color: AppColors.primary),
                ),

                GestureDetector(
                  onTap: () => controller.toggleLike(doc),
                  child: Icon(
                    doc.isLiked
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: doc.isLiked
                        ? Colors.red
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),

            const Spacer(),

            Text(
              doc.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              "Tap to read",
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 📭 Empty State
  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.description,
              size: 70,
              color: AppColors.primary.withOpacity(0.4)),
          const SizedBox(height: 12),
          Text(
            "No Documents Yet",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Tap + to add your first document",
            style: TextStyle(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}