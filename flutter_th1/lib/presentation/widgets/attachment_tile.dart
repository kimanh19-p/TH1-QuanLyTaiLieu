import 'package:flutter/material.dart';

import '../../core/utils/attachment_formatters.dart';
import '../../core/utils/date_formatters.dart';
import '../../domain/models/study_attachment.dart';

enum AttachmentAction { save, rename, replace, delete }

// Hiển thị metadata file và menu thao tác.
class AttachmentTile extends StatelessWidget {
  const AttachmentTile({
    super.key,
    required this.attachment,
    required this.onAction,
    this.enabled = true,
  });

  final StudyAttachment attachment;
  final ValueChanged<AttachmentAction> onAction;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFE4EFE9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          attachmentIcon(attachment.extension),
          color: const Color(0xFF175C4B),
        ),
      ),
      title: Text(
        attachment.fileName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${formatAttachmentSize(attachment.sizeBytes)}  ·  ${formatDocumentDate(attachment.createdAt)}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: PopupMenuButton<AttachmentAction>(
        tooltip: 'Thao tác tệp',
        enabled: enabled,
        onSelected: onAction,
        itemBuilder:
            (context) => const [
              PopupMenuItem(
                value: AttachmentAction.save,
                child: ListTile(
                  dense: true,
                  leading: Icon(Icons.download_outlined),
                  title: Text('Tải xuống / Mở'),
                ),
              ),
              PopupMenuItem(
                value: AttachmentAction.rename,
                child: ListTile(
                  dense: true,
                  leading: Icon(Icons.edit_outlined),
                  title: Text('Đổi tên'),
                ),
              ),
              PopupMenuItem(
                value: AttachmentAction.replace,
                child: ListTile(
                  dense: true,
                  leading: Icon(Icons.sync_alt_rounded),
                  title: Text('Thay file'),
                ),
              ),
              PopupMenuItem(
                value: AttachmentAction.delete,
                child: ListTile(
                  dense: true,
                  leading: Icon(Icons.delete_outline_rounded),
                  title: Text('Xóa'),
                ),
              ),
            ],
        icon: const Icon(Icons.more_vert_rounded),
      ),
    );
  }
}
