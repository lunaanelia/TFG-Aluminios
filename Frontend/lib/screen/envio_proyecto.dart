import 'package:aluminios/mixins/user_loader.dart';
import 'package:aluminios/mixins/utils_product.dart';
import 'package:aluminios/models/datos_envio.dart';
import 'package:aluminios/models/presupuesto.dart';
import 'package:aluminios/repository/tarea_repository.dart';
import 'package:aluminios/widgets/need_login_widget.dart';
import 'package:aluminios/widgets/no_access_widget.dart';
import 'package:aluminios/widgets/menu_empresa.dart';
import 'package:flutter/material.dart';
import '../utils/toast_manager.dart';
import '../utils/tipos.dart';

class DatosProyectPage extends StatefulWidget {
  final int? id;
  const DatosProyectPage({ super.key, this.id});

  @override
  State<DatosProyectPage> createState() => _DatosProyectState();
}

class _DatosProyectState extends State<DatosProyectPage> with UserLoaderMixin, ProductCommuns{

  final TareaRepository _tareaRepository = TareaRepository();

  DatosEnvio ? _datos;

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
      _isIntialized = true;
    }

  }

  Future<void> _loadData() async{
    await loadCurrentUserData();
    if(userName == null){
      setState(() {
        isLoanding = false;
        return;
      });
    }
    try{
      final res = await _tareaRepository.getDatosEnvio(_id!);

      if(mounted){
        setState(() {
         _datos = res;
         isLoanding = false;
        });
      }
    }catch (e){
      if(mounted) {
        ToastManager.show(context, "$e", success: false);
      }
    }

  }


  Future<void> _terminarTarea() async{
    try{

      await _tareaRepository.terminarTarea(_id!);

      if (mounted){
        Navigator.of(context).pop(true);
        ToastManager.show(context, "Estado pedido actualizado correctamente", success: true);
      }

    }catch(e){
      if(mounted) {
        ToastManager.show(context, "$e", success: false);
      }
    }
  }


  Widget _buildListaPresupuesto() {
    if (_datos!.presupuesto.lineas.isEmpty) {
      return const Center(child: Text("No hay líneas en este presupuesto."));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _datos!.presupuesto.lineas.length,
      itemBuilder: (context, index) {
        final linea = _datos!.presupuesto.lineas[index];
        return _buildTarjetaProducto(linea);
      },
    );
  }

  Widget _buildTarjetaProducto (LineaPresupuesto linea) {
    List<OpcionSeleccionada> caracteristicas = linea.opciones;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE0E2E5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Producto: ${linea.nombreProducto}",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF1E2856)),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Medidas: ${linea.ancho} × ${linea.alto}",
                style: const TextStyle(fontSize: 18, color: Color(0xFF1E2856),),
              ),
              Text(
                "Cant: ${linea.cantidad}",
                style: const TextStyle(fontSize: 18, color: Color(0xFF1E2856)),
              ),
            ],
          ),

          const SizedBox(height: 12),

          if (caracteristicas.isNotEmpty) ...[
            const Text(
              "Características",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E2856)),
            ),
            const SizedBox(height: 4),

            ...caracteristicas.map((carac) {
              return Padding(
                padding: const EdgeInsets.only(left: 8.0, top: 2.0),
                child: Row(
                  children: [
                    const Icon(
                      Icons.fiber_manual_record,
                      size: 8,
                      color: Color(0xFF222B6F),
                    ),
                    SizedBox(width: 10,),
                    Expanded(
                      child: Text(
                        "${carac.caracteristicaNombre}: ${carac.nombre}",
                        style: const TextStyle(fontSize: 18, color: Color(0xFF1E2856), fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],

          const SizedBox(height: 10),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context){
    final screenWidth = MediaQuery.of(context).size.width;

    if (isLoanding){
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if(userName == null){
      return NeedLoginWidget();
    }

    if(_id == -1){
      return const NoAccessWidget();
    }

    return Scaffold(
      drawer: MenuEmpresa(current: PageKind.modificarProyecto, rol: userRol!),
      body:  LayoutBuilder(
          builder: (context, constrait){
            bool esMovil = constrait.maxWidth < 700;

            return
              SingleChildScrollView(
                child: Padding(
                      padding: esMovil
                          ? EdgeInsets.only(top:40, bottom: 20, left: 10, right: 10)
                          : EdgeInsets.symmetric(horizontal: userRol==UserType.cliente ? screenWidth*0.07 : 40, vertical: 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

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
                                'DATOS ENVÍO',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: esMovil ? 20 :24,
                                  color: Color(0xFF222B6F),
                                ),
                              ),
                              Spacer(),
                            ],
                          ),
                          SizedBox(height: 40,),
                          Wrap(
                            spacing: 10,
                            runSpacing: 5,
                            alignment: WrapAlignment.start,
                            crossAxisAlignment: WrapCrossAlignment.start,
                            children: [
                              Text(
                                'Cliente:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Color(0xFF222B6F),
                                ),
                              ),
                              Text(
                                _datos!.proyecto.nombre ?? "error al cargar",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Color(0xFF222B6F),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 20,),
                          Wrap(
                            spacing: 10,
                            runSpacing: 5,
                            alignment: WrapAlignment.start,
                            crossAxisAlignment: WrapCrossAlignment.start,
                            children: [
                              Text(
                                'Direccion de obra:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Color(0xFF222B6F),
                                ),
                              ),
                              SizedBox(width: 10,),
                              Text(
                                _datos!.proyecto.direccionObra ?? "error al cargar",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Color(0xFF222B6F),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 20,),
                          Wrap(
                            spacing: 10,
                            runSpacing: 5,
                            alignment: WrapAlignment.start,
                            crossAxisAlignment: WrapCrossAlignment.start,
                            children: [
                              Text(
                                'Número:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Color(0xFF222B6F),
                                ),
                              ),
                              Text(
                                _datos!.proyecto.numero.toString(),
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Color(0xFF222B6F),
                                ),
                              ),

                              Text(
                                _datos!.proyecto.detalles ?? "error al cargar",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Color(0xFF222B6F),
                                ),
                              ),


                            ],
                          ),

                          SizedBox(height: 20,),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                'Productos del envio:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Color(0xFF222B6F),
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: esMovil ? 0 : 30,),

                          _buildListaPresupuesto(),
                          SizedBox(height: 40,),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              OutlinedButton(

                                onPressed: (){
                                  Navigator.pop(context);
                                },
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Color(0xFF222B6F), width: 1.5),
                                ),
                                child: const Text("Volver atrás", style: TextStyle( color: Color(0xFF222B6F), fontSize: 18)),
                              ),

                                ElevatedButton(
                                  onPressed: (){
                                    _terminarTarea();
                                  },
                                  child: const Text("Pedido enviado", style: TextStyle(color: Colors.white, fontSize: 18)),
                                ),
                            ],
                          ),
                          SizedBox(height: 30,),
                        ],
                      ),
                    )
              );

          }),
    );
  }

}