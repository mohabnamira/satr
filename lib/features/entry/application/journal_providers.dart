import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/journal_entry.dart';
import 'journal_repository.dart';

final journalBoxProvider = Provider<Box<JournalEntry>>((ref) {
  return Hive.box<JournalEntry>('journalEntries');
});


final journalRepositoryProvider = Provider<JournalRepository>((ref) {
  final box = ref.watch(journalBoxProvider);
  return JournalRepository(box);
});

final journalEntriesProvider = StreamProvider<List<JournalEntry>>((ref) {
  final repository = ref.watch(journalRepositoryProvider);
  return repository.watchEntries();
});
final searchQueryProvider = StateProvider<String>((ref) => '');
final filteredEntriesProvider =
    Provider<AsyncValue<List<JournalEntry>>>((ref) {
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();
  return ref.watch(journalEntriesProvider).whenData((entries) {
    if (query.isEmpty) return entries;
    return entries
        .where((e) => e.content.toLowerCase().contains(query))
        .toList();
  });
});