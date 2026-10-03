import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

// Khai báo cấu trúc tài liệu học tập trong SQLite.
class StudyDocuments extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get type => text()();
  TextColumn get subject => text()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

// Lưu metadata và nội dung file, xóa theo tài liệu cha.
class Attachments extends Table {
  TextColumn get id => text()();
  TextColumn get documentId =>
      text().references(StudyDocuments, #id, onDelete: KeyAction.cascade)();
  TextColumn get fileName => text()();
  TextColumn get extension => text()();
  TextColumn get mimeType => text().nullable()();
  IntColumn get sizeBytes => integer()();
  BlobColumn get bytes => blob()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

// Metadata không bao gồm Blob để tránh tải nội dung file vào danh sách.
class AttachmentMetadata {
  const AttachmentMetadata({
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

@DriftDatabase(tables: [StudyDocuments, Attachments])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(
        executor ??
            driftDatabase(
              name: 'study_docs',
              web: DriftWebOptions(
                sqlite3Wasm: Uri.parse('sqlite3.wasm'),
                driftWorker: Uri.parse('drift_worker.js'),
              ),
            ),
      );

  @override
  int get schemaVersion => schemaVersionGlobal;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
    onUpgrade: (migrator, from, to) async {
      if (from < 2) await migrator.createTable(attachments);
    },
    beforeOpen: (_) async => customStatement('PRAGMA foreign_keys = ON'),
  );

  Stream<List<(StudyDocument, int)>> watchDocuments({
    String keyword = '',
    String? type,
  }) {
    final attachmentCount = attachments.id.count();
    final query =
        selectOnly(studyDocuments)
          ..addColumns([...studyDocuments.$columns, attachmentCount])
          ..join([
            leftOuterJoin(
              attachments,
              attachments.documentId.equalsExp(studyDocuments.id),
            ),
          ])
          ..groupBy([studyDocuments.id]);
    if (type != null) {
      query.where(studyDocuments.type.equals(type));
    }
    final trimmedKeyword = keyword.trim();
    if (trimmedKeyword.isNotEmpty) {
      query.where(
        studyDocuments.title.contains(trimmedKeyword) |
            studyDocuments.subject.contains(trimmedKeyword) |
            studyDocuments.note.contains(trimmedKeyword),
      );
    }
    query.orderBy([OrderingTerm.desc(studyDocuments.createdAt)]);
    return query
        .map(
          (row) => (
            StudyDocument(
              id: row.read(studyDocuments.id)!,
              title: row.read(studyDocuments.title)!,
              type: row.read(studyDocuments.type)!,
              subject: row.read(studyDocuments.subject)!,
              note: row.read(studyDocuments.note),
              createdAt: row.read(studyDocuments.createdAt)!,
            ),
            row.read(attachmentCount) ?? 0,
          ),
        )
        .watch();
  }

  Stream<List<AttachmentMetadata>> watchAttachments(String documentId) {
    final query =
        selectOnly(attachments)
          ..addColumns([
            attachments.id,
            attachments.documentId,
            attachments.fileName,
            attachments.extension,
            attachments.mimeType,
            attachments.sizeBytes,
            attachments.createdAt,
          ])
          ..where(attachments.documentId.equals(documentId))
          ..orderBy([OrderingTerm.desc(attachments.createdAt)]);
    return query
        .map(
          (row) => AttachmentMetadata(
            id: row.read(attachments.id)!,
            documentId: row.read(attachments.documentId)!,
            fileName: row.read(attachments.fileName)!,
            extension: row.read(attachments.extension)!,
            mimeType: row.read(attachments.mimeType),
            sizeBytes: row.read(attachments.sizeBytes)!,
            createdAt: row.read(attachments.createdAt)!,
          ),
        )
        .watch();
  }

  Future<AttachmentMetadata?> findAttachmentMetadata(String id) {
    final query =
        selectOnly(attachments)
          ..addColumns([
            attachments.id,
            attachments.documentId,
            attachments.fileName,
            attachments.extension,
            attachments.mimeType,
            attachments.sizeBytes,
            attachments.createdAt,
          ])
          ..where(attachments.id.equals(id));
    return query
        .map(
          (row) => AttachmentMetadata(
            id: row.read(attachments.id)!,
            documentId: row.read(attachments.documentId)!,
            fileName: row.read(attachments.fileName)!,
            extension: row.read(attachments.extension)!,
            mimeType: row.read(attachments.mimeType),
            sizeBytes: row.read(attachments.sizeBytes)!,
            createdAt: row.read(attachments.createdAt)!,
          ),
        )
        .getSingleOrNull();
  }

  Future<Uint8List?> readAttachmentBytes(String id) async {
    final query =
        selectOnly(attachments)
          ..addColumns([attachments.bytes])
          ..where(attachments.id.equals(id));
    return query.map((row) => row.read(attachments.bytes)!).getSingleOrNull();
  }

  Future<int> insertDocument(StudyDocumentsCompanion document) =>
      into(studyDocuments).insert(document);

  Future<bool> updateDocument(StudyDocumentsCompanion document) =>
      update(studyDocuments).replace(document);

  Future<int> deleteDocument(String id) =>
      (delete(studyDocuments)..where((row) => row.id.equals(id))).go();

  Future<void> insertAttachment(AttachmentsCompanion attachment) async {
    await into(attachments).insert(attachment);
  }

  Future<void> updateAttachment(AttachmentsCompanion attachment) async {
    await update(attachments).replace(attachment);
  }

  Future<int> deleteAttachment(String id) =>
      (delete(attachments)..where((row) => row.id.equals(id))).go();

  Future<int> deleteAttachmentsForDocument(
    String documentId,
    List<String> ids,
  ) {
    if (ids.isEmpty) return Future.value(0);
    return (delete(attachments)..where(
      (row) => row.documentId.equals(documentId) & row.id.isIn(ids),
    )).go();
  }

  Future<int> renameAttachment(String id, String fileName) =>
      (update(attachments)..where(
        (row) => row.id.equals(id),
      )).write(AttachmentsCompanion(fileName: Value(fileName)));

  Future<int> countAttachments(String documentId) async {
    final count = attachments.id.count();
    final query =
        selectOnly(attachments)
          ..addColumns([count])
          ..where(attachments.documentId.equals(documentId));
    return await query.map((row) => row.read(count) ?? 0).getSingle();
  }
}

const int schemaVersionGlobal = 2;
