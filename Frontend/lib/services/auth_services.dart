import 'package:flutter/cupertino.dart';

import 'api_client.dart';
import '../utils/toke_storage.dart';


class AuthService {
  late ApiClient _client;

  AuthService({ApiClient? apiClient}) {
    _client = apiClient ?? ApiClient();
  }

  Future<Map<String, dynamic>> login(String telefono, String password) async {
    final payload = {
      "username": telefono,
      "password": password,

    };

    final res =  await _client.post("/api/auth/login/", payload);
    if (res.containsKey('token') && res['token'] != null) {
      String token = res['token'];
      debugPrint("Token recibido con éxito: $token");

      await TokenStorage().saveToken(token);
    } else {
      throw Exception("Respuesta inesperada de Django: $res");
    }
    return res;

  }


  Future<Map<String, dynamic>>  confirmarPassword(String uid, String token, String password) async {
    final payload = {
      "uid": uid,
      "token": token,
      "password": password,

    };

    final res =  await _client.post("/api/auth/confirmar-password/", payload);

    return res;

  }
}