import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:satr/core/constants/app_constants.dart';
import 'package:satr/features/entry/data/journal_entry.dart';
import 'package:satr/features/entry/data/journal_repository.dart';

final journalBoxProvider = Provider<Box<JournalEntry>>((ref) {
  return Hive.box<JournalEntry>(kJournalEntriesBox);
});

final journalRepositoryProvider = Provider<JournalRepository>((ref) {
  final box = ref.watch(journalBoxProvider);
  return JournalRepository(box);
});

final journalEntriesProvider = StreamProvider<List<JournalEntry>>((ref) {
  final repository = ref.watch(journalRepositoryProvider);
  return repository.watchEntries();
});