import 'package:aluminios/utils/mensajes.dart';

(bool, String) checkPassword(String password){
  bool result = true;
  String mensaje = "";

  if (!RegExp(r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d).{8,}$').hasMatch(password)) {
    result = false;
    mensaje = passwordInvalida;
  }

  return (result, mensaje);
}

(bool, String) checkEmail(String email){
  bool result = true;
  String mensaje = "";

  if (!RegExp(r'^\w+([.-_+]?\w+)*@\w+([.-]?\w+)*(\.\w{2,10})+$',).hasMatch(email)){
    result = false;
    mensaje = correoInvalido;
  }

  return (result, mensaje);
}

(bool, String) checkTelefono(String telefono){
  bool result = true;
  String mensaje = "";

  String telefonoSin = telefono.replaceAll(' ', '');

  if (!RegExp(r'^\d{9}$').hasMatch(telefonoSin)){
    result = false;
    mensaje = telefonoInvalido;
  }

  return (result, mensaje);
}
