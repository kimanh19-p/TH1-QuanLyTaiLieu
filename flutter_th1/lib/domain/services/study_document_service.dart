import 'dart:typed_data';

import 'package:uuid/uuid.dart';

import '../../core/utils/document_type.dart';
import '../../data/repositories/study_document_repository.dart';
import '../models/study_attachment.dart';
import '../models/study_document.dart';

// Xác thực tài liệu/file và điều phối nghiệp vụ qua repository.
class StudyDocumentService {
  StudyDocumentService(this._repository, {Uuid? uuid})
    : _uuid = uuid ?? const Uuid();

  final StudyDocumentRepository _repository;
  final Uuid _uuid;
  static const maximumAttachmentBytes = 10 * 1024 * 1024;
  static const allowedExtensions = {
    'pdf',
    'doc',
    'docx',
    'ppt',
    'pptx',
    'xls',
    'xlsx',
    'txt',
    'png',
    'jpg',
    'jpeg',
    'zip',
  };

  Stream<List<StudyDocument>> watchDocuments({
    String keyword = '',
    DocumentType? type,
  }) => _repository.watchDocuments(keyword: keyword, type: type);

  Stream<List<StudyAttachment>> watchAttachments(String documentId) =>
      _repository.watchAttachments(documentId);

  Future<String> save({
    String? id,
    required String title,
    required DocumentType type,
    required String subject,
    String? note,
    DateTime? createdAt,
    List<PendingAttachment> attachments = const [],
    List<String> removedAttachmentIds = const [],
  }) async {
    final cleanTitle = title.trim();
    final cleanSubject = subject.trim();
    if (cleanTitle.isEmpty) {
      throw ArgumentError('Tiêu đề không được để trống.');
    }
    if (cleanSubject.isEmpty) {
      throw ArgumentError('Môn học không được để trống.');
    }
    if (!DocumentType.values.contains(type)) {
      throw ArgumentError('Loại tài liệu không hợp lệ.');
    }
    validatePendingAttachments(attachments);

    final cleanNote = note?.trim();
    final document = StudyDocument(
      id: id ?? _uuid.v4(),
      title: cleanTitle,
      type: type,
      subject: cleanSubject,
      note: cleanNote == null || cleanNote.isEmpty ? null : cleanNote,
      createdAt: createdAt ?? DateTime.now(),
    );
    await _repository.saveDocument(
      document: document,
      isNew: id == null,
      attachments: _toPayloads(document.id, attachments),
      removedAttachmentIds: removedAttachmentIds,
    );
    return document.id;
  }

  Future<void> delete(String id) => _repository.delete(id);

  Future<void> addAttachments(
    String documentId,
    List<PendingAttachment> attachments,
  ) async {
    if (attachments.isEmpty) return;
    validatePendingAttachments(attachments);
    await _repository.addAttachments(
      documentId,
      _toPayloads(documentId, attachments),
    );
  }

  Future<void> replaceAttachment(
    String id,
    PendingAttachment replacement,
  ) async {
    validatePendingAttachments([replacement]);
    final previous = await _repository.findAttachment(id);
    if (previous == null) throw ArgumentError('Không tìm thấy tệp đính kèm.');
    final payload = _toPayloads(previous.documentId, [replacement]).single;
    await _repository.replaceAttachment(
      AttachmentPayload(
        id: previous.id,
        documentId: previous.documentId,
        fileName: payload.fileName,
        extension: payload.extension,
        mimeType: payload.mimeType,
        sizeBytes: payload.sizeBytes,
        bytes: payload.bytes,
        createdAt: previous.createdAt,
      ),
    );
  }

  Future<void> renameAttachment(String id, String name) async {
    final previous = await _repository.findAttachment(id);
    if (previous == null) throw ArgumentError('Không tìm thấy tệp đính kèm.');
    final cleanName = name.trim();
    if (cleanName.isEmpty) throw ArgumentError('Tên file không được để trống.');
    final suffix = '.${previous.extension}';
    final fileName =
        cleanName.toLowerCase().endsWith(suffix.toLowerCase())
            ? cleanName
            : '$cleanName$suffix';
    await _repository.renameAttachment(id, fileName);
  }

  Future<void> deleteAttachment(String id) => _repository.deleteAttachment(id);

  Future<StudyAttachment?> findAttachment(String id) =>
      _repository.findAttachment(id);

  Future<Uint8List?> readAttachmentBytes(String id) =>
      _repository.readAttachmentBytes(id);

  void validatePendingAttachments(List<PendingAttachment> attachments) {
    for (final attachment in attachments) {
      final extension = attachment.extension.toLowerCase().replaceFirst(
        '.',
        '',
      );
      if (!allowedExtensions.contains(extension)) {
        throw ArgumentError('Định dạng .$extension không được hỗ trợ.');
      }
      if (attachment.sizeBytes > maximumAttachmentBytes) {
        throw ArgumentError('Mỗi file không được vượt quá 10 MB.');
      }
      if (attachment.fileName.trim().isEmpty) {
        throw ArgumentError('Tên file không được để trống.');
      }
    }
  }

  List<AttachmentPayload> _toPayloads(
    String documentId,
    List<PendingAttachment> attachments,
  ) {
    final createdAt = DateTime.now();
    return attachments
        .map((attachment) {
          final extension = attachment.extension.toLowerCase().replaceFirst(
            '.',
            '',
          );
          return AttachmentPayload(
            id: _uuid.v4(),
            documentId: documentId,
            fileName: attachment.fileName.trim(),
            extension: extension,
            mimeType: attachment.mimeType,
            sizeBytes: attachment.sizeBytes,
            bytes: attachment.bytes,
            createdAt: createdAt,
          );
        })
        .toList(growable: false);
  }
}
