import 'package:doc_reader/core/app_color.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/home_controller.dart';

class HomeWrapper extends GetView<HomeController> {
  const HomeWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() => Scaffold(
      body: controller.pages[controller.currentIndex.value],

      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(Icons.home, "Home", 0),
            _navItem(Icons.picture_as_pdf, "Docs", 1),
            _navItem(Icons.settings, "Settings", 2),
          ],
        ),
      ),
    ));
  }

  Widget _navItem(IconData icon, String label, int index) {
    final isSelected = controller.currentIndex.value == index;

    return GestureDetector(
      onTap: () => controller.changeTab(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.blue : Colors.grey,
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}