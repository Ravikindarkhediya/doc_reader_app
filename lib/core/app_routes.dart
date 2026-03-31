import 'package:get/get.dart';
import '../view/home_wrapper.dart';
import '../view/reader_view.dart';
import '../view/all_documents_screen.dart';

class AppPages {
  static final routes = [
    GetPage(name: '/', page: () => const HomeWrapper()),
    GetPage(name: '/reader', page: () => const ReaderView()),
    GetPage(name: '/all-docs', page: () => const AllDocumentsScreen()),
    GetPage(name: '/bookmarks', page: () => const BookmarksScreen()),
    GetPage(name: '/liked', page: () => const LikedScreen()),
  ];
}
