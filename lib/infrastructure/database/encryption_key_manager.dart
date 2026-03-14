import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EncryptionKeyManager {
  static const String _keyAlias = 'tazakar_db_key';

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  /// Returns existing key or generates and stores a new one.
  static Future<String> getOrCreateKey() async {
    final existing = await _storage.read(key: _keyAlias);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }
    final newKey = _generateSecureKey();
    await _storage.write(key: _keyAlias, value: newKey);
    return newKey;
  }

  /// Generates a cryptographically secure 256-bit hex key.
  static String _generateSecureKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
