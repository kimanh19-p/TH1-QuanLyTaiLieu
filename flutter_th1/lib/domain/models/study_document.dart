import '../../core/utils/document_type.dart';

// Đại diện metadata tài liệu và số file đính kèm.
class StudyDocument {
  const StudyDocument({
    required this.id,
    required this.title,
    required this.type,
    required this.subject,
    required this.createdAt,
    this.note,
    this.attachmentCount = 0,
  });

  final String id;
  final String title;
  final DocumentType type;
  final String subject;
  final String? note;
  final DateTime createdAt;
  final int attachmentCount;
}
