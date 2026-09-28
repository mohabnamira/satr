import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:satr/core/constants/app_constants.dart';
import 'package:satr/core/theme/app_theme.dart';
import 'package:satr/core/utils/greeting.dart';
import 'package:satr/core/utils/storage_exception.dart';
import 'package:satr/core/widgets/app_toast.dart';
import 'package:satr/features/entry/application/journal_providers.dart';
import 'package:satr/features/entry/presentation/entry_view_screen.dart';
import 'package:satr/features/entry/presentation/new_entry_screen.dart';
import 'package:satr/features/history/presentation/history_widgets.dart';
import 'package:satr/features/home/application/search_providers.dart';
import 'package:satr/features/prompts/application/prompt_providers.dart';
import 'package:satr/features/settings/presentation/settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _searching = false;
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  late final String greeting;

  @override
  void initState() {
    super.initState();
    greeting = pickGreeting();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _searching = !_searching;
      if (_searching) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _searchFocusNode.requestFocus();
        });
      } else {
        _searchFocusNode.unfocus();
        _searchController.clear();
        ref.read(searchQueryProvider.notifier).state = '';
      }
    });
  }

  void _openEditor({bool withPrompt = false}) {
    final prompt =
        withPrompt ? ref.read(promptRepositoryProvider).randomPrompt() : null;
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration:
            disableAnimations ? Duration.zero : kRouteTransitionDuration,
        reverseTransitionDuration:
            disableAnimations ? Duration.zero : kReverseRouteTransitionDuration,
        pageBuilder: (context, animation, secondaryAnimation) {
          return NewEntryScreen(initialPrompt: prompt);
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          if (disableAnimations) return child;
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOutCubic,
            ),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final entriesAsync = ref.watch(filteredEntriesProvider);
    final query = ref.watch(searchQueryProvider);
    final disableAnimations = MediaQuery.disableAnimationsOf(context);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: kHorizontalPadding),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    SizedBox(
                      height: kMinInteractiveDimension,
                      child: AnimatedCrossFade(
                        duration: disableAnimations
                            ? Duration.zero
                            : kCrossfadeDuration,
                        firstCurve: Curves.easeInOutCubic,
                        secondCurve: Curves.easeInOutCubic,
                        sizeCurve: Curves.easeInOutCubic,
                        crossFadeState: _searching
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        firstChild: Row(
                          children: [
                            Expanded(
                              child: Text(
                                greeting,
                                style: theme.textTheme.headlineMedium,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.search),
                              tooltip: 'search',
                              onPressed: _toggleSearch,
                            ),
                            IconButton(
                              icon: const Icon(Icons.settings_outlined),
                              tooltip: 'settings',
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const SettingsScreen(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        secondChild: Container(
                          height: kMinInteractiveDimension,
                          decoration: BoxDecoration(
                            color: colors.surfaceContainer,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: colors.outlineVariant.withValues(alpha: 0.5),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Row(
                            children: [
                              Icon(Icons.search,
                                  size: 20, color: colors.onSurfaceVariant),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  focusNode: _searchFocusNode,
                                  style: theme.textTheme.bodyLarge,
                                  onChanged: (value) => ref
                                      .read(searchQueryProvider.notifier)
                                      .state = value,
                                  decoration: InputDecoration(
                                    hintText: 'search entries...',
                                    hintStyle: TextStyle(
                                        color: colors.onSurfaceVariant),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding:
                                        const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 20),
                                tooltip: 'close',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: _toggleSearch,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    Hero(
                      tag: 'main_entry_hero_card',
                      child: Material(
                        color: colors.surfaceContainer,
                        borderRadius: BorderRadius.circular(kRadiusCard),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(kRadiusCard),
                          onTap: _openEditor,
                          child: Container(
                            width: double.infinity,
                            height: 160,
                            padding: const EdgeInsets.all(20),
                            alignment: Alignment.topLeft,
                            child: Text(
                              "What's on your mind today?",
                              style: theme.textTheme.titleLarge,
                            ),
                          ),
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
                              color: AppTheme.swipeDeleteBackground,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: const Icon(
                              Icons.delete_outline,
                              color: AppTheme.swipeDeleteIcon,
                            ),
                          ),
                          onDismissed: (_) async {
                            final repository =
                                ref.read(journalRepositoryProvider);
                            try {
                              await repository.deleteEntry(entry.id);
                              if (context.mounted) {
                                AppToast.showUndo(
                                  context,
                                  message: 'entry deleted',
                                  onUndo: () async {
                                    try {
                                      await repository.restoreEntry(entry);
                                    } on StorageException catch (e) {
                                      if (context.mounted) {
                                        AppToast.show(context, message: e.message);
                                      }
                                    } catch (_) {
                                      if (context.mounted) {
                                        AppToast.show(
                                          context,
                                          message: "couldn't restore entry. try again",
                                        );
                                      }
                                    }
                                  },
                                );
                              }
                            } on StorageException catch (e) {
                              if (context.mounted) {
                                AppToast.show(context, message: e.message);
                              }
                            } catch (_) {
                              if (context.mounted) {
                                AppToast.show(
                                  context,
                                  message: "couldn't delete entry. try again",
                                );
                              }
                            }
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
                child: SizedBox.shrink(),
              ),
              error: (err, stack) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "couldn't load your entries",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => ref.invalidate(journalEntriesProvider),
                          child: const Text('retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}