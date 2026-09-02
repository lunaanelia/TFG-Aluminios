import 'package:aluminios/mixins/user_loader.dart';
import 'package:aluminios/mixins/utils_product.dart';
import 'package:aluminios/models/presupuesto.dart';
import 'package:aluminios/repository/cita_repository.dart';
import 'package:aluminios/repository/presupuesto_repository.dart';
import 'package:aluminios/repository/proyecto_repository.dart';
import 'package:aluminios/repository/tarea_repository.dart';
import 'package:aluminios/widgets/need_login_widget.dart';
import 'package:aluminios/widgets/no_access_widget.dart';
import 'package:aluminios/widgets/menu_empresa.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/cita.dart';
import '../models/proyecto.dart';
import '../models/tarea.dart';
import '../widgets/banner_delete.dart';
import '../widgets/dialog_asignar_montaje.dart';
import '../utils/toast_manager.dart';
import '../utils/tipos.dart';

class ModificationProyectPage extends StatefulWidget {
  final int? id;
  const ModificationProyectPage({ super.key, this.id});

  @override
  State<ModificationProyectPage> createState() => _ModificationProyectState();
}

class _ModificationProyectState extends State<ModificationProyectPage> with UserLoaderMixin, ProductCommuns{
  final ProyectoRepository _proyectoRepository = ProyectoRepository();
  final PresupuestoRepository _presupuestoRepository = PresupuestoRepository();
  final TareaRepository _tareaRepository = TareaRepository();
  final CitaRepository _citaRepository = CitaRepository();

  Proyecto ?  _proyecto;
  Presupuesto ? _presupuesto;
  Cita ? _cita;

  List<Tarea> _tareasMontar = [];

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

  Future<void> _eliminarTarea(int id) async{
    try{
      await _tareaRepository.deleteTareaMontaje(id);

      if(mounted){
        setState(() {
          _tareasMontar.removeWhere((t) => t.id == id);
        });
        ToastManager.show(context, "Tarea eliminada correctamente", success: true);
      }
    }catch(e){
     if (mounted) ToastManager.show(context, "Error: $e", success: false);
    }

  }

  Future<void> _loadTareas()async{
    try{
      final tar = await _proyectoRepository.getTareasMontar(_proyecto!.id);
      if (mounted){
        setState(() {
          _tareasMontar = tar;
        });
      }
    }catch(e){
      if(mounted) {
        ToastManager.show(context, "$e", success: false);
      }
    }
  }

  Future<void> _loadData() async{
    await  loadCurrentUserData();
    if (userName == null){
      setState(() {
        isLoanding = false;
      });
      return;
    }
    try{
      final res = await _proyectoRepository.getProyectoById(_id!);

      if(mounted){
        setState(() {
          _proyecto = res;
        });

        if(_proyecto!.estado == EstadoProyecto.montaje){
          await _loadTareas();
        }

        try{
          final res = await _presupuestoRepository.getPresupuestoById(_proyecto!.presupuestoId);
          if(mounted){
            setState(() {
              _presupuesto = res;
              isLoanding = false;
            });

            if(_proyecto!.cita != null){
              try{
                final cita= await _citaRepository.getCitaById(_proyecto!.cita!);

                if(mounted){
                  setState(() {
                    _cita = cita;
                  });
                }
              }catch(e){
                if(mounted) {
                  ToastManager.show(context, "$e", success: false);
                }
              }
            }

          }

        }catch(e){
          if(mounted) {
            ToastManager.show(context, "$e", success: false);
          }
        }
      }
    }catch (e){
      if(mounted) {
        ToastManager.show(context, "$e", success: false);
      }
    }

  }

  void _checkFields() async {
    if(_presupuesto!.requireRevision!){
      ToastManager.show(context, "Este presupuesto antes de ser confirmado necesita modificarse. Pulse el boton MODIFICAR ", success: false);
      return;
    }

    try{
      final res = await _proyectoRepository.confirmarProyecto(_proyecto!.id);

      if (mounted){
        setState(() {
          _proyecto!.estado = res!;
        });
        ToastManager.show(context, "Proyecto confirmado correctamente", success: true);
      }
    }catch(e){
      if(mounted) {
        ToastManager.show(context, "$e", success: false);
      }
    }

  }

  Future<void> _pedirMateriales() async{
    try{
      final res = await _proyectoRepository.pedirMateriales(_proyecto!.id);

      if (mounted){
        setState(() {
          _proyecto!.estado = res!;
        });
        ToastManager.show(context, "Estado del proyecto actualizado correctamente", success: true);
      }

    }catch(e){
      if(mounted) {
        ToastManager.show(context, "$e", success: false);
      }
    }
  }

  Future<void> _pedidoRecogido() async{
    try{
      final res = await _proyectoRepository.proyectoRecogido(_proyecto!.id);

      if (mounted){
        setState(() {
          _proyecto!.estado = res!;
        });
        ToastManager.show(context, "Estado del proyecto actualizado correctamente", success: true);
      }

    }catch(e){
      if(mounted) {
        ToastManager.show(context, "$e", success: false);
      }
    }
  }

  Future<void> _recibirMateriales() async{
    try{
      final res = await _proyectoRepository.recibirMateriales(_proyecto!.id);

      if (mounted){
        setState(() {
          _proyecto!.estado = res!;
        });
        ToastManager.show(context, "Estado del proyecto actualizado correctamente", success: true);
      }

    }catch(e){
      if(mounted) {
        ToastManager.show(context, "$e", success: false);
      }
    }
  }

  void _mostrarAvisoConfirmacion(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: const BorderSide(color: Colors.red, width: 2),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red),
              SizedBox(width: 10),
              Text(
                "Confirmar acción",
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          content: Text(
            "¡Esta operación es IRREVERSIBLE!\n\nVa a cambiar el estado del proyecto del cliente: ${_proyecto!.nombre?.toUpperCase()} con dirección: ${_proyecto!.direccionObra}.\n\nEl proyecto pasará a: PEDIR MATERIALES.\n\n¿Estás seguro?",
            style: const TextStyle(fontSize: 16),
          ),
          actions:[
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancelar", style: TextStyle(color: Colors.white)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.of(context).pop();
                _checkFields();
              },
              child: const Text("Confirmar", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }


  Widget _buildListaPresupuesto() {
    if (_presupuesto!.lineas.isEmpty) {
      return const Center(child: Text("No hay líneas en este presupuesto."));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _presupuesto!.lineas.length,
      itemBuilder: (context, index) {
        final linea = _presupuesto!.lineas[index];
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
                        "${carac.caracteristicaNombre}: ${carac.nombre} (+${carac.precioExtra}€)",
                        style: const TextStyle(fontSize: 18, color: Color(0xFF1E2856), fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],

          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              "Total producto: ${linea.precioFinal}€",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF1E2856)),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildListaTareas () {

    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          if (_tareasMontar.isNotEmpty) ...[
            const Text(
              "Días de montaje:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E2856)),
            ),
            const SizedBox(height: 4),

            ..._tareasMontar.map((tarea) {
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
                        "Tiempo: ${DateFormat('dd/MM HH:mm').format(tarea.fechaInicio!)} - ${DateFormat('HH:mm').format(tarea.fechaFin!)}",
                        style: const TextStyle(fontSize: 18, color: Color(0xFF1E2856)),
                      ),
                    ),
                    IconButton(
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.edit_outlined, color: Color(0xFF222B6F)),
                      onPressed: () async {

                        final resultado = await showDialog<bool>(
                          context: context,
                          builder: (context) => DialogAsignarMontaje(proyectoId: _proyecto!.id, tarea: tarea),
                        );
                        if (resultado == true && mounted){
                          await _loadTareas();
                        }

                      },
                    ),
                    SizedBox(width: 10,),
                    IconButton(
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.delete_outline_outlined, color: Colors.red, size: 24),
                      onPressed: () {
                        mostrarDialogoConfirmacion(
                          context: context,
                          mensaje: "¿Estas seguro que quieres borrar este porducto del presupuesto?",
                          id: tarea.id,
                          accionBorrar: (idParaBorrar) async {
                            await _eliminarTarea(idParaBorrar);
                          },
                        );
                      },
                    )
                  ],
                ),
              );
            }),
          ],


        ],
      );
  }

  @override
  Widget build(BuildContext context){
    final screenWidth = MediaQuery.of(context).size.width;
    bool esMovil = screenWidth < 600;

    if (isLoanding){
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if(userName == null){
      return NeedLoginWidget();
    }

    if(!isLoadingUser && userRol != UserType.jefe && userRol != UserType.administrativo ){
      return const NoAccessWidget();
    }

    return Scaffold(
      drawer: MenuEmpresa(current: PageKind.modificarProyecto, rol: userRol!),
      body:  LayoutBuilder(
          builder: (context, constrait){
            return
              SingleChildScrollView(

                  child: Padding(
                      padding: esMovil
                          ? EdgeInsets.only(top:40, bottom: 20, left: 10, right: 10)
                          : EdgeInsets.all(40),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          //SizedBox(height: 40,),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                                'REVISIÓN PROYECTO',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: esMovil ? 20 : 24,
                                  color: Color(0xFF222B6F),
                                ),
                              ),
                              Spacer(),
                            ],
                          ),
                          SizedBox(height: esMovil ? 20 : 40,),
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
                                _proyecto!.nombre ?? "error al cargar",
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
                                _proyecto!.direccionObra ?? "error al cargar",
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
                                _proyecto!.numero.toString(),
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Color(0xFF222B6F),
                                ),
                              ),

                              Text(
                                _proyecto!.detalles ?? "error al cargar",
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
                                'Reunión:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Color(0xFF222B6F),
                                ),
                              ),
                              Text(
                                _cita != null ? " ${DateFormat('dd-MM-yyyy').format(_cita!.fecha)}" : " No escogida todavía" ,
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
                                'Fianza pagada:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Color(0xFF222B6F),
                                ),
                              ),
                              Text(
                                "${_proyecto!.fianza}€",
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
                                'Total presupuesto:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Color(0xFF222B6F),
                                ),
                              ),
                              Text(
                                "${_presupuesto!.total}€",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Color(0xFF222B6F),
                                ),
                              ),


                            ],
                          ),


                          SizedBox(height: 20,),
                          if(_proyecto!.estado == EstadoProyecto.montaje)...[

                            _buildListaTareas(),
                            SizedBox(height: 20,),
                          ],

                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                'Presupuesto:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Color(0xFF222B6F),
                                ),
                              ),
                            ],
                          ),

                          if(_presupuesto!.requireRevision!)...[
                            SizedBox(height: 20,),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 8,
                                  color: Colors.grey,
                                ),

                                Expanded(
                                  child: Text(
                                    'Atención, este presupueto contiene productos descatalagodos, por favor, antes de confirmar pulse modificar y reviselo',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: Color(0xFF222B6F),
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ],

                          SizedBox(height: 10,),
                          _buildListaPresupuesto(),
                          SizedBox(height: 40,),
                          Align(
                            alignment: Alignment.center,
                            child:Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
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
                              if(_proyecto!.estado==EstadoProyecto.revision)...[

                                ElevatedButton(
                                  onPressed: (){
                                    Navigator.pushNamed(context, 'createPresupuesto/', arguments: {
                                      'id' : _presupuesto!.id,
                                      'idProyecto' : _proyecto!.id
                                    });
                                  },
                                  child: const Text("Modificar", style: TextStyle(color: Colors.white, fontSize: 18)),
                                ),

                                ElevatedButton(
                                  key: const Key('confirmarBoton'),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green
                                  ),
                                  onPressed: (){_mostrarAvisoConfirmacion(context);},
                                  child: const Text("Confirmar", style: TextStyle(color: Colors.white, fontSize: 18)),
                                ),
                              ],
                              if(_proyecto!.estado==EstadoProyecto.materiales)...[
                                ElevatedButton(
                                  key: const Key('materialesPedidos'),
                                  onPressed: (){
                                    _pedirMateriales();
                                  },
                                  child: const Text("Materiales Pedidos", style: TextStyle(color: Colors.white, fontSize: 18)),
                                ),
                              ],
                              if(_proyecto!.estado==EstadoProyecto.esperando_materiales)...[
                                ElevatedButton(
                                  key: const Key('materialesRecibidos'),
                                  onPressed: (){
                                    _recibirMateriales();
                                  },
                                  child: const Text("Materiales Recibidos", style: TextStyle(color: Colors.white, fontSize: 18)),
                                ),
                              ],

                              if(_proyecto!.estado==EstadoProyecto.listo_recogida)...[
                                ElevatedButton(
                                  onPressed: (){
                                    _pedidoRecogido();
                                  },
                                  child: const Text("Pedido recogido", style: TextStyle(color: Colors.white, fontSize: 18)),
                                ),
                              ],

                              if(_proyecto!.estado==EstadoProyecto.listo_montaje)...[
                                ElevatedButton(
                                  onPressed: () async {
                                    if (_id == null){
                                      return;
                                    }
                                    final resultado = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => DialogAsignarMontaje(proyectoId: _id!),
                                    );

                                    if (resultado == true && mounted){
                                      await _loadData();
                                    }

                                  },
                                  child: const Text("Asignar día montaje", style: TextStyle(color: Colors.white, fontSize: 18)),
                                ),
                              ],

                              if(_proyecto!.estado==EstadoProyecto.montaje)...[
                                ElevatedButton(
                                  onPressed: () async {
                                    final resultado = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => DialogAsignarMontaje(proyectoId: _proyecto!.id, ),
                                    );

                                    if (resultado == true && mounted){
                                      await _loadTareas();
                                    }
                                  },
                                  child: const Text("Añadir otro día montaje", style: TextStyle(color: Colors.white, fontSize: 18)),
                                ),
                              ],

                              /*if(_proyecto!.estado==EstadoProyecto.listo_recogida)...[
                                ElevatedButton(
                                  onPressed: (){
                                    ToastManager.show(context, "AÑADIR METODO");
                                  },
                                  child: const Text("El proyecto ha sido recogido", style: TextStyle(color: Colors.white, fontSize: 18)),
                                ),
                              ],*/

                              if(_proyecto!.estado==EstadoProyecto.enviado)...[
                                ElevatedButton(
                                  onPressed: (){
                                    ToastManager.show(context, "AÑADIR METODO");
                                  },
                                  child: const Text("El proyecto ha llegado al destinatario", style: TextStyle(color: Colors.white, fontSize: 18)),
                                ),
                              ],
                            ],
                          ),),
                          SizedBox(height: 30,),
                        ],
                      ),
                    )
              );

          }),
    );
  }

}