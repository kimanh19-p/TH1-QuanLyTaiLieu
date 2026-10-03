import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/document_type.dart';
import '../../domain/models/study_document.dart';
import '../../domain/services/study_document_service.dart';
import '../controllers/documents_controller.dart';
import '../widgets/attachment_dialogs.dart';
import '../widgets/document_details_dialog.dart';
import '../widgets/document_form_dialog.dart';
import '../widgets/document_tile.dart';

// Hiển thị thư viện tài liệu và mở các hộp thoại nghiệp vụ.
class DocumentsPage extends StatelessWidget {
  const DocumentsPage({super.key});

  Future<void> _openForm(
    BuildContext context, [
    StudyDocument? document,
  ]) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => DocumentFormDialog(document: document),
    );
    if (saved == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            document == null ? 'Đã thêm tài liệu.' : 'Đã cập nhật tài liệu.',
          ),
        ),
      );
    }
  }

  Future<void> _openDetails(
    BuildContext context,
    StudyDocument document,
  ) async {
    final deleted = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => DocumentDetailsDialog(
            document: document,
            onEdit: () {
              Navigator.of(dialogContext).pop();
              _openForm(context, document);
            },
          ),
    );
    if (deleted == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa tài liệu và các file bên trong.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DocumentsController>();
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tài liệu học tập',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0),
        ),
        actions: [
          IconButton(
            tooltip: 'Thêm tài liệu',
            onPressed: () => _openForm(context),
            icon: const Icon(Icons.add_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kho tài liệu',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: const Color(0xFF182823),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Gom bài giảng, bài tập và nguồn tham khảo vào một nơi.',
                  style: TextStyle(color: Color(0xFF66716B), height: 1.4),
                ),
                const SizedBox(height: 20),
                TextField(
                  onChanged: controller.setKeyword,
                  textInputAction: TextInputAction.search,
                  decoration: const InputDecoration(
                    hintText: 'Tìm tiêu đề, môn học, ghi chú',
                    prefixIcon: Icon(Icons.search_rounded),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 14),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'Tất cả',
                        selected: controller.type == null,
                        onSelected: () => controller.setType(null),
                      ),
                      for (final type in DocumentType.values)
                        _FilterChip(
                          label: type.label,
                          selected: controller.type == type,
                          onSelected: () => controller.setType(type),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<StudyDocument>>(
              stream: controller.documents(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const _MessageState(
                    icon: Icons.error_outline_rounded,
                    title: 'Không thể tải tài liệu',
                    detail: 'Vui lòng thử mở lại ứng dụng.',
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final documents = snapshot.data!;
                if (documents.isEmpty) {
                  return _MessageState(
                    icon:
                        controller.keyword.isNotEmpty || controller.type != null
                            ? Icons.search_off_rounded
                            : Icons.menu_book_outlined,
                    title:
                        controller.keyword.isNotEmpty || controller.type != null
                            ? 'Không tìm thấy tài liệu'
                            : 'Chưa có tài liệu nào',
                    detail:
                        controller.keyword.isNotEmpty || controller.type != null
                            ? 'Thử từ khóa hoặc bộ lọc khác.'
                            : 'Tạo tài liệu đầu tiên để bắt đầu.',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  itemCount: documents.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 9),
                  itemBuilder: (context, index) {
                    final document = documents[index];
                    return Dismissible(
                      key: ValueKey(document.id),
                      direction: DismissDirection.horizontal,
                      background: const _DeleteBackground(
                        alignment: Alignment.centerLeft,
                      ),
                      secondaryBackground: const _DeleteBackground(
                        alignment: Alignment.centerRight,
                      ),
                      confirmDismiss:
                          (_) => confirmDeleteDialog(
                            context,
                            title: 'Xóa tài liệu?',
                            message:
                                'Tài liệu "${document.title}" và ${document.attachmentCount} file bên trong sẽ bị xóa vĩnh viễn.',
                          ),
                      onDismissed: (_) async {
                        await context.read<StudyDocumentService>().delete(
                          document.id,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Đã xóa tài liệu.')),
                          );
                        }
                      },
                      child: DocumentTile(
                        document: document,
                        onTap: () => _openDetails(context, document),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Thêm tài liệu'),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
        showCheckmark: false,
        side: BorderSide(
          color: selected ? const Color(0xFF175C4B) : const Color(0xFFE0E2D9),
        ),
        backgroundColor: const Color(0xFFFFFEFA),
        selectedColor: const Color(0xFFDDEBE4),
        labelStyle: TextStyle(
          color: selected ? const Color(0xFF175C4B) : const Color(0xFF4D5852),
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }
}

class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground({required this.alignment});

  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(0xFFB4483A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder:
          (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 44, color: const Color(0xFF7A8980)),
                      const SizedBox(height: 14),
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        detail,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFF66716B)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
    );
  }
}
