import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:open_filex/open_filex.dart';

import '../../domain/models/study_attachment.dart';

// Đọc file từ picker và xuất bytes ra thiết bị/trình duyệt.
class AttachmentFileService {
  Future<List<PendingAttachment>> pickFiles({bool allowMultiple = true}) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const [
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
      ],
      allowMultiple: allowMultiple,
      withData: true,
    );
    if (result == null) return const [];

    final files = <PendingAttachment>[];
    for (final file in result.files) {
      final extension = (file.extension ?? '').toLowerCase();
      final bytes = file.bytes ?? await file.xFile.readAsBytes();
      files.add(
        PendingAttachment(
          fileName: file.name,
          extension: extension,
          mimeType: _mimeType(extension),
          bytes: bytes,
        ),
      );
    }
    return files;
  }

  Future<void> saveFile(StudyAttachment attachment, Uint8List bytes) async {
    final suffix = '.${attachment.extension}';
    final name =
        attachment.fileName.toLowerCase().endsWith(suffix.toLowerCase())
            ? attachment.fileName.substring(
              0,
              attachment.fileName.length - suffix.length,
            )
            : attachment.fileName;
    final savedPath = await FileSaver.instance.saveFile(
      name: name,
      bytes: bytes,
      fileExtension: attachment.extension,
      mimeType: MimeType.custom,
      customMimeType: attachment.mimeType ?? 'application/octet-stream',
    );
    if (!kIsWeb) {
      final result = await OpenFilex.open(savedPath);
      if (result.type != ResultType.done) {
        throw StateError('Đã lưu file nhưng không thể mở: ${result.message}');
      }
    }
  }

  String? _mimeType(String extension) {
    return switch (extension) {
      'pdf' => 'application/pdf',
      'doc' => 'application/msword',
      'docx' =>
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'ppt' => 'application/vnd.ms-powerpoint',
      'pptx' =>
        'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      'xls' => 'application/vnd.ms-excel',
      'xlsx' =>
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'txt' => 'text/plain',
      'png' => 'image/png',
      'jpg' || 'jpeg' => 'image/jpeg',
      'zip' => 'application/zip',
      _ => null,
    };
  }
}
