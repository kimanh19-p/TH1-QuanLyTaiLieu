import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_docs/core/utils/document_type.dart';
import 'package:study_docs/data/database/app_database.dart';
import 'package:study_docs/data/repositories/study_document_repository.dart';
import 'package:study_docs/domain/models/study_attachment.dart';
import 'package:study_docs/domain/services/study_document_service.dart';

void main() {
  test(
    'version 1 migration keeps documents and creates attachment storage',
    () async {
      final database = AppDatabase(
        NativeDatabase.memory(
          setup: (connection) {
            connection.execute('''
            CREATE TABLE study_documents (
              id TEXT NOT NULL PRIMARY KEY,
              title TEXT NOT NULL,
              type TEXT NOT NULL,
              subject TEXT NOT NULL,
              note TEXT,
              created_at INTEGER NOT NULL
            )
          ''');
            connection.execute('''
            INSERT INTO study_documents
              (id, title, type, subject, note, created_at)
            VALUES ('legacy-id', 'Bài cũ', 'lecture', 'Toán', NULL, 1700000000000)
          ''');
            connection.execute('PRAGMA user_version = 1');
          },
        ),
      );
      addTearDown(database.close);

      final documents = await database.select(database.studyDocuments).get();
      expect(documents, hasLength(1));
      expect(documents.single.id, 'legacy-id');
      expect(await database.countAttachments('legacy-id'), 0);
      final foreignKeys =
          await database.customSelect('PRAGMA foreign_keys').getSingle();
      expect(foreignKeys.data['foreign_keys'], 1);
    },
  );

  test(
    'stores attachments, reads bytes on demand, and cascades deletion',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final service = StudyDocumentService(StudyDocumentRepository(database));
      final documentId = await service.save(
        title: 'Giáo trình',
        type: DocumentType.lecture,
        subject: 'Vật lý',
        attachments: [
          PendingAttachment(
            fileName: 'chuong-1.pdf',
            extension: 'pdf',
            mimeType: 'application/pdf',
            bytes: Uint8List.fromList([1, 2, 3, 4]),
          ),
          PendingAttachment(
            fileName: 'ghi-chu.txt',
            extension: 'txt',
            mimeType: 'text/plain',
            bytes: Uint8List.fromList([65, 66]),
          ),
        ],
      );

      final document = await service.watchDocuments().first;
      expect(document.single.attachmentCount, 2);
      final attachments = await service.watchAttachments(documentId).first;
      expect(
        attachments.map((file) => file.fileName),
        contains('chuong-1.pdf'),
      );
      expect(attachments.every((file) => file is! AttachmentPayload), isTrue);
      final pdf = attachments.singleWhere((file) => file.extension == 'pdf');
      expect(await service.readAttachmentBytes(pdf.id), [1, 2, 3, 4]);

      await service.delete(documentId);
      expect(await database.countAttachments(documentId), 0);
    },
  );

  test(
    'rolls back document creation when an attachment insert fails',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final service = StudyDocumentService(StudyDocumentRepository(database));
      await database.select(database.studyDocuments).get();
      await database.customStatement('''
      CREATE TRIGGER reject_attachment BEFORE INSERT ON attachments
      BEGIN SELECT RAISE(ABORT, 'attachment rejected'); END
    ''');

      await expectLater(
        service.save(
          title: 'Không được lưu dở',
          type: DocumentType.lecture,
          subject: 'Tin học',
          attachments: [
            PendingAttachment(
              fileName: 'slides.pptx',
              extension: 'pptx',
              bytes: Uint8List.fromList([1]),
            ),
          ],
        ),
        throwsA(anything),
      );
      expect(await database.select(database.studyDocuments).get(), isEmpty);
    },
  );

  test('rejects disallowed extensions and files larger than 10 MB', () {
    final database = AppDatabase(NativeDatabase.memory());
    final service = StudyDocumentService(StudyDocumentRepository(database));
    addTearDown(database.close);

    expect(
      () => service.validatePendingAttachments([
        PendingAttachment(
          fileName: 'script.exe',
          extension: 'exe',
          bytes: Uint8List(1),
        ),
      ]),
      throwsArgumentError,
    );
    expect(
      () => service.validatePendingAttachments([
        PendingAttachment(
          fileName: 'large.zip',
          extension: 'zip',
          bytes: Uint8List(StudyDocumentService.maximumAttachmentBytes + 1),
        ),
      ]),
      throwsArgumentError,
    );
  });
}
