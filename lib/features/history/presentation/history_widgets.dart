import 'package:flutter/material.dart';
import 'package:satr/core/utils/text_direction.dart';
import 'package:satr/features/entry/data/journal_entry.dart';
import 'package:satr/features/prompts/data/prompt_category.dart';

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String formatTime(DateTime d) {
  final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final minute = d.minute.toString().padLeft(2, '0');
  return '$hour:$minute ${d.hour >= 12 ? 'PM' : 'AM'}';
}

String dayLabel(DateTime d) {
  final now = DateTime.now();
  final date = '${d.day.toString().padLeft(2, '0')}.'
      '${d.month.toString().padLeft(2, '0')}';
  if (isSameDay(d, now)) return 'TODAY, $date';
  if (isSameDay(d, now.subtract(const Duration(days: 1)))) {
    return 'YESTERDAY, $date';
  }
  const days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
  return '${days[d.weekday - 1]}, $date';
}

String? promptSourceLabel(JournalEntry entry) {
  for (final c in PromptCategory.values) {
    if (c.name == entry.promptCategory) return c.label;
  }
  return null;
}

String fullDateTime(DateTime d) {
  const months = [
    'JAN',
    'FEB',
    'MAR',
    'APR',
    'MAY',
    'JUN',
    'JUL',
    'AUG',
    'SEP',
    'OCT',
    'NOV',
    'DEC'
  ];
  return '${d.day} ${months[d.month - 1]} ${d.year}, ${formatTime(d)}';
}

class DateDivider extends StatelessWidget {
  const DateDivider({super.key, required this.date});
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Text(
        dayLabel(date),
        style: theme.textTheme.labelSmall
            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      ),
    );
  }
}

class HistoryEntryCard extends StatelessWidget {
  const HistoryEntryCard({super.key, required this.entry, required this.onTap});

  final JournalEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final body = theme.textTheme.bodyMedium!;
    final bold = body.copyWith(fontWeight: FontWeight.w600, fontSize: 15);
    final prompt = entry.promptUsed;
    final source = promptSourceLabel(entry);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: prompt == null
                      ? Text(
                          entry.content,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          textDirection: directionOf(entry.content),
                          textAlign: isRtl(entry.content)
                              ? TextAlign.right
                              : TextAlign.left,
                        )
                      : Text.rich(
                          TextSpan(children: [
                            TextSpan(text: prompt, style: bold),
                            if (source != null)
                              TextSpan(
                                text: ' from $source',
                                style: bold.copyWith(
                                    color: colors.onSurfaceVariant),
                              ),
                          ]),
                          textDirection: directionOf(prompt),
                          textAlign:
                              isRtl(prompt) ? TextAlign.right : TextAlign.left,
                        ),
                ),
                const SizedBox(width: 12),
                Text(
                  formatTime(entry.createdAt),
                  style: body.copyWith(
                      fontSize: 11, color: colors.onSurfaceVariant),
                ),
              ],
            ),
            if (prompt != null) ...[
              const SizedBox(height: 8),
              Text(
                entry.content,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                textDirection: directionOf(entry.content),
                textAlign:
                    isRtl(entry.content) ? TextAlign.right : TextAlign.left,
              ),
            ],
          ],
        ),
      ),
    );
  }
}