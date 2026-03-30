import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/reader_controller.dart';
import '../core/app_color.dart';

class ReaderView extends GetView<ReaderController> {
  const ReaderView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.readingBackground,

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Get.back(),
        ),
        title: Text(
          "Reader",
          style: TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert, color: AppColors.textSecondary),
            onPressed: () => _showOptions(),
          ),
        ],
      ),

      body: Column(
        children: [

          /// 📖 READING AREA
          Expanded(child: _reader()),

          /// 🎛 MINI PLAYER
          _miniPlayer(),
        ],
      ),
    );
  }

  // 📖 Reader
  Widget _reader() {
    return Obx(() {
      if (controller.chunks.isEmpty) {
        return Center(child: Text("No content"));
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: controller.chunks.length,
        itemBuilder: (context, index) {

          final isActive = controller.currentIndex.value == index;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),

            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.highlight
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),

            child: Text(
              controller.chunks[index],
              style: TextStyle(
                fontSize: isActive ? 18 : 16,
                height: 1.6,
                color: AppColors.textPrimary,
                fontWeight:
                isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          );
        },
      );
    });
  }

  // 🎛 MINI PLAYER (Modern)
  Widget _miniPlayer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          /// 🔊 SPEED
          Row(
            children: [
              Icon(Icons.speed, color: AppColors.textSecondary),
              Expanded(
                child: Obx(() => Slider(
                  value: controller.speed.value,
                  min: 0.3,
                  max: 1.5,
                  activeColor: AppColors.primary,
                  onChanged: controller.setSpeed,
                )),
              ),
              Obx(() => Text(
                "${controller.speed.value.toStringAsFixed(1)}x",
                style: TextStyle(color: AppColors.textSecondary),
              ))
            ],
          ),

          /// ▶ CONTROLS
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [

              IconButton(
                icon: Icon(Icons.replay_10, size: 28),
                onPressed: controller.rewind,
              ),

              /// PLAY BUTTON
              Obx(() => GestureDetector(
                onTap: controller.isPlaying.value
                    ? controller.pause
                    : controller.play,
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.secondary,
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    controller.isPlaying.value
                        ? Icons.pause
                        : Icons.play_arrow,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              )),

              IconButton(
                icon: Icon(Icons.forward_10, size: 28),
                onPressed: controller.forward,
              ),
            ],
          ),

          const SizedBox(height: 6),

          /// ⚙ OPTIONS BUTTON
          TextButton.icon(
            onPressed: _showOptions,
            icon: Icon(Icons.tune, color: AppColors.primary),
            label: Text("More Options",
                style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  // ⚙ FEATURE PANEL (BOTTOM SHEET)
  void _showOptions() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Wrap(
          children: [

            _optionTile(Icons.bookmark, "Bookmark", () {}),
            _optionTile(Icons.language, "Language", () {}),
            _optionTile(Icons.record_voice_over, "Voice", () {}),
            _optionTile(Icons.audiotrack, "Save as MP3", () {}),
            _optionTile(Icons.play_circle, "Background Play", () {}),
            _optionTile(Icons.delete, "Delete File", () {}),

          ],
        ),
      ),
    );
  }

  Widget _optionTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title),
      onTap: onTap,
    );
  }
}