import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/database/app_database.dart';
import 'data/services/attachment_file_service.dart';
import 'data/repositories/study_document_repository.dart';
import 'domain/services/study_document_service.dart';
import 'presentation/controllers/documents_controller.dart';
import 'presentation/pages/documents_page.dart';

void main() {
  runApp(StudyDocsApp(database: AppDatabase()));
}

class StudyDocsApp extends StatelessWidget {
  const StudyDocsApp({super.key, required this.database});

  final AppDatabase database;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AppDatabase>.value(value: database),
        Provider<AttachmentFileService>(create: (_) => AttachmentFileService()),
        Provider<StudyDocumentRepository>(
          create: (context) => StudyDocumentRepository(context.read()),
        ),
        Provider<StudyDocumentService>(
          create: (context) => StudyDocumentService(context.read()),
        ),
        ChangeNotifierProvider<DocumentsController>(
          create: (context) => DocumentsController(context.read()),
        ),
      ],
      child: MaterialApp(
        title: 'Quản lý Tài liệu Học tập',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFF5F5F0),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF175C4B),
            primary: const Color(0xFF175C4B),
            secondary: const Color(0xFFE5A93D),
            surface: const Color(0xFFFFFEFA),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFFF5F5F0),
            foregroundColor: Color(0xFF182823),
            surfaceTintColor: Colors.transparent,
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFFFFFEFA),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE0E2D9)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE0E2D9)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF175C4B),
                width: 1.5,
              ),
            ),
          ),
        ),
        home: const DocumentsPage(),
      ),
    );
  }
}
