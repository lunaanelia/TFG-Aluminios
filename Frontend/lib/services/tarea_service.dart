import '../models/usuario.dart';
import 'api_client.dart';

class TareaService {
  final ApiClient _client = ApiClient();


  Future<List<dynamic>> getTareas() async {
    final res = await _client.get("/api/tareas", auth: true);
    return res;
  }
  Future<List<dynamic>> getTodasTareas() async {
    final res = await _client.get("/api/tareas/todas", auth: true);
    return res;
  }

  Future<Map<String, dynamic>> getTareasById(int id) async {
    return await _client.get("/api/tareas/$id", auth: true);
  }

  Future<Map<String, dynamic>> iniciarTarea(int id) async {
    final Map<String, dynamic> payload = {};

    return await _client.post("/api/tareas/$id/iniciar", payload, auth: true);
  }

  Future<Map<String, dynamic>> terminarTarea(int id) async {
    final Map<String, dynamic> payload = {};

    return await _client.post("/api/tareas/$id/terminar", payload, auth: true);
  }

  Future<void> crearTarea(
      int tareaId,
      DateTime fechaInicio,
      DateTime fechaFin,
      List<Usuario> trabajadores
      ) async {

    List<int> trabajadoresIds = trabajadores.map((u) => u.id!).toList();
    final double tiempoEstimadoHoras = fechaFin.difference(fechaInicio).inMinutes / 60.0;

    final payload = {
      "proyecto_id": tareaId,
      "fecha_inicio_estimada" : fechaInicio.toIso8601String(),
      "fecha_fin_estimada" :fechaFin.toIso8601String(),
      "trabajadores_ids": trabajadoresIds,
      "tiempo_estimado_horas": tiempoEstimadoHoras.toDouble()
    };
    await _client.post("/api/tareas/crear_montaje", payload, auth: true);
  }

  Future<void> modificarTarea(
      int tareaId,
      int proyectoId,
      DateTime fechaInicio,
      DateTime fechaFin,
      List<Usuario> trabajadores
      ) async {

    List<int> trabajadoresIds = trabajadores.map((u) => u.id!).toList();
    final double tiempoEstimadoHoras = fechaFin.difference(fechaInicio).inMinutes / 60.0;

    final payload = {
      "proyecto_id": proyectoId,
      "fecha_inicio_estimada" : fechaInicio.toIso8601String(),
      "fecha_fin_estimada" :fechaFin.toIso8601String(),
      "trabajadores_ids": trabajadoresIds,
      "tiempo_estimado_horas": tiempoEstimadoHoras.toDouble()
    };

      await _client.put("/api/tareas/$tareaId/modificar_montaje", payload, auth: true);
  }

  Future<bool> deleteTarea(int id) async {
    await _client.delete( "/api/tareas/$id", auth: true,);
    return true;
  }

  Future<Map<String, dynamic>> obtenerDatosEnvio(int tareaId) async {
    return await _client.get("/api/tareas/$tareaId/datos_envio", auth: true,);
  }

  Future<List<dynamic>> getTiempoTareas() async {
    final res = await _client.get("/api/tiempo-tareas", auth: true);
    return res;
  }


  Future<void> updateTiempoTarea(int tareaId, double duracion,) async {


    final payload = {
      "tiempo_estimado_horas": duracion,
    };

    await _client.update("/api/tiempo-tareas/$tareaId", payload, auth: true);

  }
}
