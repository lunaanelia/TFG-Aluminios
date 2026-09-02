class Opcion {
  int ? id;
  String ? nombre;
  String ? descripcion;
  double ? precioExtra;
  bool ? active;
  List<int> habitacionesRecomendadas;

  Opcion({
    this.id,
    this.nombre,
    this.descripcion,
    this.precioExtra,
    this.active,
    List<int>? habitacionesRecomendadas,
  }) : this.habitacionesRecomendadas = habitacionesRecomendadas ?? [];


  factory Opcion.fromJson(Map<String, dynamic> json) {
    return Opcion(
        id: json["id"] ?? 0,
        nombre: json['nombre'],
        descripcion: json['decripcion'] ?? '',
        precioExtra: json['precio_extra'] != null
            ? double.tryParse(json['precio_extra'].toString()) ?? 0.0
            : 0.0,
        active: json['activo'],
        habitacionesRecomendadas: json['habitaciones_recomendadas_data'] != null
            ? List<int>.from(
            json['habitaciones_recomendadas_data']
                .map((x) => int.parse(x.toString()))
        )
            : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "nombre": nombre,
      "descripcion": descripcion ?? "",
      "precio_extra": precioExtra,
      "activo" : active,
      "habitaciones_recomendadas" : habitacionesRecomendadas,
    };
  }
}

class Recomendacion{
  int ? id;
  int ? habitacion;
  String ? habitacionNombre;
  int ? opcion;
  String ? opcionNombre;
  int ? carateristica;
  String ? carateristicaNombre;

  Recomendacion({
    this.id,
    this.habitacion,
    this.habitacionNombre,
    this.opcion,
    this.opcionNombre,
    this.carateristica,
    this.carateristicaNombre,

  });

  factory Recomendacion.fromJson(Map<String, dynamic> json) {
    return Recomendacion(
      id: json["id"] ?? 0,
     habitacion: json['habitacion'],
      habitacionNombre: json['habitacion_nombre'] ?? '',
      opcion: json['opcion'],
      opcionNombre: json['opcion_nombre'] ?? '',
      carateristica: json['carateristica'],
      carateristicaNombre: json['carateristica_nombre'] ?? '',


    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "habitacion": habitacion,
      "habitacion_nombre": habitacionNombre,
      "opcion": opcion,
      "opcion_nombre" : opcionNombre,
      "carateristica" : carateristica,
      "carateristica_nombre": carateristicaNombre
    };
  }
}

class Caracteristica {
  int ? id;
  String ? nombre;
  bool ? active;
  List<Opcion> ? opciones;

  Caracteristica({
    this.id,
    this.nombre,
    this.active,
    this.opciones
  });

  factory Caracteristica.fromJson(Map<String, dynamic> json) {
    return Caracteristica(
        id: json["id"] ?? 0,
        nombre: json['nombre'],
        active: json['activo'],
        opciones: (json['opciones'] != null)
            ? (json['opciones'] as List).map((o) => Opcion.fromJson(o)).toList()
            : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "nombre": nombre,
      "activo" : active,
      "opciones" : opciones?.map((d)=>d.toJson()).toList() ?? [],
    };
  }
}

class Producto {
  int ? id;
  String ? nombre;
  String ? descripcion;
  double ? precio;
  List<Caracteristica> ? caracteristicas;
  bool ? activo;

  Producto({
    this.id,
    this.nombre,
    this.descripcion,
    this.precio,
    this.caracteristicas,
    this.activo
  });

  factory Producto.fromJson(Map<String, dynamic> json) {

    return Producto(
        id: json["id"] ?? 0,
        nombre: json['nombre'],
        descripcion: json['descripcion'] ?? "",
        precio: json['precio_base'] != null
            ? double.tryParse(json['precio_base'].toString()) ?? 0.0
            : 0.0,

        caracteristicas: json['caracteristicas'] != null && json['caracteristicas'] is List
            ? (json['caracteristicas'] as List).map((c) => Caracteristica.fromJson(c)).toList()
            : [],
        activo: json['is_active']
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "nombre": nombre,
      "descripcion": descripcion,
      "precio_base": precio,
      "caracteristicas": caracteristicas?.map((d)=>d.toJson()).toList(),
      "activo" : activo
    };
  }
}