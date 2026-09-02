import 'package:aluminios/models/presupuesto.dart';
import 'package:aluminios/repository/presupuesto_repository.dart';
import 'package:aluminios/widgets/banner_delete.dart';
import 'package:aluminios/widgets/menu_empresa.dart';
import 'package:aluminios/widgets/need_login_widget.dart';
import 'package:flutter/material.dart';
import '../widgets/header.dart';
import '../utils/toast_manager.dart';
import '../utils/tipos.dart';
import '../mixins/user_loader.dart';

class GestionPresupuestosPage extends StatefulWidget {
  const GestionPresupuestosPage({super.key});

  @override
  State<GestionPresupuestosPage> createState() => _GestionPresupuestosState();
}

class _GestionPresupuestosState extends State<GestionPresupuestosPage> with UserLoaderMixin{

  List <Presupuesto> _allPresupuestos = [];
  bool _isLoanging = true;

  final PresupuestoRepository _presupuestoRepository = PresupuestoRepository();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _eliminarPresupuesto(int id) async{
      try{
        await _presupuestoRepository.deletePresupuesto(id);

        if(mounted){
          setState(() {
            _allPresupuestos.removeWhere((presupuesto) => presupuesto.id == id);
          });
          ToastManager.show(context, "Presupuesto eliminado correctamente", success: true);
        }
      }catch(e){
        ToastManager.show(context, "Error $e", success: false);
      }

  }



  Future<void> _loadData() async {
    await loadCurrentUserData();

    if(userName == null){
      setState(() {
        _isLoanging = false;
      });
      return;
    }

    try {
     final res = await _presupuestoRepository.getPresupuestos();

      if (mounted) {
        setState(() {
          _isLoanging = false;
          _allPresupuestos = res;
        });
      }
    } catch (e) {
      debugPrint("Get products error: $e");
    }
  }


  Widget _cabeceraCliente(bool esMovil){
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
                esMovil ? 'PRESUPUESTOS' : 'PRESUPUESTOS POR CONFIRMAR',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Color(0xFF222B6F),
                ),
              ),

              Spacer(),

              IconButton(
                tooltip: 'Crear presupuesto',
                iconSize: 30.0,
                icon: const Icon(Icons.add, color: Color(0xFF222B6F)),

                onPressed: () async {
                  final res = await Navigator.pushNamed(context, 'createPresupuesto/');
                  if (res == true){
                    setState(() {
                      _isLoanging = true;
                    });
                    _loadData();
                  }

                },
              ),
              SizedBox(width: 25,)
            ],

          ),

      ]
    );
  }

  Widget _cabeceraEmpresa(bool esMovil){
    return  Column(
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
              esMovil ? 'PRESUPUESTOS' : 'PRESUPUESTOS POR CONFIRMAR',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: esMovil ? 20 : 24,
                color: Color(0xFF222B6F),
              ),
            ),
            Spacer()
          ],
        ),

        SizedBox(height: 20,),
        Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child:Row(
          mainAxisAlignment: MainAxisAlignment.end,

          children: [
            ElevatedButton(
                onPressed: () async {
                  await Navigator.pushNamed(context, 'createPresupuesto/');
                },
                child: Text(
                    "Crear nuevo presupuesto",
                ),
            )
          ]
        )
        )
      ],
    );

  }


  Widget _listado() {

    double anchoPantalla = MediaQuery.of(context).size.width;
    bool esMovil= anchoPantalla > 850;

    if (!esMovil) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: List.generate(_allPresupuestos.length, (index) {
            return _buildCard(_allPresupuestos[index], index);
          }),
        ),
      );
    }

    List<Widget> filasDePresupuestos = [];

    for (int i = 0; i < _allPresupuestos.length; i += 2) {
      final presupuestoIzquierda = _allPresupuestos[i];
      final tieneDerecha = (i + 1) < _allPresupuestos.length;
      final presupuestoDerecha = tieneDerecha ? _allPresupuestos[i + 1] : null;

      filasDePresupuestos.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _buildCard(presupuestoIzquierda, i),
              ),
              const SizedBox(width: 32),

              Expanded(
                child: tieneDerecha
                    ? _buildCard(presupuestoDerecha!, i + 1)
                    : const SizedBox(),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: filasDePresupuestos,
      ),
    );
  }

  Widget _buildCard(final presupuesto, int index) {

    final bool esMovil = MediaQuery.of(context).size.width < 600;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: const Color(0xffdcdcdc),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: esMovil
                ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Row(
                  children: [
                    Text(
                      "Presupuesto ${index + 1}",
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.edit_outlined, color: Color(0xFF222B6F), size: 24),
                      onPressed: () => Navigator.pushNamed(context, 'createPresupuesto/', arguments: _allPresupuestos[index].id!),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.delete_outline_outlined, color: Colors.red, size: 24),
                      onPressed: () {
                        mostrarDialogoConfirmacion(
                          context: context,
                          mensaje: "¿Estas seguro que quieres borrar este porducto del presupuesto?",
                          id: _allPresupuestos[index].id!,
                          accionBorrar: (idParaBorrar) async => await _eliminarPresupuesto(idParaBorrar),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, 'confirmacionPresupuesto/', arguments: _allPresupuestos[index].id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF222B6F),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text("Confirmar Presupuesto", style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ),
              ],
            )
                : Row(

              children: [
                Text(
                  "Presupuesto ${index + 1}",
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, 'confirmacionPresupuesto/', arguments: _allPresupuestos[index].id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF222B6F),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text("Confirmar", style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
                const SizedBox(width: 12),
                IconButton(
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.edit_outlined, color: Color(0xFF222B6F), size: 24),
                  onPressed: () => Navigator.pushNamed(context, 'createPresupuesto/', arguments: _allPresupuestos[index].id!),
                ),
                const SizedBox(width: 12),
                IconButton(
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.delete_outline_outlined, color: Colors.red, size: 24),
                  onPressed: () {
                    mostrarDialogoConfirmacion(
                      context: context,
                      mensaje: "¿Estas seguro que quieres borrar este porducto del presupuesto?",
                      id: _allPresupuestos[index].id!,
                      accionBorrar: (idParaBorrar) async => await _eliminarPresupuesto(idParaBorrar),
                    );
                  },
                ),
              ],
            ),
          ),

          const Divider(color: Colors.white, height: 1, thickness: 1.5),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Expanded(flex: esMovil ? 3 : 4, child: const Text("Resumen:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                    Expanded(flex: 3, child: const Text("Medidas", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.center)),
                    Expanded(flex: 2, child: const Text("Cant.", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.center)),
                    Expanded(flex: esMovil ? 2 : 3, child: const Text("Precio", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.end)),
                  ],
                ),
                const SizedBox(height: 12),
                ...presupuesto.lineas.map((linea) {
                  return Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [

                        Expanded(
                          flex: esMovil ? 3 : 4,
                          child: Row(
                            children: [
                              const Icon(Icons.fiber_manual_record, size: 8, color: Color(0xFF222B6F)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  linea.nombreProducto ?? 'Producto',
                                  style: TextStyle(fontSize: esMovil ? 14 : 16),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),

                        Expanded(
                          flex: 3,
                          child: Text(
                            "${linea.ancho} x ${linea.alto}",
                            style: TextStyle(fontSize: esMovil ? 14 : 16),
                            textAlign: TextAlign.center,
                          ),
                        ),

                        Expanded(
                          flex: 2,
                          child: Text(
                            "${linea.cantidad}",
                            style: TextStyle(fontSize: esMovil ? 14 : 16),
                            textAlign: TextAlign.center,
                          ),
                        ),

                        Expanded(
                          flex: esMovil ? 2 : 3,
                          child: Text(
                            "${linea.precioFinal ?? 0.0}€",
                            style: TextStyle(fontSize: esMovil ? 14 : 16),
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),

                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      "Total: ${presupuesto.total ?? 0.0}€",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context){
    final screenWidth = MediaQuery.of(context).size.width;

    if(!isLoadingUser && userName == null){
      return NeedLoginWidget();
    }

    if (_isLoanging){
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Scaffold(
      drawer: (userRol != null && userRol != UserType.cliente)
        ? MenuEmpresa(current: PageKind.mispresupuestos, rol: userRol!)
        : null,
      body: LayoutBuilder(
          builder: (context, constraints) {
            bool esMovil = constraints.maxWidth < 700;

            if(userId == null) {
              return NeedLoginWidget();
            }

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                  padding: esMovil
                      ? EdgeInsets.only(top:40, bottom: 20, left: 10, right: 10)
                      : EdgeInsets.symmetric(horizontal: /*userRol == UserType.cliente ? screenWidth*0.07 : */ 40, vertical: 40),
                  child: Column(
                    children: [

                      if(userRol == UserType.cliente)...[
                        _cabeceraCliente(esMovil)
                      ]else...[
                        _cabeceraEmpresa(esMovil)
                      ],

                      SizedBox(height: 20,),
                      
                      if(_allPresupuestos.isEmpty)...[
                        Text("No tiene presupuesto, crear uno para quqe aparezcan aqui")
                      ]else...[
                        _listado()
                      ]
                    ],
                  )
              ),
            );
          }),
    );
  }
}