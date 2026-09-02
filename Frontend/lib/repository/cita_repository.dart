import 'package:aluminios/models/cita.dart';
import '../services/cita_service.dart';

class CitaRepository {
  final CitaService _citaService = CitaService();


  Future<List<Cita>> getCita() async {
    final citaJson = await _citaService.getCitas();

    List<Cita> citas= [];

    if (citaJson.isNotEmpty) {
      for (int i = 0; i < citaJson.length; i++) {
        citas.add(Cita.fromJson(citaJson[i]));
      }
    }

    return citas;
  }

  Future<Cita> getCitaById(int citaId) async {
    final response = await _citaService.getCitaById(citaId);
    return Cita.fromJson(response);
  }


  Future<Cita?> createCita(DateTime fecha, String horaIni, String horaFin) async {
    final res = await _citaService.createCita(fecha, horaIni, horaFin);
    return Cita.fromJson(res);
  }

  Future<Cita?> updateCita(
      int citaId, {
        DateTime ? fecha,
        String ? horaInicio,
        String ? horaFin,
      }) async {
    final resp = await _citaService.updateCita(
      citaId,
      fecha: fecha,
      horaInicio: horaInicio,
      horaFin: horaFin,
    );

    return Cita.fromJson(resp);
  }

  Future<void> deleteCita(int id) async {
    await _citaService.deleteCita(id);

  }

  Future<void> reservarCita(int id, int proyectoId) async {
    await _citaService.reservarCita(id, proyectoId);

  }

  Future<void> cancelarCita(int id) async {
    await _citaService.cancelarCita(id);

  }

  Future<int> getDiasCancelacion() async {
    final res = await _citaService.getDiasCancelacion();
   int dias = res["dias_cancelacion_cita"] ?? 0.0;

    return dias;
  }

  Future<int> updateDiasCancelacion(int nueva) async {
    final res = await _citaService.upadateDiasCancelacion(nueva);
    int dias = res["dias_cancelacion_cita"] ?? 0.0;

    return dias;
  }

}