import 'package:aluminios/mixins/utils_info_proyecto_cliente.dart';
import 'package:aluminios/models/proyecto.dart';
import 'package:aluminios/widgets/menu_empresa.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/cita.dart';
import '../widgets/banner_delete.dart';
import '../widgets/header.dart';
import '../widgets/need_login_widget.dart';
import '../utils/toast_manager.dart';
import '../utils/tipos.dart';
import '../mixins/user_loader.dart';
import 'package:collection/collection.dart';

class ListadoProyectosPage extends StatefulWidget {
  const ListadoProyectosPage({super.key});

  @override
  State<ListadoProyectosPage> createState() => _ListadoProyectosState();
}

class _ListadoProyectosState extends State<ListadoProyectosPage> with UserLoaderMixin, UtilsInfoProyectoClienteMixin{

  List <Proyecto> _allProyectos = [];
  List <Proyecto> _foundProyectos= [];

  EstadoProyecto?  _filtroSeleccionado = EstadoProyecto.todo;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _searchProduct(String enteredKeyword) {
    List<Proyecto> results = [];

    if (enteredKeyword.isEmpty) {
      results = _allProyectos;
    } else {
      results = _allProyectos.where((p) {
        final direccion = (p.direccionObra ?? '').toLowerCase();
        final query = enteredKeyword.toLowerCase();
        return direccion.contains(query);
      }).toList();
    }

    setState(() {
      _foundProyectos = results;
    });
  }


  Future<void> _loadData() async {
    try {
      await loadCurrentUserData();
      _allProyectos = await proyectoRepository.getProyectos(true);

      if (mounted) {
        setState(() {
          _foundProyectos = _allProyectos;
        });
      }
    } catch (e) {
      debugPrint("Get proyects error: $e");
    }
  }

  Widget _buildText(int cita){

    Cita? asociada = misCitas.firstWhereOrNull( (c) => c.id == cita);

    if (asociada == null) return Text("");
    String mensaje = "Reunión día ${DateFormat('dd-MM-yyyy').format(asociada.fecha)} a la hora ${asociada.horaInicio}";
    return Text(mensaje);
  }

  Widget _cabeceraCliente(){
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
                'GESTIÓN PROYECTOS',
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



  @override
  Widget build(BuildContext context){
    final screenWidth = MediaQuery.of(context).size.width;

    if (isLoadingUser){
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (userName == null){
      return NeedLoginWidget();
    }

    return Scaffold(
      drawer: MenuEmpresa(current: PageKind.misproyectos, rol: userRol!),
      body: LayoutBuilder(
          builder: (context, constraints) {
            bool esMovil = constraints.maxWidth < 700;
            final double anchoElemento = esMovil
                ? constraints.maxWidth
                : 250.0;
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                  padding: esMovil
                      ? EdgeInsets.only(top:40, bottom: 20, left: 10, right: 10)
                      : EdgeInsets.symmetric(horizontal: /*userRol == UserType.cliente ? screenWidth*0.07 : */ 40, vertical: 40),
                  child: Column(
                    children: [
                      if(userRol == UserType.cliente)...[
                        _cabeceraCliente()
                      ]else...[
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
                      ],

                      SizedBox(height: esMovil ? 20 : 40,),
                      SizedBox(
                        width: double.infinity,
                        child: Wrap(

                          alignment: WrapAlignment.end,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 10,
                          runSpacing: 15,
                          children: [
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
                            child: InkWell(
                              onTap: () {
                                if (proyecto.estado != EstadoProyecto.cancelado) {
                                  Navigator.pushNamed(context, 'verProyecto/', arguments: proyecto.id);
                                }else{
                                  ToastManager.show(context, "Los proyectos cancelados no se pueden ver", success: false);
                                }
                              },
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
                                            "Dirección: ${proyecto.direccionObra}",
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                              color: Color(0xFF222B6F),
                                            ),
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

                                        if (proyecto.estado == EstadoProyecto.pendiente_cita) ...[
                                          ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            ),
                                            label: Text("RESERVAR CITA"),
                                            onPressed: () async {
                                              final si = await seleccionarCita(context, proyecto.id);
                                              if (si == true && mounted) {
                                                _loadData();
                                              }
                                            },
                                          )
                                        ],

                                        if (proyecto.estado == EstadoProyecto.pendiente_cita ||
                                            proyecto.estado == EstadoProyecto.pendiente_pago ||
                                            proyecto.estado == EstadoProyecto.materiales ||
                                            proyecto.estado == EstadoProyecto.revision
                                        ) ...[
                                          ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            ),
                                            label: Text("Cancelar"),
                                            onPressed: () async {
                                              final si = await mostrarDialogoConfirmarCancelar(context);
                                              if (si == true && mounted) {
                                                await cancelarProyecto(proyecto);
                                              }
                                            },
                                          )
                                        ],

                                        if (proyecto.estado == EstadoProyecto.revision) ...[

                                          _buildText(proyecto.cita!),
                                          ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            ),
                                            label: Text("ANULAR CITA"),
                                            onPressed: () async {
                                              mostrarDialogoConfirmacion(
                                                context: context,
                                                mensaje: "¿Estas seguro que quieres anular la cita?",
                                                id: proyecto.cita!,
                                                accionBorrar: (idParaBorrar) async {
                                                  bool ok = await anularCita(idParaBorrar);
                                                  if (ok && mounted) {
                                                    _loadData();
                                                  }
                                                },
                                              );
                                            },
                                          )
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
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