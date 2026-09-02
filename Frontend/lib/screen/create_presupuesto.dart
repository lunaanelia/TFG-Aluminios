import 'package:aluminios/mixins/user_loader.dart';
import 'package:aluminios/models/habitacion.dart';
import 'package:aluminios/models/producto.dart';
import 'package:aluminios/repository/presupuesto_repository.dart';
import 'package:aluminios/repository/product_repository.dart';
import 'package:aluminios/widgets/menu_empresa.dart';
import 'package:aluminios/widgets/need_login_widget.dart';
import 'package:flutter/material.dart';
import '../models/direccion.dart';
import '../models/presupuesto.dart';
import '../widgets/header.dart';
import '../utils/toast_manager.dart';
import '../utils/tipos.dart';
import 'dart:async';
import '../widgets/banner_delete.dart';

class CreatePresupuestoPage extends StatefulWidget {
  final int? id;
  final int? idProyecto;
  const CreatePresupuestoPage({super.key, this.id, this.idProyecto});

  @override
  State<CreatePresupuestoPage> createState() => _CreatePresupuestoState();
}

class _CreatePresupuestoState extends State<CreatePresupuestoPage> with UserLoaderMixin{
  final PresupuestoRepository _presupuestoRepository = PresupuestoRepository();

  final ProductRepository _productRepository = ProductRepository();

  List<Direccion> sugerencias = [];
  double? latitudSeleccionada;
  double? longitudSeleccionada;

  final TextEditingController _anchoController = TextEditingController();
  final TextEditingController _altoController = TextEditingController();
  final TextEditingController _cantidadController = TextEditingController(text: "1");

  List<Producto> productos = [];
  List<Habitacion> habitaciones = [];

  int? productoSeleccionadoId;
  int? habitacionSeleccioandaId;

  List<Caracteristica> caracteristicasP = [];
  Map<int, Opcion> extrasElegidos = {};

  bool _cargandoProductos= true;
  bool _cargandoHabitaciones = true;

  int ? _idModificar;
  int ? _id;
  int ? _idProyecto;

  Presupuesto? _presupuesto ;
  bool _cargandoPresupuesto = false;
  bool _isIntialized = false;

  List<int> _lineasIncompletas = [];

  @override
  void didChangeDependencies(){
    super.didChangeDependencies();

    if (!_isIntialized) {
      if (widget.id != null) {
        _id = widget.id;
      } else {
        final args = ModalRoute.of(context)?.settings.arguments;
        if (args is Map && args.containsKey('id')) {
          _id = args['id'] as int?;
        } else if (args is int) {
          _id = args;
        }
      }

      if (widget.idProyecto != null) {
        _idProyecto = widget.idProyecto;
      } else {
        final args = ModalRoute.of(context)?.settings.arguments;
        if (args is Map && args.containsKey('idProyecto')) {
          _idProyecto = args['idProyecto'] as int?;
        }
      }

      _loadData();
      _isIntialized= true;
    }
  }


  @override
  void dispose(){
    _cantidadController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async{
    await loadCurrentUserData();


    if (userName == null){
      return;
    }

    try{
      productos = await _productRepository.getProducts();

      if (mounted){
        setState(() {
          _cargandoProductos = false;

        });
      }

    }catch(e){
      if(mounted) {
        ToastManager.show(context, "Error: $e", success: false);
      }
    }

    try{
      habitaciones = await _productRepository.getHabitaciones();

      if (mounted){
        setState(() {
          debugPrint(habitaciones.length.toString());
          _cargandoHabitaciones = false;
        });
      }
    }catch(e){
      if(mounted) {
        ToastManager.show(
            context, "Error al cargar habitaciones: $e", success: false);
      }
    }

    if(_id!=null){
      setState(() {
        _cargandoPresupuesto = true;
      });
      try{
        final res = await _presupuestoRepository.getPresupuestoById(_id!);

        if (mounted){
          setState(() {
            _presupuesto = res;
            _cargandoPresupuesto = false;
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


  void _modificarOpcion(int idLinea){
    LineaPresupuesto lineaMod = _presupuesto!.lineas.firstWhere(
          (linea) => linea.id == idLinea,
      orElse: () => throw Exception("No se encontró la línea con ID $idLinea"),
    );

    setState(() {
      _anchoController.text = lineaMod.ancho.toString();
      _altoController.text = lineaMod.alto.toString();
      _cantidadController.text = lineaMod.cantidad.toString();

      productoSeleccionadoId = lineaMod.producto;
      _idModificar = idLinea;

      extrasElegidos = {};

    });


    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      setState(() {
        extrasElegidos = {};

        for (var opc in lineaMod.opciones) {
          int idDelCatalogo = opc.opcionId ?? opc.id;

          int? idCaractEncontrado;
          for (var car in caracteristicasP) {
            if (car.opciones?.any((o) => o.id == idDelCatalogo) ?? false) {
              idCaractEncontrado = car.id;
              break;
            }
          }

          if (idCaractEncontrado != null) {
            debugPrint("Emparejado: Característica ID $idCaractEncontrado controla Opción ID $idDelCatalogo (${opc.nombre})");

            extrasElegidos[idCaractEncontrado] = Opcion(
              id: idDelCatalogo,
              nombre: opc.nombre,
              precioExtra: opc.precioExtra,
            );
          } else {
            debugPrint("No se pudo encontrar la característica para la opción: ${opc.nombre} (ID: $idDelCatalogo)");
          }
        }
        debugPrint("Tamaño final de extrasElegidos estructurado: ${extrasElegidos.length}");
      });
    });
  }

  Future<void> _agrearProducto(int ? idL)async{
    setState(() { _cargandoPresupuesto = true; });

    List<OpcionSeleccionada> listaOpciones = extrasElegidos.values.map((opcion) {
      final caracteristica = caracteristicasP.firstWhere(
            (c) => c.opciones?.any((o) => o.id == opcion.id) ?? false,
        orElse: () => Caracteristica(nombre: "Sin característica"),
      );
      return OpcionSeleccionada(
        id: opcion.id!,
        opcionId: opcion.id!,
        caracteristicaNombre: caracteristica.nombre ?? 'sin car',
        nombre: opcion.nombre  ?? "Opcion ${opcion.id}",
        precioExtra: opcion.precioExtra ?? 0.0,
      );
    }).toList();

    LineaPresupuesto productoAniadir = LineaPresupuesto(
          id: idL,
          producto: productoSeleccionadoId!,
          cantidad: int.tryParse(_cantidadController.text.trim()) ?? 1,
          ancho: double.tryParse(_anchoController.text.trim()) ?? 0.0,
          alto: double.tryParse(_altoController.text.trim()) ?? 0.0,
          opciones: listaOpciones
      );

    if (_presupuesto==null){
      List<LineaPresupuesto> lineas = [productoAniadir];

      try{
        final res = await _presupuestoRepository.createPresupuesto(lineas);

        if(mounted){
          setState(() {
            _presupuesto = res;
            extrasElegidos = {};
            for (int i = 0; i<_presupuesto!.lineas.length; i++){
              for(int j = 0; j<_presupuesto!.lineas[i].opciones.length; j++)
                {

                  debugPrint("NOmbre de la opcion con id ${_presupuesto!
                      .lineas[i].opciones[j].id} es ${_presupuesto!
                      .lineas[i].opciones[j].nombre}");
                }
            }

            _cargandoPresupuesto = false;
            _idModificar = null;
            debugPrint("DEBUG DEL PRESUPUESTO TOTAL ${_presupuesto!.total}");
            debugPrint("DEBUG DEL PRESUPUESTO LINEAS TAMAÑO ${_presupuesto!.lineas.length}");

          });
        }
      }catch(e){
        setState(() {
          _cargandoPresupuesto = false;
        });
        if(mounted) {
          ToastManager.show(context, "Error $e", success: false);
        }
      }
    }else{

      List<LineaPresupuesto> lineasSincronizadas = List.from(_presupuesto!.lineas);

      if (idL != null) {
        int index = lineasSincronizadas.indexWhere((l) => l.id == idL);
        if (index != -1) {
          lineasSincronizadas[index] = productoAniadir;
        }
      } else {
        lineasSincronizadas.add(productoAniadir);
      }

      try{
        final res = await _presupuestoRepository.updatePresupuesto(_presupuesto!.id!,lineas: lineasSincronizadas);

        if(mounted){
          setState(() {
            _presupuesto = res;
            _cargandoPresupuesto = false;
            _idModificar = null;
            extrasElegidos = {};
          });
        }
      }catch(e){
        if(mounted) {
          ToastManager.show(context, "Error $e", success: false);
        }
      }

    }
    _resetFields(false);
  }

  Future<void> _eliminarLineaPresupuesto(int id)async{
    if (_presupuesto == null) return;

    List<LineaPresupuesto> lineasRestantes = List.from(_presupuesto!.lineas);

    lineasRestantes.removeWhere((linea) => linea.id == id);

    setState(() => _cargandoPresupuesto = true);

    try {
       final res = await _presupuestoRepository.updatePresupuesto(_presupuesto!.id!, lineas: lineasRestantes);

      if (mounted) {
        setState(() {
          _presupuesto = res;
          _cargandoPresupuesto = false;
          debugPrint("Línea borrada. Nuevo total: ${_presupuesto!.total}");
          debugPrint("Cantidad de líneas que quedan: ${_presupuesto!.lineas.length}");
          ToastManager.show(context, "Accion realizada correctamente", success: true);
        });
      }
    } catch (e) {
      setState(() => _cargandoPresupuesto = false);
      if (mounted) ToastManager.show(context, "Error al eliminar la línea: $e", success: false);
    }
  }

  Future<void> _limpiarPresupuesto(int id)async{
    setState(() { _cargandoPresupuesto = true; });
    

    if (_presupuesto!=null){
      try{
        final res = await _presupuestoRepository.limpiaePresupuesto(id);

        if(mounted){
          setState(() {
            _presupuesto = res;
            extrasElegidos = {};
            for (int i = 0; i<_presupuesto!.lineas.length; i++){
              for(int j = 0; j<_presupuesto!.lineas[i].opciones.length; j++)
              {
                debugPrint("Nombre de la opcion con id ${_presupuesto!
                    .lineas[i].opciones[j].id} es ${_presupuesto!
                    .lineas[i].opciones[j].nombre}");
              }
            }

            _cargandoPresupuesto = false;
            _idModificar = null;
            debugPrint("DEBUG DEL PRESUPUESTO TOTAL ${_presupuesto!.total}");
            debugPrint("DEBUG DEL PRESUPUESTO LINEAS TAMAÑO ${_presupuesto!.lineas.length}");

          });
        }
      }catch(e){
        setState(() {
          _cargandoPresupuesto = false;
        });
        if (mounted) ToastManager.show(context, "Error $e", success: false);
      }
    }
  }

  void _obtenerLineasIncompletas(){
    List<int> nuevas = [];

    if(_presupuesto == null || _presupuesto!.lineas.isEmpty){
      setState(() {
        _lineasIncompletas = nuevas;
      });
      return;
    }

    for (LineaPresupuesto linea in _presupuesto!.lineas){
      Producto productoCatalogo = productos.firstWhere(
            (p) => p.id == linea.producto,
            orElse: () => Producto(id: -1, nombre: '', caracteristicas: []),
          );

      if (productoCatalogo.id == -1 || productoCatalogo.caracteristicas == null) {
        if (linea.id != null) nuevas.add(linea.id!);
        continue;
      }

      int totalCaracteristicasExigidas = productoCatalogo.caracteristicas!.length;

      List<int> caracteristicasCubiertas = [];

      for (var opcGuardada in linea.opciones) {
        int idDelCatalogo = opcGuardada.opcionId ?? opcGuardada.id;

        for (var car in productoCatalogo.caracteristicas!) {
          if (car.opciones?.any((o) => o.id == idDelCatalogo) ?? false) {
            if (car.id != null && !caracteristicasCubiertas.contains(car.id)) {
              caracteristicasCubiertas.add(car.id!);
            }
            break;
          }
        }
      }

      if (caracteristicasCubiertas.length < totalCaracteristicasExigidas) {
        if (linea.id != null) {
          nuevas.add(linea.id!);
        }
      }

    }

    setState(() {
      _lineasIncompletas = nuevas;
    });
  }

  void _checkFields() async {
    if (productoSeleccionadoId == null){
      ToastManager.show(context, "Por favor, seleccione un producto", success: false);
      return;
    }

    String altoText = _altoController.text.trim();
    String anchoText = _anchoController.text.trim();
    String cantidadText = _cantidadController.text.trim();

    if (altoText.isEmpty || anchoText.isEmpty || cantidadText.isEmpty) {
      ToastManager.show(context, "Todos los campos de medidas y cantidad son obligatorios", success: false);
      return;
    }

    double? alto = double.tryParse(altoText);
    double? ancho = double.tryParse(anchoText);
    int? cantidad = int.tryParse(cantidadText);


    if (alto == null || alto <= 0 || ancho == null || ancho <= 0) {
      ToastManager.show(context, "Las medidas deben ser un número mayor a 0", success: false);
      return;
    }

    if (cantidad == null || cantidad <= 0) {
      ToastManager.show(context, "La cantidad debe ser un número mayor a 0", success: false);
      return;
    }

    for (var caracteristica in caracteristicasP) {
      int idCaract = caracteristica.id ?? 0;

      if (!extrasElegidos.containsKey(idCaract) || extrasElegidos[idCaract] == null) {
        ToastManager.show( context, "Falta seleccionar una opción en: ${caracteristica.nombre}", success: false);
        return;
      }
    }

    _agrearProducto(_idModificar);
  }

  void _resetFields(bool todo) async{
    setState(() {
      _anchoController.text = "";
      _altoController.text = "";
      _cantidadController.text = "1";

      _idModificar = null;

      extrasElegidos = {};
      if(todo){
        _presupuesto = null;
      }
    });

  }

  Future<void> _eliminarPresupuesto(int id) async{
    setState(() { _cargandoPresupuesto = true; });
    bool todo  = false;
    if(_presupuesto != null){
      try{
        await _presupuestoRepository.deletePresupuesto(id);

        if(mounted){
          setState(() {
            _cargandoPresupuesto = false;
            todo = true;

            debugPrint("DEBUG DEL PRESUPUESTO TOTAL${_presupuesto!.total}");
            debugPrint("DEBUG DEL PRESUPUESTO LINEAS TAMAÑO${_presupuesto!.lineas.length}");

          });
        }
      }catch(e){
        setState(() {
          _cargandoPresupuesto = false;
        });
        if(mounted) ToastManager.show(context, "Error $e", success: false);
      }
    }

    _resetFields(todo);

  }

  Widget _formularioCompleto (bool esMovil){
    Widget devolver;
    if (!esMovil) {
      devolver = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Expanded(
              flex: 1,
              child: _formularioIzq(esMovil),
            ),

            SizedBox(width: 20,),
            Expanded(
              flex: 1,
              child: _fomularioDech(esMovil),
            ),
          ],
      );
    }
    else {
      devolver = Column(
        children: [
          _formularioIzq(esMovil),
          SizedBox(height: 20,),
          _fomularioDech(esMovil)

        ],
      );
    }

    return devolver;
  }

  Widget _buildCantidad(){
    return Expanded(
      flex: 1,
      child: TextField(
        controller: _cantidadController,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.start,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          labelText: "Cantidad",
          suffixIcon: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              GestureDetector(
                onTap: () {
                  int valorActual = int.tryParse(_cantidadController.text) ?? 1;
                  setState(() {
                    _cantidadController.text = (valorActual + 1).toString();
                  });
                },
                child: const Icon(Icons.keyboard_arrow_up, size: 18, color: Colors.grey),
              ),

              GestureDetector(
                onTap: () {
                  int valorActual = int.tryParse(_cantidadController.text) ?? 1;
                  if (valorActual > 1) {
                    setState(() {
                      _cantidadController.text = (valorActual - 1).toString();

                    });
                  }
                },
                child: const Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.grey),
              ),
            ],
          ),
        ),

        onChanged: (texto) {
          if (texto.isEmpty) return;
          int? numero = int.tryParse(texto);
          if (numero == null || numero < 1) {
            _cantidadController.text = "1";
            _cantidadController.selection = TextSelection.fromPosition(
              TextPosition(offset: _cantidadController.text.length),
            );
          }
        },
      ),
    );
  }

  Widget _formularioIzq(bool esMovil){

    caracteristicasP =  productoSeleccionadoId == null ? [] :
                        productos.firstWhere((p) => p.id == productoSeleccionadoId,).caracteristicas ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,

      children: [
        SizedBox(height: esMovil ? 10 : 60,),
        Row(
          children: [
            _cargandoProductos
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF222B6F)))
                : Expanded(child: DropdownButtonFormField<int>(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Selecciona un producto...",
              ),

              initialValue: productoSeleccionadoId,
              items: productos.map<DropdownMenuItem<int>>((producto) {
                return DropdownMenuItem<int>(
                  value: producto.id,
                  child: Text(
                      "${producto.nombre!} (${producto.precio} €/m²)",
                    style: TextStyle(
                      fontSize: 18,
                      color: Color(0xFF222B6F),
                    ),
                  ),
                );
              }).toList(),
              onChanged: _idModificar != null ?  null : (nuevoIdSelected) {
                setState(() {

                  productoSeleccionadoId = nuevoIdSelected;

                  Producto? productoSeleccionado;
                  try {
                    productoSeleccionado = productos.firstWhere(
                          (p) => p.id == productoSeleccionadoId,
                    );
                  } catch(e) {
                    productoSeleccionado = null;
                  }

                  if (productoSeleccionado == null) {
                    caracteristicasP = [];
                  }
                  else {
                    caracteristicasP = productoSeleccionado.caracteristicas ?? [];
                  }
                });
                debugPrint("Producto seleccionado ID: $productoSeleccionadoId");
              },
              validator: (value) {
                if (value == null) {
                  return 'Por favor, selecciona un producto';
                }
                return null;
              },

            ),
            )

          ],
        ),

        SizedBox(height: 40,),

        Row(
          children: [
            _cargandoHabitaciones
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF222B6F)))
                : Expanded(child: DropdownButtonFormField<int>(
              isExpanded: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Selecciona una habitación para suguerir recomendaciones",
              ),

              items: habitaciones.map<DropdownMenuItem<int>>((habitacion) {
                return DropdownMenuItem<int>(
                  value: habitacion.id,
                  child: Text(habitacion.nombre ?? '',
                    style: TextStyle(
                    fontSize: 18,
                    color: Color(0xFF222B6F),
                  ),),
                );
              }).toList(),
              onChanged: (nuevoId) {
                setState(() {
                  habitacionSeleccioandaId = nuevoId;
                });
                debugPrint("Habitacion seleccionada ID: $habitacionSeleccioandaId");
              },
            ),)

          ],
        ),
        SizedBox(height: 40,),
        Row(
          children: [
            Text("Medidas"),
            SizedBox(width: 10,),
            Expanded(
              flex: 3,
              child: TextField(
                key: const Key('anchoField'),
                controller: _anchoController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.start,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  labelText: "ancho",
                  suffix: Text('m'),
                ),

                onChanged: (texto) {
                  if (texto.isEmpty) return;
                  String textoLimpio = texto.trim().replaceAll(',', '.');
                  double? numero = double.tryParse(textoLimpio);
                  if (numero == null || numero < 0) {
                    ToastManager.show(context, "Las medidas deben ser números", success: false);
                  }
                },
              ),
            ),
            SizedBox(width: 10,),
            Text("x"),
            SizedBox(width: 10,),
            Expanded(
              flex: 3,
              child : TextField(
                key: const Key('altoField'),
                controller: _altoController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.start,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  labelText: "Alto",
                  suffix: Text('m'),
                ),

                onChanged: (texto) {
                  if (texto.isEmpty) return;
                  String textoLimpio = texto.trim().replaceAll(',', '.');
                  double? numero = double.tryParse(textoLimpio);
                  if (numero == null || numero < 0) {
                    ToastManager.show(context, "Las medidas deben ser números", success: false);
                  }
                },
              ),
            ),
          ],
        ),



        SizedBox(height: 40,),
        Row(
          children: [
          _buildCantidad(),
        ],),

        SizedBox(height: 20,),
        
        if (caracteristicasP.isNotEmpty)...[
          Divider(),
          SizedBox(height: 20,),
          Text(
              "Seleccione una opción por característica",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF222B6F),
              ),
          ),
          SizedBox(height: 20,),
          ...caracteristicasP.map<Widget>((caracteristica) {
            int idCaract = caracteristica.id ?? 0;
            String nombreCaract = caracteristica.nombre ?? '';
            var opcionesRaw = caracteristica.opciones ?? [];

            return Container(
              width: double.infinity,
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nombreCaract,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Color(0xFF222B6F),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Wrap(
                    spacing: 12,
                    runSpacing: 10,
                    alignment: WrapAlignment.start,
                    children: opcionesRaw.map<Widget>((opc) {
                      final opcionModelo = opc;
                      bool estaSeleccionado = extrasElegidos[idCaract]?.id == opcionModelo.id;
                      double precioExtraSeguro = opcionModelo.precioExtra ?? 0.0;

                      return OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: estaSeleccionado ? const Color(0xFF222B6F) : Colors.white,
                          side: const BorderSide(color: Color(0xFF222B6F), width: 1.5),
                        ),
                        onPressed: () {
                          setState(() {
                            extrasElegidos[idCaract] = opcionModelo;
                          });
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              precioExtraSeguro > 0
                                  ? "${opcionModelo.nombre} (+$precioExtraSeguro€)"
                                  : opcionModelo.nombre!,
                              style: TextStyle(
                                color: estaSeleccionado ? Colors.white : const Color(0xFF222B6F),
                                fontWeight: estaSeleccionado ? FontWeight.bold : FontWeight.normal,
                                fontSize: 16,
                              ),
                            ),

                            if (opcionModelo.habitacionesRecomendadas.contains(habitacionSeleccioandaId))...[
                              SizedBox(width: 20,),
                              Icon(
                                Icons.star,
                                size: 20,
                                color: estaSeleccionado ? Colors.white : const Color(0xFF222B6F),
                              )
                            ],
                          ],
                        )
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          })
        ],

        SizedBox(height: 40,),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton(
              onPressed: () {
                _checkFields();
              },
              child: Text(_idModificar == null ? "Añadir al presupuesto" : "Modificar producto", style: TextStyle(color: Colors.white, fontSize: 18)),
            ),

            if(_idModificar!=null)...[
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: () {
                  _resetFields(false);
                },
                child: Text("Restablecer", style: TextStyle(color: Colors.white, fontSize: 18)),

              ),
            ]
          ],
        ),
        SizedBox(height: 40,),
      ],
    );
  }

  Widget _fomularioDech(bool esMovil){
    final lineasP = _presupuesto?.lineas ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const Center(
          child: Text(
            "Resumen Presupuesto",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24,
              color: Color(0xFF222B6F),
            ),
          ),
        ),

        const SizedBox(height: 40,),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const Text(
              "TOTAL PRESUPUESTO: ",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF222B6F), letterSpacing: 0.5),
            ),
            SizedBox(width: 20,),
            Text(
              "${(_presupuesto?.total ?? 0.0).toStringAsFixed(2)}€",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF222B6F)),
            ),
          ],
        ),
        const SizedBox(height: 20,),

        Text(
          "Productos:",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF222B6F), letterSpacing: 0.5),
        ),
        const SizedBox(height: 20,),

        if (_cargandoPresupuesto)
          const Center(child: CircularProgressIndicator(color: Color(0xFF222B6F)))
        else if (lineasP.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 40.0),
              child: Text(
                "No hay productos añadidos al presupuesto.",
                style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 16),
              ),
            ),
          )
        else
          ...lineasP.map((linea) {
            bool revisar = linea.requiereRevision ?? false;
            bool incompleto = _lineasIncompletas.contains(linea.id);

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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if(revisar || incompleto)...[
                          Tooltip(
                            message: revisar ? 'Producto descatalogado o con opciones descatalogadas' : 'Quedan caracteristicas por elegir',
                            waitDuration: Duration(milliseconds: 500),
                            showDuration: Duration(seconds: 2),
                            child:  Icon(
                              Icons.error_outline,
                              color: Colors.red,
                            ),
                          ),

                          SizedBox(width: 10,)
                        ],
                        Expanded(
                          child: Text(
                            linea.nombreProducto ?? "Producto sin nombre",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ),
                        Text(
                            "Cant: ${linea.cantidad}",
                            style: const TextStyle(color: Color(0xFF222B6F), fontWeight: FontWeight.bold)
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          "Medidas : ${linea.ancho.toStringAsFixed(2)} x ${linea.alto.toStringAsFixed(2)}",
                          style: const TextStyle(color: Color(0xFF222B6F), fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Spacer(),
                        Text(
                          "${linea.precioFinal?.toStringAsFixed(2) ?? '0.00'}€",
                          style: const TextStyle(color: Color(0xFF222B6F), fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),


                    if (linea.opciones.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: linea.opciones.map((opc) {
                          bool activa = opc.opcionActiva ?? true;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),

                            child: Row(
                             children: [
                               Text(
                                 "${opc.caracteristicaNombre}: ${opc.nombre}",

                                 style: activa ? TextStyle(
                                   fontSize: 13,
                                   color: Colors.black54,
                                 ) :
                                 TextStyle(
                                   fontSize: 13,
                                   color: Colors.black54,
                                   fontStyle: FontStyle.italic
                               ),
                               ),

                               if(!activa)...[
                                 SizedBox(width: 6,),
                                 Tooltip(
                                   message: 'Opción descatalogada',
                                   waitDuration: Duration(milliseconds: 500),
                                   showDuration: Duration(seconds: 2),
                                   child:  Icon(
                                     Icons.error_outline,
                                     color: Colors.black54,
                                   ),
                                 )

                               ]
                             ],
                            )
                          );

                        }).toList(),
                      ),
                    ],

                    const Divider(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if(linea.productoActivo!)...[
                          IconButton(
                            icon: Icon(
                                Icons.edit_outlined,
                                color: linea.id == _idModificar ? Colors.grey[300] : Color(0xFF222B6F)
                            ),
                            onPressed: () {
                              _modificarOpcion(linea.id!);
                            },
                          ),
                        ],

                        IconButton(
                          icon: Icon(
                              Icons.delete_outline,
                              color: linea.id == _idModificar ? Colors.grey[300] : Colors.red
                          ),
                          onPressed: () {
                            if(linea.id == _idModificar) return;

                            if (lineasP.length > 1) {
                              mostrarDialogoConfirmacion(
                                context: context,
                                mensaje: "¿Estas seguro que quieres borrar este porducto del presupuesto?",
                                id: linea.id!,
                                accionBorrar: (idParaBorrar) async {
                                  await _eliminarLineaPresupuesto(idParaBorrar);
                                  _resetFields(false);
                                },
                              );
                            }else{
                              if (_presupuesto == null) {
                                _resetFields(false);
                              }
                              else{
                                mostrarDialogoConfirmacion(
                                  context: context,
                                  mensaje: "¿Estas seguro que quieres borrar este presupuesto?",
                                  id: _presupuesto!.id!,
                                  accionBorrar: (idParaBorrar) async {
                                    await _eliminarPresupuesto(idParaBorrar);
                                    _resetFields(true);
                                  },
                                );
                              }

                              }
                            }

                        ),
                      ],
                    )
                  ],
                ),
              ),
            );
          }),

        SizedBox(height: lineasP.isEmpty ? 250 : 40),

        const Divider(thickness: 1.5),

        const SizedBox(height: 10),

        Align(
          alignment: Alignment.centerRight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [

              Row(

                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  if(_idProyecto==null)...[
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      ),
                      onPressed: lineasP.isEmpty ? null : () async {
                          if(_presupuesto == null){
                            _resetFields(false);
                          }else {
                            mostrarDialogoConfirmacion(
                              context: context,
                              mensaje: "¿Estas seguro que quieres borrar este presupuesto?",
                              id:_presupuesto!.id!,
                              accionBorrar: (idParaBorrar) async {
                                await _eliminarPresupuesto(idParaBorrar);
                                _resetFields(true);
                              },
                            );
                          }
                        },
                      child: const Text("Borrar", style: TextStyle(color: Colors.black54)),
                    ),
                    Spacer(),
                  ],

                  if(_presupuesto!=null && _presupuesto!.requireRevision!)...[
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      ),
                      onPressed: (){_limpiarPresupuesto(_presupuesto!.id!);},
                      child: const Text("Limpiar", style: TextStyle(color: Colors.black54)),
                    ),
                    Spacer(),
                  ],

                  ElevatedButton(
                    key: const Key('botonConfirmar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF222B6F),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    ),
                    onPressed: lineasP.isEmpty ? null : () {
                      _obtenerLineasIncompletas();
                      if(_idProyecto != null){
                        Navigator.pushNamed(context, 'modificarProyecto/', arguments: _idProyecto);
                      }
                      else if (_presupuesto != null && _lineasIncompletas.isEmpty){
                        Navigator.pushNamed(context, 'confirmacionPresupuesto/', arguments: _presupuesto!.id);
                      }else{
                        ToastManager.show(context, "Hay productos incompletos o no hya porductos en el presupuesto", success: false);
                      }
                    },
                    child: const Text("Confirmar Presupuesto", style: TextStyle(color: Colors.white)),
                  ),
                ],
              )
            ],
          ),
        ),
        const SizedBox(height: 40,),
      ],
    );
  }

  Widget _esCliente(bool esMovil, double ancho){
    return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,

        children: [
          Header(name: userName ?? '', isLoged: true),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              IconButton(
                  onPressed: (){
                    Navigator.pop(context, true);

                  },
                  icon:  Icon(Icons.arrow_back_ios_new_outlined, color: Color(0xFF222B6F))
              ),
              Text(
                _id == null ? 'CREAR PRESUPUESTO' : 'MODIFICAR PRESUPUESTO',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Color(0xFF222B6F),
                ),
              ),
            ],

          ),
          SizedBox(height: 20,),
          _formularioCompleto(esMovil)
        ]
    );
  }

  Widget _esEmpresa(bool esMovil, double ancho){
    return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,

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
                _id == null ? 'CREAR PRESUPUESTO' : 'MODIFICAR PRESUPUESTO',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: esMovil ? 20 : 24,
                  color: Color(0xFF222B6F),
                ),
              ),
              Spacer(),
            ],
          ),
          SizedBox(height: esMovil ? 0 : 50,),
          _formularioCompleto(esMovil)
        ]
    );
  }

  @override
  Widget build(BuildContext context){
    final screenWidth = MediaQuery.of(context).size.width;

    bool esMovil = screenWidth < 800;

    if (isLoadingUser){
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    if(userName == null){
      return NeedLoginWidget();
    }
    return Scaffold(
      drawer: (userRol != null && userRol != UserType.cliente)
          ? MenuEmpresa(current: PageKind.crearpreuspuesto, rol: userRol!)
          : null,
      body:
      LayoutBuilder(
          builder: (context, constrait){
            return
              SingleChildScrollView(
                child: Center(
                    child: Padding(
                      padding: esMovil
                          ? EdgeInsets.only(top:40, bottom: 20, left: 10, right: 10)
                          : EdgeInsets.symmetric(horizontal: /*userRol == UserType.cliente ? 40 :*/ 40, vertical: 40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,

                        children: [

                          if(userRol == UserType.cliente)...[
                            _esCliente(esMovil, screenWidth)
                          ]else...[
                            _esEmpresa(esMovil, screenWidth)
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