import 'dart:async';
import 'package:aluminios/models/tiempo_tarea.dart';
import 'package:aluminios/models/habitacion.dart';
import 'package:aluminios/repository/cita_repository.dart';
import 'package:aluminios/repository/presupuesto_repository.dart';
import 'package:aluminios/repository/product_repository.dart';
import 'package:aluminios/repository/tarea_repository.dart';
import 'package:aluminios/widgets/need_login_widget.dart';
import 'package:aluminios/widgets/no_access_widget.dart';
import 'package:aluminios/widgets/menu_empresa.dart';
import 'package:aluminios/utils/toast_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' show LatLng, Distance;
import '../widgets/banner_delete.dart';
import '../utils/tipos.dart';
import '../mixins/user_loader.dart';

class ConfiguracionPage extends StatefulWidget {
  const ConfiguracionPage({super.key});

  @override
  State<ConfiguracionPage> createState() => _ConfiguracionState();
}

class _ConfiguracionState extends State<ConfiguracionPage> with UserLoaderMixin{
  static const LatLng _centroBase = LatLng(37.29436173988716, -4.871455574171553);
  double _distanciaKm = 5.0;

  final double _distanciaMin = 1.0;
  final double _distanciaMax = 150.0;
  final MapController _mapController = MapController();

  bool _mapaListo = false;

  final ProductRepository _productRepository = ProductRepository();
  final PresupuestoRepository _presupuestoRepository = PresupuestoRepository();
  final TareaRepository _tareaRepository = TareaRepository();
  final CitaRepository _citaRepository = CitaRepository();

  List <Habitacion> _allHabitaciones = [];
  List <TiempoTarea> _allTiempoTareas = [];

  final TextEditingController _fianzaController = TextEditingController();
  final TextEditingController _diasController = TextEditingController();

  bool _isLoading = true;

  Timer? _fianzaDebounceTimer;
  Timer ? _diasDebounceTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose(){
    _fianzaDebounceTimer?.cancel();
    _diasDebounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    await loadCurrentUserData();

    if(userName == null){
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try{
      final res = await _productRepository.getHabitaciones();

      if(mounted){
        setState(() {
          _allHabitaciones = res;
          _isLoading = false;
        });
      }
    }catch(e){
      if(mounted){
        setState(() {
          _isLoading = false;
        });
        ToastManager.show(context, "$e", success: false);
      }
    }

    try{
      final res = await _presupuestoRepository.getDistancia();
      if(mounted){

        setState(() {
          _distanciaKm = res;
          _ajustarZoomAlRadio(_distanciaKm);
        });
      }
    }catch(e){
      if(mounted){
        ToastManager.show(context, "$e", success: false);
      }
    }

    try{
      final res = await _tareaRepository.getTiempoTareas();

      if(mounted){
        setState(() {
          _allTiempoTareas = res;
        });
      }
    }catch(e){
      if(mounted){
        ToastManager.show(context, "$e", success: false);
      }
    }

    try{
      final res = await _presupuestoRepository.getFianza();
      if(mounted){
        setState(() {
          _fianzaController.text = res.toString();
        });
      }
    }catch(e){
      if(mounted) ToastManager.show(context, "$e", success: false);
    }

    try{
      final res = await _citaRepository.getDiasCancelacion();
      if(mounted){
        setState(() {
          _diasController.text = res.toString();
        });
      }
    }catch(e){
      if(mounted) ToastManager.show(context, "$e", success: false);
    }

  }

  Future<void> _updateDistancia() async{
    try{
      await _presupuestoRepository.updateDistancia(_distanciaKm);
      if(mounted){
        ToastManager.show(context, "Distancia cambiada con exito");
      }
    }catch(e){
      if (mounted) {
        ToastManager.show(context, "$e", success: false);
      }
    }
  }

  void _onFianzaChange(String nuevo){
    if(_fianzaDebounceTimer?.isActive ?? false) _fianzaDebounceTimer!.cancel();


    _fianzaDebounceTimer = Timer(const Duration(milliseconds: 1000), ()async{

      String textoLimpio = nuevo.replaceAll(',', '.');
      double fianza = double.tryParse(textoLimpio) ?? 0.0;
      try {
        await _presupuestoRepository.updateFianza(fianza);
        if (mounted) {
          //ToastManager.show(context, "Distancia cambiada con exito");
        }
      } catch (e) {
        if (mounted) {
          ToastManager.show(context, "$e", success: false);
        }
      }

    });
  }

  void _onDiasChange(String nuevo){
    if(_diasDebounceTimer?.isActive ?? false) _diasDebounceTimer!.cancel();

    _diasDebounceTimer = Timer(const Duration(milliseconds: 1000), ()async{

      int dias = int.tryParse(_diasController.text) ?? 0;
      try{
        await _citaRepository.updateDiasCancelacion(dias);
        if(mounted){
          //ToastManager.show(context, "Distancia cambiada con exito");
        }
      }catch(e){
        if (mounted) {
          ToastManager.show(context, "$e", success: false);
        }
      }

    });
  }

  void _mostrarDialogoNuevaHabitacion(BuildContext context) {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: const Text('Nueva Habitación', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Ej: Salón, Cocina, Buhardilla...',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF222B6F), foregroundColor: Colors.white),
              onPressed: () {
                _createHabitacion(controller.text);
                Navigator.pop(context);
              },
              child: const Text('Añadir'),
            ),
          ],
        );
      },
    );
  }

  void _ajustarZoomAlRadio(double radioEnKm) {
    if (!_mapaListo) return;

    final Distance objetoDistancia = const Distance();

    double distanciaMetros = radioEnKm * 1000;

    LatLng puntoNorte = objetoDistancia.offset(_centroBase, distanciaMetros, 0);
    LatLng puntoEste  = objetoDistancia.offset(_centroBase, distanciaMetros, 90);
    LatLng puntoSur   = objetoDistancia.offset(_centroBase, distanciaMetros, 180);
    LatLng puntoOeste = objetoDistancia.offset(_centroBase, distanciaMetros, 270);

    final bounds = LatLngBounds.fromPoints([puntoNorte, puntoEste, puntoSur, puntoOeste]);

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(50.0),
      ),
    );
  }

  Future<void> _createHabitacion(String nombre)async{
    try{
      final res = await _productRepository.createHabitacion(nombre);

      if(mounted){
        setState(() {
          _allHabitaciones.add(res);
          ToastManager.show(context, "Habitación añadida correctamente");
        });
      }

    }catch(e){
      if(mounted){
        ToastManager.show(context, "$e", success: false);
      }
    }
  }

  Future<void> _deleteHabitacion(int id)async{
    try{
      await _productRepository.deleteHabitacion(id);
      if(mounted){
        setState(() {
          _allHabitaciones.removeWhere((h) => h.id == id);
          ToastManager.show(context, "Habitación eliminada correctamente");
        });
      }
    }catch(e){
      if(mounted){
        ToastManager.show(context, "$e", success: false);

      }
    }
  }

  Future<void> _modificarDuracion(int id, double duracion)async{
    try{
      await _tareaRepository.updateTiempoTarea(id, duracion);
      if(mounted){
        setState(() {
          TiempoTarea tareaT = _allTiempoTareas.firstWhere((tarea) => tarea.id == id);
          tareaT.tiempoEstimadoHoras = duracion;

          ToastManager.show(context, "Duración tarea actualizado");
        });
      }
    }catch(e){
      if(mounted){
        ToastManager.show(context, "$e", success: false);

      }
    }
  }

  @override
  Widget build(BuildContext context){

    if (_isLoading){
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if(userName == null){
      return NeedLoginWidget();
    }

    return Scaffold(
        drawer: MenuEmpresa(current: PageKind.configuracion, rol: userRol!),
        body: LayoutBuilder(
            builder: (context, constraints) {
              bool esMovil = constraints.maxWidth < 700;

              if(!isLoadingUser && userRol != UserType.jefe){
                return const NoAccessWidget();
              }

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                    padding: esMovil
                        ? EdgeInsets.only(top:40, bottom: 20, left: 10, right: 10)
                        : EdgeInsets.all(40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                                'CONFIGURACIÓN',
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Expanded(
                                  child: Text(
                                    'Configuración de dirección máxima para montar:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: Color(0xFF222B6F),
                                    ),
                                  ),
                              ),
                            ],
                          ),
                          SizedBox(height: 20,),

                          Column(
                            children: [
                              SizedBox(
                                height: 400,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: FlutterMap(
                                    mapController: _mapController,
                                    options: MapOptions(
                                      initialCenter: _centroBase,
                                      initialZoom: 11.0,
                                      onMapReady: () {
                                        setState(() {
                                          _mapaListo = true;
                                        });
                                        _ajustarZoomAlRadio(_distanciaKm);
                                      },
                                    ),
                                    children: [
                                      TileLayer(
                                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                        userAgentPackageName: 'com.tuempresa.aluminios',
                                      ),
                                      CircleLayer(
                                        circles: [
                                          CircleMarker(
                                            point: _centroBase,
                                            color: Color(0xFF222B6F).withValues(alpha: 0.15),
                                            borderColor: Color(0xFF222B6F),
                                            borderStrokeWidth: 2,
                                            useRadiusInMeter: true,
                                            radius: _distanciaKm * 1000,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(16.0),
                                color: Colors.white,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'Distancia: ${_distanciaKm.toStringAsFixed(1)} km',
                                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                        ),
                                        Spacer(),
                                        IconButton(
                                            onPressed: (){_updateDistancia();},
                                            icon: Icon(
                                                Icons.save,
                                              color: Color(0xFF222B6F),
                                            )
                                        )
                                      ],
                                    ),

                                    Row(
                                      children: [
                                        Text('${_distanciaMin.toInt()} km'),
                                        Expanded(
                                          child: SliderTheme(
                                            data: SliderTheme.of(context).copyWith(
                                              activeTrackColor: Color(0xFF222B6F),
                                              inactiveTrackColor: Color(0xFF222B6F)..withValues(alpha: 0.24),
                                              thumbColor: Color(0xFF222B6F),
                                              overlayColor: Color(0xFF222B6F)..withValues(alpha: 0.12),
                                              activeTickMarkColor: Color(0xFF222B6F),
                                              inactiveTickMarkColor:Color(0xFF222B6F)..withValues(alpha: 0.5),
                                            ),
                                            child: Slider(
                                              value: _distanciaKm,
                                              min: _distanciaMin,
                                              max: _distanciaMax,
                                              divisions: 49,
                                              onChanged: (nuevoValor) {
                                                setState(() {
                                                  _distanciaKm = nuevoValor;
                                                });
                                                Future.microtask(() => _ajustarZoomAlRadio(nuevoValor));
                                              },
                                            ),
                                          )
                                        ),
                                        Text('${_distanciaMax.toInt()} km'),
                                      ],
                                    ),
                                  ],
                                ),
                              )
                            ],
                          ),

                          SizedBox(height: 40,),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Configuración de habitaciones:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Color(0xFF222B6F),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),

                              IconButton(
                                icon: const Icon(Icons.add, color: Color(0xFF222B6F),),
                                onPressed: () => _mostrarDialogoNuevaHabitacion(context),
                              ),

                            ],
                          ),
                          SizedBox(height: 20,),
                          if (_allHabitaciones.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                              ),
                              child: const Center(
                                child: Text(
                                  'No hay habitaciones añadidas. Configura al menos una para recomendar productos.',
                                  style: TextStyle(color: Colors.grey, fontSize: 14),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            )
                          else
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final bool esAncho = constraints.maxWidth > 600;
                                final double tarjetaWidth = esAncho ? (constraints.maxWidth - 12) / 2 : constraints.maxWidth;

                                return Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: List.generate(_allHabitaciones.length, (index) {
                                    return SizedBox(
                                      width: tarjetaWidth,
                                      child: Card(
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          side: BorderSide(color: Colors.grey.shade300, width: 1),
                                        ),
                                        color: const Color(0xFFF8FAFC),
                                        child: ListTile(
                                          title: Text(
                                            _allHabitaciones[index].nombre!,
                                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF222B6F)),
                                          ),
                                          trailing: IconButton(
                                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                            tooltip: 'Eliminar estancia',
                                            onPressed: () {
                                              mostrarDialogoConfirmacion(
                                                context: context,
                                                mensaje: "¿Estas seguro que quieres borrar esta habitacion para recomendaciones?",
                                                id: _allHabitaciones[index].id!,
                                                accionBorrar: (idParaBorrar) async {
                                                  await _deleteHabitacion(idParaBorrar);
                                                },
                                              );

                                              },
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                );
                              },
                            ),

                          SizedBox(height: 40,),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                'Configuración de tiempo por tarea:',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Color(0xFF222B6F),
                                  fontWeight: FontWeight.bold
                                ),
                              ),

                            ],
                          ),
                          SizedBox(height: 20,),
                          if (_allTiempoTareas.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                              ),
                              child: const Center(
                                child: Text(
                                  'Cargando ...',
                                  style: TextStyle(color: Colors.grey, fontSize: 14),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            )
                          else
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final bool esAncho = constraints.maxWidth > 600;
                                final double tarjetaWidth = esAncho ? (constraints.maxWidth - 12) / 2 : constraints.maxWidth;

                                Duration doubleADuration(double horasDecimales) {
                                  final int minutosTotales = (horasDecimales * 60).round();
                                  return Duration(minutes: minutosTotales);
                                }

                                double durationADouble(Duration duracion) {
                                  return duracion.inMinutes / 60.0;
                                }

                                return Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: List.generate(_allTiempoTareas.length, (index) {
                                    final tiempoTarea = _allTiempoTareas[index];

                                    final duration = doubleADuration(tiempoTarea.tiempoEstimadoHoras);
                                    final String textoHoras = '${duration.inHours}h';
                                    final String textoMinutos = duration.inMinutes % 60 > 0 ? ' ${duration.inMinutes % 60}min' : '';

                                    return SizedBox(
                                      width: tarjetaWidth,
                                      child: Card(
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          side: BorderSide(color: Colors.grey.shade300, width: 1),
                                        ),
                                        color: const Color(0xFFF8FAFC),
                                        child: ListTile(

                                          title: Text(
                                            tiempoTarea.proceso.text,
                                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF222B6F)),
                                          ),
                                          subtitle: Text(
                                            'Tiempo estimado: $textoHoras$textoMinutos',
                                            style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500),
                                          ),

                                          trailing: IconButton(
                                            icon: const Icon(Icons.edit_calendar_rounded, color: Color(0xFF222B6F), size: 20),
                                            tooltip: 'Modificar tiempo',
                                            onPressed: () async {
                                              final TimeOfDay? tiempoElegido = await showTimePicker(
                                                context: context,
                                                initialTime: TimeOfDay(hour: duration.inHours, minute: duration.inMinutes % 60),
                                                helpText: 'DURACIÓN: ${tiempoTarea.proceso.text.toUpperCase()}',
                                                initialEntryMode: TimePickerEntryMode.input,
                                                builder: (BuildContext context, Widget? child) {
                                                  return MediaQuery(
                                                    data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
                                                    child: child!,
                                                  );
                                                },
                                              );

                                              if (tiempoElegido != null && mounted) {
                                                final nuevaDuration = Duration(hours: tiempoElegido.hour, minutes: tiempoElegido.minute);
                                                _modificarDuracion(_allTiempoTareas[index].id, durationADouble(nuevaDuration));
                                              }
                                            },
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                );
                              },
                            ),

                          SizedBox(height: 40,),
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 15,
                            runSpacing: 10,
                            children: [
                              const Text(
                                'Configuración porcentaje fianza:',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Color(0xFF222B6F),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              SizedBox(
                                width: 120,
                                child: TextField(
                                  controller: _fianzaController,
                                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                                  onChanged: (value) => _onFianzaChange(value),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFF222B6F),
                                    fontWeight: FontWeight.bold,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Fianza',
                                    labelStyle: const TextStyle(color: Color(0xFF222B6F)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),

                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(color: Color(0xFF222B6F), width: 1.5),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(color: Color(0xFF222B6F), width: 2.0),
                                    ),

                                    suffixIcon: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        GestureDetector(
                                          onTap: () {
                                            double actual = double.tryParse(_fianzaController.text) ?? 0;
                                            _fianzaController.text = (actual + 5).toString();
                                            _onFianzaChange(_fianzaController.text);
                                          },
                                          child: const Icon(Icons.keyboard_arrow_up, color: Color(0xFF222B6F), size: 18),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            double actual = double.tryParse(_fianzaController.text) ?? 0.0;
                                            if (actual >= 5) _fianzaController.text = (actual - 5).toString();
                                            _onFianzaChange(_fianzaController.text);
                                          },
                                          child: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF222B6F), size: 18),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 40,),

                          Wrap(

                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 15,
                            runSpacing: 10,
                            children: [
                              const Text(
                                'Configuración días de cancelación:',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Color(0xFF222B6F),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(
                                width: 120,
                                child: TextField(
                                  controller: _diasController,
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) => _onDiasChange(value),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFF222B6F),
                                    fontWeight: FontWeight.bold,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Días',
                                    labelStyle: const TextStyle(color: Color(0xFF222B6F)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),

                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(color: Color(0xFF222B6F), width: 1.5),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(color: Color(0xFF222B6F), width: 2.0),
                                    ),

                                    suffixIcon: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        GestureDetector(
                                          onTap: () {
                                            int actual = int.tryParse(_diasController.text) ?? 0;
                                            _diasController.text = (actual + 1).toString();
                                            _onDiasChange(_diasController.text);
                                          },
                                          child: const Icon(Icons.keyboard_arrow_up, color: Color(0xFF222B6F), size: 18),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            int actual = int.tryParse(_diasController.text) ?? 0;
                                            if (actual >= 1) _diasController.text = (actual - 1).toString();
                                            _onDiasChange(_diasController.text);
                                          },
                                          child: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF222B6F), size: 18),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 20,),
                        ],
                      )
                    ),
              );
          }),
    );
  }
}