import 'package:aluminios/models/tarea.dart';
import 'package:aluminios/utils/tipos.dart';
import '../models/proyecto.dart';
import '../services/proyecto_service.dart';

class ProyectoRepository {
  final ProyectoService _proyectoService = ProyectoService();


  Future<List<Proyecto>> getProyectos(bool mios) async {
    final List proJson;

    if (mios){
      proJson = await _proyectoService.getMisProyectos();
    }else{
      proJson = await _proyectoService.getProyectos();
    }

    List<Proyecto> proyectos= [];

    if (proJson.isNotEmpty) {
      for (int i = 0; i < proJson.length; i++) {
        proyectos.add(Proyecto.fromJson(proJson[i]));
      }
    }

    return proyectos;
  }

  Future<Proyecto> getProyectoById(int proyectoId) async {
    final response = await _proyectoService.getProyectoById(proyectoId);
    return Proyecto.fromJson(response);
  }


  Future<Proyecto?> createProyecto(int id, String metodo, String dirObra, double lat, double lon, String num, String detalles, String entrega) async {
    final res = await _proyectoService.createProyecto( id, metodo, dirObra, lat, lon, num, detalles, entrega );
    return Proyecto.fromJson(res);
  }

  Future<EstadoProyecto?> pagoProyecto(int id) async {
    final res = await _proyectoService.pagoProyecto(id);
    EstadoProyecto est = EstadoProyecto.values.byName( res["estado"] ?? 'pendiente_pago');

    return est;
  }

  Future<String> pagoOnlineProyecto(int id) async {
    final res = await _proyectoService.pagoOnlineProyecto(id);
    final url = res['checkout_url'];
    return url;
  }


  Future<EstadoProyecto?> confirmarProyecto(int id) async {
    final res = await _proyectoService.confirmarProyecto(id);
    EstadoProyecto est = EstadoProyecto.values.byName( res["estado"] ?? 'pendiente_pago');

    return est;
  }

  Future<EstadoProyecto?> pedirMateriales(int id) async {
    final res = await _proyectoService.pedirMateriales(id);
    EstadoProyecto est = EstadoProyecto.values.byName( res["estado"] ?? 'pendiente_pago');

    return est;
  }

  Future<EstadoProyecto?> recibirMateriales(int id) async {
    final res = await _proyectoService.recibirMateriales(id);
    EstadoProyecto est = EstadoProyecto.values.byName( res["estado"] ?? 'pendiente_pago');

    return est;
  }

  Future<EstadoProyecto?> proyectoRecogido(int id) async {
    final res = await _proyectoService.proyectoRecogido(id);
    EstadoProyecto est = EstadoProyecto.values.byName( res["estado"] ?? 'pendiente_pago');

    return est;
  }

  Future<List<Tarea>> getTareasMontar(int id) async {
    final tareasJson = await _proyectoService.getTareasMontaje(id);
    List<Tarea> tareas= [];

    if (tareasJson.isNotEmpty) {
      for (int i = 0; i < tareasJson.length; i++) {
        tareas.add(Tarea.fromJson(tareasJson[i]));
      }
    }
    
    return tareas;
  }

  Future<EstadoProyecto?> cancelarProyecto(int id) async {
    final res = await _proyectoService.cancelarProyecto(id);
    EstadoProyecto est = EstadoProyecto.values.byName( res["estado"] ?? 'pendiente_pago');

    return est;
  }

}