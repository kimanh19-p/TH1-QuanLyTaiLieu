import 'package:flutter/material.dart';

import '../../core/utils/date_formatters.dart';
import '../../domain/models/study_document.dart';

class DocumentTile extends StatelessWidget {
  const DocumentTile({super.key, required this.document, required this.onTap});

  final StudyDocument document;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = Color(document.type.colorValue);
    return Material(
      color: const Color(0xFFFFFEFA),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          constraints: const BoxConstraints(minHeight: 96),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE5E5DD)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  document.type.shortLabel,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF182823),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${document.subject}  ·  ${document.type.label}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF66716B),
                        fontSize: 12,
                      ),
                    ),
                    if (document.note != null) ...[
                      const SizedBox(height: 5),
                      Text(
                        document.note!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF858D86),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.attach_file_rounded,
                size: 16,
                color: Color(0xFF66716B),
              ),
              const SizedBox(width: 2),
              Text(
                '${document.attachmentCount}',
                style: const TextStyle(
                  color: Color(0xFF66716B),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                formatDocumentDate(document.createdAt),
                style: const TextStyle(color: Color(0xFF858D86), fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
