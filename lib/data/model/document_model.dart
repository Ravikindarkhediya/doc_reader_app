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

  @HiveField(6)
  List<int> bookmarks; // chunk indices that are bookmarked

  @HiveField(7)
  String? mimeType; // pdf, txt, docx

  @HiveField(8)
  int wordCount;

  DocumentModel({
    required this.name,
    required this.path,
    this.extractedText = "",
    this.lastPosition = 0,
    this.isLiked = false,
    this.addedAt,
    List<int>? bookmarks,
    this.mimeType,
    this.wordCount = 0,
  }) : bookmarks = bookmarks ?? [];

  String get extension => name.split('.').last.toLowerCase();

  String get readTimeEstimate {
    if (wordCount == 0) return '—';
    final mins = (wordCount / 200).ceil();
    return '$mins min read';
  }

  bool get isBookmarked => bookmarks.isNotEmpty;

  void addBookmark(int chunkIndex) {
    if (!bookmarks.contains(chunkIndex)) {
      bookmarks.add(chunkIndex);
      save();
    }
  }

  void removeBookmark(int chunkIndex) {
    bookmarks.remove(chunkIndex);
    save();
  }

  bool hasBookmark(int chunkIndex) => bookmarks.contains(chunkIndex);
}
