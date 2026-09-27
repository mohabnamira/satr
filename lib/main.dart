import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:satr/features/lock/application/lock_providers.dart';
import 'package:satr/features/lock/data/pin_repository.dart';
import 'package:satr/features/lock/presentation/lock_gate.dart';
import 'models/journal_entry.dart';
import 'package:satr/core/theme/app_theme.dart';
import 'package:satr/data/settings_repository.dart';

final hapticsEnabledProvider = Provider<bool>((ref) => false);
final themeModeProvider = Provider<ThemeMode>((ref) => ThemeMode.system);
final isFirstLaunchProvider = StateProvider<bool>((ref) => true);
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(Hive.box('settings'));
});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(JournalEntryAdapter());
  await Hive.openBox<JournalEntry>('journalEntries');
  await Hive.openBox('settings');
  final hasPin = await PinRepository().hasPin();

  final settingsRepo = SettingsRepository(Hive.box('settings'));
  final hapticsEnabled = settingsRepo.hapticsEnabled;
  final themeModeName = settingsRepo.themeModeName;
  final isFirstLaunch = settingsRepo.isFirstLaunch;
  ThemeMode themeModeFromName(String name) {
    switch (name) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
  runApp(
    ProviderScope(
      overrides: [
        unlockedProvider.overrideWith((ref) => !hasPin),
        hapticsEnabledProvider.overrideWith((ref) => hapticsEnabled),
        themeModeProvider.overrideWith((ref) => themeModeFromName(themeModeName)),
        isFirstLaunchProvider.overrideWith((ref) => isFirstLaunch),
        settingsRepositoryProvider.overrideWithValue(settingsRepo),
      ],
      child: const SatrApp(),
    ),
  );
}

class SatrApp extends ConsumerWidget {
  const SatrApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'satr',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      home: const LockGate(),
    );
  }
}