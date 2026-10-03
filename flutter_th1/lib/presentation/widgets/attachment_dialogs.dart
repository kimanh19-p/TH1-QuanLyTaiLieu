import 'package:flutter/material.dart';

// Hiển thị xác nhận xóa ở giữa màn hình.
Future<bool> confirmDeleteDialog(
  BuildContext context, {
  required String title,
  required String message,
}) async {
  return await showDialog<bool>(
        context: context,
        builder:
            (context) => Dialog(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      Text(message),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Hủy'),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.tonal(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Xóa'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
      ) ??
      false;
}

// Yêu cầu tên mới và giữ extension của file.
Future<String?> renameAttachmentDialog(
  BuildContext context, {
  required String fileName,
  required String extension,
}) {
  final suffix = '.$extension';
  final withoutExtension =
      fileName.toLowerCase().endsWith(suffix.toLowerCase())
          ? fileName.substring(0, fileName.length - suffix.length)
          : fileName;
  return showDialog<String>(
    context: context,
    builder:
        (context) => _RenameAttachmentDialog(
          initialName: withoutExtension,
          extension: extension,
        ),
  );
}

class _RenameAttachmentDialog extends StatefulWidget {
  const _RenameAttachmentDialog({
    required this.initialName,
    required this.extension,
  });

  final String initialName;
  final String extension;

  @override
  State<_RenameAttachmentDialog> createState() =>
      _RenameAttachmentDialogState();
}

class _RenameAttachmentDialogState extends State<_RenameAttachmentDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Đổi tên file',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Tên file',
                  suffixText: '.${widget.extension}',
                ),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Hủy'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(onPressed: _submit, child: const Text('Lưu')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isNotEmpty) Navigator.pop(context, name);
  }
}
