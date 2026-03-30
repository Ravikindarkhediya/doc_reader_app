import 'package:get/get.dart';
import '../controller/home_controller.dart';
import '../controller/reader_controller.dart';

class AppBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HomeController>(() => HomeController());
    Get.lazyPut<ReaderController>(() => ReaderController());
  }
}