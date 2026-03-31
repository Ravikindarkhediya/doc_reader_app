import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller/theme_controller.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColorExtension>()!;

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Text("Settings",
                  style: TextStyle(
                      fontSize: 26, fontWeight: FontWeight.w800, color: c.textPrimary)),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  // Theme section
                  _sectionLabel("Appearance", c),
                  _themeSelector(c),

                  const SizedBox(height: 24),

                  // About
                  _sectionLabel("About", c),
                  _tile(Icons.info_outline_rounded, "App Version", "1.0.0", c, null),
                  _tile(Icons.code_rounded, "Built with Flutter", "❤️", c, null),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label, AppColorExtension c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(label.toUpperCase(),
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: c.textLight,
              letterSpacing: 1.2)),
    );
  }

  Widget _themeSelector(AppColorExtension c) {
    final tc = Get.find<ThemeController>();

    return Obx(() => Container(
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: c.shadow, blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          _themeTile(Icons.wb_sunny_rounded, "Light Mode", AppThemeMode.light, tc, c),
          Divider(height: 1, indent: 56, color: c.highlight),
          _themeTile(Icons.nights_stay_rounded, "Dark Mode", AppThemeMode.dark, tc, c),
        ],
      ),
    ));
  }

  Widget _themeTile(IconData icon, String label, AppThemeMode mode, ThemeController tc, AppColorExtension c) {
    final isSelected = tc.themeMode.value == mode;
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? c.primary.withOpacity(0.12) : c.highlight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: isSelected ? c.primary : c.textSecondary, size: 20),
      ),
      title: Text(label, style: TextStyle(color: c.textPrimary, fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal)),
      trailing: isSelected ? Icon(Icons.check_circle_rounded, color: c.primary) : null,
      onTap: () => tc.setTheme(mode),
    );
  }

  Widget _tile(IconData icon, String title, String subtitle, AppColorExtension c, VoidCallback? onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: c.shadow, blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: ListTile(
        leading: Icon(icon, color: c.textSecondary),
        title: Text(title, style: TextStyle(color: c.textPrimary)),
        trailing: Text(subtitle, style: TextStyle(color: c.textLight)),
        onTap: onTap,
      ),
    );
  }
}
