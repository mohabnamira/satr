import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:satr/core/constants/app_constants.dart';

class PinStorageException implements Exception {
  const PinStorageException(this.message);
  final String message;

  @override
  String toString() => message;
}

class PinRepository {
  final _storage = const FlutterSecureStorage();

  Future<bool> hasPin() async {
    try {
      final pin = await _storage.read(key: kPinStorageKey);
      return pin != null && pin.isNotEmpty;
    } catch (e, stack) {
      debugPrint('PinRepository.hasPin failed: $e\n$stack');
      return false;
    }
  }

  Future<void> setPin(String pin) async {
    try {
      await _storage.write(key: kPinStorageKey, value: pin);
    } catch (e, stack) {
      debugPrint('PinRepository.setPin failed: $e\n$stack');
      throw const PinStorageException("couldn't save your pin. please try again");
    }
  }

  Future<bool> verify(String pin) async {
    try {
      final stored = await _storage.read(key: kPinStorageKey);
      return stored == pin;
    } catch (e, stack) {
      debugPrint('PinRepository.verify failed: $e\n$stack');
      throw const PinStorageException("couldn't check your pin. please try again");
    }
  }

  Future<void> clearPin() async {
    try {
      await _storage.delete(key: kPinStorageKey);
    } catch (e, stack) {
      debugPrint('PinRepository.clearPin failed: $e\n$stack');
      throw const PinStorageException("couldn't remove your pin. please try again");
    }
  }
}