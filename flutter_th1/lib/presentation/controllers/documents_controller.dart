import 'package:flutter/foundation.dart';

import '../../core/utils/document_type.dart';
import '../../domain/models/study_document.dart';
import '../../domain/services/study_document_service.dart';

class DocumentsController extends ChangeNotifier {
  DocumentsController(this._service);

  final StudyDocumentService _service;
  String _keyword = '';
  DocumentType? _type;

  String get keyword => _keyword;
  DocumentType? get type => _type;

  Stream<List<StudyDocument>> documents() =>
      _service.watchDocuments(keyword: _keyword, type: _type);

  void setKeyword(String value) {
    if (_keyword == value) return;
    _keyword = value;
    notifyListeners();
  }

  void setType(DocumentType? value) {
    if (_type == value) return;
    _type = value;
    notifyListeners();
  }
}
