import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'controller/theme_controller.dart';
import 'core/app_binding.dart';
import 'data/model/document_model.dart';
import 'view/home_wrapper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(DocumentModelAdapter());
  await Hive.openBox<DocumentModel>('docs');
  await Hive.openBox('settings'); // For theme preference
  Get.put(ThemeController(), permanent: true);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final tc = Get.find<ThemeController>();
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      initialBinding: AppBinding(),
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: tc.isDark ? ThemeMode.dark : ThemeMode.light,
      home: const HomeWrapper(),
    );
  }
}
