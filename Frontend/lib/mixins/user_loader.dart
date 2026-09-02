import 'package:aluminios/models/horario.dart';
import 'package:flutter/material.dart';
import '../models/usuario.dart';
import '../repository/user_repository.dart';
import '../utils/tipos.dart';

class UserSession{
  static Usuario? usuario;
}

mixin UserLoaderMixin<T extends StatefulWidget> on State<T> {
  final UserRepository _userRepository = UserRepository();

  UserType? userRol;
  int? userId;
  String ? userName;
  String ? userApellidos;
  String ? userTelf;
  String ? userEmail;
  List<DiaLaboral>? userHorario;

  bool isLoadingUser = true;
  bool esLogued = false;

  Future<void> loadCurrentUserData({bool forceRefresh = false}) async {
    if (UserSession.usuario == null || forceRefresh){
      try {
        Usuario user = await _userRepository.getCurrentUser();
        if (mounted) {
          setState(() {
            UserSession.usuario = user;
            isLoadingUser = false;
            esLogued = true;
          });
        }
      } catch (e) {
        debugPrint("Error cargando usuario: $e");
        if (mounted) {
          setState(() => isLoadingUser = false);
        }
      }
    }

    setState(() {
      userRol = UserType.values.byName(UserSession.usuario!.rol ?? 'cliente');
      userId = UserSession.usuario!.id;
      userName = UserSession.usuario!.firstName;
      userApellidos = UserSession.usuario!.lastName;
      userTelf = UserSession.usuario!.telefono;
      userEmail = UserSession.usuario!.email;
      userHorario = UserSession.usuario!.horario;
      isLoadingUser = false;

      debugPrint("$userId, $userName, $userApellidos, $userTelf");
    });
  }
}