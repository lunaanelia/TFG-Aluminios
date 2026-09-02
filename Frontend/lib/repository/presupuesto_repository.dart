import 'package:aluminios/models/opciones_entrega.dart';
import 'package:aluminios/models/presupuesto.dart';
import '../services/presupuesto_service.dart';

class PresupuestoRepository{
  final PresupuestoService _presupuestoService = PresupuestoService();


  Future<List<Presupuesto>> getPresupuestos() async {
    final presupuestosJson = await _presupuestoService.getPresupuestos();
    List<Presupuesto> presupuestos= [];

    if (presupuestosJson.isNotEmpty) {
      for (int i = 0; i < presupuestosJson.length; i++) {
        presupuestos.add(Presupuesto.fromJson(presupuestosJson[i]));
      }
    }
    return presupuestos;
  }

  Future<List<Presupuesto>> getPresupuestosConfirmados() async {
    final presupuestosJson = await _presupuestoService.getPresupuestosConfirmados();
    List<Presupuesto> presupuestos= [];

    if (presupuestosJson.isNotEmpty) {
      for (int i = 0; i < presupuestosJson.length; i++) {
        presupuestos.add(Presupuesto.fromJson(presupuestosJson[i]));
      }
    }
    return presupuestos;
  }

  Future<Presupuesto> getPresupuestoById(int presupuestoId) async {
    final response = await _presupuestoService.getPresupuestoById(presupuestoId);
    return Presupuesto.fromJson(response);
  }


  Future<Presupuesto?> updatePresupuesto(
      int productId, {
        List<LineaPresupuesto> ? lineas,
      }) async {
    final resp = await _presupuestoService.updatePresupuesto(
      productId,
      lineas: lineas,
    );

    return Presupuesto.fromJson(resp);
  }

  Future<Presupuesto?> createPresupuesto(
      List<LineaPresupuesto> lineas,
      ) async {
    final res = await _presupuestoService.createPresupuesto(
      lineas
    );
    return Presupuesto.fromJson(res);
  }

  Future<List<OpcionEntrega>> getOpcionesEntrega(double lat, double lon) async {

    final res = await _presupuestoService.getOpcionesEntrega(lat, lon);

    List<OpcionEntrega> opEntrega = [];

    final opciones = res["opciones_disponibles"] as List<dynamic>;

    for (final item in opciones) {
     opEntrega.add(OpcionEntrega.fromJson(item));
    }

    return opEntrega;

  }

  Future<void> deletePresupuesto(int id)async{
    await _presupuestoService.deletePresupuesto(id);
  }

  Future<Presupuesto?> limpiaePresupuesto(int id) async {
    final res = await _presupuestoService.limpiarPresupuesto(id);
    return Presupuesto.fromJson(res);
  }

  Future<double> getDistancia() async {
    final res = await _presupuestoService.getDistancia();
    double distancia = res["distancia_maxima"] ?? 0.0;

    return distancia;
  }

  Future<double> updateDistancia(double nueva) async {
    final res = await _presupuestoService.upadateDistancia(nueva);
    double distancia = res["distancia_maxima"] ?? 0.0;

    return distancia;
  }

  Future<double> getFianza() async {
    final res = await _presupuestoService.getFianza();
    double porcentaje = res["porcentaje"] ?? 0.0;

    return porcentaje;
  }

  Future<double> updateFianza(double nueva) async {
    final res = await _presupuestoService.upadateFianza(nueva);
    double porcentaje = res["porcentaje"] ?? 0.0;

    return porcentaje;
  }

}