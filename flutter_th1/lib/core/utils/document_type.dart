enum DocumentType {
  lecture('lecture', 'Bài giảng', 'BG', 0xFF175C4B),
  assignment('assignment', 'Bài tập', 'BT', 0xFF9B4F2F),
  reference('reference', 'Tham khảo', 'TK', 0xFF355D9A);

  const DocumentType(this.value, this.label, this.shortLabel, this.colorValue);

  final String value;
  final String label;
  final String shortLabel;
  final int colorValue;

  static DocumentType? fromValue(String value) {
    for (final type in values) {
      if (type.value == value) return type;
    }
    return null;
  }
}
