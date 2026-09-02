import 'package:aluminios/utils/tipos.dart';

class Proyecto{

  final int id;
  final int presupuestoId;

  EstadoProyecto estado;
  final String metodoPago;
  String ? estadoPago;

  double ?  latitud;
  double  ? longitud;

  String ? direccionObra;
  int ? numero;
  String ? detalles;
  String ? entrega;

  String ? nombre;

  double ? fianza;

  int ? cita;

  DateTime ? fechaConfirmacion;
  DateTime ? fechaLimite;



  Proyecto({
    required this.id,
    required this.presupuestoId,
    required this.estado,
    required this.estadoPago,
    required this.metodoPago,
    this.longitud,
    this.latitud,
    this.direccionObra,
    this.numero,
    this.detalles,
    this.entrega,
    this.nombre,
    this.fianza,
    this.cita,
    this.fechaConfirmacion,
    this.fechaLimite,
  });

  factory Proyecto.fromJson(Map<String, dynamic> json) {
    return Proyecto(
      id: json["id"],
      presupuestoId: json["presupuesto"],
      estado: EstadoProyecto.values.byName( json["estado"] ?? 'cliente'),
      metodoPago: json['metodo_pago'],
      estadoPago: json['estado_pago'] ?? '',
      latitud: double.tryParse(json['latitud'].toString()) ?? 0.0,
      longitud: double.tryParse(json['longitud'].toString()) ?? 0.0,
      direccionObra: json['direccion_obra'] ?? "",
      numero: int.tryParse(json['numero'].toString()) ?? 0,
      detalles: json["detalles"] ?? '',
      entrega: json['entrega'] ?? '',
      nombre: json['cliente_nombre'] ?? "Sin nombre",
      fianza: double.tryParse(json['fianza'].toString()) ?? 0,
      cita: json['cita'],
      fechaConfirmacion: json["fecha_confirmacion"] != null
          ? DateTime.parse(json["fecha_confirmacion"])
          : null,
      fechaLimite: json["fecha_limite_pago"] != null
          ? DateTime.parse(json["fecha_limite_pago"])
          : null,
    );}

  Map<String, dynamic> toJson() {
    return {

    };
  }
}