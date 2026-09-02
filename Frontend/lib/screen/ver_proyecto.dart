import 'package:aluminios/mixins/user_loader.dart';
import 'package:aluminios/mixins/utils_info_proyecto_cliente.dart';
import 'package:aluminios/mixins/utils_product.dart';
import 'package:aluminios/models/presupuesto.dart';
import 'package:aluminios/repository/presupuesto_repository.dart';
import 'package:aluminios/widgets/header.dart';
import 'package:aluminios/widgets/menu_empresa.dart';
import 'package:aluminios/widgets/need_login_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/cita.dart';
import '../models/proyecto.dart';
import '../widgets/banner_delete.dart';
import '../utils/toast_manager.dart';
import '../utils/tipos.dart';

class VerProyectPage extends StatefulWidget {
  final int? id;
  const VerProyectPage({ super.key, this.id});

  @override
  State<VerProyectPage> createState() => _VerProyectState();
}

class _VerProyectState extends State<VerProyectPage> with UserLoaderMixin, ProductCommuns, UtilsInfoProyectoClienteMixin, WidgetsBindingObserver{

  final PresupuestoRepository _presupuestoRepository = PresupuestoRepository();

  Proyecto ?  _proyecto;
  Presupuesto ? _presupuesto;
  Cita ? _cita;

  bool isLoanding = true;

  int ? _id;
  bool _isIntialized = false;

  bool _esperandoPago = false;

  @override
  void initState(){
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _esperandoPago) {
      _esperandoPago = false;
      _comprobarEstadoPago();
    }
  }

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
      });
      return;
    }
    try{

      final res = await proyectoRepository.getProyectoById(_id!);

      if(mounted){
        setState(() {
          _proyecto = res;
        });

        try{
          final res = await _presupuestoRepository.getPresupuestoById(_proyecto!.presupuestoId);
          if(mounted){
            setState(() {
              _presupuesto = res;
              isLoanding = false;
            });

            if(_proyecto!.cita != null){
              try{
                final cita= await citaRepository.getCitaById(_proyecto!.cita!);

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

  void _mostrarOpcionesPago(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(20)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 450,
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Confirmar Pedido",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.amber.shade800),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            "Recuerde: Dispone de 10 días hábiles para realizar el pago una vez confirmado.",
                            style: TextStyle(fontSize: 13, color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _procesarPago("online");
                      },
                      icon: const Icon(Icons.credit_card, color: Colors.white),
                      label: const Text("Pagar Online (Tarjeta)"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _procesarPago("taller");
                      },
                      icon: const Icon(Icons.storefront, color: Colors.blue),
                      label: const Text("Pagar en el Taller"),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.blue, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "Volver atrás",
                      style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _comprobarEstadoPago() async {
    for (int i = 0; i < 5; i++) {
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      final proyecto = await proyectoRepository.getProyectoById(_id!);

      if (proyecto.estado == EstadoProyecto.pendiente_cita) {
        setState(() {
          _proyecto = proyecto;
          _esperandoPago = false;
        });
        return;
      }
    }

    if (mounted) {
      ToastManager.show(
          context,
          'El pago no se ha completado',
          success: false
      );
      setState(() {
        _esperandoPago = false;
      });
    }
  }


  Future<void> _procesarPago(String metodo) async {
    try{
      final url =  await proyectoRepository.pagoOnlineProyecto(_proyecto!.id);
      if(mounted){
        setState(() {
          _esperandoPago = true;
        });
        await launchUrl(
          Uri.parse(url),
          mode: LaunchMode.externalApplication,
        );
      }
    }catch(e){
      setState(() {
        _esperandoPago = false;
      });
      if(mounted) ToastManager.show(context, "Error: $e", success: false);
    }
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
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
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

    return Scaffold(
      drawer: MenuEmpresa(current: PageKind.verProyecto, rol: userRol!),
      body:  LayoutBuilder(
          builder: (context, constrait){
            bool esMovil = constrait.maxWidth < 700;

            return
              SingleChildScrollView(
                child: Padding(
                      padding: esMovil
                          ? EdgeInsets.only(top:40, bottom: 20, left: 10, right: 10)
                          : EdgeInsets.symmetric(horizontal: /*userRol == UserType.cliente ? screenWidth*0.07 : */ 40, vertical: 40),

                  child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [

                          if(userRol  != UserType.cliente)...[

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
                                  'PROYECTO',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: esMovil ? 20 : 24,
                                    color: Color(0xFF222B6F),
                                  ),
                                ),
                                Spacer(),
                              ],
                            ),
                          ]else...[
                            SizedBox(height: 40,),
                            Header(name: userName ?? '', isLoged:true )
                          ],
                          SizedBox(height: esMovil ? 20: 40,),
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

                          if(_proyecto != null && _proyecto!.estado == EstadoProyecto.pendiente_pago)...[
                            SizedBox(height: 20,),
                            Wrap(
                              spacing: 10,
                              runSpacing: 5,
                              alignment: WrapAlignment.start,
                              crossAxisAlignment: WrapCrossAlignment.start,
                              children: [
                                Text(
                                  'Fecha límite para pagar:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Color(0xFF222B6F),
                                  ),
                                ),
                                Text(
                                  _proyecto!.fechaLimite != null ? " ${DateFormat('dd-MM-yyyy').format(_proyecto!.fechaLimite!)}" : " Error al cargar" ,
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Color(0xFF222B6F),
                                  ),
                                ),

                              ],
                            ),
                          ],
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
                                  switch (_proyecto!.estado) {
                                    EstadoProyecto.pendiente_pago => "Fianza por pagar: ",
                                    _                  => "Fianza pagada: ",
                                  },
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

                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                'Productos:',
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

                          SizedBox(height: esMovil ? 0 : 30,),

                          _buildListaPresupuesto(),
                          SizedBox(height: 40,),
                          SizedBox(
                            width: double.infinity,
                            child: Wrap(
                              alignment: WrapAlignment.spaceEvenly,
                              runAlignment: WrapAlignment.center,
                              spacing: 12.0,
                              runSpacing: 12.0,
                              children: [
                                OutlinedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Color(0xFF222B6F), width: 1.5),
                                  ),
                                  child: const Text("Volver atrás", style: TextStyle(color: Color(0xFF222B6F), fontSize: 18)),
                                ),

                                if (_proyecto!.estado == EstadoProyecto.pendiente_cita)
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                    label: const Text("RESERVAR CITA"),
                                    onPressed: () async {
                                      final si = await seleccionarCita(context, _proyecto!.id);
                                      if (si == true && mounted) {
                                        _loadData();
                                      }
                                    },
                                  ),

                                if (_proyecto != null && _proyecto!.estado == EstadoProyecto.pendiente_pago)
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                    label: const Text("PAGAR AHORA"),
                                    onPressed: () {
                                      _mostrarOpcionesPago(context);
                                    },
                                  ),

                                if (_proyecto!.estado == EstadoProyecto.pendiente_cita ||
                                    _proyecto!.estado == EstadoProyecto.pendiente_pago ||
                                    _proyecto!.estado == EstadoProyecto.materiales ||
                                    _proyecto!.estado == EstadoProyecto.revision)
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                    label: const Text("Cancelar"),
                                    onPressed: () async {
                                      final si = await mostrarDialogoConfirmarCancelar(context);
                                      if (si == true && mounted) {
                                        await cancelarProyecto(_proyecto!);
                                      }
                                    },
                                  ),

                                if (_proyecto!.estado == EstadoProyecto.revision)
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                    label: const Text("ANULAR CITA"),
                                    onPressed: () async {
                                      mostrarDialogoConfirmacion(
                                        context: context,
                                        mensaje: "¿Estas seguro que quieres anular la cita?",
                                        id: _proyecto!.cita!,
                                        accionBorrar: (idParaBorrar) async {
                                          bool ok = await anularCita(idParaBorrar);
                                          if (ok && mounted) {
                                            _loadData();
                                          }
                                        },
                                      );
                                    },
                                  ),

                              ],
                            ),
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