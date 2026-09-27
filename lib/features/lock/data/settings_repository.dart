import 'package:hive_flutter/hive_flutter.dart';

class SettingsRepository {
  SettingsRepository(this._box);
  final Box _box;

  static const _hapticsKey = 'hapticsEnabled';
  static const _themeModeKey = 'themeMode';

  bool get hapticsEnabled => _box.get(_hapticsKey, defaultValue: true);
  Future<void> setHapticsEnabled(bool value) => _box.put(_hapticsKey, value);

  String get themeModeName => _box.get(_themeModeKey, defaultValue: 'system');
  Future<void> setThemeModeName(String value) => _box.put(_themeModeKey, value);
}