import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller/reader_controller.dart';
import '../controller/theme_controller.dart';
import '../core/chunk_engine.dart';

class ReaderView extends GetView<ReaderController> {
  const ReaderView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColorExtension>()!;

    return Scaffold(
      backgroundColor: c.background,
      appBar: _buildAppBar(c),
      body: Column(
        children: [
          // Progress bar
          Obx(() => LinearProgressIndicator(
            value: controller.progressPercent,
            backgroundColor: c.highlight,
            valueColor: AlwaysStoppedAnimation(c.primary),
            minHeight: 3,
          )),

          // Reader body
          Expanded(child: _buildReader(c)),

          // Mini player
          _buildMiniPlayer(c),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(AppColorExtension c) {
    return AppBar(
      backgroundColor: c.card,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_rounded, color: c.textPrimary, size: 20),
        onPressed: () {
          controller.pause();
          Get.back();
        },
      ),
      title: Obx(() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            controller.currentDoc.value?.name ?? "Reader",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: c.textPrimary,
            ),
          ),
          Text(
            controller.progressText,
            style: TextStyle(fontSize: 11, color: c.textSecondary),
          ),
        ],
      )),
      actions: [
        // Bookmark current chunk
        Obx(() => IconButton(
          icon: Icon(
            controller.isCurrentChunkBookmarked
                ? Icons.bookmark_rounded
                : Icons.bookmark_border_rounded,
            color: controller.isCurrentChunkBookmarked ? c.primary : c.textSecondary,
          ),
          onPressed: controller.toggleBookmark,
        )),
        // More options
        IconButton(
          icon: Icon(Icons.tune_rounded, color: c.textSecondary),
          onPressed: () => _showOptionsSheet(c),
        ),
      ],
    );
  }

  Widget _buildReader(AppColorExtension c) {
    return Obx(() {
      if (controller.isLoading.value) {
        return Center(child: CircularProgressIndicator(color: c.primary));
      }

      if (controller.hasError.value) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline_rounded, size: 56, color: c.error),
                const SizedBox(height: 16),
                Text(
                  controller.errorMessage.value,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: c.textSecondary),
                ),
              ],
            ),
          ),
        );
      }

      if (controller.chunks.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.text_snippet_outlined, size: 56, color: c.textLight),
              const SizedBox(height: 12),
              Text("No content to display",
                  style: TextStyle(color: c.textSecondary)),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        itemCount: controller.chunks.length,
        itemBuilder: (context, index) {
          return Obx(() {
            final isActive = controller.currentIndex.value == index;
            final isBookmarked = controller.currentDoc.value?.hasBookmark(index) ?? false;

            return GestureDetector(
              onTap: () => controller.jumpTo(index),
              onLongPress: () {
                // Toggle bookmark on long press
                controller.jumpTo(index);
                controller.toggleBookmark();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isActive ? c.highlight : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  border: isBookmarked
                      ? Border.all(color: c.primary.withOpacity(0.4), width: 1.5)
                      : null,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isBookmarked)
                      Padding(
                        padding: const EdgeInsets.only(top: 3, right: 8),
                        child: Icon(Icons.bookmark_rounded, size: 14, color: c.primary),
                      ),
                    Expanded(
                      child: Text(
                        controller.chunks[index],
                        style: TextStyle(
                          fontSize: isActive ? 18 : 15,
                          height: 1.7,
                          color: isActive ? c.textPrimary : c.textSecondary,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          });
        },
      );
    });
  }

  Widget _buildMiniPlayer(AppColorExtension c) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: c.shadow, blurRadius: 20, offset: const Offset(0, -4))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Speed row
          Row(
            children: [
              Icon(Icons.speed_rounded, size: 18, color: c.textSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Obx(() => SliderTheme(
                  data: SliderTheme.of(Get.context!).copyWith(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                  ),
                  child: Slider(
                    value: controller.speed.value,
                    min: 0.3,
                    max: 1.5,
                    divisions: 12,
                    activeColor: c.primary,
                    inactiveColor: c.highlight,
                    onChanged: controller.setSpeed,
                  ),
                )),
              ),
              Obx(() => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: c.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "${controller.speed.value.toStringAsFixed(1)}x",
                  style: TextStyle(
                    fontSize: 12,
                    color: c.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )),
            ],
          ),

          const SizedBox(height: 8),

          // Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _controlBtn(Icons.replay_10_rounded, c, controller.rewind),
              const SizedBox(width: 8),
              // Play/Pause
              Obx(() => GestureDetector(
                onTap: controller.isPlaying.value ? controller.pause : controller.play,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [c.primary, c.secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: c.primary.withOpacity(0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      key: ValueKey(controller.isPlaying.value),
                      controller.isPlaying.value
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 34,
                    ),
                  ),
                ),
              )),
              const SizedBox(width: 8),
              _controlBtn(Icons.forward_10_rounded, c, controller.forward),
            ],
          ),
        ],
      ),
    );
  }

  Widget _controlBtn(IconData icon, AppColorExtension c, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.highlight,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: c.textPrimary, size: 24),
      ),
    );
  }

  void _showOptionsSheet(AppColorExtension c) {
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
            Text("Options",
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700, color: c.textPrimary)),
            const SizedBox(height: 16),

            // Chunk Mode
            _sheetSection("Reading Mode", c),
            Obx(() => Row(
              children: ChunkMode.values.map((mode) {
                final isSelected = controller.chunkMode.value == mode;
                final label = mode.name[0].toUpperCase() + mode.name.substring(1);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(label),
                    selected: isSelected,
                    onSelected: (_) => controller.changeChunkMode(mode),
                    selectedColor: c.primary,
                    backgroundColor: c.highlight,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : c.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            )),

            const SizedBox(height: 16),

            // Language
            _optTile(Icons.language_rounded, "Language", c, () => _showLanguagePicker(c)),

            // Voice
            _optTile(Icons.record_voice_over_rounded, "Voice", c, () => _showVoicePicker(c)),

            // Save as MP3
            Obx(() => _optTile(
              Icons.audiotrack_rounded,
              controller.isSavingMp3.value ? "Saving..." : "Save as MP3",
              c,
              controller.isSavingMp3.value ? null : () {
                Get.back();
                controller.saveAsMp3();
              },
            )),

            // Bookmark
            _optTile(Icons.bookmark_add_rounded, "Bookmark Position", c, () {
              Get.back();
              controller.toggleBookmark();
            }),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _sheetSection(String label, AppColorExtension c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(label,
          style: TextStyle(fontSize: 13, color: c.textSecondary, fontWeight: FontWeight.w600)),
    );
  }

  Widget _optTile(IconData icon, String title, AppColorExtension c, VoidCallback? onTap) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: c.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: c.primary, size: 20),
      ),
      title: Text(title, style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w500)),
      trailing: Icon(Icons.chevron_right_rounded, color: c.textLight),
      onTap: onTap,
    );
  }

  void _showLanguagePicker(AppColorExtension c) {
    Get.back();
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        height: 400,
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Select Language",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: c.textPrimary)),
            const SizedBox(height: 12),
            Expanded(
              child: Obx(() {
                final langs = controller.availableLanguages;
                if (langs.isEmpty) {
                  return Center(child: Text("No languages available",
                      style: TextStyle(color: c.textSecondary)));
                }
                return ListView.builder(
                  itemCount: langs.length,
                  itemBuilder: (_, i) {
                    final lang = langs[i];
                    final isSelected = controller.selectedLanguage.value == lang;
                    return ListTile(
                      title: Text(lang, style: TextStyle(color: c.textPrimary)),
                      trailing: isSelected
                          ? Icon(Icons.check_circle_rounded, color: c.primary)
                          : null,
                      onTap: () {
                        controller.setLanguage(lang);
                        Get.back();
                      },
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  void _showVoicePicker(AppColorExtension c) {
    Get.back();
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        height: 400,
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Select Voice",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: c.textPrimary)),
            const SizedBox(height: 12),
            Expanded(
              child: Obx(() {
                final voices = controller.availableVoices;
                if (voices.isEmpty) {
                  return Center(child: Text("No voices available",
                      style: TextStyle(color: c.textSecondary)));
                }
                return ListView.builder(
                  itemCount: voices.length,
                  itemBuilder: (_, i) {
                    final voice = voices[i];
                    final name = voice['name']?.toString() ?? 'Voice ${i + 1}';
                    final locale = voice['locale']?.toString() ?? '';
                    return ListTile(
                      title: Text(name, style: TextStyle(color: c.textPrimary)),
                      subtitle: Text(locale, style: TextStyle(color: c.textSecondary, fontSize: 12)),
                      onTap: () {
                        controller.setVoice(voice);
                        Get.back();
                      },
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
