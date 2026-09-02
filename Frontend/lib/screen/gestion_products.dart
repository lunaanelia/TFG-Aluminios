import 'package:aluminios/models/producto.dart';
import 'package:aluminios/repository/product_repository.dart';
import 'package:aluminios/widgets/banner_delete.dart';
import 'package:aluminios/widgets/need_login_widget.dart';
import 'package:aluminios/widgets/no_access_widget.dart';
import 'package:aluminios/widgets/menu_empresa.dart';
import 'package:flutter/material.dart';
import '../utils/toast_manager.dart';
import '../utils/tipos.dart';
import '../mixins/user_loader.dart';

class GestionProductsPage extends StatefulWidget {
  const GestionProductsPage({super.key});

  @override
  State<GestionProductsPage> createState() => _GestionProductsState();
}

class _GestionProductsState extends State<GestionProductsPage> with UserLoaderMixin{

  List <Producto> _allProducts = [];
  List <Producto> _foundProducts= [];
  
  final ProductRepository _productoRepository = ProductRepository();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _searchProduct(String enteredKeyword) {
    List<Producto> results = [];

    results = _allProducts;

    if (enteredKeyword.isNotEmpty) {

      results =
          _foundProducts.where((product) => product.nombre!.toLowerCase().contains(enteredKeyword.toLowerCase(),),).toList();
    }

    setState(() {
      _foundProducts = results;
    });
  }


  Future<void> _loadData() async {
    await loadCurrentUserData();
    if(userName == null){
      return;
    }
    try {

      _allProducts = await _productoRepository.getProducts();

      if (mounted) {
        setState(() {
          _foundProducts = _allProducts;
        });
      }
    } catch (e) {
      debugPrint("Get products error: $e");
    }
  }

  Future<void> _eliminarProdcuto(int id)async{
    try{
      await _productoRepository.deleteProducto(id);

      if (mounted){
        setState(() {
          _allProducts.removeWhere((p) => p.id == id);
          _foundProducts = _allProducts;
        });
        ToastManager.show(context, "Producto eliminado correctamente", success: true);
      }

    }catch(e){
      if (mounted) ToastManager.show(context, "Error $e", success: false);
    }
  }

  @override
  Widget build(BuildContext context){

    if (isLoadingUser){
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if(userName == null){
      return NeedLoginWidget();
    }

    return Scaffold(
      drawer: MenuEmpresa(current: PageKind.productos, rol: userRol!),
      body: LayoutBuilder(
          builder: (context, constraints) {
            bool esMovil = constraints.maxWidth < 700;
            double cardWidth = (constraints.maxWidth - 80 - 10) / 2;

            if(esMovil){
              cardWidth = constraints.maxWidth;
            }

            if(!isLoadingUser && userRol != UserType.jefe && userRol != UserType.administrativo){
              return const NoAccessWidget();
            }

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                  padding: esMovil
                      ? EdgeInsets.only(top:40, bottom: 20, left: 10, right: 10)
                      : EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          IconButton(
                              onPressed: () {
                                if (Scaffold.of(context).isDrawerOpen) {
                                  Navigator.pop(context);
                                } else {
                                  Scaffold.of(context).openDrawer();
                                }
                              },
                              icon: Icon(Icons.menu, color: Color(0xFF222B6F))
                          ),
                          Spacer(),
                          Text(
                            'GESTIÓN DE PRODUCTOS',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: esMovil ? 20 : 24,
                              color: Color(0xFF222B6F),
                            ),
                          ),
                          Spacer(),
                        ],
                      ),
                      SizedBox(height: 40,),
                      SizedBox(
                        width: double.infinity,
                        child: Wrap(

                          alignment: WrapAlignment.end,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 10,
                          runSpacing: 15,
                          children: [
                            SizedBox(
                              width: esMovil ? constraints.maxWidth : 300,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Expanded(child: Container(
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: TextField(
                                      onChanged: (value) => _searchProduct(value),
                                      decoration: InputDecoration(
                                        prefixIcon: Icon(
                                          Icons.search,
                                          size: 20,
                                          color: Colors.grey,
                                        ),
                                        hintText: 'Buscar producto ...',
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(
                                          vertical: 8,
                                          horizontal: 10,
                                        ),
                                        isDense: true,
                                      ),
                                    ),
                                  ),),
                                  IconButton(
                                    tooltip: 'Crear producto',
                                    iconSize: 30.0,
                                    icon: const Icon(Icons.add, color: Color(0xFF222B6F)),

                                    onPressed: () async {
                                      await Navigator.pushNamed(context, 'createProduct/');
                                    },
                                  ),
                                ],
                              ),
                            ),

                          ],
                        ),
                      ),

                      SizedBox(height: 40,),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        alignment: WrapAlignment.start,
                        children: _foundProducts.map((product) {
                          return SizedBox(
                            width: cardWidth,
                            child: Card(
                              elevation: 2,
                              child: ListTile(
                                title: Text("${product.nombre} ${product.precio}€/m²"),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      tooltip: 'Modificar Producto',
                                      icon: const Icon(Icons.edit_outlined, color: Color(0xFF222B6F)),
                                      onPressed: () {Navigator.pushNamed(context, 'modificateProduct/', arguments: product.id);
                                        },
                                    ),
                                    IconButton(
                                      tooltip: 'Eliminar',
                                      icon: const Icon(Icons.delete_outline_outlined, color: Colors.red),
                                      onPressed: () {
                                        mostrarDialogoConfirmacion(
                                          context: context,
                                          mensaje: "¿Estas seguro que quieres borrar este porducto?",
                                          id: product.id!,
                                          accionBorrar: (idParaBorrar) async {
                                            await _eliminarProdcuto(idParaBorrar);
                                          },
                                        );
                                        },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  )
              ),

            );

          }),
    );
  }
}