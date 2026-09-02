class Direccion{

  String nombre;
  double latitud ;
  double longitud;


  Direccion({
    required this.nombre,
    required this.latitud,
    required this.longitud
  });

  factory Direccion.fromJson(Map<String, dynamic> json) {
    return Direccion(
      nombre: json["display_name"],
      latitud: double.parse(json['lat']),
      longitud: double.parse(json['lon']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "display_name": nombre,
      "lat" : latitud,
      "lon": longitud
    };
  }
}