import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

enum AppThemeMode { light, dark }

class ThemeController extends GetxController {
  var themeMode = AppThemeMode.light.obs;

  @override
  void onInit() {
    super.onInit();
    _loadTheme();
  }

  void _loadTheme() {
    final box = Hive.box('settings');
    final saved = box.get('theme', defaultValue: 'light');
    themeMode.value =
    saved == 'dark' ? AppThemeMode.dark : AppThemeMode.light;

    _applyTheme();
  }

  void setTheme(AppThemeMode mode) {
    themeMode.value = mode;
    final box = Hive.box('settings');
    box.put('theme', mode.name);
    _applyTheme();
  }

  void _applyTheme() {
    if (themeMode.value == AppThemeMode.dark) {
      Get.changeTheme(AppTheme.dark());
    } else {
      Get.changeTheme(AppTheme.light());
    }
  }

  bool get isDark => themeMode.value == AppThemeMode.dark;
  bool get isLight => themeMode.value == AppThemeMode.light;
}

// We need to add reading theme to AppTheme
class AppTheme {
  static ThemeData light() {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: const Color(0xFF4F6EF7),
      scaffoldBackgroundColor: const Color(0xFFF5F7FF),
      fontFamily: 'Nunito',
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF4F6EF7),
        secondary: Color(0xFF7C3AED),
        surface: Color(0xFFFFFFFF),
        error: Color(0xFFEF4444),
      ),
      cardColor: const Color(0xFFFFFFFF),
      extensions: [
        AppColorExtension.light(),
      ],
    );
  }

  static ThemeData dark() {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: const Color(0xFF6B8BFF),
      scaffoldBackgroundColor: const Color(0xFF0F1117),
      fontFamily: 'Nunito',
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF6B8BFF),
        secondary: Color(0xFF9D6FFF),
        surface: Color(0xFF1C1F2E),
        error: Color(0xFFFC8181),
      ),
      cardColor: const Color(0xFF1C1F2E),
      extensions: [
        AppColorExtension.dark(),
      ],
    );
  }

  static ThemeData reading() {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: const Color(0xFF8B5E3C),
      scaffoldBackgroundColor: const Color(0xFFF9F3E8),
      fontFamily: 'Nunito',
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF8B5E3C),
        secondary: Color(0xFFD4956A),
        surface: Color(0xFFF0E8D5),
        error: Color(0xFFEF4444),
      ),
      cardColor: const Color(0xFFF0E8D5),
      extensions: [
        AppColorExtension.reading(),
      ],
    );
  }
}

class AppColorExtension extends ThemeExtension<AppColorExtension> {
  final Color primary;
  final Color secondary;
  final Color background;
  final Color card;
  final Color textPrimary;
  final Color textSecondary;
  final Color textLight;
  final Color highlight;
  final Color shadow;
  final Color error;
  final Color success;

  const AppColorExtension({
    required this.primary,
    required this.secondary,
    required this.background,
    required this.card,
    required this.textPrimary,
    required this.textSecondary,
    required this.textLight,
    required this.highlight,
    required this.shadow,
    required this.error,
    required this.success,
  });

  factory AppColorExtension.light() => const AppColorExtension(
    primary: Color(0xFF4F6EF7),
    secondary: Color(0xFF7C3AED),
    background: Color(0xFFF5F7FF),
    card: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF1A1D3A),
    textSecondary: Color(0xFF6B7280),
    textLight: Color(0xFFB0B7C3),
    highlight: Color(0xFFEEF2FF),
    shadow: Color(0x1A000000),
    error: Color(0xFFEF4444),
    success: Color(0xFF10B981),
  );

  factory AppColorExtension.dark() => const AppColorExtension(
    primary: Color(0xFF6B8BFF),
    secondary: Color(0xFF9D6FFF),
    background: Color(0xFF0F1117),
    card: Color(0xFF1C1F2E),
    textPrimary: Color(0xFFF0F2FF),
    textSecondary: Color(0xFF9CA3AF),
    textLight: Color(0xFF6B7280),
    highlight: Color(0xFF252840),
    shadow: Color(0x40000000),
    error: Color(0xFFFC8181),
    success: Color(0xFF34D399),
  );

  factory AppColorExtension.reading() => const AppColorExtension(
    primary: Color(0xFF8B5E3C),
    secondary: Color(0xFFD4956A),
    background: Color(0xFFF9F3E8),
    card: Color(0xFFF0E8D5),
    textPrimary: Color(0xFF3D2B1F),
    textSecondary: Color(0xFF7D5A3C),
    textLight: Color(0xFFB09070),
    highlight: Color(0xFFFFE082),
    shadow: Color(0x1A3D2B1F),
    error: Color(0xFFEF4444),
    success: Color(0xFF10B981),
  );

  @override
  AppColorExtension copyWith({
    Color? primary, Color? secondary, Color? background, Color? card,
    Color? textPrimary, Color? textSecondary, Color? textLight,
    Color? highlight, Color? shadow, Color? error, Color? success,
  }) {
    return AppColorExtension(
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      background: background ?? this.background,
      card: card ?? this.card,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textLight: textLight ?? this.textLight,
      highlight: highlight ?? this.highlight,
      shadow: shadow ?? this.shadow,
      error: error ?? this.error,
      success: success ?? this.success,
    );
  }

  @override
  AppColorExtension lerp(AppColorExtension? other, double t) {
    if (other == null) return this;
    return AppColorExtension(
      primary: Color.lerp(primary, other.primary, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      background: Color.lerp(background, other.background, t)!,
      card: Color.lerp(card, other.card, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textLight: Color.lerp(textLight, other.textLight, t)!,
      highlight: Color.lerp(highlight, other.highlight, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      error: Color.lerp(error, other.error, t)!,
      success: Color.lerp(success, other.success, t)!,
    );
  }
}

extension AppColorContext on BuildContext {
  AppColorExtension get colors =>
      Theme.of(this).extension<AppColorExtension>()!;
}
