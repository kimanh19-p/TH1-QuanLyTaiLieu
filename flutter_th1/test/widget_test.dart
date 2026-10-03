import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_docs/data/database/app_database.dart';
import 'package:study_docs/main.dart';

void main() {
  testWidgets('creates, edits, and searches study documents', (tester) async {
    final database = AppDatabase(NativeDatabase.memory());
    await tester.pumpWidget(StudyDocsApp(database: database));
    await _pumpUi(tester);

    expect(find.text('Chưa có tài liệu nào'), findsOneWidget);
    await tester.tap(find.text('Thêm tài liệu'));
    await _pumpUi(tester);
    await tester.tap(find.text('Lưu tài liệu'));
    await _pumpUi(tester);
    expect(find.text('Tiêu đề không được để trống.'), findsOneWidget);
    expect(find.text('Môn học không được để trống.'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(0), 'Giải tích 1');
    await tester.enterText(find.byType(TextFormField).at(1), 'Toán học');
    await tester.enterText(
      find.byType(TextFormField).at(2),
      'Ôn chương đạo hàm',
    );
    await tester.tap(find.text('Lưu tài liệu'));
    await _pumpUi(tester);
    expect(find.text('Giải tích 1'), findsOneWidget);

    await tester.tap(find.text('Bài tập'));
    await _pumpUi(tester);
    expect(find.text('Không tìm thấy tài liệu'), findsOneWidget);
    await tester.tap(find.text('Tất cả'));
    await _pumpUi(tester);
    expect(find.text('Giải tích 1'), findsOneWidget);

    await tester.tap(find.text('Giải tích 1'));
    await _pumpUi(tester);
    expect(find.text('Chi tiết tài liệu'), findsOneWidget);
    await tester.tap(find.text('Sửa tài liệu'));
    await _pumpUi(tester);
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'Giải tích nâng cao',
    );
    await tester.tap(find.text('Lưu thay đổi'));
    await _pumpUi(tester);
    expect(find.text('Giải tích nâng cao'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Toán học');
    await _pumpUi(tester);
    expect(find.text('Giải tích nâng cao'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'Vật lý');
    await _pumpUi(tester);
    expect(find.text('Không tìm thấy tài liệu'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '');
    await _pumpUi(tester);
    await tester.drag(find.text('Giải tích nâng cao'), const Offset(500, 0));
    await _pumpUi(tester);
    await tester.tap(find.text('Xóa'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Giải tích nâng cao'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
    await database.close();
  });
}

Future<void> _pumpUi(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}
