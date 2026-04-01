import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/reader_controller.dart';
import '../controller/theme_controller.dart';

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
          // ── Top progress bar ──────────────────────────────────────────────
          Obx(() => LinearProgressIndicator(
            value: controller.progressPercent,
            backgroundColor: c.highlight,
            valueColor: AlwaysStoppedAnimation(c.primary),
            minHeight: 3,
          )),

          // ── Word reader body ──────────────────────────────────────────────
          Expanded(child: _buildWordView(c)),

          // ── Mini player ───────────────────────────────────────────────────
          _buildMiniPlayer(c),
        ],
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────
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
      title: Obx(() {
        final doc = controller.currentDoc.value;
        final title = doc?.title?.isNotEmpty == true ? doc!.title! : doc?.name ?? "Reader";
        final subtitle = doc?.subtitle?.isNotEmpty == true ? doc!.subtitle : null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: c.textPrimary,
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: c.textSecondary),
              ),
            Text(
              controller.wordProgress,
              style: TextStyle(fontSize: 10, color: c.textSecondary),
            ),
          ],
        );
      }),
      actions: [
        IconButton(
          icon: Icon(Icons.tune_rounded, color: c.textSecondary),
          onPressed: () => _showOptionsSheet(c),
        ),
      ],
    );
  }

  // ── Word View ─────────────────────────────────────────────────────────────
  Widget _buildWordView(AppColorExtension c) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.hasError.value) {
        return Center(
          child: Text(
            controller.errorMessage.value,
            style: TextStyle(color: c.textSecondary),
          ),
        );
      }

      if (controller.words.isEmpty) {
        return Center(
          child: Text("No content", style: TextStyle(color: c.textSecondary)),
        );
      }

      // We render paragraph by paragraph.
      // Each paragraph is a card container. Words inside are Wrap'd with
      // per-word highlighting via GlobalKeys.
      return SingleChildScrollView(
        controller: controller.scrollController,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _buildParagraphCards(c),
        ),
      );
    });
  }

  List<Widget> _buildParagraphCards(AppColorExtension c) {
    final paragraphs = controller.paragraphs;
    final widgets = <Widget>[];
    int wordOffset = 0; // global word index offset for current paragraph

    for (int pIdx = 0; pIdx < paragraphs.length; pIdx++) {
      final paraWords = paragraphs[pIdx]
          .split(RegExp(r'\s+'))
          .where((w) => w.isNotEmpty)
          .toList();

      final int paraStartIndex = wordOffset;
      final int capturedWordOffset = wordOffset;

      widgets.add(
        Obx(() {
          final activeWordIdx = controller.currentWordIndex.value;
          final activeParagraph = controller.currentParagraphIndex.value;
          final isParagraphActive = activeParagraph == pIdx;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isParagraphActive
                  ? c.primary.withOpacity(0.06)
                  : c.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isParagraphActive
                    ? c.primary.withOpacity(0.25)
                    : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Wrap(
              spacing: 4,
              runSpacing: 6,
              children: List.generate(paraWords.length, (wIdx) {
                final globalIdx = capturedWordOffset + wIdx;
                final isActive = globalIdx == activeWordIdx;

                // Bounds check — keys list is built during setDocument
                final hasKey = globalIdx < controller.wordKeys.length;

                return GestureDetector(
                  onTap: () => controller.jumpToWord(globalIdx),
                  child: Container(
                    key: hasKey ? controller.wordKeys[globalIdx] : null,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 3, vertical: 2),
                    decoration: isActive
                        ? BoxDecoration(
                      color: c.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    )
                        : null,
                    child: Text(
                      paraWords[wIdx],
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.65,
                        color: isActive ? c.primary : c.textPrimary,
                        fontWeight: isActive
                            ? FontWeight.w700
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                );
              }),
            ),
          );
        }),
      );

      wordOffset += paraWords.length;
    }

    return widgets;
  }

  // ── Mini Player ───────────────────────────────────────────────────────────
  Widget _buildMiniPlayer(AppColorExtension c) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 22),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius:
        const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: c.shadow,
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Seek slider (word position) ─────────────────────────────────
          Obx(() {
            final total = controller.words.length.toDouble();
            final current = controller.currentWordIndex.value
                .toDouble()
                .clamp(0.0, total > 0 ? total : 1.0);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.text_fields_rounded,
                        size: 14, color: c.textSecondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(Get.context!).copyWith(
                          trackHeight: 3,
                          thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 7),
                          overlayShape:
                          const RoundSliderOverlayShape(overlayRadius: 14),
                          activeTrackColor: c.primary,
                          inactiveTrackColor: c.highlight,
                          thumbColor: c.primary,
                          overlayColor: c.primary.withOpacity(0.15),
                        ),
                        child: Slider(
                          value: current,
                          min: 0,
                          max: total > 0 ? total : 1,
                          onChangeStart: (_) {
                            // pause while dragging for smooth UX
                            if (controller.isPlaying.value) {
                              controller.tts.stop();
                            }
                          },
                          onChanged: (v) {
                            controller.currentWordIndex.value = v.toInt();
                            controller.updateParagraphIndex(v.toInt());
                            controller.scrollToWord(v.toInt());
                          },
                          onChangeEnd: (v) =>
                              controller.jumpToWord(v.toInt()),
                        ),
                      ),
                    ),
                    Text(
                      "${controller.currentWordIndex.value}/${controller.words.length}",
                      style: TextStyle(
                          fontSize: 11, color: c.textSecondary),
                    ),
                  ],
                ),
              ],
            );
          }),

          const SizedBox(height: 4),

          // ── Speed slider ────────────────────────────────────────────────
          Obx(() => Row(
            children: [
              Icon(Icons.speed_rounded,
                  size: 14, color: c.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(Get.context!).copyWith(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 7),
                    overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 14),
                    activeTrackColor: c.secondary,
                    inactiveTrackColor: c.highlight,
                    thumbColor: c.secondary,
                    overlayColor: c.secondary.withOpacity(0.15),
                  ),
                  child: Slider(
                    value: controller.speed.value,
                    min: 0.1,
                    max: 1.5,
                    divisions: 14,
                    onChanged: controller.setSpeed,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: c.secondary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "${controller.speed.value.toStringAsFixed(1)}x",
                  style: TextStyle(
                      fontSize: 11,
                      color: c.secondary,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ],
          )),

          const SizedBox(height: 10),

          // ── Transport controls ─────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _controlBtn(Icons.replay_10_rounded, c, controller.rewind),
              const SizedBox(width: 8),
              Obx(() => GestureDetector(
                onTap: controller.isPlaying.value
                    ? controller.pause
                    : controller.play,
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
        decoration:
        BoxDecoration(color: c.highlight, shape: BoxShape.circle),
        child: Icon(icon, color: c.textPrimary, size: 24),
      ),
    );
  }

  // ── Options sheet ─────────────────────────────────────────────────────────
  void _showOptionsSheet(AppColorExtension c) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius:
          const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Options",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: c.textPrimary),
            ),
            const SizedBox(height: 16),
            _optTile(Icons.language_rounded, "Language", c,
                    () => _showLanguagePicker(c)),
            _optTile(Icons.record_voice_over_rounded, "Voice", c,
                    () => _showVoicePicker(c)),
            Obx(() => _optTile(
              Icons.audiotrack_rounded,
              controller.isSavingMp3.value ? "Saving..." : "Save as MP3",
              c,
              controller.isSavingMp3.value
                  ? null
                  : () {
                Get.back();
                controller.saveAsMp3();
              },
            )),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _optTile(
      IconData icon,
      String title,
      AppColorExtension c,
      VoidCallback? onTap,
      ) {
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
      title: Text(title,
          style: TextStyle(
              color: c.textPrimary, fontWeight: FontWeight.w500)),
      trailing:
      Icon(Icons.chevron_right_rounded, color: c.textLight),
      onTap: onTap,
    );
  }

  void _showLanguagePicker(AppColorExtension c) {
    Get.back();
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        height: 420,
        decoration: BoxDecoration(
          color: c.card,
          borderRadius:
          const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Select Language",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: c.textPrimary),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Obx(() {
                final langs = controller.availableLanguages;
                if (langs.isEmpty) {
                  return Center(
                    child: Text("No languages available",
                        style: TextStyle(color: c.textSecondary)),
                  );
                }
                return ListView.builder(
                  itemCount: langs.length,
                  itemBuilder: (_, i) {
                    final lang = langs[i];
                    final isSelected =
                        controller.selectedLanguage.value == lang;
                    return ListTile(
                      title: Text(lang,
                          style: TextStyle(color: c.textPrimary)),
                      trailing: isSelected
                          ? Icon(Icons.check_circle_rounded,
                          color: c.primary)
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
        height: 420,
        decoration: BoxDecoration(
          color: c.card,
          borderRadius:
          const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Select Voice",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: c.textPrimary),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Obx(() {
                final voices = controller.availableVoices;
                if (voices.isEmpty) {
                  return Center(
                    child: Text("No voices available",
                        style: TextStyle(color: c.textSecondary)),
                  );
                }
                return ListView.builder(
                  itemCount: voices.length,
                  itemBuilder: (_, i) {
                    final voice = voices[i];
                    final name =
                        voice['name']?.toString() ?? 'Voice ${i + 1}';
                    final locale =
                        voice['locale']?.toString() ?? '';
                    return ListTile(
                      title: Text(name,
                          style: TextStyle(color: c.textPrimary)),
                      subtitle: Text(locale,
                          style: TextStyle(
                              color: c.textSecondary, fontSize: 12)),
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
