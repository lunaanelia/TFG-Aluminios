import 'package:aluminios/models/proyecto.dart';
import 'package:aluminios/models/presupuesto.dart';

class DatosEnvio {
  final Proyecto proyecto;
  final Presupuesto presupuesto;

  DatosEnvio({
    required this.proyecto,
    required this.presupuesto,
  });

  factory DatosEnvio.fromJson(Map<String, dynamic> json) {
    return DatosEnvio(
      proyecto: Proyecto.fromJson(json['proyecto']),
      presupuesto: Presupuesto.fromJson(json['presupuesto']),
    );
  }
}