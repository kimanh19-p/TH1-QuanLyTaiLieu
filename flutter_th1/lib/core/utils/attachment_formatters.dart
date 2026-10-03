import 'package:flutter/material.dart';

String formatAttachmentSize(int sizeBytes) {
  if (sizeBytes < 1024 * 1024) {
    return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
  }
  return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

IconData attachmentIcon(String extension) {
  return switch (extension.toLowerCase()) {
    'pdf' => Icons.picture_as_pdf_outlined,
    'doc' || 'docx' => Icons.description_outlined,
    'ppt' || 'pptx' => Icons.slideshow_outlined,
    'xls' || 'xlsx' => Icons.table_chart_outlined,
    'png' || 'jpg' || 'jpeg' => Icons.image_outlined,
    'zip' => Icons.folder_zip_outlined,
    _ => Icons.article_outlined,
  };
}
