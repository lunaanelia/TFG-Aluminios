import 'package:aluminios/mixins/user_loader.dart';
import 'package:aluminios/models/tarea.dart';
import 'package:aluminios/repository/tarea_repository.dart';
import 'package:aluminios/widgets/need_login_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../widgets/menu_empresa.dart';
import '../utils/tipos.dart';
import '../utils/toast_manager.dart';


class TareasPageBoss extends StatefulWidget {
  const TareasPageBoss ({super.key});

  @override
  State<TareasPageBoss > createState() => _TareasPageBossState();
}

class _TareasPageBossState extends State<TareasPageBoss> with UserLoaderMixin {

  final TareaRepository _tareaRepository = TareaRepository();

  Map<DateTime, List<Tarea>> _tareasPorDia = {};

  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    loadCurrentUserData();
    _selectedDay = _focusedDay;
    _loadData();
  }

  Future <void> _loadData()async{
    try{
      final res = await _tareaRepository.getTodasTarea();
      if (mounted) {
        res.sort((a, b){
          if (a.fechaInicio!=null && b.fechaInicio!=null){
            return a.fechaInicio!.compareTo(b.fechaInicio!);
          }
          return (a.fechaInicio == null) ? 1 : -1;
        });

        Map<DateTime, List<Tarea>> tempTareas = {};
        for (var tarea in res){
          if (tarea.fechaInicio == null ) {
            continue;
          }

          DateTime fecha = tarea.fechaInicio!;
          DateTime fechaNormalizada = DateTime(fecha.year, fecha.month, fecha.day);

          if (tempTareas[fechaNormalizada] == null) {
            tempTareas[fechaNormalizada] = [];
          }
          tempTareas[fechaNormalizada]!.add(tarea);

          setState(() {
            _tareasPorDia = tempTareas;
          });
        }

      }
    }catch(e){
      if (mounted) {
        ToastManager.show(context, '$e', success: false);
      }
    }
  }

  List<Tarea> _getTareasDelDia(DateTime day) {
    final fechaNormalizada = DateTime(day.year, day.month, day.day);
    return _tareasPorDia[fechaNormalizada] ?? [];
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                  border: Border.all(color: tarea.bloqueada! ? Colors.grey.withValues(alpha:0.4) :colorEstado.withValues(alpha:0.4)),
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

          const SizedBox(height: 12),
          if (tarea.tipo != TipoTarea.montaje)...[
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Icon(Icons.person_outline, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Text(
                  "Trabajador asignado: ",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                ),
                Text(
                  "${tarea.trabajador}",
                  style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF222B6F), fontSize: 15),
                ),

              ],
            ),
          ],
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
        ],
      ),
    );
  }


  @override
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    bool esMovil = screenWidth < 600;
    if(isLoadingUser){
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if(userName == null){
      return NeedLoginWidget();
    }
    return Scaffold(
      drawer: MenuEmpresa(current: PageKind.todastareas, rol: userRol!),
      body: LayoutBuilder(
        builder: (context, constraints) {
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
                        icon: const Icon(Icons.menu, color: Color(0xFF222B6F)),
                      ),
                      Spacer(),
                      Text(
                          'CALENDARIO DE TAREAS',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: esMovil ? 20 : 24,
                            color: Color(0xFF222B6F),
                          ),
                          softWrap: true,
                      ),
                      const Spacer(),
                    ],
                  ),

                  const SizedBox(height: 40),
                  TableCalendar(
                    firstDay: DateTime.utc(2025, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    calendarFormat: _calendarFormat,
                    startingDayOfWeek: StartingDayOfWeek.monday,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    daysOfWeekHeight: 25.0,
                    locale: 'es_ES',
                    eventLoader: _getTareasDelDia,
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    },
                    onFormatChanged: (format) {
                      setState(() {
                        _calendarFormat = format;
                      });
                    },
                    onPageChanged: (focusedDay) {
                      _focusedDay = focusedDay;
                    },
                    calendarStyle: const CalendarStyle(
                      defaultTextStyle: TextStyle(color: Color(0xFF222B6F), fontWeight: FontWeight.w500),
                      weekendTextStyle: TextStyle(color: Colors.blueGrey),

                      outsideTextStyle: TextStyle(color: Colors.black26),

                      selectedDecoration: BoxDecoration(color: Color(0xFF222B6F), shape: BoxShape.circle),
                      selectedTextStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),


                      todayDecoration: BoxDecoration(color: Color(0xFFA2C5DB), shape: BoxShape.circle),
                      todayTextStyle: TextStyle(color: Colors.white),

                      markerDecoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    ),
                  ),

                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 20),

                  _getTareasDelDia(_selectedDay!).isEmpty
                      ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text("No hay tareas programadas para este día."),
                    ),
                  )
                      : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _getTareasDelDia(_selectedDay!).length,
                    itemBuilder: (context, index) {
                      final tarea = _getTareasDelDia(_selectedDay!)[index];
                      return _buildTareaCard(tarea);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}