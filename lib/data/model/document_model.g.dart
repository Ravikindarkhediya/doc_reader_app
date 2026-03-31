// GENERATED CODE - DO NOT MODIFY BY HAND
// Run: flutter pub run build_runner build --delete-conflicting-outputs
// If you added new HiveFields, delete this file and re-run build_runner.

part of 'document_model.dart';

class DocumentModelAdapter extends TypeAdapter<DocumentModel> {
  @override
  final int typeId = 0;

  @override
  DocumentModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DocumentModel(
      name: fields[0] as String,
      path: fields[1] as String,
      extractedText: fields[2] as String? ?? '',
      lastPosition: fields[3] as int? ?? 0,
      isLiked: fields[4] as bool? ?? false,
      addedAt: fields[5] as DateTime?,
      bookmarks: (fields[6] as List?)?.cast<int>(),
      mimeType: fields[7] as String?,
      wordCount: fields[8] as int? ?? 0,
    );
  }

  @override
  void write(BinaryWriter writer, DocumentModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.path)
      ..writeByte(2)
      ..write(obj.extractedText)
      ..writeByte(3)
      ..write(obj.lastPosition)
      ..writeByte(4)
      ..write(obj.isLiked)
      ..writeByte(5)
      ..write(obj.addedAt)
      ..writeByte(6)
      ..write(obj.bookmarks)
      ..writeByte(7)
      ..write(obj.mimeType)
      ..writeByte(8)
      ..write(obj.wordCount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DocumentModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
