// lib/models/journal_entry.dart
import 'package:hive/hive.dart';

part 'journal_entry.g.dart';

@HiveType(typeId: 0)
class JournalEntry extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String content;

  @HiveField(2)
  DateTime createdAt;

  @HiveField(3)
  DateTime? updatedAt;

  @HiveField(4)
  String? promptUsed;

  @HiveField(5)
  String? promptCategory;

  JournalEntry({
    required this.id,
    required this.content,
    required this.createdAt,
    this.updatedAt,
    this.promptUsed,
    this.promptCategory,
  });
}