import 'package:aluminios/mixins/user_loader.dart';
import 'package:aluminios/mixins/utils_product.dart';
import 'package:aluminios/widgets/need_login_widget.dart';
import 'package:aluminios/widgets/no_access_widget.dart';
import 'package:aluminios/widgets/menu_empresa.dart';
import 'package:flutter/material.dart';
import '../utils/toast_manager.dart';
import '../utils/tipos.dart';

class ModificationProductPage extends StatefulWidget {
  final int? id;
  const ModificationProductPage({ super.key, this.id});

  @override
  State<ModificationProductPage> createState() => _ModificationProductState();
}

class _ModificationProductState extends State<ModificationProductPage> with UserLoaderMixin, ProductCommuns{
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _precioController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();

  bool isLoanding = true;

  int ? _id;
  bool _isIntialized = false;

  @override
  void didChangeDependencies(){
    super.didChangeDependencies();
    if(!_isIntialized){
      final receiveId = ModalRoute.of(context)!.settings.arguments;

      if(receiveId is int){
        _id = receiveId;
      }else{
        _id = -1;
      }
      _loadData();
      loadCurrentUserData();
      _isIntialized = true;
    }

  }

  void _loadData() async{
    await loadCurrentUserData();
    await loadHabitaciones();

    if(userName == null){
      setState(() {
        isLoanding = false;
      });
      return;
    }

    debugPrint("id del porducto $_id");
    if (_id! > -1){
      await _loadProduct();
    }else{
      addCaracteristica();
    }

    setState(() {
      isLoanding = false;
    });

  }

  Future<void> _loadProduct() async{

    try{
      final data = await productRepository.getProductById(_id!);
      debugPrint("DEBUG nombre porducto: ${data.nombre}");
      debugPrint("DEBUG descripcion porducto: ${data.descripcion}");
      debugPrint("DEBUG precio porducto: ${data.precio}");
      debugPrint("DEBUG caracterisiticas porducto: ${data.caracteristicas!.length}");
      if(mounted){
        setState(() {
          _nombreController.text = data.nombre!;
          _descripcionController.text = data.descripcion!;
          _precioController.text = data.precio!.toString();
          caracteristicas = data.caracteristicas!;
        });
      }

    }catch(e){
      if (mounted) ToastManager.show(context, "Error con el servidor. No se ha podido cargar el porducto", success: false);
    }
  }

  void _checkFields() async {
    if(_formKey.currentState!.validate()){
      if(caracteristicas.isEmpty){
        ToastManager.show(context, "Debes anñadir al menos una caracterisitca", success: false);
        return;
      }

      for (var c in caracteristicas){

        if (c.opciones == null || c.opciones!.isEmpty) {
          ToastManager.show(context, "La característica '${c.nombre}' debe tener al menos una opción", success: false);
          return;
        }

      }

      try{
        String precioTexto = _precioController.text.replaceAll(',', '.').trim();
        double precio = double.tryParse(precioTexto) ?? 0.0;
        String nombre = _nombreController.text.trim();
        String descripcion = _descripcionController.text.trim();
        var data = await productRepository.updateProduct(_id!, nombre: nombre, descripcion: descripcion, precioBase: precio, caracteristicas: caracteristicas);

        if(mounted){
          debugPrint("Id: ${data!.id}");
          ToastManager.show(context, 'Producto actualizado con exito', success: true);
        }
      }catch(e){
        if (mounted) ToastManager.show(context, "$e", success: false);
      }
    }
  }


  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context){
    final screenWidth = MediaQuery.of(context).size.width;
    bool esMovil = screenWidth < 600;
    double tamText = (screenWidth * 0.5) - ((40+10)/2)-25;

    if (isLoanding){
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if(userName == null){
      return NeedLoginWidget();
    }

    if(!isLoanding && userRol != UserType.jefe && userRol != UserType.administrativo){
      return const NoAccessWidget();
    }

    return Scaffold(
      drawer: MenuEmpresa(current: PageKind.modificarProducto, rol: userRol!),
      body:
      Form(
        key: _formKey,
        child: ListView(
          padding: esMovil
              ? EdgeInsets.only(top:40, bottom: 20, left: 10, right: 10)
              : EdgeInsets.all(40),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Builder(
                    builder: (context){
                      return IconButton(
                          onPressed: () {
                            if (Scaffold.of(context).isDrawerOpen) {
                              Navigator.pop(context);
                            } else {
                              Scaffold.of(context).openDrawer();
                            }
                          },
                          icon: Icon(Icons.menu, color: Color(0xFF222B6F))
                      );
                    }
                ),

                Spacer(),
                Text(
                  "MODIFICAR PRODUCTO",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: esMovil ? 20 : 24,
                    color: Color(0xFF222B6F),
                  ),
                  textAlign: TextAlign.center,
                ),
                Spacer(),
              ],
            ),
            const SizedBox(height: 40),
            Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 10,
                runSpacing: 40,
                children: [
                  SizedBox(
                    width:  esMovil ? screenWidth : tamText,
                    child: buildTextField(_nombreController, "Nombre del producto"),

                  ),
                  SizedBox(
                    width: esMovil ? screenWidth : tamText,
                    child: buildTextField(_precioController, "Precio Base (€/m²)", icon : Icons.euro, isNumber: true),
                  ),

                ]
            ),

            const SizedBox(height: 40),
            buildTextField(_descripcionController, "Descripción del producto", obligatorio: false, maxLines: 3),

            const SizedBox(height: 40,),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Características:", style: TextStyle(fontSize: 18),),
                IconButton(
                    onPressed: addCaracteristica,
                    tooltip: 'Añadir una caracteristica',
                    iconSize: 30.0,
                    icon: Icon(Icons.add, color: Color(0xFF222B6F))
                ),
              ],
            ),

            const SizedBox(height: 10),

            ...caracteristicas.asMap().entries.map((entry) {
              return buildCaracteristicaCard(entry.value);
            }),

            const SizedBox(height: 30),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ElevatedButton(
                  onPressed: _checkFields,
                  child: const Text("Guardar", style: TextStyle(color: Colors.white, fontSize: 18)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red
                  ),
                  onPressed: _loadProduct,
                  child: const Text("Cancelar", style: TextStyle(color: Colors.white, fontSize: 18)),
                )
              ],
            )


          ],
        ),
      ),
    );
  }

}