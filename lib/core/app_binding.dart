import 'package:get/get.dart';
import '../controller/home_controller.dart';
import '../controller/reader_controller.dart';
import '../controller/theme_controller.dart';

class AppBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<ThemeController>(ThemeController(), permanent: true);
    Get.put<ReaderController>(ReaderController(), permanent: true);
    Get.put<HomeController>(HomeController(), permanent: true);
  }
}
