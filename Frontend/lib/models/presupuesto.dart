class OpcionSeleccionada {
  int id;
  int? opcionId;
  String caracteristicaNombre;
  String nombre;
  double precioExtra;
  bool ? opcionActiva;

  OpcionSeleccionada({
    required this.id,
    this.opcionId,
    required this.caracteristicaNombre,
    required this.nombre,
    required this.precioExtra,
    this.opcionActiva,
  });

  factory OpcionSeleccionada.fromJson(Map<String, dynamic> json) {
    return OpcionSeleccionada(
      id: json['id'],
      opcionId: json['opcion_id'],
      caracteristicaNombre: json['caracteristica_nombre'] ?? "sin",
      nombre: json["opcion_nombre"],
      precioExtra: json['precio_extra'] is String ? double.parse(json['precio_extra']) : (json['precio_extra'] as num).toDouble(),
      opcionActiva: json['opcion_activa'] ?? true,
    );
  }


  Map<String, dynamic> toJson() {
    return {
      "id": id,
    };
  }
}

class LineaPresupuesto{

  int ? id;
  int producto;
  String ? nombreProducto;
  bool ? productoActivo;
  int cantidad ;
  double ancho;
  double alto;
  double ? precioFinal;
  List<OpcionSeleccionada> opciones;
  bool ? requiereRevision;


  LineaPresupuesto({
    this.id,
    required this.producto,
    this.nombreProducto,
    this.productoActivo,
    this.requiereRevision,
    required this.cantidad,
    required this.ancho,
    required this.alto,
    this.precioFinal,
    required this.opciones,
  });

  factory LineaPresupuesto.fromJson(Map<String, dynamic> json) {
    return LineaPresupuesto(
      id: json["id"],
      producto: json['producto_id'],
      nombreProducto: json['producto_nombre'],
      productoActivo: json['producto_activo'] ?? true,
      cantidad: json['cantidad'],
      ancho: (json['ancho'] as num).toDouble(),
      alto: (json['alto'] as num).toDouble(),
      precioFinal: json['precio_final'] is String ? double.parse(json['precio_final']) : (json['precio_final'] as num).toDouble(),
      opciones: (json['opciones_seleccionadas'] as List?)
          ?.map((item) => OpcionSeleccionada.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
      requiereRevision: json["requiere_revision"] ?? false
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id" : id,
      "producto": producto,
      "cantidad" : cantidad,
      "ancho": ancho,
      'alto': alto,
      'opciones' : opciones.map((op)=> op.opcionId ?? op.id).toList()
    };
  }
}


class Presupuesto{

  int ? id;
  double ? total;
  List<LineaPresupuesto> lineas;
  bool ? requireRevision;
  String estadoPagado;
  double ?  fianza;

  Presupuesto({
    this.id,
    this.total,
    required this.lineas,
    this.requireRevision,
    required this.estadoPagado,
    this.fianza
  });

  factory Presupuesto.fromJson(Map<String, dynamic> json) {
    return Presupuesto(
      id: json["id"],
      total: json['total'] != null? double.tryParse(json['total'].toString()) : 0.0,
      requireRevision: json['requiere_revision'] ?? false,
      estadoPagado: json['estado_pagado'],
      fianza: json['total'] != null? double.tryParse(json['fianza'].toString()) : 0.0,
      lineas: (json['lineas'] as List?)
          ?.map((item) => LineaPresupuesto.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],);


  }

  Map<String, dynamic> toJson() {
    return {
      'lineas' : lineas.map((l)=> l.toJson()).toList()
    };
  }
}