import 'package:aluminios/services/direccion_service.dart';
import '../models/direccion.dart';

class DireccionRepository {
  final DireccionService _dirService = DireccionService();


  Future<List<Direccion>>buscarDirecciones(String query) async {
    final res = await _dirService.buscarDirecciones(query);

    List<Direccion> direcciones = [];

    if (res.isNotEmpty) {
      for (int i = 0; i < res.length; i++) {
        direcciones.add(Direccion.fromJson(res[i]));
      }
    }

    return direcciones;
  }
}