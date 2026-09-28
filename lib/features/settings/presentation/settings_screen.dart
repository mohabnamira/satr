import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:satr/core/constants/app_constants.dart';
import 'package:satr/core/theme/app_theme.dart';
import 'package:satr/core/utils/storage_exception.dart';
import 'package:satr/core/widgets/app_toast.dart';
import 'package:satr/features/entry/application/journal_providers.dart';
import 'package:satr/features/lock/application/lock_providers.dart';
import 'package:satr/features/lock/data/pin_repository.dart';
import 'package:satr/features/lock/presentation/pin_setup.dart';
import 'package:satr/features/settings/data/data_transfer_service.dart';
import 'package:satr/features/settings/presentation/widgets/settings_section.dart';
import 'package:satr/features/settings/presentation/widgets/settings_tile.dart';
import 'package:share_plus/share_plus.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool? _hasPin;
  PackageInfo? _packageInfo;
  final _dataTransferService = const DataTransferService();

  @override
  void initState() {
    super.initState();
    _loadHasPin();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) setState(() => _packageInfo = info);
    } catch (e) {
      debugPrint('SettingsScreen._loadPackageInfo failed: $e');
    }
  }

  Future<void> _loadHasPin() async {
    try {
      final value = await ref.read(pinRepositoryProvider).hasPin();
      if (mounted) setState(() => _hasPin = value);
    } catch (e) {
      debugPrint('SettingsScreen._loadHasPin failed: $e');
      if (mounted) setState(() => _hasPin = false);
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
          title: const Text('remove pin lock?'),
          content: const Text("you'll no longer need a pin to open satr."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('remove'),
            ),
          ],
        ),
      );
      if (confirmed == true) {
        try {
          await repo.clearPin();
          if (mounted) {
            AppToast.show(context, message: 'pin removed');
          }
        } on PinStorageException catch (e) {
          if (mounted) AppToast.show(context, message: e.message);
        } catch (_) {
          if (mounted) {
            AppToast.show(context, message: "couldn't remove your pin. please try again");
          }
        }
      }
    }
    await _loadHasPin();
  }

  Future<void> _changePin() async {
    final repo = ref.read(pinRepositoryProvider);
    await setPin(context, repo);
    await _loadHasPin();
  }

  Future<void> _exportEntries(BuildContext tileContext) async {
    final entries = ref.read(journalRepositoryProvider).getAllEntries();
    if (entries.isEmpty) {
      if (mounted) AppToast.show(context, message: 'nothing to export');
      return;
    }

    final RenderBox? box = tileContext.findRenderObject() as RenderBox?;
    final Rect? origin =
        box != null && box.hasSize ? box.localToGlobal(Offset.zero) & box.size : null;

    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(kRadiusBottomSheet),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'export entries',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              SettingsTile(
                title: 'json backup',
                subtitle: 'can be imported back into satr',
                leading: const Icon(Icons.data_object_outlined),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _performExport(
                    isJson: true,
                    entries: entries,
                    shareOrigin: origin,
                  );
                },
              ),
              SettingsTile(
                title: 'plain text',
                subtitle: "readable anywhere, can't be imported",
                leading: const Icon(Icons.description_outlined),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _performExport(
                    isJson: false,
                    entries: entries,
                    shareOrigin: origin,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _performExport({
    required bool isJson,
    required List entries,
    Rect? shareOrigin,
  }) async {
    File? tempFile;
    try {
      final now = DateTime.now();
      final dateStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final extension = isJson ? 'json' : 'txt';
      final fileName = 'satr-export-$dateStr.$extension';

      final content = isJson
          ? _dataTransferService.exportToJson(
              ref.read(journalRepositoryProvider).getAllEntries(),
              now: now,
            )
          : _dataTransferService.exportToPlainText(
              ref.read(journalRepositoryProvider).getAllEntries(),
            );

      final tempDir = await getTemporaryDirectory();
      tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsString(content, flush: true);

      final xFile = XFile(
        tempFile.path,
        mimeType: isJson ? 'application/json' : 'text/plain',
        name: fileName,
      );

      await SharePlus.instance.share(
        ShareParams(
          files: [xFile],
          sharePositionOrigin: shareOrigin,
        ),
      );
    } catch (e) {
      debugPrint('SettingsScreen._performExport failed: $e');
      if (mounted) {
        AppToast.show(context, message: "couldn't export entries");
      }
    } finally {
      if (tempFile != null && await tempFile.exists()) {
        try {
          await tempFile.delete();
        } catch (_) {}
      }
    }
  }

  Future<void> _importEntries() async {
    try {
      final result = await FilePickerPlatform.instance.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['json'],
      );

      if (result.isEmpty) {
        return;
      }

      final file = result.first;
      final filePath = file.path;
      if (filePath == null) {
        if (mounted) {
          AppToast.show(context, message: "couldn't read that file");
        }
        return;
      }

      final ioFile = File(filePath);
      if (!await ioFile.exists()) {
        if (mounted) {
          AppToast.show(context, message: "couldn't read that file");
        }
        return;
      }

      final size = await ioFile.length();
      if (size > kMaxImportBytes) {
        if (mounted) {
          AppToast.show(context, message: "couldn't read that file");
        }
        return;
      }

      final jsonString = await ioFile.readAsString();

      final repo = ref.read(journalRepositoryProvider);
      final currentEntries = repo.getAllEntries();
      final currentIds = currentEntries.map((e) => e.id).toSet();

      final analysis = _dataTransferService.parseJsonBackup(
        jsonString,
        existingIds: currentIds,
      );

      if (analysis.hasError) {
        if (mounted) {
          AppToast.show(
            context,
            message: analysis.errorMessage ?? "couldn't read that file",
          );
        }
        return;
      }

      if (!analysis.hasImportableEntries) {
        if (mounted) {
          AppToast.show(context, message: 'nothing to import');
        }
        return;
      }

      if (!mounted) return;

      final n = analysis.entriesToImport.length;
      final d = analysis.duplicateCount;

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(n == 1 ? 'import 1 entry?' : 'import $n entries?'),
          content: Text(
            d > 0
                ? 'existing entries are never overwritten. $d already on this device will be skipped.'
                : 'existing entries are never overwritten.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('import'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      final entriesMap = {
        for (final entry in analysis.entriesToImport) entry.id: entry,
      };

      await repo.putAllEntries(entriesMap);

      if (mounted) {
        final message = d > 0
            ? 'imported $n ${n == 1 ? 'entry' : 'entries'} · $d already existed'
            : 'imported $n ${n == 1 ? 'entry' : 'entries'}';
        AppToast.show(context, message: message);
      }
    } catch (e) {
      debugPrint('SettingsScreen._importEntries failed: $e');
      if (mounted) {
        AppToast.show(context, message: "couldn't read that file");
      }
    }
  }

  Future<void> _clearAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('clear all data?'),
        content: const Text(
          "this permanently deletes every journal entry on this device. your pin and preferences are kept. this can't be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'clear',
              style: TextStyle(color: AppTheme.dangerRed),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(journalRepositoryProvider).clearAllEntries();
      if (mounted) {
        AppToast.show(context, message: 'all entries deleted');
      }
    } on StorageException catch (e) {
      if (mounted) AppToast.show(context, message: e.message);
    } catch (_) {
      if (mounted) {
        AppToast.show(context, message: "couldn't clear entries. try again");
      }
    }
  }

  void _showPrivacyPolicy() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(kRadiusBottomSheet),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  'privacy policy',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                _privacyParagraph(
                  'satr is offline-first. everything you write stays on this device.',
                ),
                _privacyParagraph(
                  'your entries live in a local database on your phone. there are no accounts, no servers and no analytics.',
                ),
                _privacyParagraph(
                  'satr never sends your entries anywhere. they only leave your device when you choose to export them.',
                ),
                _privacyParagraph(
                  "your pin is kept in your device's secure storage (keychain on ios, keystore on android), separate from your entries. the pin controls access to the app; it does not encrypt your entries on disk.",
                ),
                _privacyParagraph(
                  "if you uninstall satr or clear all data, your entries can't be recovered unless you exported a backup first.",
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _privacyParagraph(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final hasPin = _hasPin;
    final pinReady = hasPin != null;
    final isPinSet = hasPin == true;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: kHorizontalPadding,
            vertical: 16,
          ),
          children: [
            Row(
              children: [
                SizedBox(
                  width: kMinInteractiveDimension,
                  height: kMinInteractiveDimension,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    tooltip: 'back',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'settings',
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 24),

            // Section 1: Security & Privacy
            SettingsSection(
              title: 'security & privacy',
              children: [
                SettingsTile(
                  title: 'pin lock',
                  subtitle: 'require a pin to open satr',
                  enabled: pinReady,
                  trailing: Switch(
                    value: isPinSet,
                    onChanged: pinReady ? _togglePin : null,
                  ),
                  onTap: pinReady ? () => _togglePin(!isPinSet) : null,
                ),
                SettingsTile(
                  title: 'change pin',
                  enabled: pinReady && isPinSet,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: (pinReady && isPinSet) ? _changePin : null,
                ),
              ],
            ),

            // Section 2: Data & Storage
            SettingsSection(
              title: 'data & storage',
              children: [
                Builder(
                  builder: (tileContext) => SettingsTile(
                    title: 'export entries',
                    leading: const Icon(Icons.upload_outlined),
                    onTap: () => _exportEntries(tileContext),
                  ),
                ),
                SettingsTile(
                  title: 'import entries',
                  leading: const Icon(Icons.download_outlined),
                  onTap: _importEntries,
                ),
                SettingsTile(
                  title: 'clear all data',
                  destructive: true,
                  leading: const Icon(Icons.delete_outline),
                  onTap: _clearAllData,
                ),
              ],
            ),

            // Section 3: About & Legal
            SettingsSection(
              title: 'about & legal',
              children: [
                SettingsTile(
                  title: 'privacy policy',
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _showPrivacyPolicy,
                ),
                SettingsTile(
                  title: 'version',
                  enabled: false,
                  trailing: Text(
                    _packageInfo?.version ?? '1.0.0',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}