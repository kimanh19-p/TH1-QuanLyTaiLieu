import 'package:drift/drift.dart';

import '../../core/utils/document_type.dart';
import '../../domain/models/study_attachment.dart';
import '../../domain/models/study_document.dart' as domain;
import '../database/app_database.dart' as db;

// Điều phối truy vấn SQLite và chuyển đổi dữ liệu miền.
class StudyDocumentRepository {
  const StudyDocumentRepository(this._database);

  final db.AppDatabase _database;

  Stream<List<domain.StudyDocument>> watchDocuments({
    String keyword = '',
    DocumentType? type,
  }) {
    return _database
        .watchDocuments(keyword: keyword, type: type?.value)
        .map(
          (rows) => rows
              .map((row) => _toDomain(row.$1, row.$2))
              .toList(growable: false),
        );
  }

  Stream<List<StudyAttachment>> watchAttachments(String documentId) {
    return _database
        .watchAttachments(documentId)
        .map((rows) => rows.map(_toAttachment).toList(growable: false));
  }

  Future<StudyAttachment?> findAttachment(String id) async {
    final row = await _database.findAttachmentMetadata(id);
    return row == null ? null : _toAttachment(row);
  }

  Future<void> saveDocument({
    required domain.StudyDocument document,
    required bool isNew,
    required List<AttachmentPayload> attachments,
    required List<String> removedAttachmentIds,
  }) async {
    await _database.transaction(() async {
      if (isNew) {
        await _database.insertDocument(_toCompanion(document));
      } else {
        await _database.updateDocument(_toCompanion(document));
      }
      await _database.deleteAttachmentsForDocument(
        document.id,
        removedAttachmentIds,
      );
      for (final attachment in attachments) {
        await _database.insertAttachment(_toAttachmentCompanion(attachment));
      }
    });
  }

  Future<void> addAttachments(
    String documentId,
    List<AttachmentPayload> attachments,
  ) async {
    await _database.transaction(() async {
      for (final attachment in attachments) {
        await _database.insertAttachment(_toAttachmentCompanion(attachment));
      }
    });
  }

  Future<Uint8List?> readAttachmentBytes(String id) =>
      _database.readAttachmentBytes(id);

  Future<void> replaceAttachment(AttachmentPayload attachment) async {
    await _database.updateAttachment(_toAttachmentCompanion(attachment));
  }

  Future<void> renameAttachment(String id, String fileName) async {
    await _database.renameAttachment(id, fileName);
  }

  Future<void> deleteAttachment(String id) async {
    await _database.deleteAttachment(id);
  }

  Future<void> delete(String id) async {
    await _database.deleteDocument(id);
  }

  domain.StudyDocument _toDomain(db.StudyDocument row, int attachmentCount) {
    final type = DocumentType.fromValue(row.type);
    if (type == null) {
      throw StateError('Loại tài liệu không hợp lệ: ${row.type}');
    }
    return domain.StudyDocument(
      id: row.id,
      title: row.title,
      type: type,
      subject: row.subject,
      note: row.note,
      createdAt: row.createdAt,
      attachmentCount: attachmentCount,
    );
  }

  StudyAttachment _toAttachment(db.AttachmentMetadata row) {
    return StudyAttachment(
      id: row.id,
      documentId: row.documentId,
      fileName: row.fileName,
      extension: row.extension,
      mimeType: row.mimeType,
      sizeBytes: row.sizeBytes,
      createdAt: row.createdAt,
    );
  }

  db.StudyDocumentsCompanion _toCompanion(domain.StudyDocument document) {
    return db.StudyDocumentsCompanion(
      id: Value(document.id),
      title: Value(document.title),
      type: Value(document.type.value),
      subject: Value(document.subject),
      note: Value(document.note),
      createdAt: Value(document.createdAt),
    );
  }

  db.AttachmentsCompanion _toAttachmentCompanion(AttachmentPayload attachment) {
    return db.AttachmentsCompanion(
      id: Value(attachment.id),
      documentId: Value(attachment.documentId),
      fileName: Value(attachment.fileName),
      extension: Value(attachment.extension),
      mimeType: Value(attachment.mimeType),
      sizeBytes: Value(attachment.sizeBytes),
      bytes: Value(attachment.bytes),
      createdAt: Value(attachment.createdAt),
    );
  }
}
