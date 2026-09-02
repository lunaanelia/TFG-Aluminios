import 'package:aluminios/mixins/user_loader.dart';
import 'package:aluminios/models/habitacion.dart';
import 'package:aluminios/models/producto.dart';
import 'package:aluminios/models/proyecto.dart';
import 'package:aluminios/repository/direccion_repository.dart';
import 'package:aluminios/repository/presupuesto_repository.dart';
import 'package:aluminios/repository/proyecto_repository.dart';
import 'package:aluminios/widgets/menu_empresa.dart';
import 'package:aluminios/widgets/need_login_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart' show launchUrl;
import 'package:url_launcher/url_launcher_string.dart';
import '../models/direccion.dart';
import '../models/opciones_entrega.dart';
import '../models/presupuesto.dart';
import '../widgets/header.dart';
import '../utils/toast_manager.dart';
import '../utils/tipos.dart';
import 'dart:async';

class ConfirmacionPresupuestoPage extends StatefulWidget {
  final int? id;
  const ConfirmacionPresupuestoPage({super.key, this.id});

  @override
  State<ConfirmacionPresupuestoPage> createState() => _ConfirmacionPresupuestoState();
}

class _ConfirmacionPresupuestoState extends State<ConfirmacionPresupuestoPage> with UserLoaderMixin, WidgetsBindingObserver{

  final DireccionRepository _direccionRepository = DireccionRepository();
  final PresupuestoRepository _presupuestoRepository = PresupuestoRepository();
  final ProyectoRepository _proyectoRepository = ProyectoRepository();
  Timer ? _debounce;

  List<Direccion> sugerencias = [];
  double? latitudSeleccionada;
  double? longitudSeleccionada;

  bool _isLoanding = true;

  final TextEditingController _direccionController = TextEditingController();
  final TextEditingController _numeroController = TextEditingController();
  final TextEditingController _detallesController = TextEditingController();

  String ? _opcionEntregaSeleccionada;

  List<Producto> productos = [];
  List<Habitacion> habitaciones = [];

  int? productoSeleccionadoId;
  int? habitacionSeleccioandaId;
  String? opcionEntregaSeleccionadaId;

  List<Caracteristica> caracteristicasP = [];
  Map<int, Opcion> extrasElegidos = {};
  List<OpcionEntrega> _opcionesEntrega = [];

  int ? _id;
  int ? _idProyecto;

  Presupuesto? _presupuesto ;
  bool _isIntialized = false;

  bool _errorDireccion = false;
  bool _errorNumero = false;
  bool _errorMetodo = false;
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
        _id = null;
      }

      _loadData();
      _isIntialized = true;
    }

  }

  Future<void> _loadData() async{
    loadCurrentUserData();

    if(userName == null){
      return;
    }

    if(_id!=null){

      try{
        final res = await _presupuestoRepository.getPresupuestoById(_id!);

        if (mounted){
          setState(() {
            _presupuesto = res;
            _isLoanding = false;
          });
        }
      }catch(e){
        if(mounted) {
          ToastManager.show(
              context, "Error al cargar el presupuesto: $e", success: false);
        }
      }
    }

  }


  Future<void> _loadOpcionEntrega (double lat, double lon) async{
    setState(() {
      _opcionEntregaSeleccionada = null;
    });

    try{
      final res = await _presupuestoRepository.getOpcionesEntrega(lat, lon);
      setState(() {
        _opcionesEntrega = res;
      });

    }catch(e){
      if (mounted) {
        ToastManager.show(context, "Error: $e", success: false);
      }
    }
  }

  Future<void> _comprobarEstadoPago() async {
    for (int i = 0; i < 5; i++) {
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      final proyecto = await _proyectoRepository.getProyectoById(_idProyecto!);

      if (proyecto.estado ==  EstadoProyecto.pendiente_cita) {
        Navigator.pushReplacementNamed(context, 'verProyecto/',arguments: _idProyecto!);
        return;
      }
    }

    if (mounted) {
      Navigator.pushReplacementNamed(context, 'verProyecto/',arguments: _idProyecto!);
      ToastManager.show(
          context,
          'El pago no se ha completado',
          success: false
      );
    }
  }


  bool _checkFields() {
    if(_presupuesto == null){
      ToastManager.show(context, "Error al cargar el presupuesto. Intentelo de nuevo más tarde", success: false);
      return false;
    }

    if(_presupuesto!.requireRevision!){
      ToastManager.show(context, "El presupuesto tiene productos u ocpines descatalogadas, porfavor arreglelo", success: false);
    }
    setState(() {
      _errorDireccion = _direccionController.text.isEmpty;
      _errorNumero = _numeroController.text.isEmpty;
      _errorMetodo = _opcionEntregaSeleccionada == null;
    });

    if (!_errorNumero){
      int? numero = int.tryParse(_numeroController.text);
      if (numero == null || numero < 0) {
        ToastManager.show(context, "El número del portal debe ser un número", success: false);
        setState(() {
          _errorNumero = true;
        });
      }
    }

    if(_errorNumero || _errorDireccion || _errorMetodo){
      ToastManager.show(context, "Todos los campos deben estar rellenos", success: false);
      return false;
    } else{
      return true;
    }
  }

  Widget _buildTextField({
    required String clave,
    required TextEditingController controller,
    required String labelText,
    String? hintText,
    bool ? hasError,
    TextInputType keyboardType = TextInputType.text,
    ValueChanged<String>? onChanged,
  }) {
    final bool errorActivo = hasError ?? false;

    return TextField(
      key: Key(clave),
      controller: controller,
      keyboardType: keyboardType,
      textAlign: TextAlign.start,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        errorText: errorActivo ? "" : null,
        errorStyle: errorActivo ? const TextStyle(height: 0, fontSize: 0) : null,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      onChanged: onChanged,
    );
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
                      key: const Key('pagarTaller'),
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

  Future<void> _procesarPago(String metodo) async {
    try{
      String num = _numeroController.text;
      final res = await _proyectoRepository.createProyecto(_presupuesto!.id!, 'taller', _direccionController.text, latitudSeleccionada!, latitudSeleccionada!, num, _detallesController.text, _opcionEntregaSeleccionada!);

      if(mounted && res != null){
        Proyecto ? proyecto = res;
        _idProyecto = proyecto.id;
        debugPrint("DEBUG PROYECTO metodo de pago ${proyecto.metodoPago}");
        debugPrint("DEBUG PROYECTO estado ${proyecto.estado}");

        if (metodo == 'online'){
          try{
            final url =  await _proyectoRepository.pagoOnlineProyecto(proyecto.id);
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
            if(mounted) {
              setState(() {
                _esperandoPago = false;
              });
              ToastManager.show(context, "Error: $e", success: false);
            }
          }

        }else {
          ToastManager.show(context,
              "Proyecto confirmado correctamente. Dispone hasta el día ${DateFormat(
                  'dd/MM/yy').format(proyecto.fechaLimite!)} para pagar.");
          //Navigator.pushNamed(context, 'verProyecto/', arguments: proyecto.id);
        }

        Navigator.pushNamed(context, 'verProyecto/', arguments: proyecto.id);
      }
    }catch(e){
      if(mounted) {
        ToastManager.show(context, "Error: $e", success: false);
      }
    }
  }

  Widget _buildDropEntrega(){
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: InputDecorator(
              decoration: InputDecoration(
                errorText: _errorMetodo ? "" : null,
                errorStyle: _errorMetodo ? const TextStyle(height: 0, fontSize: 0) : null,
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _opcionEntregaSeleccionada,
                  hint: const Text("Selecciona cómo recibir el material"),
                  isExpanded: true,
                  items: _opcionesEntrega.map<DropdownMenuItem<String>>((valor) {
                    return DropdownMenuItem<String>(
                      value: valor.id,
                      child: Text(valor.label),
                    );
                  }).toList(),
                  onChanged: (String? nuevoValor) {
                    setState(() {
                      _opcionEntregaSeleccionada = nuevoValor;
                      if (nuevoValor != null) {
                        _errorMetodo = false;
                      }
                    });
                  },
                ),
              ),
            )
          ),
        ),
      ],
    );
  }

  Widget _buildTextDireccion() {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,

      children: [
        _buildTextField(
          clave: 'direccionField',
          controller: _direccionController,
          labelText: 'Calle',
          hintText: 'Ej: Avenida Andalucia, Estepa...',
          hasError: _errorDireccion,
          onChanged: (value) {
            if (_debounce?.isActive ?? false) _debounce!.cancel();
            _debounce = Timer(const Duration(milliseconds: 800), () async {
              if (value.trim().length < 3) {
                setState(() {
                  sugerencias = [];
                  _errorDireccion = true;
                });
                return;
              }
              try {
                setState(() => _errorDireccion = false);
                List<Direccion> resultados = await _direccionRepository.buscarDirecciones(value);
                setState(() {
                  sugerencias = resultados;
                });
              } catch (e) {
                debugPrint("$e");
              }
            });
          },
        ),

        const SizedBox(height: 10),

        if (sugerencias.isNotEmpty)
          SizedBox(
            height: 200,
            child: Card(
              child: ListView.builder(
                itemCount:
                sugerencias.length,
                itemBuilder: (context, index) {
                  final direccion =
                  sugerencias[index];
                  return ListTile(
                    title: Text(
                      direccion.nombre,
                    ),

                    onTap: () {
                      _direccionController.text = direccion.nombre;
                      latitudSeleccionada = direccion.latitud;
                      longitudSeleccionada = direccion.longitud;
                      _loadOpcionEntrega(latitudSeleccionada!, longitudSeleccionada!);

                      setState(() {
                        sugerencias = [];
                      });
                    },
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _cabeceraCliente(bool esMovil){
    return Column(
        children: [
          Header(name: userName ?? '', isLoged: true),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              IconButton(
                  onPressed: (){
                    Navigator.pop(context);

                  },
                  icon:  Icon(Icons.arrow_back_ios_new_outlined, color: Color(0xFF222B6F))
              ),
              Text(
                esMovil ? 'CONFIRMACIÓN' : 'CONFIRMACIÓN DEL PRESUPUESTO',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Color(0xFF222B6F),
                ),
              ),

              Spacer(),
            ],

          ),

        ]
    );
  }

  Widget _cabeceraEmpresa(bool esMovil){
    return  Column(
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
              esMovil ? 'CONFIRMACIÓN' : 'CONFIRMACIÓN DEL PRESUPUESTO',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: esMovil ? 20 : 24,
                color: Color(0xFF222B6F),
              ),
            ),
            Spacer()
          ],
        ),
      ],
    );

  }


  @override
  Widget build(BuildContext context){
    final screenWidth = MediaQuery.of(context).size.width;

    if (_isLoanding){
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if(userName == null){
      return NeedLoginWidget();
    }

    return Scaffold(
      drawer: (userRol != null && userRol != UserType.cliente)
          ? MenuEmpresa(current: PageKind.confirmacionPresupuesto, rol: userRol!)
          : null,
      body:
      LayoutBuilder(
          builder: (context, constrait){
            bool esMovil = constrait.maxWidth < 700;
            if(_id == null){
              return NeedLoginWidget();
            }

            return
              SingleChildScrollView(
                child: Center(
                    child: Padding(
                      padding: esMovil
                          ? EdgeInsets.only(top:40, bottom: 20, left: 10, right: 10)
                          : EdgeInsets.symmetric(horizontal: /*userRol == UserType.cliente ? screenWidth*0.07 : */ 40, vertical: 40),

                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          if(userRol == UserType.cliente)...[
                            _cabeceraCliente(esMovil)
                          ]else...[
                            _cabeceraEmpresa(esMovil)
                          ],
                          SizedBox(height: esMovil ? 20 : 40,),
                          Text(
                            "Direccion de obra:",
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 20,),
                          _buildTextDireccion(),
                          SizedBox(height: 20,),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Expanded(
                                flex: 1,
                                child: _buildTextField(
                                  clave: 'numeroField',
                                  controller: _numeroController,
                                  labelText: "número",
                                  keyboardType: TextInputType.number,
                                  hasError: _errorNumero,
                                  onChanged: (texto) {
                                    if (texto.isEmpty) {
                                      setState(() => _errorNumero = false);
                                      return;
                                    }
                                    int? numero = int.tryParse(texto);
                                    if (numero == null || numero < 0) {
                                      setState(() {
                                        _errorNumero = true;
                                      });
                                      ToastManager.show(context, "El número del portal debe ser un número", success: false);
                                    } else {
                                      setState(() {
                                        _errorNumero = false;
                                      });
                                    }
                                  },
                                ),
                              ),
                              SizedBox(width: 10,),
                              Expanded(
                                  flex:2,
                                  child: _buildTextField(
                                    clave: 'detalleField',
                                    controller: _detallesController,
                                    labelText: "Portal, Piso , ...",
                                    hasError: false,
                                  ),
                              )
                            ],
                          ),

                          SizedBox(height: 40,),
                          Text(
                            "Método de entrega:",
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          _buildDropEntrega(),
                          SizedBox(height: 40,),
                          Text(
                            "Resumen del presupuesto:",
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 20,),

                          if(_presupuesto!=null && _presupuesto!.requireRevision!)...[
                            Row(
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(width: 6,),
                                  Expanded(child: Text(
                                    "Por favor revise el presupuesto. Puede ser que desde que usted lo creo hasta ahora se han descatalgodo productos o cambido su precio. Si paga este presupuesto, se tendrán en cuenta los precios actuales y los porductos del catalgo, eliminando aquellos que no se encuentren.",
                                    style: TextStyle(fontSize: 14, color : Colors.grey),
                                  ),),

                                ]

                            ),
                          ],

                          if (_presupuesto != null)...[
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 16),

                                  ..._presupuesto!.lineas.map((linea) {
                                    bool revision = !(linea.productoActivo ?? true);
                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 16),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        side: BorderSide(color: Colors.grey[200]!),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      color: Colors.grey[200],
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Wrap(
                                              runSpacing: 12,
                                              children: [
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.start,
                                                  children: [
                                                    if (revision || linea.requiereRevision!) ...[
                                                      Icon(
                                                        Icons.warning_amber,
                                                        color: Colors.red,
                                                      ),
                                                      SizedBox(width: 10,)
                                                    ],

                                                    Text(
                                                      linea.nombreProducto ?? "Producto sin nombre",
                                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                                                    ),

                                                  ],
                                                ),
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Text(
                                                      "Medidas : ${linea.ancho.toStringAsFixed(2)} x ${linea.alto.toStringAsFixed(2)}",
                                                      style: const TextStyle(color: Color(0xFF222B6F), fontWeight: FontWeight.bold, fontSize: 16),
                                                    ),
                                                    Text(
                                                        "Cant: ${linea.cantidad}",
                                                        style: const TextStyle(color: Color(0xFF222B6F), fontWeight: FontWeight.bold)
                                                    ),

                                                    Text(
                                                      "${linea.precioFinal?.toStringAsFixed(2) ?? '0.00'}€",
                                                      style: TextStyle(color: revision ? Colors.grey : Color(0xFF222B6F), fontWeight: FontWeight.bold, fontSize: 16),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),

                                            Text(
                                              'Caracterisiticas:',
                                                style: const TextStyle(
                                                  color: Color(0xFF222B6F),
                                                  fontWeight: FontWeight.bold,
                                                )
                                            ),


                                            if (linea.opciones.isNotEmpty) ...[
                                              const SizedBox(height: 10),

                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: linea.opciones.map((opc) {
                                                  bool activado = opc.opcionActiva!;
                                                  return Padding(
                                                    padding: const EdgeInsets.only(bottom: 4, left: 20),

                                                    child: Row(
                                                      mainAxisAlignment: MainAxisAlignment.start,
                                                      children: [
                                                        Icon(
                                                          Icons.fiber_manual_record,
                                                          size: 10,
                                                          color: activado ? Color(0xFF222B6F) :  Colors.grey ,
                                                        ),
                                                        const SizedBox(width: 6),
                                                        Expanded(
                                                            child: Text(
                                                              "${opc.caracteristicaNombre}: ${opc.nombre} (+ ${opc.precioExtra} €)",

                                                              style: activado  ? TextStyle(
                                                                fontSize: 18,
                                                                color: Color(0xFF222B6F),
                                                              ) :
                                                              TextStyle(
                                                                fontWeight: FontWeight.bold,
                                                                color: Colors.grey,
                                                                fontSize: 18,
                                                                decoration: TextDecoration.lineThrough,
                                                                decorationColor: Colors.grey,
                                                                decorationThickness: 2,

                                                              )

                                                            ),
                                                        ),

                                                      ],
                                                    ),
                                                  );

                                                }).toList(),
                                              ),
                                            ],

                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.end,
                                              children: [
                                                Text("Total del porducto: ${linea.precioFinal}€",
                                                  style:
                                                    revision ? TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.grey,
                                                      fontSize: 18,
                                                        decoration: TextDecoration.lineThrough,
                                                        decorationColor: Colors.grey,
                                                        decorationThickness: 2,

                                                  ):TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 18,

                                                    )

                                                )
                                              ],
                                            ),

                                          ],
                                        ),
                                      ),
                                    );
                                  }),

                                  const SizedBox(height: 16),
                                  const Divider(color: Colors.white, thickness: 1.5),
                                  const SizedBox(height: 8),

                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text(
                                        "Total a presupuesto: ${_presupuesto!.total ?? 0.0}€",
                                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF222B6F)),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text(
                                        "Total a pagar (fianza): ${_presupuesto!.fianza ?? 0.0}€",
                                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF222B6F)),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12,),
                                  SizedBox(
                                    width: double.infinity,
                                  child: Wrap(
                                      alignment: WrapAlignment.spaceAround,
                                      runAlignment: WrapAlignment.center,
                                      spacing: 16.0,
                                      runSpacing: 12.0,
                                      children: [

                                        OutlinedButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                          child: const Text("Volver atrás"),
                                        ),

                                        ElevatedButton(
                                          onPressed: () {
                                            Navigator.pushNamed(context, 'createPresupuesto/', arguments: _presupuesto!.id!);
                                          },
                                          child: const Text("Modificar Presupuesto"),
                                        ),

                                        ElevatedButton(
                                          key: const Key('Pagar'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            foregroundColor: Colors.white,
                                          ),
                                          onPressed: () {
                                            if (_checkFields()) {
                                              _mostrarOpcionesPago(context);
                                            }
                                          },
                                          child: const Text("Pagar"),
                                        ),

                                      ],
                                    ),
                                  )
                                ],
                              ),
                          ],

                        ],
                      ),
                    )

                ),
              );

          }),
    );
  }
}