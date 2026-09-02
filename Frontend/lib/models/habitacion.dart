class Habitacion{
  int ? id;
  String ? nombre;


  Habitacion({
    this.id,
    this.nombre
  });


  factory Habitacion.fromJson(Map<String, dynamic> json) {
    return Habitacion(
        id: json["id"] ?? 0,

        nombre: json["nombre"],
    );
  }


  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "nombre": nombre
    };
  }
}