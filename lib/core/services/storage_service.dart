import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  final _storage = const FlutterSecureStorage();

  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';

  Future<void> saveAuth(String token, String userId) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _userIdKey, value: userId);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<String?> getUserId() async {
    return await _storage.read(key: _userIdKey);
  }

  Future<void> clear() async {
    await _storage.deleteAll();
  }
}
