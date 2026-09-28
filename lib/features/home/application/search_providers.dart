import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:satr/features/entry/application/journal_providers.dart';
import 'package:satr/features/entry/data/journal_entry.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');

final filteredEntriesProvider = Provider<AsyncValue<List<JournalEntry>>>((ref) {
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();
  return ref.watch(journalEntriesProvider).whenData((entries) {
    if (query.isEmpty) return entries;
    return entries
        .where((e) => e.content.toLowerCase().contains(query))
        .toList();
  });
});
