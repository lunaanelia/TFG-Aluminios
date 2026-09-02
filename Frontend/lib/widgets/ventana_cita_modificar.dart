import 'package:aluminios/repository/cita_repository.dart';
import 'package:aluminios/utils/toast_manager.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/cita.dart';

class VentanaCitaModificar extends StatefulWidget{
  final Cita cita;

  final VoidCallback onCitaModificada;

  const VentanaCitaModificar({
    super.key,
    required this.cita,
    required this.onCitaModificada
  });

  @override
  State<VentanaCitaModificar> createState()=> _VentanaCitaState();

}

class _VentanaCitaState extends State<VentanaCitaModificar> {
  late TextEditingController _fechaController;
  late TextEditingController _horaInicioController;
  late TextEditingController _horaFinController;

  bool _fechaError = false;
  bool _horaIniError = false;
  bool _horaFinError = false;

  final CitaRepository _citaRepository = CitaRepository();

  @override
  void initState() {
    super.initState();
    _fechaController = TextEditingController(text: DateFormat('dd/MM/yyyy').format(widget.cita.fecha));
    _horaInicioController = TextEditingController(text: widget.cita.horaInicio);
    _horaFinController = TextEditingController(text: widget.cita.horaFin);
  }

  Future<void> _checkFields() async {
    setState(() {
      _fechaError = _fechaController.text.isEmpty;
      _horaIniError = _horaInicioController.text.isEmpty;
      _horaFinError = _horaFinController.text.isEmpty;
    });

    if(_fechaError ||_horaFinError || _horaIniError){
      ToastManager.show(context, "Todos los campos deben estar rellenos.",success: false);
      return;
    }

    try{
      final DateTime fecha = DateFormat("d/M/yyyy",).parse(_fechaController.text);
      final String horaIni =  _horaInicioController.text;
      final String horaFin = _horaFinController.text;

      debugPrint("hora modificada?: $horaIni");
      final res = await _citaRepository.updateCita(widget.cita.id, fecha: fecha, horaInicio: horaIni, horaFin: horaFin);

      if (mounted){
        setState(() {
          widget.cita.fecha = DateFormat("d/M/yyyy",).parse(_fechaController.text);
          widget.cita.horaInicio = _horaInicioController.text;
          widget.cita.horaFin = _horaFinController.text;

          ToastManager.show(context, "Cita modificada correctamente");
        });
        if(res != null){
          widget.onCitaModificada();
          Navigator.pop(context);
        }
      }

    }catch(e){
      if(mounted)ToastManager.show(context, "$e", success: false);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        const Text(
          "MODIFICAR HORARIO CITA",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF222B6F)),
        ),
        const SizedBox(height: 20),

        _buildCampoTexto(
          label: "Fecha de la cita",
          controller: _fechaController,
          icon: Icons.calendar_today,
          hint: "Selecciona día",
          onTap: () => _seleccionarFecha(context),
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: _buildCampoTexto(
                label: "Hora Inicio",
                controller: _horaInicioController,
                icon: Icons.access_time,
                hint: "00:00",
                onTap: () => _seleccionarHora(context, _horaInicioController),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCampoTexto(
                label: "Hora Fin",
                controller: _horaFinController,
                icon: Icons.access_time,
                hint: "00:00",
                onTap: () => _seleccionarHora(context, _horaFinController),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),

        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF222B6F)),
              onPressed: () async {
                await _checkFields();
              },
              child: const Text("Modificar Cita", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        )
      ],
    );
  }


  Widget _buildCampoTexto({required String label, required TextEditingController controller, required IconData icon, required String hint, required VoidCallback onTap}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          readOnly: true,
          onTap: onTap,
          decoration: InputDecoration(
            hintText: hint,
            fillColor: Colors.white,
            filled: true,
            prefixIcon: Icon(icon, color: const Color(0xFF222B6F), size: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          ),
        ),
      ],
    );
  }

  Future<void> _seleccionarFecha(BuildContext context) async {
    DateTime? picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2025), lastDate: DateTime(2030));
    if (picked != null) setState(() => _fechaController.text = "${picked.day}/${picked.month}/${picked.year}");
  }

  Future<void> _seleccionarHora(BuildContext context, TextEditingController controller) async {
    TimeOfDay? picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null) {
      final hora = picked.hour.toString().padLeft(2, '0');
      final minutos = picked.minute.toString().padLeft(2, '0');

      setState(() {
        controller.text = "$hora:$minutos:00";
      });
    }
  }
}