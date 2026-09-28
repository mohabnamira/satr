import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:satr/core/constants/app_constants.dart';
import 'package:satr/core/utils/storage_exception.dart';

class SettingsRepository {
  SettingsRepository(this._box);

  final Box _box;

  bool get isFirstLaunch {
    try {
      return _box.get(kIsFirstLaunchKey, defaultValue: true) as bool? ?? true;
    } catch (e, stack) {
      debugPrint('SettingsRepository.isFirstLaunch failed: $e\n$stack');
      return true;
    }
  }

  Future<void> setFirstLaunch(bool value) async {
    try {
      await _box.put(kIsFirstLaunchKey, value);
    } catch (e, stack) {
      debugPrint('SettingsRepository.setFirstLaunch failed: $e\n$stack');
      throw const StorageException("couldn't save preference. try again");
    }
  }
}