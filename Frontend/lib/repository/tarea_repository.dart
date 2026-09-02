import 'package:aluminios/models/tiempo_tarea.dart';
import 'package:aluminios/services/tarea_service.dart';
import '../models/datos_envio.dart';
import '../models/tarea.dart';
import '../models/usuario.dart';

class TareaRepository {
  final TareaService _tareaService = TareaService();


  Future<List<Tarea>> getTarea() async {
    final List tareaJson = await _tareaService.getTareas();


    List<Tarea> tareas = [];

    if (tareaJson.isNotEmpty) {
      for (int i = 0; i < tareaJson.length; i++) {
        tareas.add(Tarea.fromJson(tareaJson[i]));
      }
    }

    return tareas;
  }

  Future<List<Tarea>> getTodasTarea() async {
    final List tareaJson = await _tareaService.getTodasTareas();


    List<Tarea> tareas = [];

    if (tareaJson.isNotEmpty) {
      for (int i = 0; i < tareaJson.length; i++) {
        tareas.add(Tarea.fromJson(tareaJson[i]));
      }
    }

    return tareas;
  }

  Future<Tarea> getTareaById(int tareaId) async {
    final response = await _tareaService.getTareasById(tareaId);
    return Tarea.fromJson(response);
  }


  Future<String?> iniciarTarea(int id) async {
    final res = await _tareaService.iniciarTarea(id);
    String est = res['estado'];
    return est;
  }

  Future<String?> terminarTarea(int id) async {
    final res = await _tareaService.terminarTarea(id);
    String est = res['estado'];
    return est;
  }

  Future<void> crearTarea(
      int tareaId,
      DateTime fechaInicio,
      DateTime fechaFin,
      List<Usuario> trabajadores
      ) async {

      await _tareaService.crearTarea(tareaId, fechaInicio, fechaFin, trabajadores);
  }

  Future<void> modificarTarea(
      int tareaId,
      int proyectoId,
      DateTime fechaInicio,
      DateTime fechaFin,
      List<Usuario> trabajadores
      ) async {

    await _tareaService.modificarTarea(tareaId, proyectoId, fechaInicio, fechaFin, trabajadores);
  }

  Future<void> deleteTareaMontaje (int id)async{
    await _tareaService.deleteTarea(id);
  }

  Future<DatosEnvio> getDatosEnvio(int tareaId) async {
    final res = await _tareaService.obtenerDatosEnvio(tareaId);
    return DatosEnvio.fromJson(res);
  }

  Future<List<TiempoTarea>> getTiempoTareas() async {
    final List tareaJson = await _tareaService.getTiempoTareas();


    List<TiempoTarea> tareas = [];

    if (tareaJson.isNotEmpty) {
      for (int i = 0; i < tareaJson.length; i++) {
        tareas.add(TiempoTarea.fromJson(tareaJson[i]));
      }
    }

    return tareas;
  }

  Future<void> updateTiempoTarea( int id, double duracion) async {
    await _tareaService.updateTiempoTarea(id, duracion);
  }
}