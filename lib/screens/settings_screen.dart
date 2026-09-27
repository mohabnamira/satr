import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/lock/application/lock_providers.dart';
import '../features/lock/presentation/pin_setup.dart';
import '../data/journal_providers.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool? _hasPin;
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    _loadHasPin();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) setState(() => _packageInfo = info);
  }

  Future<void> _loadHasPin() async {
    final value = await ref.read(pinRepositoryProvider).hasPin();
    if (mounted) setState(() => _hasPin = value);
  }

  Future<void> _clearAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear all data?'),
        content: const Text(
          'This permanently deletes every journal entry. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Clear',
                style: TextStyle(color: Color(0xFFC62828))),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref.read(journalRepositoryProvider).clearAllEntries();
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('All entries deleted')));
    }
  }

  Future<void> _togglePin(bool enable) async {
    final repo = ref.read(pinRepositoryProvider);
    if (enable) {
      await setPin(context, repo);
    } else {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Remove PIN lock?'),
          content: const Text("You'll no longer need a PIN to open the app."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Remove'),
            ),
          ],
        ),
      );
      if (confirmed == true) await repo.clearPin();
    }
    await _loadHasPin();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: 8),
              Text('Settings', style: theme.textTheme.headlineMedium),
              const SizedBox(height: 24),
              if (_hasPin == null)
                const Center(child: CircularProgressIndicator())
              else ...[
                Row(
                  children: [
                    Expanded(
                      child: Text('PIN lock', style: theme.textTheme.bodyLarge),
                    ),
                    Switch(value: _hasPin!, onChanged: _togglePin),
                  ],
                ),
                if (_hasPin!) ...[
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () async {
                      await setPin(context, ref.read(pinRepositoryProvider));
                      await _loadHasPin();
                    },
                    child: Text(
                      'Change PIN',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: colors.onSurfaceVariant),
                    ),
                  ),
                ],
                Divider(height: 32, color: colors.outlineVariant),
                GestureDetector(
                  onTap: _clearAllData,
                  child: Row(
                    children: [
                      Icon(Icons.delete_forever_outlined,
                          color: const Color(0xFFC62828), size: 20),
                      const SizedBox(width: 12),
                      Text(
                        'Clear all data',
                        style: theme.textTheme.bodyLarge
                            ?.copyWith(color: const Color(0xFFC62828)),
                      ),
                    ],
                  ),
                ),
                Divider(height: 32, color: colors.outlineVariant),
                Row(
                  children: [
                    Text('Version', style: theme.textTheme.bodyLarge),
                    const Spacer(),
                    Text(
                      _packageInfo == null
                          ? '...'
                          : '${_packageInfo!.version}+${_packageInfo!.buildNumber}',
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}