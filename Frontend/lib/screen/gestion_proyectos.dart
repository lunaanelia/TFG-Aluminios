import 'package:aluminios/models/proyecto.dart';
import 'package:aluminios/repository/proyecto_repository.dart';
import 'package:aluminios/widgets/need_login_widget.dart';
import 'package:aluminios/widgets/no_access_widget.dart';
import 'package:aluminios/widgets/menu_empresa.dart';
import 'package:flutter/material.dart';
import '../utils/toast_manager.dart';
import '../utils/tipos.dart';
import '../mixins/user_loader.dart';

class GestionProyectosPage extends StatefulWidget {
  const GestionProyectosPage({super.key});

  @override
  State<GestionProyectosPage> createState() => _GestionProyectosState();
}

class _GestionProyectosState extends State<GestionProyectosPage> with UserLoaderMixin{

  List <Proyecto> _allProyectos = [];
  List <Proyecto> _foundProyectos= [];

  final ProyectoRepository _proyectoRepository = ProyectoRepository();

  EstadoProyecto?  _filtroSeleccionado = EstadoProyecto.todo;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _searchProduct(String enteredKeyword) {
    List<Proyecto> results = [];

    if (enteredKeyword.isEmpty) {
      if (_filtroSeleccionado == EstadoProyecto.todo){
        results = _allProyectos;
      }else{
        results = _allProyectos.where((p) => p.estado == _filtroSeleccionado).toList();

      }
    } else {
      results = _foundProyectos.where((p) {
        final nombreCliente = (p.nombre ?? '').toLowerCase();
        final direccion = (p.direccionObra ?? '').toLowerCase();
        final query = enteredKeyword.toLowerCase();
        return nombreCliente.contains(query) || direccion.contains(query);
      }).toList();
    }

    setState(() {
      _foundProyectos = results;
    });
  }


  Future<void> _loadData() async {
    await loadCurrentUserData();
    if(userName == null){
      return;
    }
    try {

      _allProyectos = await _proyectoRepository.getProyectos(false);

      if (mounted) {
        setState(() {
          _foundProyectos = _allProyectos;
        });
      }
    } catch (e) {
      debugPrint("Get proyects error: $e");
    }
  }

  Future<void> _upadateProyectoPagado(int id) async {

    try{
      final (res)= await _proyectoRepository.pagoProyecto(id);

      if(mounted && res != null){
        final indexAll = _allProyectos.indexWhere((p) => p.id == id);
        final indexFound = _foundProyectos.indexWhere((p) => p.id == id);

        setState(() {
          _allProyectos[indexAll].estado = res;
          _allProyectos = List.from(_allProyectos);

          _foundProyectos[indexFound].estado = res;
          _foundProyectos = List.from(_foundProyectos);
        });
        ToastManager.show(context, "Proyecto registrado como pagado");

      }
    }catch(e){
      ToastManager.show(context, "Error $e", success: false);
    }

  }

  void _mostrarAvisoConfirmacionPago(BuildContext context, Proyecto proyecto) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: const BorderSide(color: Colors.red, width: 2),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red),
              SizedBox(width: 10),
              Text(
                "Confirmar acción",
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          content: Text(
            "¡Esta operación es IRREVERSIBLE!\n\nVa a cambiar el estado del proyecto del cliente: ${proyecto.nombre?.toUpperCase()} con dirección: ${proyecto.direccionObra}.\n\nEl proyecto pasará a: PAGADA LA FIANZA.\n\n¿Estás seguro?",
            style: const TextStyle(fontSize: 16),
          ),
          actions:[
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancelar", style: TextStyle(color: Colors.white)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.of(context).pop();
                _upadateProyectoPagado(proyecto.id);
              },
              child: const Text("Confirmar", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context){
    if (isLoadingUser){
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if(userName == null){
      return NeedLoginWidget();
    }


    return Scaffold(
      drawer: MenuEmpresa(current: PageKind.proyectos, rol: userRol!),
      body: LayoutBuilder(
          builder: (context, constraints) {
            bool esMovil = constraints.maxWidth < 700;
            final double anchoElemento = esMovil
                ? constraints.maxWidth
                : 250.0;
            if(!isLoadingUser && userRol != UserType.jefe && userRol != UserType.administrativo ){
              return const NoAccessWidget();
            }

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
                            'GESTIÓN DE PROYECTOS',
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
                      SizedBox(
                        width: double.infinity,
                        child: Wrap(

                          alignment: WrapAlignment.end,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 10,
                          runSpacing: 15,
                          children: [
                            SizedBox(
                              width: anchoElemento,
                              height: 36,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF4F5F7),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFF222B6F), width: 1.5),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<EstadoProyecto?>(
                                    value: _filtroSeleccionado,
                                    isExpanded: true,
                                    icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF222B6F)),
                                    style: const TextStyle(color: Color(0xFF222B6F), fontSize: 15, fontWeight: FontWeight.w600),
                                    items: EstadoProyecto.values.map((EstadoProyecto estado) {
                                      return DropdownMenuItem<EstadoProyecto?>(
                                        value: estado,
                                        child: Text(estado.text),
                                      );
                                    }).toList(),
                                    onChanged: (nuevoFiltro) {
                                      setState(() {
                                        _filtroSeleccionado = nuevoFiltro;
                                        if (_filtroSeleccionado == EstadoProyecto.todo) {
                                          _foundProyectos = _allProyectos;
                                        } else {
                                          _foundProyectos = _allProyectos.where((p) => p.estado == _filtroSeleccionado).toList();
                                        }
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(
                              width: anchoElemento,
                              height: 36,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: TextField(
                                  onChanged: (value) => _searchProduct(value),
                                  decoration: const InputDecoration(
                                    prefixIcon: Icon(
                                      Icons.search,
                                      size: 20,
                                      color: Colors.grey,
                                    ),
                                    hintText: 'Buscar producto ...',
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: 10,
                                      horizontal: 10,
                                    ),
                                    isDense: true,
                                  ),
                                ),
                              ),
                            ),

                          ],
                        ),
                      ),

                      SizedBox(height: esMovil ? 0 : 40,),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _foundProyectos.length,
                        itemBuilder: (context, index) {
                          final proyecto = _foundProyectos[index];

                          return Card(
                            elevation: 3,
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Flex(
                                direction: esMovil ? Axis.vertical : Axis.horizontal,
                                crossAxisAlignment: esMovil ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                                children: [
                                  Flexible(
                                    flex: esMovil ? 0 : 1,
                                    fit: esMovil ? FlexFit.loose : FlexFit.tight,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          proyecto.nombre ?? "Cliente Desconocido",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                            color: Color(0xFF222B6F),
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          "Dirección: ${proyecto.direccionObra}",
                                          style: const TextStyle(color: Colors.grey, fontSize: 14),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),

                                  if (esMovil) const SizedBox(height: 16) else const SizedBox(width: 16),

                                  Wrap(
                                    spacing: 10,
                                    runSpacing: 10,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: proyecto.estado.color,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          "Estado: ${(proyecto.estado.text)}",
                                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                        ),
                                      ),

                                      if (proyecto.estado == EstadoProyecto.pendiente_pago) ...[
                                        ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          ),
                                          icon: const Icon(Icons.payments_outlined, size: 18),
                                          label: Text("COBRAR (${proyecto.fianza} €)"),
                                          onPressed: () {
                                            _mostrarAvisoConfirmacionPago(context, proyecto);
                                          },
                                        )
                                      ],
                                      if (proyecto.estado == EstadoProyecto.revision) ...[
                                        IconButton(
                                          tooltip: 'Modificar',
                                          icon: const Icon(Icons.edit_outlined, color: Color(0xFF222B6F), size: 26),
                                          onPressed: () {
                                            Navigator.pushNamed(context, 'modificarProyecto/', arguments: proyecto.id);
                                            },
                                        ),
                                      ],
                                      if (
                                          proyecto.estado == EstadoProyecto.materiales ||
                                          proyecto.estado == EstadoProyecto.esperando_materiales ||
                                          proyecto.estado == EstadoProyecto.listo_envio ||
                                          proyecto.estado == EstadoProyecto.listo_recogida ||
                                          proyecto.estado == EstadoProyecto.listo_montaje
                                      ) ...[
                                        ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Color(0xFFAFC0E8),
                                            foregroundColor: Color(0xFF222B6F),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          ),
                                          label: Text(
                                              switch (proyecto.estado) {
                                                EstadoProyecto.materiales => "PEDIR MATERIALES",
                                                EstadoProyecto.esperando_materiales => "MATERIALES RECIBIDOS",
                                                EstadoProyecto.listo_envio => "PREPARAR ENVIO",
                                                EstadoProyecto.listo_recogida => "RECOGIDO",
                                                EstadoProyecto.listo_montaje => "ASIGNAR MONTAJE",
                                                _                  => "",
                                              },
                                          ),
                                          onPressed: () {
                                            Navigator.pushNamed(context, 'modificarProyecto/', arguments: proyecto.id);
                                          },
                                        ),
                                      ],

                                      if (proyecto.estado == EstadoProyecto.produccion || proyecto.estado == EstadoProyecto.finalizado || proyecto.estado == EstadoProyecto.enviado || proyecto.estado == EstadoProyecto.montaje) ...[
                                        IconButton(
                                          tooltip: 'Ver ficha',
                                          icon: const Icon(Icons.visibility_outlined, color: Color(0xFF222B6F), size: 26),
                                          onPressed: () {Navigator.pushNamed(context, 'modificarProyecto/', arguments: proyecto.id);},
                                        ),
                                      ]
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  )
              ),
            );
          }),
    );
  }
}