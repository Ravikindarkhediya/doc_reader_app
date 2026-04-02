import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller/reader_controller.dart';
import '../controller/theme_controller.dart';
import '../core/utils/tts_utils.dart';

class ReaderView extends GetView<ReaderController> {
  const ReaderView({super.key});

  @override
  Widget build(BuildContext context) {
    // GetBuilder ensures ReaderView rebuilds on theme changes
    return GetBuilder<ThemeController>(
      builder: (_) {
        final c = Theme.of(context).extension<AppColorExtension>()!;
        return Scaffold(
          backgroundColor: c.background,
          appBar: _buildAppBar(context, c),
          body: Column(
            children: [
              // Top progress bar
              Obx(() => LinearProgressIndicator(
                value: controller.progressPercent,
                backgroundColor: c.highlight,
                valueColor: AlwaysStoppedAnimation(c.primary),
                minHeight: 3,
              )),
              Expanded(child: _buildWordView(c)),
              _buildMiniPlayer(context, c),
            ],
          ),
        );
      },
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(BuildContext context, AppColorExtension c) {
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
        final title =
            (doc?.title?.isNotEmpty == true ? doc!.title! : doc?.name) ?? "Reader";
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
                  color: c.textPrimary),
            ),
            Obx(() => Text(
              controller.wordProgress,
              style: TextStyle(fontSize: 10, color: c.textSecondary),
            )),
          ],
        );
      }),
      actions: [
        IconButton(
          icon: Icon(Icons.tune_rounded, color: c.textSecondary),
          onPressed: () => _showOptionsSheet(context, c),
        ),
      ],
    );
  }

  // ── Word View ─────────────────────────────────────────────────────────────

  Widget _buildWordView(AppColorExtension c) {
    return Obx(() {
      if (controller.isLoading.value) {
        return Center(
            child: CircularProgressIndicator(color: c.primary));
      }
      if (controller.hasError.value) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(controller.errorMessage.value,
                textAlign: TextAlign.center,
                style: TextStyle(color: c.textSecondary)),
          ),
        );
      }
      if (controller.words.isEmpty) {
        return Center(
            child: Text("No content", style: TextStyle(color: c.textSecondary)));
      }
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
    int wordOffset = 0;

    for (int pIdx = 0; pIdx < paragraphs.length; pIdx++) {
      final paraWords = paragraphs[pIdx]
          .split(RegExp(r'\s+'))
          .where((w) => w.isNotEmpty)
          .toList();

      final capturedOffset = wordOffset;
      wordOffset += paraWords.length;

      widgets.add(
        Obx(() {
          final activeWord = controller.currentWordIndex.value;
          final activePara = controller.currentParagraphIndex.value;
          final isParagraphActive = activePara == pIdx;

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
                final globalIdx = capturedOffset + wIdx;
                final isActive = globalIdx == activeWord;
                final hasKey = globalIdx < controller.wordKeys.length;

                return GestureDetector(
                  onTap: () => controller.jumpToWord(globalIdx),
                  child: Container(
                    key: hasKey ? controller.wordKeys[globalIdx] : null,
                    padding:
                    const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
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
                        height: 1.7,
                        color: isActive ? c.primary : c.textPrimary,
                        fontWeight:
                        isActive ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                  ),
                );
              }),
            ),
          );
        }),
      );
    }
    return widgets;
  }

  // ── Mini Player ───────────────────────────────────────────────────────────

  Widget _buildMiniPlayer(BuildContext context, AppColorExtension c) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
              color: c.shadow,
              blurRadius: 20,
              offset: const Offset(0, -4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Word progress slider ──────────────────────────────────────────
          Obx(() {
            final total = controller.words.length.toDouble();
            final current = controller.currentWordIndex.value
                .toDouble()
                .clamp(0.0, total > 0 ? total : 1.0);
            return _sliderRow(
              icon: Icons.text_fields_rounded,
              label:
              "${controller.currentWordIndex.value}/${controller.words.length}",
              labelColor: c.textSecondary,
              c: c,
              child: Slider(
                value: current,
                min: 0,
                max: total > 0 ? total : 1,
                onChangeStart: (_) {
                  if (controller.isPlaying.value) controller.tts.stop();
                },
                onChanged: (v) {
                  controller.currentWordIndex.value = v.toInt();
                },
                onChangeEnd: (v) => controller.jumpToWord(v.toInt()),
              ),
              trackColor: c.primary,
            );
          }),

          const SizedBox(height: 2),

          // ── Speed slider ──────────────────────────────────────────────────
          Obx(() => _sliderRow(
            icon: Icons.speed_rounded,
            label: "${controller.speed.value.toStringAsFixed(1)}x",
            labelColor: c.secondary,
            c: c,
            child: Slider(
              value: controller.speed.value,
              min: 0.1,
              max: 1.5,
              divisions: 14,
              onChanged: controller.setSpeed,
            ),
            trackColor: c.secondary,
          )),

          const SizedBox(height: 10),

          // ── Transport controls ────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ◀◀ Previous paragraph
              _smallBtn(
                  Icons.skip_previous_rounded, c, controller.prevParagraph,
                  tooltip: 'Prev paragraph'),
              const SizedBox(width: 8),
              // ⏪ -10 words
              _smallBtn(Icons.replay_10_rounded, c, controller.rewind,
                  tooltip: '-10 words'),
              const SizedBox(width: 12),
              // ▶ / ⏸ Play / Pause
              Obx(() => GestureDetector(
                onTap: controller.togglePlay,
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
              const SizedBox(width: 12),
              // ⏩ +10 words
              _smallBtn(Icons.forward_10_rounded, c, controller.forward,
                  tooltip: '+10 words'),
              const SizedBox(width: 8),
              // ▶▶ Next paragraph
              _smallBtn(
                  Icons.skip_next_rounded, c, controller.nextParagraph,
                  tooltip: 'Next paragraph'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sliderRow({
    required IconData icon,
    required String label,
    required Color labelColor,
    required AppColorExtension c,
    required Widget child,
    required Color trackColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14, color: c.textSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 3,
              thumbShape:
              const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape:
              const RoundSliderOverlayShape(overlayRadius: 14),
              activeTrackColor: trackColor,
              inactiveTrackColor: c.highlight,
              thumbColor: trackColor,
              overlayColor: trackColor.withOpacity(0.15),
            ),
            child: child,
          ),
        ),
        Container(
          padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: labelColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
                fontSize: 11,
                color: labelColor,
                fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  Widget _smallBtn(
      IconData icon,
      AppColorExtension c,
      VoidCallback onTap, {
        String? tooltip,
      }) {
    final btn = GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration:
        BoxDecoration(color: c.highlight, shape: BoxShape.circle),
        child: Icon(icon, color: c.textPrimary, size: 22),
      ),
    );
    if (tooltip != null) {
      return Tooltip(message: tooltip, child: btn);
    }
    return btn;
  }

  // ── Options sheet ─────────────────────────────────────────────────────────

  void _showOptionsSheet(BuildContext context, AppColorExtension c) {
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
            Text("Options",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: c.textPrimary)),
            const SizedBox(height: 16),
            _optTile(Icons.language_rounded, "Language", c,
                    () => _showLanguagePicker(c)),
            _optTile(Icons.record_voice_over_rounded, "Voice", c,
                    () => _showVoicePicker(c)),
            Obx(() => _optTile(
              Icons.audiotrack_rounded,
              controller.isSavingMp3.value ? "Saving…" : "Save as MP3",
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
      trailing: Icon(Icons.chevron_right_rounded, color: c.textLight),
      onTap: onTap,
    );
  }

  void _showLanguagePicker(AppColorExtension c) {
    Get.back();
    Get.bottomSheet(
      _TtsPicker(
        title: "Select Language",
        c: c,
        itemCount: controller.availableLanguages.length,
        itemBuilder: (i) {
          final code = controller.availableLanguages[i];
          final isSelected = controller.selectedLanguage.value == code;
          return ListTile(
            title: Text(TtsUtils.formatLanguageName(code),
                style: TextStyle(color: c.textPrimary)),
            subtitle: Text(code,
                style: TextStyle(color: c.textSecondary, fontSize: 11)),
            trailing: isSelected
                ? Icon(Icons.check_circle_rounded, color: c.primary)
                : null,
            onTap: () {
              controller.setLanguage(code);
              Get.back();
            },
          );
        },
        emptyMessage: "No languages available",
      ),
    );
  }

  void _showVoicePicker(AppColorExtension c) {
    Get.back();
    Get.bottomSheet(
      _TtsPicker(
        title: "Select Voice",
        c: c,
        itemCount: controller.availableVoices.length,
        itemBuilder: (i) {
          final voice = controller.availableVoices[i];
          final name = TtsUtils.formatVoiceName(voice);
          final locale = voice['locale']?.toString() ?? '';
          final isSelected =
              controller.selectedVoice.value?['name'] == voice['name'];
          return ListTile(
            title: Text(name, style: TextStyle(color: c.textPrimary)),
            subtitle: Text(locale,
                style: TextStyle(color: c.textSecondary, fontSize: 11)),
            trailing: isSelected
                ? Icon(Icons.check_circle_rounded, color: c.primary)
                : null,
            onTap: () {
              controller.setVoice(voice);
              Get.back();
            },
          );
        },
        emptyMessage: "No voices available",
      ),
    );
  }
}

/// Reusable scrollable bottom-sheet list for TTS pickers
class _TtsPicker extends StatelessWidget {
  final String title;
  final AppColorExtension c;
  final int itemCount;
  final Widget Function(int i) itemBuilder;
  final String emptyMessage;

  const _TtsPicker({
    required this.title,
    required this.c,
    required this.itemCount,
    required this.itemBuilder,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      height: 440,
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: c.textPrimary)),
          const SizedBox(height: 12),
          Expanded(
            child: itemCount == 0
                ? Center(
                child: Text(emptyMessage,
                    style: TextStyle(color: c.textSecondary)))
                : ListView.builder(
              itemCount: itemCount,
              itemBuilder: (_, i) => itemBuilder(i),
            ),
          ),
        ],
      ),
    );
  }
}