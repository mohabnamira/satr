import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:satr/core/constants/app_constants.dart';
import 'package:satr/core/utils/storage_exception.dart';
import 'package:satr/core/utils/text_direction.dart';
import 'package:satr/core/widgets/app_toast.dart';
import 'package:satr/core/widgets/typewriter_text.dart';
import 'package:satr/features/entry/application/journal_providers.dart';
import 'package:satr/features/entry/data/journal_entry.dart';
import 'package:satr/features/prompts/application/prompt_providers.dart';
import 'package:satr/features/prompts/data/prompt.dart';
import 'package:satr/features/prompts/data/prompt_category.dart';

class NewEntryScreen extends ConsumerStatefulWidget {
  const NewEntryScreen({super.key, this.entry, this.initialPrompt});

  final JournalEntry? entry;
  final Prompt? initialPrompt;

  @override
  ConsumerState<NewEntryScreen> createState() => _NewEntryScreenState();
}

class _NewEntryScreenState extends ConsumerState<NewEntryScreen> {
  TextDirection _direction = TextDirection.ltr;
  late final TextEditingController _controller;
  PromptCategory? _category;
  Prompt? _prompt;
  bool _showCategories = false;

  void _pick(PromptCategory? category) {
    setState(() {
      _category = category;
      _prompt = ref.read(promptRepositoryProvider).randomPrompt(
            category: category,
            exclude: _prompt?.text,
          );
    });
  }

  void _startPrompt() {
    setState(() {
      _showCategories = true;
      _prompt = ref.read(promptRepositoryProvider).randomPrompt();
    });
  }

  bool get _isEditing => widget.entry != null;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.entry?.content);
    _prompt = widget.initialPrompt;
    _showCategories = _prompt != null;
    _direction =
        isRtl(_controller.text) ? TextDirection.rtl : TextDirection.ltr;
    _controller.addListener(() {
      final next =
          isRtl(_controller.text) ? TextDirection.rtl : TextDirection.ltr;
      if (next != _direction) setState(() => _direction = next);
    });
  }

  Future<void> _saveEntry() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final repository = ref.read(journalRepositoryProvider);
    try {
      if (_isEditing) {
        await repository.updateEntry(widget.entry!.id, text);
      } else {
        await repository.addEntry(
          content: text,
          promptUsed: _prompt?.text,
          promptCategory: _prompt?.category.name,
        );
      }

      if (mounted) {
        AppToast.show(
          context,
          message: _isEditing ? 'entry updated' : 'entry saved',
        );
        Navigator.of(context).pop();
      }
    } on StorageException catch (e) {
      if (mounted) AppToast.show(context, message: e.message);
    } catch (_) {
      if (mounted) {
        AppToast.show(context, message: "couldn't save entry. try again");
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final heroTag = widget.entry == null ? 'main_entry_hero_card' : null;

    Widget bodyContent = Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (!_isEditing) ...[
            if (!_showCategories)
              GestureDetector(
                onTap: _startPrompt,
                child: Text(
                  "I don't know what to write",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              )
            else ...[
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  for (final c in PromptCategory.values)
                    GestureDetector(
                      // Tapping the selected word again goes back to "any".
                      onTap: () => _pick(_category == c ? null : c),
                      child: Text(
                        c.label,
                        style: TextStyle(
                          color: _category == c
                              ? colors.onSurface
                              : colors.onSurfaceVariant,
                          fontWeight: _category == c
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                ],
              ),
              if (_prompt != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TypewriterText(
                          key: ValueKey(_prompt!.text),
                          text: _prompt!.text,
                          style: theme.textTheme.titleMedium,
                          textDirection: directionOf(_prompt!.text),
                          textAlign: isRtl(_prompt!.text)
                              ? TextAlign.right
                              : TextAlign.left,
                          durationPerChar: kTypewriterDurationPerChar,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.shuffle),
                        tooltip: 'shuffle prompt',
                        onPressed: () => _pick(_category),
                      ),
                    ],
                  ),
                ),
            ],
            const SizedBox(height: 8),
          ],
          Expanded(
            child: TextField(
              controller: _controller,
              autofocus: true,
              maxLines: null,
              expands: true,
              textDirection: _direction,
              textAlign: _direction == TextDirection.rtl
                  ? TextAlign.right
                  : TextAlign.left,
              textAlignVertical: TextAlignVertical.top,
              decoration: const InputDecoration(
                hintText: "What's on your mind?",
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );

    if (heroTag != null) {
      bodyContent = Hero(
        tag: heroTag,
        child: Material(
          color: theme.scaffoldBackgroundColor,
          child: bodyContent,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'save entry',
            onPressed: _saveEntry,
          ),
        ],
      ),
      body: bodyContent,
    );
  }
}