import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:satr/core/utils/storage_exception.dart';
import 'package:satr/features/entry/data/journal_entry.dart';
import 'package:uuid/uuid.dart';

class JournalRepository {
  JournalRepository(this._box);

  final Box<JournalEntry> _box;
  final _uuid = const Uuid();

  List<JournalEntry> getAllEntries() {
    try {
      final entries = _box.values.toList();
      entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return entries;
    } catch (e, stack) {
      debugPrint('JournalRepository.getAllEntries failed: $e\n$stack');
      return <JournalEntry>[];
    }
  }

  Future<JournalEntry> addEntry({
    required String content,
    String? promptUsed,
    String? promptCategory,
  }) async {
    try {
      final entry = JournalEntry(
        id: _uuid.v4(),
        content: content,
        createdAt: DateTime.now(),
        promptUsed: promptUsed,
        promptCategory: promptCategory,
      );
      await _box.put(entry.id, entry);
      return entry;
    } catch (e, stack) {
      debugPrint('JournalRepository.addEntry failed: $e\n$stack');
      throw const StorageException("couldn't save entry. try again");
    }
  }

  Future<void> updateEntry(String id, String newContent) async {
    try {
      final entry = _box.get(id);
      if (entry == null) return;

      entry.content = newContent;
      entry.updatedAt = DateTime.now();
      await entry.save();
    } catch (e, stack) {
      debugPrint('JournalRepository.updateEntry failed: $e\n$stack');
      throw const StorageException("couldn't update entry. try again");
    }
  }

  Future<void> deleteEntry(String id) async {
    try {
      await _box.delete(id);
    } catch (e, stack) {
      debugPrint('JournalRepository.deleteEntry failed: $e\n$stack');
      throw const StorageException("couldn't delete entry. try again");
    }
  }

  Future<void> restoreEntry(JournalEntry entry) async {
    try {
      await _box.put(entry.id, entry);
    } catch (e, stack) {
      debugPrint('JournalRepository.restoreEntry failed: $e\n$stack');
      throw const StorageException("couldn't restore entry. try again");
    }
  }

  Future<void> putAllEntries(Map<String, JournalEntry> entries) async {
    try {
      await _box.putAll(entries);
    } catch (e, stack) {
      debugPrint('JournalRepository.putAllEntries failed: $e\n$stack');
      throw const StorageException("couldn't import entries. try again");
    }
  }

  Future<void> clearAllEntries() async {
    try {
      await _box.clear();
    } catch (e, stack) {
      debugPrint('JournalRepository.clearAllEntries failed: $e\n$stack');
      throw const StorageException("couldn't clear entries. try again");
    }
  }

  ValueListenable<Box<JournalEntry>> listenable() => _box.listenable();

  Stream<List<JournalEntry>> watchEntries() async* {
    yield getAllEntries();
    yield* _box.watch().asyncMap((_) => getAllEntries());
  }
}