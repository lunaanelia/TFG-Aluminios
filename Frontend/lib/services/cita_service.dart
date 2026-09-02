import 'api_client.dart';
import 'package:intl/intl.dart';

class CitaService {
  final ApiClient _client = ApiClient();

  Future<List<dynamic>> getCitas() async {
    return await _client.get("/api/citas", auth: true);
  }

  Future<Map<String, dynamic>> getCitaById(int citaId) async {
    return await _client.get("/api/citas/$citaId", auth: true);
  }

  Future<Map<String, dynamic>> updateCita(
      int citaId, {
        DateTime ? fecha,
        String ? horaInicio,
        String ? horaFin,
      }) async {
    final payload = {
      if (fecha!= null) "fecha": DateFormat('yyyy-MM-dd').format(fecha),
      if (horaInicio != null) "hora_inicio": horaInicio,
      if (horaFin != null) "hora_fin": horaFin,
    };

    return await _client.update("/api/citas/$citaId", payload, auth: true);
  }

  Future<Map<String, dynamic>> createCita(
      DateTime fecha,
      String horaInicio,
      String horaFin,
      ) async {

    final String fechaFormateada = DateFormat('yyyy-MM-dd').format(fecha);

    final payload = {
      "fecha": fechaFormateada,
      "hora_inicio": horaInicio,
      "hora_fin": horaFin,
    };
    final res = await _client.post("/api/citas", payload, auth: true);

    return res;
  }


  Future<bool> deleteCita(int id) async {
    await _client.delete( "/api/citas/$id", auth: true,);
    return true;
  }

  Future<Map<String, dynamic>> reservarCita(
      int citaId,
      int proyectoId
      ) async {

    final payload = {
      "proyecto_id": proyectoId,
    };

    return await _client.post("/api/citas/$citaId/reservar", payload, auth: true);
  }

  Future<Map<String, dynamic>> cancelarCita(int citaId) async {
    final Map<String, dynamic> payload = {};
    return await _client.post("/api/citas/$citaId/cancelar", payload, auth: true);
  }

  Future<Map<String, dynamic>> getDiasCancelacion() async {
    return await _client.get("/api/dias-cancelacion/", auth: true);
  }

  Future<Map<String, dynamic>> upadateDiasCancelacion(int nuevos) async {
    final payload = {
      "dias_cancelacion_cita": nuevos,
    };
    return await _client.put("/api/dias-cancelacion/", payload, auth: true);
  }

}
