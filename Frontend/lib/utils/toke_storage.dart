import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  TokenStorage._internal();

  static final TokenStorage _instance = TokenStorage._internal();

  factory TokenStorage() => _instance;

  final _storage = const FlutterSecureStorage();

  Future<void> saveToken(String token) async {
    await _storage.write(key: "token", value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: "token");
  }

  Future<void> clearToken() async {
    await _storage.delete(key: "token");
  }
}