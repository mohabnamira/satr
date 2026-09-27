import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'settings_repository.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(Hive.box('settings'));
});

final hapticsEnabledProvider = StateProvider<bool>((ref) {
  throw UnimplementedError('Override hapticsEnabledProvider in main.dart');
});

final themeModeProvider = StateProvider<ThemeMode>((ref) {
  throw UnimplementedError('Override themeModeProvider in main.dart');
});