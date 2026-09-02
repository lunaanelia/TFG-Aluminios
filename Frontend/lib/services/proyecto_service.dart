import 'api_client.dart';

class ProyectoService {
  final ApiClient _client = ApiClient();

  Future<List<dynamic>> getProyectos() async {
    return await _client.get("/api/proyectos", auth: true);
  }

  Future<List<dynamic>> getMisProyectos() async {
    return await _client.get("/api/proyectos?mios=true", auth: true);
  }

  Future<Map<String, dynamic>> getProyectoById(int proyectId) async {
    return await _client.get("/api/proyectos/$proyectId", auth: true);
  }

  Future<Map<String, dynamic>> createProyecto(
      int presupuestoId,
      String metodoPago,
      String dirObra,
      double lat,
      double lon,
      String numero,
      String detalles,
      String entrega,

      ) async {

    final payload = {
      "presupuesto_id": presupuestoId,
      "metodo_pago" : metodoPago,
      "direccion_obra" : dirObra,
      "latitud" : lat,
      "longitud" : lon,
      "numero" : numero,
      "detalles" : detalles,
      "entrega" : entrega
    };
    final res = await _client.post("/api/proyectos", payload, auth: true);
    return res;
  }

  Future<Map<String, dynamic>> pagoProyecto(int proyectoId) async {
    final Map<String, dynamic> payload = {};

    return await _client.post("/api/proyectos/$proyectoId/pagar_taller", payload, auth: true);
  }

  Future<Map<String, dynamic>> pagoOnlineProyecto(int proyectoId) async {
    final Map<String, dynamic> payload = {};

    return await _client.post("/api/proyectos/$proyectoId/crear_checkout", payload, auth: true);
  }

  Future<Map<String, dynamic>> confirmarProyecto(int proyectoId) async {
    final Map<String, dynamic> payload = {};

    return await _client.post("/api/proyectos/$proyectoId/confirmar", payload, auth: true);
  }

  Future<Map<String, dynamic>> pedirMateriales(int proyectoId) async {
    final Map<String, dynamic> payload = {};

    return await _client.post("/api/proyectos/$proyectoId/materiales_pedidos", payload, auth: true);
  }

  Future<Map<String, dynamic>> proyectoRecogido(int proyectoId) async {
    final Map<String, dynamic> payload = {};

    return await _client.post("/api/proyectos/$proyectoId/confirmar_recogida", payload, auth: true);
  }

  Future<Map<String, dynamic>> recibirMateriales(int proyectoId) async {
    final Map<String, dynamic> payload = {};

    return await _client.post("/api/proyectos/$proyectoId/materiales_recibidos", payload, auth: true);
  }

  Future<List<dynamic>> getTareasMontaje(int id) async {
    final res =  await _client.get("/api/proyectos/$id/tareas_montaje", auth: true);
    return res;
  }

  Future<Map<String, dynamic>> cancelarProyecto(int proyectoId) async {
    final Map<String, dynamic> payload = {};

    return await _client.post("/api/proyectos/$proyectoId/cancelar", payload, auth: true);
  }

}
