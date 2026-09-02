import 'package:aluminios/models/producto.dart';
import 'package:flutter/cupertino.dart';
import 'api_client.dart';

class ProductService {
  final ApiClient _client = ApiClient();

  Future<List<dynamic>> getProducts() async {
    return await _client.get("/api/productos", auth: true);
  }

  Future<Map<String, dynamic>> getProductById(int productId) async {
    return await _client.get("/api/productos/$productId", auth: true);
  }

  Future<Map<String, dynamic>> updateProduct(
      int productId, {
        String? nombre,
        String ? descripcion,
        double ? precioBase,
        List<Caracteristica> ? caracteristicas,

      }) async {
    final payload = {
      if (nombre!= null) "nombre": nombre,
      if (descripcion != null) "descripcion": descripcion,
      if (precioBase != null) "precio_base": precioBase,
      if (caracteristicas != null) "caracteristicas": caracteristicas.map((d)=> d.toJson()).toList(),
    };

    debugPrint("Payload enviado a Django: $payload");

    return await _client.update("/api/productos/$productId", payload, auth: true);
  }

  Future<Map<String, dynamic>> createProduct(
      String nombre,
      String descripcion,
      double precioBase,
      List<Caracteristica> caracterisiticas,
      ) async {

    final payload = {
      "nombre": nombre,
      "descripcion": descripcion,
      "precio_base": precioBase,
      "caracteristicas": caracterisiticas.map((d)=> d.toJson()).toList(),
    };

    return await _client.post("/api/productos", payload, auth: true);
  }

  Future<List<dynamic>> getHabitaciones() async {
     return await _client.get( "/api/habitaciones", auth: true);
  }

  Future<bool> deleteProducto(int id) async {
    await _client.delete( "/api/productos/$id", auth: true,);
    return true;
  }

  Future<Map<String, dynamic>> createHabitacion( String nombre) async {
    final payload = {
      "nombre": nombre,
    };
    return await _client.post( "/api/habitaciones", payload, auth: true);
  }

  Future<void> deleteHabitacion( int id) async {
    await _client.delete( "/api/habitaciones/$id", auth: true);
  }
}
