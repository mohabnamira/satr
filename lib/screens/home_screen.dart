import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/journal_providers.dart';
import 'new_entry_screen.dart';
import '../features/prompts/application/prompt_providers.dart';
import '../features/history/presentation/history_widgets.dart';
import 'entry_view_screen.dart';
import 'package:satr/core/greeting.dart';
import 'package:satr/core/widgets/undo_toast.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {

  bool _searching = false;
  final _searchController = TextEditingController();
  late final String greeting;

  @override
  void initState() {
    super.initState();
    greeting = pickGreeting();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() => _searching = !_searching);
    if (!_searching) {

      _searchController.clear();
      ref.read(searchQueryProvider.notifier).state = '';
    }
  }


  void _openEditor({bool withPrompt = false}) {
    final prompt =
        withPrompt ? ref.read(promptRepositoryProvider).randomPrompt() : null;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => NewEntryScreen(initialPrompt: prompt)),
    );
  }

  String formatDate(DateTime date) {
    final now = DateTime.now();
    final isToday = date.year == now.year && date.month == now.month && date.day == now.day;

    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday =
        date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day;

    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    final time = '$hour:$minute $period';

    if (isToday) return 'Today, $time';
    if (isYesterday) return 'Yesterday, $time';
    return '${date.day}/${date.month}/${date.year}, $time';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final entriesAsync = ref.watch(filteredEntriesProvider);
    final query = ref.watch(searchQueryProvider);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _searching
                              ? TextField(
                                  controller: _searchController,
                                  autofocus: true,
                                  onChanged: (value) => ref
                                      .read(searchQueryProvider.notifier)
                                      .state = value,
                                  decoration: const InputDecoration(
                                    hintText: 'Search entries',
                                    border: InputBorder.none,
                                  ),
                                )
                                : Text(greeting,
                                  style: theme.textTheme.headlineMedium),
                        ),
                        IconButton(
                          icon: Icon(_searching ? Icons.close : Icons.search),
                          tooltip: _searching ? 'Close search' : 'Search',
                          onPressed: _toggleSearch,
                        ),

                        IconButton(
                          icon: const Icon(Icons.settings_outlined),
                          tooltip: 'Settings',
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const SettingsScreen()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    Material(
                      color: colors.surfaceContainer,
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: _openEditor,
                        child: Container(
                          width: double.infinity,
                          height: 160,
                          padding: const EdgeInsets.all(20),
                          alignment: Alignment.topLeft,
                          child: Text("What's on your mind today?",
                              style: theme.textTheme.titleLarge),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton(
                        onPressed: () => _openEditor(withPrompt: true),
                        child: Text("I don't know",
                            style: TextStyle(color: colors.onSurfaceVariant)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('History', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),


            entriesAsync.when(
              data: (entries) {
                if (entries.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      child: Center(
                        child: Text(
                          query.isEmpty ? 'nothing recorded yet.' : 'no results',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                    ),
                  );
                }
                return SliverList.builder(
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    final previous = index > 0 ? entries[index - 1] : null;
                    final showDivider = previous == null ||
                        !isSameDay(previous.createdAt, entry.createdAt);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (showDivider) DateDivider(date: entry.createdAt),
                        Dismissible(
                          key: ValueKey(entry.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            margin: const EdgeInsets.symmetric(vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A1A),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: const Icon(Icons.delete_outline,
                                color: Color(0xFFC62828)),
                          ),
                          onDismissed: (_) async {
                            final repository =
                                ref.read(journalRepositoryProvider);

                            final overlayState = Overlay.of(context);

                            await repository.deleteEntry(entry.id);

                            showUndoToast(
                              overlayState,
                              message: 'entry deleted',
                              onUndo: () => repository.restoreEntry(entry),
                            );
                          },
                          child: HistoryEntryCard(
                            entry: entry,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => EntryViewScreen(entry: entry),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
              loading: () => const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator())),
              error: (err, stack) =>
                  SliverToBoxAdapter(child: Center(child: Text('Error: $err'))),
            ),
          ],
        ),
      ),
    );
  }
}