import 'package:flutter_test/flutter_test.dart';
import 'package:satr/features/entry/data/journal_entry.dart';
import 'package:satr/features/settings/data/data_transfer_service.dart';

void main() {
  const service = DataTransferService();

  group('DataTransferService Export', () {
    test('valid round trip export and import', () {
      final now = DateTime.utc(2026, 9, 28, 12, 0, 0);
      final entries = [
        JournalEntry(
          id: 'entry-1',
          content: 'First thought',
          createdAt: now,
          promptUsed: 'Prompt 1',
          promptCategory: 'feelings',
        ),
        JournalEntry(
          id: 'entry-2',
          content: 'Second thought',
          createdAt: now.add(const Duration(hours: 1)),
          updatedAt: now.add(const Duration(hours: 2)),
        ),
      ];

      final jsonOutput = service.exportToJson(entries, now: now);
      final analysis = service.parseJsonBackup(jsonOutput);

      expect(analysis.hasError, isFalse);
      expect(analysis.entriesToImport.length, 2);
      expect(analysis.duplicateCount, 0);
      expect(analysis.invalidCount, 0);

      expect(analysis.entriesToImport[0].id, 'entry-1');
      expect(analysis.entriesToImport[0].content, 'First thought');
      expect(analysis.entriesToImport[0].promptCategory, 'feelings');
      expect(analysis.entriesToImport[1].id, 'entry-2');
      expect(analysis.entriesToImport[1].updatedAt, isNotNull);
    });

    test('plain text export formats correctly', () {
      final t1 = DateTime(2026, 9, 28, 9, 30);
      final t2 = DateTime(2026, 9, 28, 11, 45);
      final entries = [
        JournalEntry(
          id: '1',
          content: 'Morning notes',
          createdAt: t1,
          promptUsed: 'How are you feeling?',
        ),
        JournalEntry(
          id: '2',
          content: 'Later notes',
          createdAt: t2,
        ),
      ];

      final text = service.exportToPlainText(entries);
      // Newest should be first
      expect(text.startsWith('2026-09-28 11:45'), isTrue);
      expect(text.contains('prompt: How are you feeling?'), isTrue);
      expect(text.contains('Morning notes'), isTrue);
    });
  });

  group('DataTransferService Import Validation', () {
    test('malformed JSON returns error', () {
      final result = service.parseJsonBackup('{ invalid json');
      expect(result.hasError, isTrue);
      expect(result.errorMessage, "couldn't read that file");
      expect(result.entriesToImport, isEmpty);
    });

    test('wrong app returns error', () {
      const json = '{"app":"otherApp","schemaVersion":1,"entries":[]}';
      final result = service.parseJsonBackup(json);
      expect(result.hasError, isTrue);
      expect(result.errorMessage, "couldn't read that file");
    });

    test('future schemaVersion returns specific error', () {
      const json = '{"app":"satr","schemaVersion":99,"entries":[]}';
      final result = service.parseJsonBackup(json);
      expect(result.hasError, isTrue);
      expect(result.errorMessage, 'made by a newer version of satr');
    });

    test('skips duplicate IDs existing on device or in batch', () {
      const json = '''
      {
        "app": "satr",
        "schemaVersion": 1,
        "entries": [
          {"id": "exist-1", "content": "Existing", "createdAt": "2026-09-28T10:00:00.000Z"},
          {"id": "new-1", "content": "New", "createdAt": "2026-09-28T11:00:00.000Z"},
          {"id": "new-1", "content": "New Duplicate", "createdAt": "2026-09-28T12:00:00.000Z"}
        ]
      }
      ''';
      final result = service.parseJsonBackup(json, existingIds: {'exist-1'});
      expect(result.hasError, isFalse);
      expect(result.entriesToImport.length, 1);
      expect(result.entriesToImport.first.id, 'new-1');
      expect(result.duplicateCount, 2); // 1 on device, 1 duplicated within file
    });

    test('invalid or missing fields are counted as skipped and non-fatal', () {
      const json = '''
      {
        "app": "satr",
        "schemaVersion": 1,
        "entries": [
          {"id": "", "content": "No ID", "createdAt": "2026-09-28T10:00:00.000Z"},
          {"id": "valid-1", "content": "   ", "createdAt": "2026-09-28T10:00:00.000Z"},
          {"id": "valid-2", "content": "Valid", "createdAt": "not-a-date"},
          {"id": "valid-3", "content": "Valid with invalid category", "createdAt": "2026-09-28T10:00:00.000Z", "promptCategory": "unknownCat"},
          "not a map",
          {"id": "valid-4", "content": "Good entry", "createdAt": "2026-09-28T10:00:00.000Z"}
        ]
      }
      ''';
      final result = service.parseJsonBackup(json);
      expect(result.hasError, isFalse);
      expect(result.invalidCount, 4);
      expect(result.entriesToImport.length, 2);
      expect(result.entriesToImport[0].id, 'valid-3');
      expect(result.entriesToImport[0].promptCategory, isNull);
      expect(result.entriesToImport[1].id, 'valid-4');
    });

    test('rejects entries list exceeding maximum capacity', () {
      final oversizedEntries = List.generate(
        50001,
        (i) => '{"id":"$i","content":"test","createdAt":"2026-09-28T00:00:00.000Z"}',
      ).join(',');
      final json = '{"app":"satr","schemaVersion":1,"entries":[$oversizedEntries]}';
      final result = service.parseJsonBackup(json);
      expect(result.hasError, isTrue);
      expect(result.errorMessage, "couldn't read that file");
    });
  });
}
