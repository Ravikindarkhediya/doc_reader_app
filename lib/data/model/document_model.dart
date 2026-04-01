import 'package:hive/hive.dart';

part 'document_model.g.dart';

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

  @HiveField(5)
  DateTime? addedAt;

  @HiveField(7)
  String? mimeType; // pdf, txt, docx

  @HiveField(8)
  int wordCount;

  @HiveField(9)
  String? title;

  @HiveField(10)
  String? subtitle;

  DocumentModel({
    required this.name,
    required this.path,
    this.extractedText = "",
    this.lastPosition = 0,
    this.isLiked = false,
    this.addedAt,
    this.mimeType,
    this.wordCount = 0,
    this.title,
    this.subtitle
  });

  String get extension => name.split('.').last.toLowerCase();

  String get readTimeEstimate {
    if (wordCount == 0) return '—';
    final mins = (wordCount / 200).ceil();
    return '$mins min read';
  }

}
