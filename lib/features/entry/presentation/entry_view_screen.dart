import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:satr/core/constants/app_constants.dart';
import 'package:satr/core/utils/storage_exception.dart';
import 'package:satr/core/utils/text_direction.dart';
import 'package:satr/core/widgets/app_toast.dart';
import 'package:satr/features/entry/application/journal_providers.dart';
import 'package:satr/features/entry/data/journal_entry.dart';
import 'package:satr/features/entry/presentation/new_entry_screen.dart';
import 'package:satr/features/history/presentation/history_widgets.dart';

class EntryViewScreen extends ConsumerWidget {
  const EntryViewScreen({super.key, required this.entry});

  final JournalEntry entry;

  void _openMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => NewEntryScreen(entry: entry),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Delete'),
              onTap: () async {
                Navigator.of(sheetContext).pop();
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('Delete entry?'),
                    content: const Text('This cannot be undone.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        child: Text(
                          'Delete',
                          style: TextStyle(
                            color: Theme.of(dialogContext).colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
                if (confirmed != true) return;

                try {
                  await ref
                      .read(journalRepositoryProvider)
                      .deleteEntry(entry.id);
                  if (context.mounted) {
                    AppToast.show(context, message: 'entry deleted');
                    Navigator.of(context).pop();
                  }
                } on StorageException catch (e) {
                  if (context.mounted) AppToast.show(context, message: e.message);
                } catch (_) {
                  if (context.mounted) {
                    AppToast.show(
                      context,
                      message: "couldn't delete entry. try again",
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final prompt = entry.promptUsed;
    final source = promptSourceLabel(entry);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            kHorizontalPadding,
            8,
            kHorizontalPadding,
            24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () => _openMenu(context, ref),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                fullDateTime(entry.createdAt),
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              if (prompt != null)
                Text.rich(
                  TextSpan(children: [
                    TextSpan(text: prompt, style: theme.textTheme.titleLarge),
                    if (source != null)
                      TextSpan(
                        text: ' from $source',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                  ]),
                  textDirection: directionOf(prompt),
                  textAlign: isRtl(prompt) ? TextAlign.right : TextAlign.left,
                ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    entry.content,
                    style: theme.textTheme.bodyLarge,
                    textDirection: directionOf(entry.content),
                    textAlign:
                        isRtl(entry.content) ? TextAlign.right : TextAlign.left,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}