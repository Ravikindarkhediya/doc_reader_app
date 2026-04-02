import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppToast {
  static void show({
    required String title,
    required String message,
    Color? bgColor,
    IconData? icon,
    Duration duration = const Duration(seconds: 3),
  }) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: bgColor ?? Colors.black87,
      colorText: Colors.white,
      margin: const EdgeInsets.all(12),
      borderRadius: 12,
      duration: duration,
      icon: icon != null ? Icon(icon, color: Colors.white) : null,
    );
  }

  // ✅ SUCCESS
  static void success(String msg) {
    show(
      title: "Success",
      message: msg,
      bgColor: Colors.green.shade600,
      icon: Icons.check_circle,
    );
  }

  // ❌ ERROR
  static void error(String msg) {
    show(
      title: "Error",
      message: msg,
      bgColor: Colors.red.shade600,
      icon: Icons.error,
    );
  }

  // ⚠️ WARNING
  static void warning(String msg) {
    show(
      title: "Warning",
      message: msg,
      bgColor: Colors.orange.shade700,
      icon: Icons.warning_rounded,
    );
  }

  // ℹ️ INFO
  static void info(String msg) {
    show(
      title: "Info",
      message: msg,
      bgColor: Colors.blue.shade600,
      icon: Icons.info,
    );
  }
}