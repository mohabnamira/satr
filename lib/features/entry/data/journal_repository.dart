// lib/data/journal_repository.dart
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/journal_entry.dart';

class JournalRepository {
  final Box<JournalEntry> _box;
  final _uuid = const Uuid();

  JournalRepository(this._box);

  List<JournalEntry> getAllEntries() {
    final entries = _box.values.toList();
    entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return entries;
  }

  Future<JournalEntry> addEntry({
    required String content,
    String? promptUsed,
    String? promptCategory,
  }) async {
    final entry = JournalEntry(
      id: _uuid.v4(),
      content: content,
      createdAt: DateTime.now(),
      promptUsed: promptUsed,
      promptCategory: promptCategory,
    );
    await _box.put(entry.id, entry);
    return entry;
  }

  Future<void> updateEntry(String id, String newContent) async {
    final entry = _box.get(id);
    if (entry == null) return;

    entry.content = newContent;
    entry.updatedAt = DateTime.now();
    await entry.save();
  }

  Future<void> deleteEntry(String id) async {
    await _box.delete(id);
  }

  Future<void> restoreEntry(JournalEntry entry) async {
    await _box.put(entry.id, entry);
  }
    Future<void> clearAllEntries() async {
    await _box.clear();
  }

  ValueListenable<Box<JournalEntry>> listenable() => _box.listenable();

  Stream<List<JournalEntry>> watchEntries() async* {
    yield getAllEntries();
    yield* _box.watch().asyncMap((_) => getAllEntries());
  }
}