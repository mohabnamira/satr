import 'dart:convert';
import 'package:satr/core/constants/app_constants.dart';
import 'package:satr/features/entry/data/journal_entry.dart';
import 'package:satr/features/prompts/data/prompt_category.dart';

class ImportAnalysis {
  const ImportAnalysis({
    required this.entriesToImport,
    required this.duplicateCount,
    required this.invalidCount,
    this.errorMessage,
  });

  final List<JournalEntry> entriesToImport;
  final int duplicateCount;
  final int invalidCount;
  final String? errorMessage;

  bool get hasError => errorMessage != null;
  bool get hasImportableEntries => entriesToImport.isNotEmpty;
}

class DataTransferService {
  const DataTransferService();

  /// Exports journal entries to a valid JSON string adhering to v1 schema.
  String exportToJson(List<JournalEntry> entries, {DateTime? now}) {
    final exportMap = <String, dynamic>{
      'app': 'satr',
      'schemaVersion': kExportSchemaVersion,
      'exportedAt': (now ?? DateTime.now()).toIso8601String(),
      'entryCount': entries.length,
      'entries': entries
          .map((e) => <String, dynamic>{
                'id': e.id,
                'content': e.content,
                'createdAt': e.createdAt.toIso8601String(),
                'updatedAt': e.updatedAt?.toIso8601String(),
                'promptUsed': e.promptUsed,
                'promptCategory': e.promptCategory,
              })
          .toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(exportMap);
  }

  /// Exports journal entries to human-readable plain text, newest first.
  String exportToPlainText(List<JournalEntry> entries) {
    final sorted = List<JournalEntry>.from(entries)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final buffer = StringBuffer();
    for (var i = 0; i < sorted.length; i++) {
      final entry = sorted[i];
      final dt = entry.createdAt;
      final dateStr =
          '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      buffer.writeln(dateStr);
      if (entry.promptUsed != null && entry.promptUsed!.trim().isNotEmpty) {
        buffer.writeln('prompt: ${entry.promptUsed!.trim()}');
      }
      buffer.writeln(entry.content.trim());
      if (i < sorted.length - 1) {
        buffer.writeln();
      }
    }
    return buffer.toString();
  }

  /// Validates and parses a JSON backup file content.
  ImportAnalysis parseJsonBackup(
    String jsonString, {
    Set<String>? existingIds,
  }) {
    final knownIds = existingIds ?? <String>{};

    dynamic decoded;
    try {
      decoded = jsonDecode(jsonString);
    } catch (_) {
      return const ImportAnalysis(
        entriesToImport: [],
        duplicateCount: 0,
        invalidCount: 0,
        errorMessage: "couldn't read that file",
      );
    }

    if (decoded is! Map<String, dynamic>) {
      return const ImportAnalysis(
        entriesToImport: [],
        duplicateCount: 0,
        invalidCount: 0,
        errorMessage: "couldn't read that file",
      );
    }

    final app = decoded['app'];
    if (app != 'satr') {
      return const ImportAnalysis(
        entriesToImport: [],
        duplicateCount: 0,
        invalidCount: 0,
        errorMessage: "couldn't read that file",
      );
    }

    final schemaVersion = decoded['schemaVersion'];
    if (schemaVersion is! int) {
      return const ImportAnalysis(
        entriesToImport: [],
        duplicateCount: 0,
        invalidCount: 0,
        errorMessage: "couldn't read that file",
      );
    }

    if (schemaVersion > kExportSchemaVersion) {
      return const ImportAnalysis(
        entriesToImport: [],
        duplicateCount: 0,
        invalidCount: 0,
        errorMessage: 'made by a newer version of satr',
      );
    }

    final rawEntries = decoded['entries'];
    if (rawEntries is! List) {
      return const ImportAnalysis(
        entriesToImport: [],
        duplicateCount: 0,
        invalidCount: 0,
        errorMessage: "couldn't read that file",
      );
    }

    if (rawEntries.length > kMaxImportEntries) {
      return const ImportAnalysis(
        entriesToImport: [],
        duplicateCount: 0,
        invalidCount: 0,
        errorMessage: "couldn't read that file",
      );
    }

    final validCategoryNames =
        PromptCategory.values.map((c) => c.name).toSet();

    final toImport = <JournalEntry>[];
    var duplicateCount = 0;
    var invalidCount = 0;
    final seenInBatch = <String>{};

    for (final item in rawEntries) {
      if (item is! Map<String, dynamic>) {
        invalidCount++;
        continue;
      }

      final id = item['id'];
      if (id is! String || id.trim().isEmpty) {
        invalidCount++;
        continue;
      }

      final content = item['content'];
      if (content is! String || content.trim().isEmpty) {
        invalidCount++;
        continue;
      }

      final createdAtRaw = item['createdAt'];
      if (createdAtRaw is! String) {
        invalidCount++;
        continue;
      }
      final createdAt = DateTime.tryParse(createdAtRaw);
      if (createdAt == null) {
        invalidCount++;
        continue;
      }

      final updatedAtRaw = item['updatedAt'];
      DateTime? updatedAt;
      if (updatedAtRaw is String) {
        updatedAt = DateTime.tryParse(updatedAtRaw);
      }

      final promptUsed = item['promptUsed'] as String?;
      final promptCategoryRaw = item['promptCategory'] as String?;
      final promptCategory = (promptCategoryRaw != null &&
              validCategoryNames.contains(promptCategoryRaw))
          ? promptCategoryRaw
          : null;

      if (knownIds.contains(id) || seenInBatch.contains(id)) {
        duplicateCount++;
        continue;
      }

      seenInBatch.add(id);
      toImport.add(
        JournalEntry(
          id: id,
          content: content.trim(),
          createdAt: createdAt,
          updatedAt: updatedAt,
          promptUsed: promptUsed,
          promptCategory: promptCategory,
        ),
      );
    }

    return ImportAnalysis(
      entriesToImport: toImport,
      duplicateCount: duplicateCount,
      invalidCount: invalidCount,
    );
  }
}
