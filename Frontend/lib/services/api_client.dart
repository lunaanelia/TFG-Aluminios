import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import '../utils/toke_storage.dart';

class ApiClient {
  static const String baseUrl = "http://127.0.0.1:8000";
  //static const String baseUrl = "http://192.168.100.140:8000";
  //static const String baseUrl = "http://192.168.1.32:8000";

  final TokenStorage _tokenStorage = TokenStorage();

  Future<Map<String, dynamic>> post(
      String path,
      Map<String, dynamic> body, {
        bool auth = false,
      }) async {
    final token = auth ? await _tokenStorage.getToken() : null;

    final response = await http.post(
      Uri.parse("$baseUrl$path"),
      headers: {
        "Content-Type": "application/json",
        if (auth && token != null) "Authorization": "Token $token",
      },
      body: jsonEncode(body),
    );

    debugPrint(response.body);
    return _handleResponse(response);
  }

  Future<dynamic> get(String path, {bool auth = false}) async {
    final token = auth ? await _tokenStorage.getToken() : null;

    final response = await http.get(
      Uri.parse("$baseUrl$path"),
      headers: {
        "Content-Type": "application/json",
        if (auth && token != null) "Authorization": "Token $token",
      },
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> update(
      String path,
      Map<String, dynamic> body, {
        bool auth = false,
      }) async {
    final token = auth ? await _tokenStorage.getToken() : null;

    final response = await http.patch(
      Uri.parse("$baseUrl$path"),
      headers: {
        "Content-Type": "application/json",
        if (auth && token != null) "Authorization": "Token $token",
      },
      body: jsonEncode(body),
    );

    return _handleResponse(response);
  }

  Future<dynamic> put(
      String path,
      Map<String, dynamic> body, {
        bool auth = false,
      }) async {
    final token = auth ? await _tokenStorage.getToken() : null;

    final response = await http.put(
      Uri.parse("$baseUrl$path"),
      headers: {
        "Content-Type": "application/json",
        if (auth && token != null) "Authorization": "Token $token",
      },
      body: jsonEncode(body),
    );

    return _handleResponse(response);
  }


  Future<dynamic> delete(String path, {bool auth = false}) async {
    final token = auth ? await _tokenStorage.getToken() : null;

    final response = await http.delete(
      Uri.parse("$baseUrl$path"),
      headers: {
        "Content-Type": "application/json",
        if (auth && token != null) "Authorization": "Token $token",
      },
    );

    return _handleResponse(response);
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.statusCode == 204) {
        return <String, dynamic>{};
      }

      return jsonDecode(response.body);
    }


    if (response.statusCode >= 300 && response.statusCode < 400) {
      throw Exception("El servidor intentó una redirección (${response.statusCode})");
    }
    dynamic errores;

    try {
      errores = jsonDecode(response.body);
    } catch (_) {
      throw Exception(
          "Error desconocido (${response.statusCode})"
      );
    }

    switch (response.statusCode) {

      case 400:

        if (errores is Map) {
          List<String> mensajes = [];
          errores.forEach((key, value) {
            if (value is List) {
              mensajes.addAll(value.map((e) => e.toString()));
            } else {
              mensajes.add(value.toString());
            }
          });
          throw Exception(mensajes.join('\n'));
        }

        throw Exception(errores.toString());
      case 401:
        throw Exception("Sesión caducada");
      case 403:
        throw Exception("No tienes permisos");

      case 404:
         throw Exception("Recurso no encontrado");

      case 500:
         throw Exception("Error interno del servidor");

      default:
        throw Exception("Error crítico (${response.statusCode})");
      }
  }
}