import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/home_controller.dart';
import '../controller/theme_controller.dart';
import 'home_view.dart';
import 'settings_view.dart';

class HomeWrapper extends GetView<HomeController> {
  const HomeWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColorExtension>()!;

    final pages = [
      const HomeView(),
      const SettingsView(),
    ];

    return Obx(() => Scaffold(
      body: pages[controller.currentTabIndex.value],
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: c.shadow,
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(Icons.home_rounded, Icons.home_outlined, "Home", 0, c),
            _navItem(Icons.settings_rounded, Icons.settings_outlined, "Settings", 1, c),
          ],
        ),
      ),
    ));
  }

  Widget _navItem(
    IconData activeIcon,
    IconData inactiveIcon,
    String label,
    int index,
    AppColorExtension c,
  ) {
    return Obx(() {
      final isSelected = controller.currentTabIndex.value == index;
      return GestureDetector(
        onTap: () => controller.currentTabIndex.value = index,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? c.primary.withOpacity(0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? activeIcon : inactiveIcon,
                color: isSelected ? c.primary : c.textSecondary,
                size: 22,
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                child: isSelected
                    ? Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Text(
                          label,
                          style: TextStyle(
                            color: c.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
    });
  }
}
