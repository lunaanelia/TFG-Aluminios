import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/cita.dart';
import '../models/proyecto.dart';
import '../repository/cita_repository.dart';
import '../repository/proyecto_repository.dart';
import '../utils/toast_manager.dart';


mixin UtilsInfoProyectoClienteMixin<T extends StatefulWidget> on State<T> {
  final ProyectoRepository proyectoRepository = ProyectoRepository();
  final CitaRepository citaRepository = CitaRepository();

  List <Cita> disponiblesCitas = [];
  List <Cita> misCitas = [];

  Future<bool> anularCita(int id)async{
    try{
      await citaRepository.cancelarCita(id);

      if (mounted){
        ToastManager.show(context, "La cita se ha anulado correctamente", success: true);
        return true;
      }

    }catch(e){
      if(mounted) {
        ToastManager.show(context, "Error $e", success: false);
        return false;
      }
    }
    return false;
  }

  Future<void> loadCitas() async {
    try {
      final lista = await citaRepository.getCita();

      if (mounted) {
        setState(() {
          disponiblesCitas = lista.where((c)=> !c.reservada).toList();
          misCitas = lista.where((c)=> c.reservada).toList();
        });
      }
    } catch (e) {
      debugPrint("Get citas error: $e");
    }
  }

  Future<void> cancelarProyecto(Proyecto p) async {
    try {
      final res = await proyectoRepository.cancelarProyecto(p.id);

      if (mounted) {
        setState(() {
          p.estado = res!;
        });
        ToastManager.show(context, " Proyecto cancelado con exito", success: true);
      }
    } catch (e) {
      if(mounted){
        ToastManager.show(context,"Error $e", success: false);
      }
    }
  }

  Future<bool?> reservarCita(int proyecto, int cita) async{
    try{
      await citaRepository.reservarCita(cita, proyecto);

      if(mounted){
        ToastManager.show(context, "Cita reservada con exito");
        return true;
      }
    }catch(e){
      if(mounted) {
        ToastManager.show(context, "$e", success: false);
        return false;
      }
    }

    return true;
  }

  String obtenerNombreDia(String fechaTexto) {
    try {
      List<String> partes = fechaTexto.split('-');
      int dia = int.parse(partes[0]);
      int mes = int.parse(partes[1]);
      int anio = int.parse(partes[2]);

       DateTime fecha = DateTime(anio, mes, dia);

      switch (fecha.weekday) {
        case 1: return "Lunes";
        case 2: return "Martes";
        case 3: return "Miércoles";
        case 4: return "Jueves";
        case 5: return "Viernes";
        case 6: return "Sábado";
        case 7: return "Domingo";
        default: return "Día";
      }
    } catch (e) {
      return "Cita";
    }
  }

  Future<bool> mostrarDialogoConfirmarCancelar(BuildContext context) async {
    final resultado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
              SizedBox(width: 8),
              Text(
                '¿Cancelar proyecto?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          content: const Text(
            '¿Estás seguro de que deseas cancelar este proyecto? '
                'Esta acción no se puede deshacer y cambiará el estado del proyecto automáticamente.',
            style: TextStyle(fontSize: 15, color: Colors.black87),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'No, volver',
                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Sí, cancelar',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );

    return resultado ?? false;
  }
  Future<bool?> seleccionarCita(BuildContext context, int proyectoId)async{
    await loadCitas();
    if (!context.mounted) return false;

    return showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            backgroundColor: const Color(0xFFF5F5F5),
            child: Container(
                padding: const EdgeInsets.all(24),
                constraints: const BoxConstraints(maxWidth: 550, maxHeight: 600),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "SELECCIONAR CITA DISPONIBLE",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF222B6F)),
                      ),
                      const SizedBox(height: 4),

                      const SizedBox(height: 20),

                      Expanded(
                          child: disponiblesCitas.isEmpty ?
                          const Center(
                            child: Text(
                              "No hay huecos libres disponibles esta semana.",
                              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                            ),
                          ) : ListView.builder(
                              itemCount: disponiblesCitas.length,
                              itemBuilder: (context, index){
                                final Cita cita = disponiblesCitas[index];
                                String fechaTexto = DateFormat('dd-MM-yyyy').format(cita.fecha);
                                String horaInicio = cita.horaInicio;
                                String horaFin = cita.horaFin;
                                String diaSemana = obtenerNombreDia(fechaTexto);

                                return Card(
                                  elevation: 1,
                                  margin: const EdgeInsets.symmetric(vertical: 6),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(color: Colors.green.withValues(alpha: 0.3), width: 1),
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () async {

                                      bool ?  ok = await reservarCita(proyectoId, cita.id);
                                      if(ok != null && ok){
                                        Navigator.pop(context, true);
                                      }
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(14.0),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.calendar_today, color: Color(0xFF222B6F), size: 24),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  "$diaSemana, $fechaTexto",
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                                  softWrap: true,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  "Horario: $horaInicio a $horaFin",
                                                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 10),

                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.green.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: const Text("LIBRE", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11)),
                                          ),

                                        ],

                                      ),
                                    ),
                                  ),
                                );
                              }
                          )
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text("Cancelar", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        ),
                      )
                    ]
                )
            ),
          );
        }
    );
  }


}