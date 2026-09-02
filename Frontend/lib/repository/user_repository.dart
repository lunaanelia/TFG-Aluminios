import 'package:aluminios/models/horario.dart';
import '../services/usuario_service.dart';
import '../models/usuario.dart';

class UserRepository {
  final UsuarioService _userService = UsuarioService();

  Future<Usuario> getCurrentUser() async {
    final res = await _userService.getCurrentUser();
    return Usuario.fromJson(res);
  }

  Future<Usuario?> registerUser(
      String firstName,
      String lastName,
      String telefono,
      String email,
      String password,
      ) async {
    final res = await _userService.registerUser(
      firstName,
      lastName,
      telefono,
      email,
      password,
    );
    return Usuario.fromJson(res);
  }

  Future<Usuario?> createUser(
      String firstName,
      String lastName,
      String telefono,
      String email,
      String rol,
      List<DiaLaboral> horario
      ) async {
    final res = await _userService.createUser(
      firstName,
      lastName,
      telefono,
      email,
      rol,
      horario
    );
    return Usuario.fromJson(res);
  }

  Future<bool> invitarUser(int id) async {
    await _userService.invitarUser(id);
    return true;
  }


  Future<bool> resetPassword(String telefono) async {
    try{
      await _userService.resetPassword(telefono);
      return true;
    }
    catch(e){
      throw Exception("Error en confirmación de contraseña: $e");
    }

  }

  Future<List<Usuario>> getUsers() async {
    final usersJson = await _userService.getUsers();
    List<Usuario> users = [];

    if (usersJson.isNotEmpty) {
      for (int i = 0; i < usersJson.length; i++) {
        users.add(Usuario.fromJson(usersJson[i]));
      }
    }
    return users;
  }

  Future<Usuario?> updateUser(
      int userId, {
        String? name,
        String? apellidos,
        String? email,
        String? password,
        String? telefono,
        String? rol,
        List<DiaLaboral>? horario
      }) async {
    final resp = await _userService.updateUser(
      userId,
      name: name,
      apellidos: apellidos,
      email: email,
      password: password,
      telefono: telefono,
      rol: rol,
      horario: horario,
    );

    return Usuario.fromJson(resp);
  }

  Future<Usuario> getUserById(int userId) async {
    final response = await _userService.getUserById(userId);
    return Usuario.fromJson(response);
  }


  Future<String> delete (int userId) async{
    return await _userService.delete(userId);
  }

  Future<bool> logout () async{
    return await _userService.logout();
  }

}