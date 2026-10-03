import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/date_formatters.dart';
import '../../data/services/attachment_file_service.dart';
import '../../domain/models/study_attachment.dart';
import '../../domain/models/study_document.dart';
import '../../domain/services/study_document_service.dart';
import 'attachment_dialogs.dart';
import 'attachment_tile.dart';

// Hiển thị thông tin tài liệu và thao tác các file đã lưu.
class DocumentDetailsDialog extends StatefulWidget {
  const DocumentDetailsDialog({
    super.key,
    required this.document,
    required this.onEdit,
  });

  final StudyDocument document;
  final VoidCallback onEdit;

  @override
  State<DocumentDetailsDialog> createState() => _DocumentDetailsDialogState();
}

class _DocumentDetailsDialogState extends State<DocumentDetailsDialog> {
  bool _busy = false;

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Không thể xử lý file: $error')));
  }

  Future<void> _addFiles() async {
    setState(() => _busy = true);
    try {
      final picker = context.read<AttachmentFileService>();
      final service = context.read<StudyDocumentService>();
      final files = await picker.pickFiles();
      service.validatePendingAttachments(files);
      await service.addAttachments(widget.document.id, files);
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _handleAction(
    StudyAttachment attachment,
    AttachmentAction action,
  ) async {
    final service = context.read<StudyDocumentService>();
    final fileService = context.read<AttachmentFileService>();
    switch (action) {
      case AttachmentAction.save:
        try {
          final bytes = await service.readAttachmentBytes(attachment.id);
          if (bytes == null) throw StateError('Không tìm thấy nội dung file.');
          await fileService.saveFile(attachment, bytes);
        } catch (error) {
          _showError(error);
        }
      case AttachmentAction.rename:
        final name = await renameAttachmentDialog(
          context,
          fileName: attachment.fileName,
          extension: attachment.extension,
        );
        if (name == null || !mounted) return;
        try {
          await service.renameAttachment(attachment.id, name);
        } catch (error) {
          _showError(error);
        }
      case AttachmentAction.replace:
        try {
          final files = await fileService.pickFiles(allowMultiple: false);
          if (files.isEmpty || !mounted) return;
          service.validatePendingAttachments(files);
          await service.replaceAttachment(attachment.id, files.single);
        } catch (error) {
          _showError(error);
        }
      case AttachmentAction.delete:
        final confirmed = await confirmDeleteDialog(
          context,
          title: 'Xóa file?',
          message: 'File "${attachment.fileName}" sẽ bị xóa vĩnh viễn.',
        );
        if (!confirmed || !mounted) return;
        try {
          await service.deleteAttachment(attachment.id);
        } catch (error) {
          _showError(error);
        }
    }
  }

  Future<void> _deleteDocument() async {
    final confirmed = await confirmDeleteDialog(
      context,
      title: 'Xóa tài liệu?',
      message:
          'Tài liệu "${widget.document.title}" và ${widget.document.attachmentCount} file bên trong sẽ bị xóa vĩnh viễn.',
    );
    if (!confirmed || !mounted) return;
    try {
      await context.read<StudyDocumentService>().delete(widget.document.id);
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      _showError(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final document = widget.document;
    final service = context.read<StudyDocumentService>();
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 560,
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Chi tiết tài liệu',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: const Color(0xFF182823),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Đóng',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                document.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              _DetailRow(label: 'Loại', value: document.type.label),
              _DetailRow(label: 'Môn học', value: document.subject),
              _DetailRow(
                label: 'Ngày tạo',
                value: formatDocumentDate(document.createdAt),
              ),
              if (document.note != null && document.note!.isNotEmpty)
                _DetailRow(label: 'Ghi chú', value: document.note!),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Tệp đính kèm',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _busy ? null : _addFiles,
                    icon:
                        _busy
                            ? const SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Icon(Icons.attach_file_rounded, size: 18),
                    label: Text(_busy ? 'Đang tải...' : 'Thêm file'),
                  ),
                ],
              ),
              StreamBuilder<List<StudyAttachment>>(
                stream: service.watchAttachments(document.id),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('Không thể tải danh sách file.'),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final attachments = snapshot.data!;
                  if (attachments.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Chưa có file đính kèm.',
                        style: TextStyle(color: Color(0xFF66716B)),
                      ),
                    );
                  }
                  return Column(
                    children: [
                      for (final attachment in attachments)
                        AttachmentTile(
                          attachment: attachment,
                          enabled: !_busy,
                          onAction:
                              (action) => _handleAction(attachment, action),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _deleteDocument,
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('Xóa tài liệu'),
                  ),
                  FilledButton.icon(
                    onPressed: _busy ? null : widget.onEdit,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Sửa tài liệu'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF66716B)),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
