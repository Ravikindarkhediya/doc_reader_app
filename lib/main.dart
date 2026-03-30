import 'package:doc_reader/core/app_binding.dart';
import 'package:doc_reader/view/home_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/adapters.dart';

import 'core/app_routes.dart';
import 'data/model/document_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(DocumentModelAdapter());
  await Hive.openBox<DocumentModel>('docs');

  runApp(const MyApp());

}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      initialBinding: AppBinding(),
      getPages: AppPages.routes,
      home: HomeWrapper(),
    );
  }
}
