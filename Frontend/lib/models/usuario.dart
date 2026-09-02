import 'package:aluminios/models/horario.dart';

class Usuario {
  int ? id;
  String ? telefono;
  String ? firstName;
  String ? lastName;
  String ? email;
  String ? rol;
  List<DiaLaboral>? horario;
  bool ? pendiente;


  Usuario({
    this.id,
    this.telefono,
    this.email,
    this.rol,
    this.firstName,
    this.lastName,
    this.horario,
    this.pendiente
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json["id"] ?? 0,
      telefono: (json["telefono"] ?? json["telefono"] ?? "").toString(),
      email: (json["email"] ?? "").toString(),
      rol: (json["rol"] ?? "cliente").toString(),
      firstName: (json["first_name"] ?? "").toString(),
      lastName: (json["last_name"] ?? "").toString(),
      horario: json['horario'] != null && json['horario'] is List
          ? (json['horario'] as List).map((d) => DiaLaboral.fromJson(d)).toList()
          : [],
      pendiente: json['password_pendiente']
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "telefono": telefono,
      "email": email,
      "horario": horario?.map((d)=>d.toJson()).toList() ?? [],
      "rol": rol,
      "first_name":firstName,
      "last_name":lastName,
      "password_pendiente" : pendiente
    };
  }
}