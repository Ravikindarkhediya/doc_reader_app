import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/reader_controller.dart';
import '../controller/theme_controller.dart';
import '../core/utils/tts_utils.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColorExtension>()!;
    final rc = Get.find<ReaderController>();

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Text(
                "Settings",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: c.textPrimary,
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  // ── Appearance ────────────────────────────────────────────
                  _sectionLabel("Appearance", c),
                  _themeSelector(c),

                  const SizedBox(height: 24),

                  // ── Speech ────────────────────────────────────────────────
                  _sectionLabel("Speech", c),
                  _speechSpeedCard(rc, c),
                  const SizedBox(height: 8),
                  _voiceCard(rc, c, context),
                  const SizedBox(height: 8),
                  _languageCard(rc, c, context),

                  const SizedBox(height: 24),

                  // ── About ─────────────────────────────────────────────────
                  _sectionLabel("About", c),
                  _infoTile(Icons.info_outline_rounded, "App Version", "1.0.0", c),
                  _infoTile(Icons.auto_stories_rounded, "Built with Flutter", "❤️", c),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Appearance ─────────────────────────────────────────────────────────────

  Widget _sectionLabel(String label, AppColorExtension c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: c.textLight,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _themeSelector(AppColorExtension c) {
    final tc = Get.find<ThemeController>();
    return Obx(() => _card(
      c,
      child: Column(
        children: [
          _themeTile(
              Icons.wb_sunny_rounded, "Light Mode", AppThemeMode.light, tc, c),
          Divider(height: 1, indent: 56, color: c.highlight),
          _themeTile(
              Icons.nights_stay_rounded, "Dark Mode", AppThemeMode.dark, tc, c),
        ],
      ),
    ));
  }

  Widget _themeTile(
      IconData icon,
      String label,
      AppThemeMode mode,
      ThemeController tc,
      AppColorExtension c,
      ) {
    final isSelected = tc.themeMode.value == mode;
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? c.primary.withOpacity(0.12) : c.highlight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon,
            color: isSelected ? c.primary : c.textSecondary, size: 20),
      ),
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
      onTap: () => tc.setTheme(mode),
    );
  }

  // ── Speech ─────────────────────────────────────────────────────────────────

  Widget _speechSpeedCard(ReaderController rc, AppColorExtension c) {
    return _card(
      c,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.speed_rounded, color: c.textSecondary, size: 18),
                const SizedBox(width: 10),
                Text("Speech Speed",
                    style: TextStyle(
                        color: c.textPrimary, fontWeight: FontWeight.w600)),
                const Spacer(),
                Obx(() => Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: c.secondary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "${rc.speed.value.toStringAsFixed(1)}x",
                    style: TextStyle(
                      fontSize: 12,
                      color: c.secondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )),
              ],
            ),
            const SizedBox(height: 8),
            Obx(() => SliderTheme(
              data: SliderThemeData(
                trackHeight: 3,
                thumbShape:
                const RoundSliderThumbShape(enabledThumbRadius: 7),
                overlayShape:
                const RoundSliderOverlayShape(overlayRadius: 14),
                activeTrackColor: c.secondary,
                inactiveTrackColor: c.highlight,
                thumbColor: c.secondary,
                overlayColor: c.secondary.withOpacity(0.15),
              ),
              child: Slider(
                value: rc.speed.value,
                min: 0.1,
                max: 1.5,
                divisions: 14,
                onChanged: rc.setSpeed,
              ),
            )),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Slow", style: TextStyle(fontSize: 11, color: c.textLight)),
                  Text("Fast", style: TextStyle(fontSize: 11, color: c.textLight)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _voiceCard(
      ReaderController rc, AppColorExtension c, BuildContext context) {
    return _tappableSettingTile(
      icon: Icons.record_voice_over_rounded,
      title: "Voice",
      c: c,
      valueBuilder: () => Obx(() {
        final v = rc.selectedVoice.value;
        return Text(
          v != null ? TtsUtils.formatVoiceName(v) : "Default",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12, color: c.textSecondary),
        );
      }),
      onTap: () => _showVoicePicker(rc, c),
    );
  }

  Widget _languageCard(
      ReaderController rc, AppColorExtension c, BuildContext context) {
    return _tappableSettingTile(
      icon: Icons.language_rounded,
      title: "Language",
      c: c,
      valueBuilder: () => Obx(() => Text(
        TtsUtils.formatLanguageName(rc.selectedLanguage.value),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 12, color: c.textSecondary),
      )),
      onTap: () => _showLanguagePicker(rc, c),
    );
  }

  Widget _tappableSettingTile({
    required IconData icon,
    required String title,
    required AppColorExtension c,
    required Widget Function() valueBuilder,
    required VoidCallback onTap,
  }) {
    return _card(
      c,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: c.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: c.primary, size: 20),
        ),
        title: Text(title,
            style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w500)),
        subtitle: valueBuilder(),
        trailing: Icon(Icons.chevron_right_rounded, color: c.textLight),
        onTap: onTap,
      ),
    );
  }

  // ── About ──────────────────────────────────────────────────────────────────

  Widget _infoTile(
      IconData icon, String title, String value, AppColorExtension c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: _card(
        c,
        child: ListTile(
          leading: Icon(icon, color: c.textSecondary),
          title: Text(title, style: TextStyle(color: c.textPrimary)),
          trailing:
          Text(value, style: TextStyle(color: c.textLight, fontSize: 13)),
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _card(AppColorExtension c, {required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: c.shadow, blurRadius: 8, offset: const Offset(0, 2))
        ],
      ),
      child: child,
    );
  }

  void _showLanguagePicker(ReaderController rc, AppColorExtension c) {
    Get.bottomSheet(
      _PickerSheet(
        title: "Select Language",
        c: c,
        items: rc.availableLanguages,
        labelOf: (code) => TtsUtils.formatLanguageName(code),
        sublabelOf: (code) => code,
        isSelected: (code) => rc.selectedLanguage.value == code,
        onSelect: (code) {
          rc.setLanguage(code);
          Get.back();
        },
      ),
    );
  }

  void _showVoicePicker(ReaderController rc, AppColorExtension c) {
    Get.bottomSheet(
      _PickerSheet(
        title: "Select Voice",
        c: c,
        items: rc.availableVoices,
        labelOf: (v) => TtsUtils.formatVoiceName(v as Map),
        sublabelOf: (v) => (v as Map)['locale']?.toString() ?? '',
        isSelected: (v) =>
        rc.selectedVoice.value?['name'] == (v as Map)['name'],
        onSelect: (v) {
          rc.setVoice(v as Map);
          Get.back();
        },
      ),
    );
  }
}

/// Generic picker sheet (language OR voice)
class _PickerSheet extends StatefulWidget {
  final String title;
  final AppColorExtension c;
  final List items;
  final String Function(dynamic item) labelOf;
  final String Function(dynamic item) sublabelOf;
  final bool Function(dynamic item) isSelected;
  final void Function(dynamic item) onSelect;

  const _PickerSheet({
    required this.title,
    required this.c,
    required this.items,
    required this.labelOf,
    required this.sublabelOf,
    required this.isSelected,
    required this.onSelect,
  });

  @override
  State<_PickerSheet> createState() => _PickerSheetState();
}

class _PickerSheetState extends State<_PickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    final filtered = _query.isEmpty
        ? widget.items
        : widget.items.where((item) {
      final label = widget.labelOf(item).toLowerCase();
      return label.contains(_query.toLowerCase());
    }).toList();

    return Container(
      height: 520,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.title,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: c.textPrimary)),
          const SizedBox(height: 12),
          // Search field
          TextField(
            onChanged: (v) => setState(() => _query = v),
            style: TextStyle(color: c.textPrimary),
            decoration: InputDecoration(
              hintText: "Search…",
              hintStyle: TextStyle(color: c.textLight),
              prefixIcon:
              Icon(Icons.search_rounded, color: c.textSecondary, size: 18),
              filled: true,
              fillColor: c.highlight,
              border: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                child: Text("No results",
                    style: TextStyle(color: c.textSecondary)))
                : ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                final item = filtered[i];
                final isSelected = widget.isSelected(item);
                return ListTile(
                  title: Text(widget.labelOf(item),
                      style: TextStyle(
                        color: c.textPrimary,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.normal,
                      )),
                  subtitle: Text(widget.sublabelOf(item),
                      style: TextStyle(
                          color: c.textSecondary, fontSize: 11)),
                  trailing: isSelected
                      ? Icon(Icons.check_circle_rounded,
                      color: c.primary)
                      : null,
                  onTap: () => widget.onSelect(item),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}