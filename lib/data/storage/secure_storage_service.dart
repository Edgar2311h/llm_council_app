import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants.dart';

/// Service for securely storing sensitive data like API keys.
/// Uses platform-native encryption (Keychain on iOS, EncryptedSharedPreferences on Android).
class SecureStorageService {
  SecureStorageService._();
  static final SecureStorageService instance = SecureStorageService._();

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  /// Save API key securely
  Future<void> saveApiKey(String apiKey) async {
    await _storage.write(key: StorageKeys.apiKey, value: apiKey);
  }

  /// Retrieve API key
  Future<String?> getApiKey() async {
    return await _storage.read(key: StorageKeys.apiKey);
  }

  /// Check if API key exists
  Future<bool> hasApiKey() async {
    final key = await getApiKey();
    return key != null && key.isNotEmpty;
  }

  /// Delete API key
  Future<void> deleteApiKey() async {
    await _storage.delete(key: StorageKeys.apiKey);
  }

  /// Save biometric preference
  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(
      key: StorageKeys.biometricEnabled,
      value: enabled.toString(),
    );
  }

  /// Get biometric preference
  Future<bool> isBiometricEnabled() async {
    final value = await _storage.read(key: StorageKeys.biometricEnabled);
    return value == 'true';
  }

  /// Save onboarding complete status
  Future<void> setOnboardingComplete(bool complete) async {
    await _storage.write(
      key: StorageKeys.onboardingComplete,
      value: complete.toString(),
    );
  }

  /// Check if onboarding is complete
  Future<bool> isOnboardingComplete() async {
    final value = await _storage.read(key: StorageKeys.onboardingComplete);
    return value == 'true';
  }

  /// Clear all secure storage
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
