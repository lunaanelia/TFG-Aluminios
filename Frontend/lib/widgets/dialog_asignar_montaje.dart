import 'package:aluminios/models/usuario.dart';
import 'package:aluminios/repository/tarea_repository.dart';
import 'package:aluminios/repository/user_repository.dart';
import 'package:aluminios/utils/toast_manager.dart';
import 'package:flutter/material.dart';

import '../models/tarea.dart';

class DialogAsignarMontaje extends StatefulWidget {
  final int proyectoId;
  final Tarea ? tarea;
  const DialogAsignarMontaje({super.key, required this.proyectoId, this.tarea});

  @override
  State<DialogAsignarMontaje> createState() => _DialogAsignarMontajeState();
}

class _DialogAsignarMontajeState extends State<DialogAsignarMontaje> {
  DateTime? _fechaSeleccionada;
  TimeOfDay? _horaInicio;
  TimeOfDay? _horaFin;
  List<Usuario> _trabajadoresSeleccionados = [];
  List<Usuario> _allUsuario = [];
  final UserRepository _userRepository = UserRepository();
  final TareaRepository _tareaRepository = TareaRepository();

  bool _isLoanding= true;

  @override
  void initState(){
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final List<Usuario> res = await _userRepository.getUsers();

      if (mounted) {
        setState(() {

          _allUsuario = res.where((usuario) {
            return (usuario.rol == "trabajador" || usuario.rol == "jefe");
          }).toList();

          if(widget.tarea != null){
            _fechaSeleccionada = widget.tarea!.fechaInicio;
            _horaInicio = TimeOfDay.fromDateTime(widget.tarea!.fechaInicio!);
            if (widget.tarea!.fechaFin != null) {
              _horaFin = TimeOfDay.fromDateTime(widget.tarea!.fechaFin!);
            }

            _trabajadoresSeleccionados = _allUsuario.where((user) {
              return widget.tarea?.trabajadoresIds?.contains(user.id) ?? false;
            }).toList();
          }
          _isLoanding = false;
        });
      }
    } catch (e) {
      debugPrint("Get usuarios error: $e");
    }
  }
  DateTime combinarFechaYHora(DateTime fecha, TimeOfDay hora) {
    return DateTime(
      fecha.year,
      fecha.month,
      fecha.day,
      hora.hour,
      hora.minute,
    );
  }

  Future<void> _crearTarea()async{
    if (_fechaSeleccionada == null || _horaInicio == null || _horaFin == null) {
      ToastManager.show(context, "Hay campos vacios", success: false);
      return;
    }
    final DateTime fechaInicio = combinarFechaYHora(_fechaSeleccionada!, _horaInicio!);
    final DateTime fechaFin = combinarFechaYHora(_fechaSeleccionada!, _horaFin!);

    try{
      if(widget.tarea == null) {
        await _tareaRepository.crearTarea(
            widget.proyectoId, fechaInicio, fechaFin,
            _trabajadoresSeleccionados);
      }else{
        await _tareaRepository.modificarTarea(
            widget.tarea!.id, widget.proyectoId, fechaInicio, fechaFin,
            _trabajadoresSeleccionados);
      }
      if (mounted){
        if(widget.tarea == null){
          ToastManager.show(context, "Tarea creada con exito", success: true);
        }else{
          ToastManager.show(context, "Tarea modificada con exito", success: true);
        }
      }
    }catch(e){
      if(mounted) ToastManager.show(context, "$e", success: false);
    }
  }
  @override
  Widget build(BuildContext context) {
    if (_isLoanding){
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.build_circle_outlined, color: Color(0xFF222B6F)),
          SizedBox(width: 8),

          Expanded(child: Text(
              'Asignar tiempo para montar',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF222B6F))
          ),)
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: const Icon(Icons.calendar_today, color: Color(0xFF222B6F)),
              title: Text(_fechaSeleccionada == null
                  ? 'Seleccionar Día'
                  : '${_fechaSeleccionada!.day}/${_fechaSeleccionada!.month}/${_fechaSeleccionada!.year}',
                  style: TextStyle(color: Color(0xFF222B6F))
              ),

              onTap: () async {
                DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2026),
                  lastDate: DateTime(2030),
                );
                if (picked != null) {
                  setState(() => _fechaSeleccionada = picked);
                }
              },
            ),
            const Divider(),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: const Text('Inicio', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    subtitle: Text(_horaInicio == null ? '--:--' : _horaInicio!.format(context)),
                    onTap: () async {
                      TimeOfDay? picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                      if (picked != null) setState(() => _horaInicio = picked);
                    },
                  ),
                ),
                Expanded(
                  child: ListTile(
                    title: const Text('Fin', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    subtitle: Text(_horaFin == null ? '--:--' : _horaFin!.format(context)),
                    onTap: () async {
                      TimeOfDay? picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                      if (picked != null) setState(() => _horaFin = picked);
                    },
                  ),
                ),
              ],
            ),
            const Divider(),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                  'Asignar Operarios:',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF222B6F))
              ),
            ),

            ..._allUsuario.map((user) {
              return CheckboxListTile(
                title: Text(user.firstName!, style: TextStyle(color: Color(0xFF222B6F)),),
                activeColor: const Color(0xFF222B6F),
                value: _trabajadoresSeleccionados.any((u) => u.id == user.id),
                onChanged: (bool? checked) {
                  setState(() {
                    if (checked == true) {
                      if (!_trabajadoresSeleccionados.any((u) => u.id == user.id)) {
                        _trabajadoresSeleccionados.add(user);
                      }
                    } else {
                      _trabajadoresSeleccionados.removeWhere((u) => u.id == user.id);
                    }
                  });
                },
              );
            })
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF222B6F),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () async {
            if (_fechaSeleccionada != null && _horaInicio != null && _horaFin != null && _trabajadoresSeleccionados.isNotEmpty) {

              await _crearTarea();
              if (context.mounted) {
                Navigator.of(context).pop(true);
              }
            }
          },
          child: const Text('Guardar Tarea'),
        ),
      ],
    );
  }
}