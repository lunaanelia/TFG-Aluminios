import 'package:aluminios/mixins/user_loader.dart';
import 'package:aluminios/models/horario.dart';
import 'package:flutter/cupertino.dart';
import 'api_client.dart';
import '../utils/toke_storage.dart';

class UsuarioService {
  late ApiClient _client;
  late TokenStorage _storage;

  UsuarioService({ApiClient? apiClient}) {
    _client = apiClient ?? ApiClient();
    _storage = TokenStorage();
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    return await _client.get("/api/usuarios/current/", auth: true);
  }

  Future<Map<String, dynamic>> registerUser(
      String firstName,
      String lastName,
      String telefono,
      String email,
      String password,
      ) async {

    final payload = {
      "first_name": firstName,
      "last_name": lastName,
      "telefono": telefono,
      "email": email,
      "password": password,
    };

    return await _client.post("/api/auth/register/", payload);
  }

  Future<Map<String, dynamic>> createUser(
      String firstName,
      String lastName,
      String telefono,
      String email,
      String rol,
      List<DiaLaboral> horario
      ) async {

    final payload = {
      "first_name": firstName,
      "last_name": lastName,
      "telefono": telefono,
      "email": email,
      "rol": rol,
      "horario": horario.map((d)=> d.toJson()).toList(),
    };

    return await _client.post("/api/admin/invitar-usuario/", payload, auth: true);
  }

  Future<Map<String, dynamic>> invitarUser(int userId) async {

    final payload = {
      "id": userId,
    };

    return await _client.post("/api/admin/reenviar-invitacion/", payload, auth: true);
  }

  Future<Map<String, dynamic>> resetPassword(String telefono) async {

    final payload = {
      "telefono": telefono,
    };

    final res = await _client.post("/api/auth/reset-password/", payload);
    return res;
  }

  Future<List<dynamic>> getUsers() async {
    final res = await _client.get("/api/usuarios", auth: true);
    return res as List<dynamic>;
  }

  Future<Map<String, dynamic>> getUserById(int userId) async {
    return await _client.get("/api/usuarios/$userId", auth: true);
  }

  Future<Map<String, dynamic>> updateUser(
      int userId, {
        String? name,
        String ? apellidos,
        String? email,
        String? password,
        String? telefono,
        String? rol,
        List<DiaLaboral>? horario
      }) async {
    final payload = {
      if (name != null) "first_name": name,
      if (apellidos != null) "last_name": apellidos,
      if (email != null) "email": email,
      if (password != null) "password": password,
      if (telefono != null) "telefono": telefono,
      if (rol != null) "rol": rol,
      if(horario != null) "horario": horario.map((d)=> d.toJson()).toList()
    };

    debugPrint("Payload enviado a Django: $payload");
    debugPrint("Payload enviado a Django: $payload");

    return await _client.update("/api/usuarios/$userId", payload, auth: true);
  }

  Future<String> delete(int id)async{
    final res = await _client.delete("/api/usuarios/$id", auth: true);
    return res['mensaje'];
  }

  Future <bool> logout() async{
    bool resultado = false;
    final Map<String, dynamic> payload = {};
    try{
      await _client.post("/api/auth/logout/", payload, auth: true);
      resultado = true;
    }catch(e){
      resultado = false;
    }
    await _storage.clearToken();
    UserSession.usuario = null;
    return resultado;
  }
}
