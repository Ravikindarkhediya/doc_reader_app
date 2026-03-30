import 'package:hive/hive.dart';

part 'document_model.g.dart'; // MUST

@HiveType(typeId: 0)
class DocumentModel extends HiveObject {

  @HiveField(0)
  String name;

  @HiveField(1)
  String path;

  @HiveField(2)
  String extractedText;

  @HiveField(3)
  int lastPosition;

  @HiveField(4)
  bool isLiked;

  DocumentModel({
    required this.name,
    required this.path,
    this.extractedText = "",
    this.lastPosition = 0,
    this.isLiked = false,
  });
}