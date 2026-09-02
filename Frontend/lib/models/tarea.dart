import 'package:aluminios/models/presupuesto.dart';
import 'package:aluminios/utils/tipos.dart';

class Tarea{

  final int id;
  final int proyectoId;
  final LineaPresupuesto? linea;
  TipoTarea tipo;
  String estado;
  String ? trabajador;
  DateTime? fechaInicio;
  DateTime? fechaFin;
  String? direccionObra;
  List<String>? trabajadoresNombres;
  List<int>? trabajadoresIds;
  bool ? bloqueada;

  Tarea({
    required this.id,
    required this.proyectoId,
    this.linea,
    required this.tipo,
    required this.estado,
    this.trabajador,
    this.fechaInicio,
    this.fechaFin,
    this.direccionObra,
    this.trabajadoresNombres,
    this.trabajadoresIds,
    this.bloqueada,
  });

  factory Tarea.fromJson(Map<String, dynamic> json) {
    return Tarea(
        id: json["id"],
        proyectoId:int.parse(json["proyecto_id"].toString()),
        linea: json['linea'] != null ? LineaPresupuesto.fromJson( json["linea"]) : null,
        tipo: TipoTarea.values.byName(json["tipo"]),
        estado: json["estado"],
        trabajador: json["trabajador_nombre"] ?? "Sin asignar",
      fechaInicio: DateTime.parse(
          json["fecha_inicio"] ?? json["fecha_inicio_estimada"] ?? DateTime.now().toIso8601String()
      ),
      fechaFin: DateTime.parse(
          json["fecha_fin"] ?? json["fecha_fin_estimada"] ?? DateTime.now().toIso8601String()
      ),
      direccionObra: json['direccion_obra'],
      bloqueada: json['bloqueada'] ?? false,
      trabajadoresNombres: json['trabajadores_nombres'] != null
          ? List<String>.from(json['trabajadores_nombres'])
          : null,
      trabajadoresIds: json['trabajadores_ids'] != null
          ? List<int>.from(json['trabajadores_ids'])
          : null,
    );}

  Map<String, dynamic> toJson() {
    return {

    };
  }
}