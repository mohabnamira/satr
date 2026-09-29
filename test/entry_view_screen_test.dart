import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satr/features/entry/data/journal_entry.dart';
import 'package:satr/features/entry/presentation/entry_view_screen.dart';

void main() {
  testWidgets('entry view labels its icon-only actions', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: EntryViewScreen(
            entry: JournalEntry(
              id: 'entry-1',
              content: 'A journal entry',
              createdAt: DateTime(2026, 9, 29),
            ),
          ),
        ),
      ),
    );

    expect(find.byTooltip('back'), findsOneWidget);
    expect(find.byTooltip('entry options'), findsOneWidget);
  });
}
