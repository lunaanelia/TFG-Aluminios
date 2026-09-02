import 'package:aluminios/utils/tipos.dart';

class Cita {
  int id;
  DateTime fecha;
  String horaInicio;
  String horaFin;
  EstadoCita estado;
  int ? proyectoId;
  String ? clienteNombre;
  bool reservada;



  Cita({
    required this.id,
    required this.fecha,
    required this.horaInicio,
    required this.horaFin,
    required this.estado,
    this.proyectoId,
    this.clienteNombre,
    required this.reservada,
  });

  factory Cita.fromJson(Map<String, dynamic> json) {
    return Cita(
      id: json["id"] ?? 0,
      fecha: DateTime.parse(json["fecha"]),
      horaInicio: json['hora_inicio'],
      horaFin: json['hora_fin'],
      estado: EstadoCita.values.byName( json["estado"] ?? 'reservada'),
      proyectoId: json['proyecto_id'],
      clienteNombre: json['cliente_nombre'],
      reservada: json['reservada'],
    );
  }


  Map<String, dynamic> toJson() {
    return {
      "fecha" :
          "${fecha.year.toString().padLeft(4, '0')}-"
          "${fecha.month.toString().padLeft(2, '0')}-"
          "${fecha.day.toString().padLeft(2, '0')}",
      "hora_inicio": horaInicio,
      "hora_fin": horaFin,
    };
  }
}