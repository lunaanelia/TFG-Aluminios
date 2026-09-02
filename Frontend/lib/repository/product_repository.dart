import 'package:aluminios/models/habitacion.dart';
import 'package:aluminios/models/producto.dart';
import '../services/product_service.dart';

class ProductRepository {
  final ProductService _productService = ProductService();


  Future<List<Producto>> getProducts() async {
    final productsJson = await _productService.getProducts();
    List<Producto> products = [];

    if (productsJson.isNotEmpty) {
      for (int i = 0; i < productsJson.length; i++) {
        products.add(Producto.fromJson(productsJson[i]));
      }
    }
    return products;
  }

  Future<Producto> getProductById(int productId) async {
    final response = await _productService.getProductById(productId);
    return Producto.fromJson(response);
  }


  Future<Producto?> updateProduct(
      int productId, {
        String? nombre,
        String? descripcion,
        double? precioBase,
        List<Caracteristica>? caracteristicas
      }) async {
    final resp = await _productService.updateProduct(
      productId,
      nombre: nombre,
      descripcion: descripcion,
      precioBase: precioBase,
      caracteristicas: caracteristicas,
    );

    return Producto.fromJson(resp);
  }

  Future<Producto?> createProduct(
      String nombre,
      String descripcion,
      double precioBase,
      List<Caracteristica> caracteristicas
      ) async {
    final res = await _productService.createProduct(
        nombre,
        descripcion,
        precioBase,
        caracteristicas,
    );
    return Producto.fromJson(res);
  }


  Future<List<Habitacion>> getHabitaciones() async{
    final res = await _productService.getHabitaciones();
    List<Habitacion> habitaciones = [];

    if (res.isNotEmpty) {
      for (int i = 0; i < res.length; i++) {
        habitaciones.add(Habitacion.fromJson(res[i]));
      }
    }
    return habitaciones;
  }

  Future<void> deleteProducto(int id)async{
    await _productService.deleteProducto(id);
  }

  Future<void> deleteHabitacion(int id)async{
    await _productService.deleteHabitacion(id);
  }

  Future<Habitacion> createHabitacion(String nombre)async{
    final res = await _productService.createHabitacion(nombre);
    return Habitacion.fromJson(res);
  }


}