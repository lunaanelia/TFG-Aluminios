import 'package:aluminios/models/presupuesto.dart';
import 'package:flutter/cupertino.dart';
import 'api_client.dart';

class PresupuestoService {
  final ApiClient _client = ApiClient();

  Future<List<dynamic>> getPresupuestos() async {
    return await _client.get("/api/presupuestos", auth: true);
  }

  Future<Map<String, dynamic>> getPresupuestoById(int productId) async {
    return await _client.get("/api/presupuestos/$productId", auth: true);
  }

  Future<List<dynamic>> getPresupuestosConfirmados() async {
    return await _client.get("/api/presupuestos/confirmados", auth: true);
  }

  Future<Map<String, dynamic>> updatePresupuesto(
      int presupuestoId, {
        List<LineaPresupuesto> ? lineas,

      }) async {
    final payload = {
      if (lineas != null) "lineas": lineas.map((d)=> d.toJson()).toList(),
    };

    debugPrint("Payload enviado a Django: $payload");

    final res = await _client.update("/api/presupuestos/$presupuestoId", payload, auth: true);

    debugPrint("Payload recibido de Django: $res");

    return res;
  }

  Future<Map<String, dynamic>> createPresupuesto(
      List<LineaPresupuesto> lineas,
      ) async {

    final payload = {
      "lineas": lineas.map((d)=> d.toJson()).toList(),
    };

    return await _client.post("/api/presupuestos", payload, auth: true);
  }


  Future<Map<String, dynamic>> getOpcionesEntrega(double lat, double lon) async {
    return await _client.get( "/api/opciones-entrega/?lat=$lat&lon=$lon", auth: true);
  }

  Future<bool> deletePresupuesto(int id) async {
    await _client.delete( "/api/presupuestos/$id", auth: true,);
    return true;
  }


  Future<Map<String, dynamic>> limpiarPresupuesto(int id) async {

    final Map<String, dynamic> payload = {};
    return await _client.post("/api/presupuestos/$id/limpiar_descatalogados", payload,  auth: true);
  }


  Future<Map<String, dynamic>> getDistancia() async {
    return await _client.get("/api/distancia/", auth: true);
  }

  Future<Map<String, dynamic>> upadateDistancia(double nuevaDistancia) async {
    final payload = {
      "distancia_maxima": nuevaDistancia,
    };
    return await _client.put("/api/distancia/", payload, auth: true);
  }

  Future<Map<String, dynamic>> getFianza() async {
    return await _client.get("/api/fianza/", auth: true);
  }

  Future<Map<String, dynamic>> upadateFianza(double nueva) async {
    final payload = {
      "porcentaje": nueva,
    };
    return await _client.put("/api/fianza/", payload, auth: true);
  }


}
