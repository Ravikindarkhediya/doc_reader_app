import 'package:doc_reader/core/render_binding.dart';
import 'package:get/get.dart';
import '../view/reader_view.dart';

class AppRoutes {
  static const reader = '/reader';
}


class AppPages {
  static final routes = [
    GetPage(
      name: AppRoutes.reader,
      page: () => const ReaderView(),
      binding: ReaderBinding(),
    ),
  ];
}