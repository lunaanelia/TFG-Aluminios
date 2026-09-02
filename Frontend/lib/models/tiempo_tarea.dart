import 'package:aluminios/utils/tipos.dart';

class TiempoTarea {
  final TipoTarea proceso;
  double tiempoEstimadoHoras;
  final int id;



  TiempoTarea({
    required this.proceso,
    required this.tiempoEstimadoHoras,
    required this.id,
  });

  factory TiempoTarea.fromJson(Map<String, dynamic> json) {
    return TiempoTarea(
      proceso: TipoTarea.values.byName(json['proceso']),
      tiempoEstimadoHoras: (json['tiempo_estimado_horas'] as num).toDouble(),
      id: json['id']
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'proceso': proceso.name,
      'tiempo_estimado_horas': tiempoEstimadoHoras,
    };
  }
}