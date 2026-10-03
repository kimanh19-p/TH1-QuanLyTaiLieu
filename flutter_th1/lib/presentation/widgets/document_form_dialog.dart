import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/document_type.dart';
import '../../data/services/attachment_file_service.dart';
import '../../domain/models/study_attachment.dart';
import '../../domain/models/study_document.dart';
import '../../domain/services/study_document_service.dart';
import 'attachment_dialogs.dart';
import 'attachment_tile.dart';

// Form tạo/sửa tài liệu và quản lý file gắn kèm.
class DocumentFormDialog extends StatefulWidget {
  const DocumentFormDialog({super.key, this.document});

  final StudyDocument? document;

  @override
  State<DocumentFormDialog> createState() => _DocumentFormDialogState();
}

class _DocumentFormDialogState extends State<DocumentFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _subjectController;
  late final TextEditingController _noteController;
  late DocumentType _type;
  final List<PendingAttachment> _pendingAttachments = [];
  final Set<String> _removedAttachmentIds = {};
  bool _saving = false;
  bool _picking = false;

  @override
  void initState() {
    super.initState();
    final document = widget.document;
    _titleController = TextEditingController(text: document?.title ?? '');
    _subjectController = TextEditingController(text: document?.subject ?? '');
    _noteController = TextEditingController(text: document?.note ?? '');
    _type = document?.type ?? DocumentType.lecture;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subjectController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  String? _required(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return '$label không được để trống.';
    }
    return null;
  }

  Future<void> _pickFiles({bool allowMultiple = true}) async {
    setState(() => _picking = true);
    try {
      final picker = context.read<AttachmentFileService>();
      final service = context.read<StudyDocumentService>();
      final files = await picker.pickFiles(allowMultiple: allowMultiple);
      service.validatePendingAttachments(files);
      if (mounted && files.isNotEmpty) {
        setState(() => _pendingAttachments.addAll(files));
      }
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final service = context.read<StudyDocumentService>();
      await service.save(
        id: widget.document?.id,
        title: _titleController.text,
        type: _type,
        subject: _subjectController.text,
        note: _noteController.text,
        createdAt: widget.document?.createdAt,
        attachments: List.of(_pendingAttachments),
        removedAttachmentIds: _removedAttachmentIds.toList(growable: false),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      _showError(error);
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _handleExistingAction(
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
        final files = await context.read<AttachmentFileService>().pickFiles(
          allowMultiple: false,
        );
        if (files.isEmpty || !mounted) return;
        try {
          await service.replaceAttachment(attachment.id, files.single);
        } catch (error) {
          _showError(error);
        }
      case AttachmentAction.delete:
        final confirmed = await confirmDeleteDialog(
          context,
          title: 'Xóa file?',
          message: 'File "${attachment.fileName}" sẽ bị xóa khi lưu thay đổi.',
        );
        if (confirmed && mounted) {
          setState(() => _removedAttachmentIds.add(attachment.id));
        }
    }
  }

  Future<void> _removePendingAttachment(int index) async {
    final attachment = _pendingAttachments[index];
    final confirmed = await confirmDeleteDialog(
      context,
      title: 'Bỏ file đã chọn?',
      message: 'File "${attachment.fileName}" sẽ không được lưu cùng tài liệu.',
    );
    if (confirmed && mounted) {
      setState(() => _pendingAttachments.removeAt(index));
    }
  }

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Không thể xử lý file: $error')));
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
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        document == null ? 'Tài liệu mới' : 'Sửa tài liệu',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: const Color(0xFF182823),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Đóng',
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Tiêu đề *',
                    hintText: 'Ví dụ: Chương 3 · Hệ điều hành',
                  ),
                  validator: (value) => _required(value, 'Tiêu đề'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<DocumentType>(
                  value: _type,
                  decoration: const InputDecoration(
                    labelText: 'Loại tài liệu *',
                  ),
                  items: [
                    for (final type in DocumentType.values)
                      DropdownMenuItem(value: type, child: Text(type.label)),
                  ],
                  onChanged:
                      _saving
                          ? null
                          : (value) {
                            if (value != null) setState(() => _type = value);
                          },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _subjectController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Môn học *',
                    hintText: 'Ví dụ: Cơ sở dữ liệu',
                  ),
                  validator: (value) => _required(value, 'Môn học'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _noteController,
                  textCapitalization: TextCapitalization.sentences,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Ghi chú',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 16),
                _attachmentSection(service, document),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed:
                            _saving ? null : () => Navigator.pop(context),
                        child: const Text('Hủy'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _saving ? null : _save,
                        icon:
                            _saving
                                ? const SizedBox.square(
                                  dimension: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Icon(Icons.check_rounded),
                        label: Text(
                          _saving
                              ? 'Đang lưu...'
                              : document == null
                              ? 'Lưu tài liệu'
                              : 'Lưu thay đổi',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _attachmentSection(
    StudyDocumentService service,
    StudyDocument? document,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Tệp đính kèm',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            TextButton.icon(
              onPressed: _saving || _picking ? null : _pickFiles,
              icon: const Icon(Icons.attach_file_rounded, size: 18),
              label: const Text('Chọn file'),
            ),
          ],
        ),
        if (_picking)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: LinearProgressIndicator(minHeight: 2),
          ),
        if (document != null)
          StreamBuilder<List<StudyAttachment>>(
            stream: service.watchAttachments(document.id),
            builder: (context, snapshot) {
              final attachments = snapshot.data ?? const <StudyAttachment>[];
              final visible = attachments
                  .where((file) => !_removedAttachmentIds.contains(file.id))
                  .toList(growable: false);
              return Column(
                children: [
                  for (final attachment in visible)
                    AttachmentTile(
                      attachment: attachment,
                      onAction:
                          (action) => _handleExistingAction(attachment, action),
                    ),
                ],
              );
            },
          ),
        for (var index = 0; index < _pendingAttachments.length; index++)
          _PendingAttachmentTile(
            attachment: _pendingAttachments[index],
            onRemove: () => _removePendingAttachment(index),
          ),
        if (document == null && _pendingAttachments.isEmpty && !_picking)
          const Padding(
            padding: EdgeInsets.only(bottom: 6),
            child: Text(
              'Chưa chọn file',
              style: TextStyle(color: Color(0xFF66716B), fontSize: 13),
            ),
          ),
      ],
    );
  }
}

class _PendingAttachmentTile extends StatelessWidget {
  const _PendingAttachmentTile({
    required this.attachment,
    required this.onRemove,
  });

  final PendingAttachment attachment;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final size = attachment.sizeBytes / 1024;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: const Icon(Icons.attach_file_rounded, color: Color(0xFF175C4B)),
      title: Text(
        attachment.fileName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text('${size.toStringAsFixed(1)} KB · Chờ lưu'),
      trailing: IconButton(
        tooltip: 'Bỏ file đã chọn',
        onPressed: onRemove,
        icon: const Icon(Icons.close_rounded),
      ),
    );
  }
}
