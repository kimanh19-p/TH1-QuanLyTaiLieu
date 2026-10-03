import 'dart:typed_data';

// Thông tin file hiển thị mà không nạp nội dung Blob.
class StudyAttachment {
  const StudyAttachment({
    required this.id,
    required this.documentId,
    required this.fileName,
    required this.extension,
    required this.sizeBytes,
    required this.createdAt,
    this.mimeType,
  });

  final String id;
  final String documentId;
  final String fileName;
  final String extension;
  final String? mimeType;
  final int sizeBytes;
  final DateTime createdAt;
}

// Payload file đã chọn, dùng trong transaction lưu tài liệu.
class PendingAttachment {
  const PendingAttachment({
    required this.fileName,
    required this.extension,
    required this.bytes,
    this.mimeType,
  });

  final String fileName;
  final String extension;
  final String? mimeType;
  final Uint8List bytes;

  int get sizeBytes => bytes.lengthInBytes;
}

// Payload nhị phân hoàn chỉnh được repository ghi vào SQLite.
class AttachmentPayload extends StudyAttachment {
  const AttachmentPayload({
    required super.id,
    required super.documentId,
    required super.fileName,
    required super.extension,
    required super.sizeBytes,
    required super.createdAt,
    required this.bytes,
    super.mimeType,
  });

  final Uint8List bytes;
}
