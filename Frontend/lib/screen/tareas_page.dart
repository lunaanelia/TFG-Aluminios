import 'package:aluminios/repository/tarea_repository.dart';
import 'package:aluminios/widgets/menu_empresa.dart';
import 'package:aluminios/widgets/need_login_widget.dart';
import 'package:aluminios/utils/tipos.dart';
import 'package:aluminios/utils/toast_manager.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../mixins/user_loader.dart';
import '../models/tarea.dart';
import '../widgets/no_access_widget.dart';

class TareasPage extends StatefulWidget {
  const TareasPage({super.key});

  @override
  State<TareasPage> createState() => _TareasPageState();
}

class _TareasPageState extends State<TareasPage> with UserLoaderMixin {
  bool _isLoading = true;
  final TareaRepository _tareaRepository = TareaRepository();
  List<Tarea> _allTareas = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await loadCurrentUserData();
    if(userName == null){
      setState(() {
        _isLoading = false;
      });
      return;
    }
    try {
      final res = await _tareaRepository.getTarea();
      if (mounted) {
        setState(() {
          _allTareas = res;
          _isLoading = false;
          _allTareas.sort((a, b){
            if (a.fechaInicio!=null && b.fechaInicio!=null){
              return a.fechaInicio!.compareTo(b.fechaInicio!);
            }
            return (a.fechaInicio == null) ? 1 : -1;
          });
        });
      }
    } catch (e) {
      if (mounted) {
        ToastManager.show(context, '$e', success: false);
        setState(() {
          _isLoading = false;
        });
      }
    }
  }


  Future<void> _asignarTarea(int id) async{
    try{
      await _tareaRepository.iniciarTarea(id);
      if (mounted){
        ToastManager.show(context, "Tarea asignada con exito");
        _loadData();
      }
    }catch(e){
      if(mounted) ToastManager.show(context, "$e", success: false);
    }
  }

  Future<void> _terminarTarea(int id) async{
    try{
      await _tareaRepository.terminarTarea(id);
      if (mounted){
        ToastManager.show(context, "Tarea actualizada con exito");
        _loadData();
      }
    }catch(e){
      if(mounted) ToastManager.show(context, "$e", success: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    bool esMovil = screenWidth < 600;

    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if(userName == null){
      return NeedLoginWidget();
    }

    if (userRol == UserType.cliente) {
      return const NoAccessWidget();
    }

    return Scaffold(
      drawer: MenuEmpresa(current: PageKind.mistareas, rol: userRol!),
      body: LayoutBuilder(
        builder: (context, constraints) {
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
                              'MIS TAREAS',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: esMovil ? 20 : 24,
                                color: Color(0xFF222B6F),
                              ),
                            ),
                            Spacer(),
                          ],
                        ),
                       _buildListaTareas(),

                        const SizedBox(height: 40),
                      ]
                  )
              )
          );
        },
      ),
    );
  }

  Widget _buildListaTareas() {
    if (_allTareas.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.assignment_turned_in_outlined, size: 48, color: Colors.grey),
              SizedBox(height: 12),
              Text(
                "No hay tareas registradas en el sistema.",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _allTareas.length,
      itemBuilder: (context, index) {
        final tarea = _allTareas[index];
        return _buildTareaCard(tarea);
      },
    );
  }

  Widget _buildTareaCard(Tarea tarea) {
    final DateFormat formateador = DateFormat('dd/MM/yyyy HH:mm');
    String inicio = tarea.fechaInicio != null ? formateador.format(tarea.fechaInicio!) : 'Sin fecha';
    String fin= tarea.fechaFin != null ? formateador.format(tarea.fechaFin!) : 'Sin fecha';

    Color colorEstado;
    IconData iconoEstado;
    switch (tarea.estado.toLowerCase()) {
      case 'terminada':
        colorEstado = Colors.green;
        iconoEstado = Icons.check_circle_outline;
        break;
      case 'en_proceso':
        colorEstado = Colors.orange;
        iconoEstado = Icons.pending_outlined;
        break;
      default:
        colorEstado = Colors.redAccent;
        iconoEstado = Icons.error_outline;
    }

    return Container(
      key: Key('tarea_${tarea.id}'),
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F5F7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF222B6F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'TAREA DE ${tarea.tipo.text.toUpperCase()}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  softWrap: true,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: tarea.bloqueada! ? Colors.grey.withValues(alpha:0.1) : colorEstado.withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: tarea.bloqueada! ? Colors.grey.withValues(alpha:0.4) : colorEstado.withValues(alpha:0.4)),
                ),
                child: Row(
                  children: [
                    if(tarea.bloqueada!)...[
                      Icon(Icons.lock, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        'BLOQUEADA',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                    ]else...[
                      Icon(iconoEstado, size: 14, color: colorEstado),
                      const SizedBox(width: 4),
                      Text(
                        tarea.estado.toUpperCase(),
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colorEstado),
                      ),
                    ]
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: Colors.black12),
          ),
          if(tarea.tipo == TipoTarea.montaje)...[

            if (tarea.trabajadoresNombres != null && tarea.trabajadoresNombres!.isNotEmpty)...[
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(Icons.people_alt_outlined, size: 20, color: Color(0xFF222B6F)),
                  SizedBox(width: 8),
                  Text(
                    "Compañeros:",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  )
                ],
              ),
              ...tarea.trabajadoresNombres!.map((nombre) {
                return Padding(
                  padding: const EdgeInsets.only(left: 28.0, bottom: 6.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [

                      const Icon(
                        Icons.fiber_manual_record,
                        size: 8,
                        color: Color(0xFF222B6F),
                      ),
                      SizedBox(width: 8,),
                      Expanded(
                        child: Text(
                          nombre,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                );
              })

            ],
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(height: 1, color: Colors.black12),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_on_outlined, size: 20, color: Color(0xFF222B6F)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Direccion: ${tarea.direccionObra ?? "Sin direccion"}",
                    softWrap: true,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],

          if(tarea.tipo != TipoTarea.montaje && tarea.tipo != TipoTarea.preparar_envio)...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Producto: ${tarea.linea!.nombreProducto!.toUpperCase()}",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18,),
                )
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 20,
              runSpacing: 10,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [

                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.straighten, size: 18, color: Color(0xFF222B6F)),
                    const SizedBox(width: 8),
                    Text(
                      "Medidas ${tarea.linea!.ancho} x ${tarea.linea!.alto} cm",
                      style: const TextStyle(fontSize: 18),
                    ),
                  ],
                ),
                Text(
                  "Cantidad: ${tarea.linea!.cantidad}",
                  style: const TextStyle(fontSize: 18),
                ),
              ],
            ),

          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(Icons.assignment_outlined, size: 20, color: Color(0xFF222B6F)),
              SizedBox(width: 8),
              Text(
                "Caracteristicas:",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          if (tarea.linea != null)
            ...tarea.linea!.opciones.map((caracteristica) {
              return Padding(
                padding: const EdgeInsets.only(left: 28.0, bottom: 6.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [

                    const Icon(
                      Icons.fiber_manual_record,
                      size: 8,
                      color: Color(0xFF222B6F),
                    ),
                    SizedBox(width: 8,),
                    Expanded(
                      child: Text(
                        "${caracteristica.caracteristicaNombre} : ${caracteristica.nombre}",
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              );
            })
          else
            const Padding(
              padding: EdgeInsets.only(left: 28.0),
              child: Text(
                "Sin características especificadas",
                style: TextStyle(fontSize: 16, color: Colors.black45, fontStyle: FontStyle.italic),
              ),
            ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: Colors.black12),
          ),
    ],
          Wrap(
            spacing: 20,
            runSpacing: 10,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [

              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.play_circle_outline, size: 16, color: Color(0xFF222B6F)),
                  const SizedBox(width: 8),
                  Text(
                    "Inicio: $inicio",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ],
              ),

              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_outline, size: 16, color: Color(0xFF222B6F)),
                  const SizedBox(width: 8),
                  Text(
                    "Fin: $fin",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if(tarea.estado == 'en_proceso') ...[
                if(tarea.tipo == TipoTarea.preparar_envio)...[
                  ElevatedButton(
                      onPressed: ()async{
                        final res = await Navigator.pushNamed(context, 'datosEnvio/', arguments: tarea.id);

                        if (mounted && res == true){
                          _loadData();
                        }
                        },
                      child: Text("Ver datos envio")
                  ),
                  SizedBox(width: 10,)
                ]else ...[
                  ElevatedButton(
                      key: Key('terminarTarea_${tarea.id}'),
                      onPressed: (){_terminarTarea(tarea.id);},
                      child: Text("Terminar tarea")
                  )
                ]
              ],
              if(tarea.estado == 'pendiente' && !tarea.bloqueada!) ...[
                ElevatedButton(
                    key: Key('iniciarTarea_${tarea.id}'),
                    onPressed: (){_asignarTarea(tarea.id);},
                    child: Text("Iniciar tarea")
                )
              ]

            ],
          ),
        ],
      ),
    );
  }
}