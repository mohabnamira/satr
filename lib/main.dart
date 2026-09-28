import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:satr/app.dart';
import 'package:satr/core/constants/app_constants.dart';
import 'package:satr/features/entry/data/journal_entry.dart';
import 'package:satr/features/lock/application/lock_providers.dart';
import 'package:satr/features/lock/data/pin_repository.dart';
import 'package:satr/features/onboarding/application/onboarding_providers.dart';
import 'package:satr/features/settings/application/settings_providers.dart';
import 'package:satr/features/settings/data/settings_repository.dart';

Future<Box<T>> _openBoxWithRecovery<T>(String boxName) async {
  try {
    return await Hive.openBox<T>(boxName);
  } catch (e, stack) {
    debugPrint('Hive.openBox("$boxName") failed: $e\n$stack. Attempting recovery...');
    try {
      await Hive.deleteBoxFromDisk(boxName);
      return await Hive.openBox<T>(boxName);
    } catch (e2, stack2) {
      debugPrint('Hive recovery for "$boxName" failed: $e2\n$stack2');
      rethrow;
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(JournalEntryAdapter());
    }
    await _openBoxWithRecovery<JournalEntry>(kJournalEntriesBox);
    final settingsBox = await _openBoxWithRecovery(kSettingsBox);

    final hasPin = await PinRepository().hasPin();
    final settingsRepo = SettingsRepository(settingsBox);
    final isFirstLaunch = settingsRepo.isFirstLaunch;

    runApp(
      ProviderScope(
        overrides: [
          unlockedProvider.overrideWith((ref) => !hasPin),
          isFirstLaunchProvider.overrideWith((ref) => isFirstLaunch),
          settingsRepositoryProvider.overrideWithValue(settingsRepo),
        ],
        child: const SatrApp(),
      ),
    );
  } catch (e, stack) {
    debugPrint('Fatal initialization error: $e\n$stack');
    runApp(
      const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(
                child: Text(
                  "satr couldn't initialize local storage. please restart the app.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, height: 1.4),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}