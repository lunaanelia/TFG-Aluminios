import '../repository/user_repository.dart';
import '../services/auth_services.dart';
import '../models/usuario.dart';

class AuthRepository {
  final AuthService _authService = AuthService();
  final UserRepository _userRepository = UserRepository();

  Future<Usuario> login(
      String telefono,
      String password
      ) async {
    final res = await _authService.login(telefono, password);

    if(res["token"] == null) {
      throw Exception("Login failed: no token recieved");
    }

    Usuario user = await _userRepository.getCurrentUser();

    return user;
  }

  Future<bool> confirmarPassword(
      String uid,
      String token,
      String password) async {
     try{
        await _authService.confirmarPassword(uid, token, password);
        return true;
     }
     catch(e){
       throw Exception("Error en confirmación de contraseña: $e");
     }

  }
}