import 'package:aluminios/mixins/user_loader.dart';
import 'package:aluminios/mixins/utils_product.dart';
import 'package:aluminios/repository/cita_repository.dart';
import 'package:aluminios/widgets/need_login_widget.dart';
import 'package:aluminios/widgets/no_access_widget.dart';
import 'package:aluminios/widgets/menu_empresa.dart';
import 'package:aluminios/utils/toast_manager.dart';
import 'package:aluminios/widgets/ventana_cita_modificar.dart';
import 'package:flutter/material.dart';
import '../models/cita.dart';
import '../widgets/banner_delete.dart';
import '../utils/tipos.dart';
import 'package:intl/intl.dart';

class CreateCitaPage extends StatefulWidget {
  const CreateCitaPage({super.key});

  @override
  State<CreateCitaPage> createState() => _CreateCitaState();
}

class _CreateCitaState extends State<CreateCitaPage> with UserLoaderMixin, ProductCommuns{

  final CitaRepository _citaRepository = CitaRepository();

  final ExpansibleController _desplegableController = ExpansibleController();

  final TextEditingController _fechaController = TextEditingController();
  final TextEditingController _horaInicioController = TextEditingController();
  final TextEditingController _horaFinController = TextEditingController();

  bool _fechaError = false;
  bool _horaIniError = false;
  bool _horaFinError = false;

  List<Cita> _allCitas = [];
  List<Cita> _foundCitas = [];


  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await loadCurrentUserData();
    if(userName == null){
      return;
    }

    try {

      _allCitas = await _citaRepository.getCita();

      if (mounted) {
        setState(() {
          _foundCitas= _allCitas;
        });
      }
    } catch (e) {
      debugPrint("Get citas error: $e");
    }
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

      final res = await _citaRepository.createCita(fecha, _horaInicioController.text, _horaFinController.text);

      if (mounted){
        setState(() {
          _allCitas.add(res!);
          ToastManager.show(context, "Cita creada correctamente", success: true);
        });
      }

    }catch(e){
      if(mounted) {
        ToastManager.show(context, "$e", success: false);
      }
    }
  }

  void _resetFields() async{
    _fechaController.clear();
    _horaInicioController.clear();
    _horaFinController.clear();
  }

  Future<void> _eliminarCita(int id)async{
    try{
      await _citaRepository.deleteCita(id);

      if (mounted){
        setState(() {
          _allCitas.removeWhere((c) => c.id == id);
          _foundCitas= _allCitas;
        });
        ToastManager.show(context, "Cita eliminada correctamente", success: true);
      }

    }catch(e){
      if(mounted) {
        ToastManager.show(context, "Error $e", success: false);
      }
    }
  }


  Future<void> _seleccionarFecha(BuildContext context) async {
    DateTime? picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2025), lastDate: DateTime(2030));
    if (picked != null) setState(() => _fechaController.text = "${picked.day}/${picked.month}/${picked.year}");
  }

  Future<void> _seleccionarHora(BuildContext context, TextEditingController controller) async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {

      final hora = picked.hour.toString().padLeft(2, '0');
      final minutos = picked.minute.toString().padLeft(2, '0');

      setState(() {
        controller.text = "$hora:$minutos:00";
      });
    }
  }


  void _mostrarEdicionCita(BuildContext context, Cita cita){

    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 5,
            backgroundColor: const Color(0xffdcdcdc),
            child: Container(
              padding: const EdgeInsets.all(24),
              constraints: const BoxConstraints(maxWidth: 450),
              child: VentanaCitaModificar(cita: cita, onCitaModificada: (){
                setState(() {

                });
              },),
            ),
          );
        },
    );
  }

  @override
  Widget build(BuildContext context) {
    double anchoPantalla = MediaQuery.of(context).size.width;
    bool esPC = anchoPantalla > 700;
    final screenWidth = MediaQuery.of(context).size.width;
    bool esMovil = screenWidth < 600;

    if (isLoadingUser){
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if(userName == null){
      return NeedLoginWidget();
    }

    if(!isLoadingUser && userRol != UserType.jefe){
      return const NoAccessWidget();
    }

    return Scaffold(
      drawer: MenuEmpresa(current: PageKind.gestioncitas, rol: userRol!),
      body: SingleChildScrollView(
        padding: esMovil
            ? EdgeInsets.only(top:40, bottom: 20, left: 10, right: 10)
            : EdgeInsets.all(40),
        child: Center(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                      'GESTIÓN DE CITAS',
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
                Card(
                  elevation: 2,
                  color: const Color(0xffdcdcdc),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ExpansionTile(
                    key: const Key('crearCita'),
                    controller: _desplegableController,
                    title: const Text(
                      "Crear Nueva Cita",
                      style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF222B6F), fontSize: 16),
                    ),
                    leading: const Icon(Icons.add_circle_outline, color: Color(0xFF222B6F)),
                    childrenPadding: const EdgeInsets.all(16),
                    shape: const Border(),
                    children: [
                      Flex(
                        direction: esPC ? Axis.horizontal : Axis.vertical,
                        children: [

                          Expanded(
                            flex: esPC ? 2 : 0,
                            child: _buildCampoTexto(
                              clave: 'fechaController',
                              label: "Fecha de la cita",
                              controller: _fechaController,
                              icon: Icons.calendar_today,
                              hint: "Selecciona día",
                              onTap: () => _seleccionarFecha(context),
                            ),
                          ),
                          if (esPC) const SizedBox(width: 16) else const SizedBox(height: 12),

                          Expanded(
                            flex: esPC ? 1 : 0,
                            child: _buildCampoTexto(
                              clave: 'horaIni',
                              label: "Hora Inicio",
                              controller: _horaInicioController,
                              icon: Icons.access_time,
                              hint: "00:00",
                              onTap: () => _seleccionarHora(context, _horaInicioController),
                            ),
                          ),
                          if (esPC) const SizedBox(width: 16) else const SizedBox(height: 12),

                          Expanded(
                            flex: esPC ? 1 : 0,
                            child: _buildCampoTexto(
                              clave: 'horaFin',
                              label: "Hora Fin",
                              controller: _horaFinController,
                              icon: Icons.access_time,
                              hint: "00:00",
                              onTap: () => _seleccionarHora(context, _horaFinController),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.red, width: 1.5),
                            ),
                            onPressed: () {
                              _resetFields();
                              _desplegableController.collapse();
                            },
                            child: const Text("Cancelar", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            key: const Key('guardarCita'),
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF222B6F)),
                            onPressed: () {
                              _checkFields();
                            },
                            child: const Text("Guardar Cita", style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      )
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                const Text(
                  "Citas Creadas",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF222B6F)),
                ),

                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _foundCitas.length,
                  itemBuilder: (context, index) {
                    final cita = _foundCitas[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child : Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            bool esPC = constraints.maxWidth > 650;

                            return Flex(
                              direction: esPC ? Axis.horizontal : Axis.vertical,
                              crossAxisAlignment: esPC ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                              children: [

                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFAFC0E8),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Icons.calendar_month, color: Color(0xFF222B6F), size: 28),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Día: ${DateFormat('dd-MM-yyyy').format(cita.fecha)}",
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "Horario: ${cita.horaInicio} a ${cita.horaFin}",
                                          style: TextStyle(color: Colors.grey[700], fontSize: 14, fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),

                                if (esPC) const Spacer() else const SizedBox(height: 16),

                                if (!cita.reservada) ...[
                                  Row(
                                    mainAxisAlignment: esPC ? MainAxisAlignment.end : MainAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Color(0xFFB1FF9C),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Text("LIBRE", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        tooltip: 'Editar horario de cita',
                                        icon: const Icon(Icons.edit_outlined, color: Color(0xFF222B6F)),
                                        onPressed: () {
                                          _mostrarEdicionCita(context, cita);
                                        },
                                      ),
                                      IconButton(
                                        tooltip: 'Eliminar hueco de cita',
                                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                        onPressed: () {
                                          mostrarDialogoConfirmacion(
                                            context: context,
                                            mensaje: "¿Estas seguro que quieres borrar esta cita?",
                                            id: cita.id,
                                            accionBorrar: (idParaBorrar) async {
                                              await _eliminarCita(idParaBorrar);
                                            },
                                          );
                                        },
                                      ),
                                    ],
                                  )
                                ] else ...[
                                  Flex(
                                    direction: esPC ? Axis.horizontal : Axis.vertical,
                                    crossAxisAlignment: esPC ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            "Cliente con Reserva:",
                                            style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
                                          ),
                                          Text(
                                            "${cita.clienteNombre}",
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF222B6F)),
                                          ),
                                        ],
                                      ),
                                      if (esPC) const SizedBox(width: 24) else const SizedBox(height: 10),

                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF222B6F),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                        ),
                                        icon: const Icon(Icons.folder_open, size: 18),
                                        label: const Text("Editar Proyecto", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                        onPressed: () {
                                          Navigator.pushNamed(context, 'modificarProyecto/', arguments: cita.proyectoId);
                                        },
                                      ),
                                    ],
                                  )
                                ],

                              ],
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
    );
  }

  Widget _buildCampoTexto({
    required String clave,
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 6),
        TextField(
          key: Key(clave),
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
}