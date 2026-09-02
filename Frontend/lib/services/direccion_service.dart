import 'api_client.dart';

class DireccionService {
  final ApiClient _client = ApiClient();

  Future<List<dynamic>> buscarDirecciones(String query) async {

    if (query.isEmpty) {
      return [];
    }

    final response = await _client.get("/api/buscar-direccion/?q=$query");

    return response;
  }

}

