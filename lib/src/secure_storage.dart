import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import 'package:spottr_mobile/core/config/logger.dart';

class SecureStorage {
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
    //encryptedSharedPreferences: true
    aOptions: AndroidOptions(),
  );
  // Logger logger = Logger('SecureStorage');

  static Future<bool> has(String key) async {
    try {
      return await _storage.containsKey(key: key);
    } catch (e) {
      return false;
    }
  }

  static Future<void> set(String key, Object? value) async {
    return _storage.write(key: key, value: jsonEncode(value));
  }

  static Future<Object?> get(String key) async {
    final result = await _storage.read(key: key);
    return result == null ? null : jsonDecode(result);
  }

  static Future<void> remove(String key) async {
    return _storage.delete(key: key);
  }

  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  static Future<bool> containsKey(String key) async {
    return await _storage.containsKey(key: key);
  }
}
