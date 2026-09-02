import 'package:aluminios/mixins/user_loader.dart';
import 'package:aluminios/utils/mensajes.dart';
import 'package:aluminios/widgets/need_login_widget.dart';
import 'package:aluminios/widgets/no_access_widget.dart';
import 'package:aluminios/widgets/menu_empresa.dart';
import 'package:flutter/material.dart';
import '../repository/user_repository.dart';
import '../utils/toast_manager.dart';
import '../models/horario.dart';
import '../utils/tipos.dart';

class ModificateUserPage extends StatefulWidget {
  final int? id;
  const ModificateUserPage({ super.key, this.id});

  @override
  State<ModificateUserPage> createState() => _ModificateUserState();
}

class _ModificateUserState extends State<ModificateUserPage> with UserLoaderMixin{
  UserType? _rol;
  UserType _rolSelected = UserType.cliente;
  String? _name;
  String? _apellidos;
  String? _email;
  String? _tlfn;
  int ? id;
  bool _pendiente = true;

  List<DiaLaboral> antiguoHorario = [
    DiaLaboral(nombre: "Lunes", turnos: []),
    DiaLaboral(nombre: "Martes", turnos: []),
    DiaLaboral(nombre: "Miercoles", turnos: []),
    DiaLaboral(nombre: "Jueves", turnos: []),
    DiaLaboral(nombre: "Viernes", turnos: []),
    DiaLaboral(nombre: "Sabado", turnos: []),
  ];

  List<DiaLaboral> semana = [
    DiaLaboral(nombre: "Lunes", turnos: []),
    DiaLaboral(nombre: "Martes", turnos: []),
    DiaLaboral(nombre: "Miercoles", turnos: []),
    DiaLaboral(nombre: "Jueves", turnos: []),
    DiaLaboral(nombre: "Viernes", turnos: []),
    DiaLaboral(nombre: "Sabado", turnos: []),
  ];

  bool _emptyHorario = false;

  final UserRepository _userRepository = UserRepository();

  int ? _id;
  bool _isIntialized = false;

  @override
  void didChangeDependencies(){
    super.didChangeDependencies();

    if(!_isIntialized){
      final receiveId = ModalRoute.of(context)!.settings.arguments;

      if(receiveId is int){
        _id = receiveId;
      }else{
        _id = -1;
      }
      _loadData();
      loadCurrentUserData();
      _isIntialized = true;
    }

  }


  Future<void>  _checkFields() async {
    bool horarioChange = false;
    bool rolChange = false;

    setState(() {
      _emptyHorario = semana.every((dia) => dia.turnos.isEmpty);
    });

    if(_rolSelected != UserType.cliente && _emptyHorario){
      ToastManager.show(context, "El horario no puede esta vacio para un usaurio con rol ${_rolSelected.name}", success: false);
      return;
    }

    if (!_emptyHorario && _rolSelected != UserType.cliente) {
      horarioChange = false;
      if(semana.length != antiguoHorario.length){
          horarioChange = true;
      }else{
        for (int i = 0; i < semana.length; i++) {
          if (!semana[i].esIgualA(antiguoHorario[i])) {
            horarioChange = true;
            break;
          }
        }
      }

      if(_rolSelected == UserType.cliente){
        horarioChange = true;
      }

    }
    if(_rol != _rolSelected){
      rolChange = true;
    }

    if(!horarioChange && !rolChange) {
      ToastManager.show(context, "No se han detectado cambios", success: false);
      return;
    }

    try {
      final data = await _userRepository.updateUser(
          _id!,
          horario: horarioChange ? semana : null,
          rol: rolChange ? _rolSelected.name : null,
      );

      if(mounted && data!=null) {
        setState(() {
          if (horarioChange) {
            antiguoHorario = semana.map((d) => d.copy()).toList();
          }
          if(rolChange) {
            _rol = _rolSelected;
          }
        });

        ToastManager.show(context, "Cambios realizados correctamente", success: true);
      }
    }catch(e) {
      debugPrint("Error updating user: $e");
      if(mounted){
        ToastManager.show(context, falloNoAutorizao, success: false);
      }
    }

  }


 Future<void> _loadData() async{
    try{
      final user = await _userRepository.getUserById(_id!);

      if (mounted){
        _name = user.firstName;
        _apellidos = user.lastName;
        _tlfn = user.telefono;
        _email = user.email;
        _rol = UserType.values.byName(user.rol!);
        antiguoHorario = user.horario!;
        _pendiente = user.pendiente == null ? true : user.pendiente!;
        _resetFields();
      }

    }catch(e){
      debugPrint("Error endpoint get user $e");
      if (mounted){
        ToastManager.show(context, "Fallo con el servidor", success: false);
      }
    }
 }


  void _resetFields() async{
    setState(() {
      if(antiguoHorario.isNotEmpty){
        semana = antiguoHorario.map((dia) => dia.copy()).toList();
      }else{
        semana = [
          DiaLaboral(nombre: "Lunes", turnos: []),
          DiaLaboral(nombre: "Martes", turnos: []),
          DiaLaboral(nombre: "Miercoles", turnos: []),
          DiaLaboral(nombre: "Jueves", turnos: []),
          DiaLaboral(nombre: "Viernes", turnos: []),
          DiaLaboral(nombre: "Sabado", turnos: []),
        ];
      }
      _rolSelected = _rol == null ? UserType.cliente : _rol!;
    });

  }

  void _agregarTurno(int diaIndex) async {
    TimeOfDay? ini = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: 8, minute: 0),
      initialEntryMode: TimePickerEntryMode.inputOnly,
    );
    if (ini == null) return;

    TimeOfDay? fin = await showTimePicker(context: context, initialTime: TimeOfDay(hour: 14, minute: 0), initialEntryMode: TimePickerEntryMode.inputOnly,);

    if (fin == null) return;

    setState(() {
      semana[diaIndex].turnos.add(Turno(inicio: ini, fin: fin));
    });
  }

  Widget _buildHorarioWidget(bool esMovil){
    return Column(
      children: [
        Text(
          "Configuración de Horario",
          style: TextStyle(
            fontSize: 18,
            color: Color(0xFF222B6F),
          ),
        ),
        SizedBox(height: esMovil ? 0 : 40),
        ListView.builder(
          itemCount: semana.length,
          shrinkWrap: true,
          itemBuilder: (context, index) {
            final dia = semana[index];
            return Card(
              child: Column(
                children: [
                  ListTile(
                    title: Text(
                      dia.nombre,
                      style: TextStyle(
                          fontSize: 18,
                          color: _rolSelected == UserType.cliente ? Color(0xFF647CB1) : Color(0xFF222B6F),
                          fontWeight: FontWeight.bold),
                    ),

                    trailing: IconButton(
                      icon: Icon(
                          Icons.add_circle_outline,
                          color: _rolSelected == UserType.cliente ? Color(0xFF647CB1) : Color(0xFF222B6F)
                      ),
                      onPressed: () => _rolSelected == UserType.cliente ? null : _agregarTurno(index),
                    ),
                  ),

                  ...dia.turnos.map((turno) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      children: [
                        Icon(Icons.timer_outlined, size: 16),
                        SizedBox(width: 8),
                        Text("${turno.inicio.format(context)} - ${turno.fin.format(context)}"),
                        Spacer(),
                        IconButton(
                          icon: Icon(Icons.delete_outline, color: Colors.red, size: 20),
                          onPressed: () => setState(() => dia.turnos.remove(turno)),
                        )
                      ],
                    ),
                  )),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _datoPerfil(String etiqueta, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Wrap(
        spacing: 20,
        runSpacing: 5,
        crossAxisAlignment: WrapCrossAlignment.start,
        children: [
          Container(
            constraints: const BoxConstraints(minWidth: 120),
            child: Text(
              etiqueta,
              style: const TextStyle(
                fontSize: 18,
                color: Color(0xFF222B6F),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(
            valor,
            style: const TextStyle(
              fontSize: 18,
              color: Color(0xFF222B6F),
            ),
          ),
        ],
      ),
    );
  }
  Widget _datos(bool esMovil){
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,

      children: [
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8.0,
          runSpacing: 0.0,
          children: [
            Text(
              "Tipo de usuario",
              style: TextStyle(
                fontSize: 18,
                color: Color(0xFF222B6F),
              ),
              textAlign: TextAlign.center,
            ),

            SegmentedButton<UserType>(
              selected: {_rolSelected},
              showSelectedIcon: false,
              onSelectionChanged: (Set<UserType> newType,) {
                setState(() {
                  _rolSelected= newType.first;

                  if(_rolSelected == UserType.cliente){

                      semana = [
                        DiaLaboral(nombre: "Lunes", turnos: []),
                        DiaLaboral(nombre: "Martes", turnos: []),
                        DiaLaboral(nombre: "Miercoles", turnos: []),
                        DiaLaboral(nombre: "Jueves", turnos: []),
                        DiaLaboral(nombre: "Viernes", turnos: []),
                        DiaLaboral(nombre: "Sabado", turnos: []),
                      ];

                  }
                });
              },

              style: SegmentedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 3.0, horizontal: 8.0),

                shape: RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(
                    10.0,
                  ),
                  side: BorderSide.none,
                ),
                side: BorderSide(
                  color:
                  Color(0xFF222B6F),
                  width: 2.0,
                ),
              ),
              segments: <ButtonSegment<UserType>>[
                ButtonSegment<UserType>(
                  value: UserType.jefe,
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Jefe',
                      style: TextStyle(color: Color(0xFF222B6F)),
                    ),
                  ),
                ),
                ButtonSegment<UserType>(
                  value: UserType.administrativo,
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Administrativo',
                      style: TextStyle(color: Color(0xFF222B6F)),
                    ),
                  ),
                ),
                ButtonSegment<UserType>(
                  value: UserType.trabajador,
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('Trabajador',  style: TextStyle(color: Color(0xFF222B6F)),),

                  ),
                ),

                ButtonSegment<UserType>(
                  value: UserType.cliente,
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('Cliente'),
                  ),
                ),
              ],
            ),
          ],
        ),

        SizedBox(height: esMovil ? 20 : 40),

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _datoPerfil('Nombre:', '$_name'),
            _datoPerfil('Apellidos:', '$_apellidos'),
            _datoPerfil('Teléfono:', '$_tlfn'),
            _datoPerfil('Correo:', '$_email'),
          ],
        ),

        SizedBox(height: esMovil ? 20 : 40),

        if (_pendiente)
          ElevatedButton(
            onPressed: (){_userRepository.invitarUser(id!);},
            child: Text(
              'Reenvio para configuración de contraseña',
            ),
          ),
         SizedBox(height: esMovil ? 20 : 40),

      ],
    );
  }

  Widget _vistaOrdenador(){
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
            flex: 1,
            child: _datos(false)
        ),
        const SizedBox(width: 40),

        Expanded(
            flex: 1,
            child: _buildHorarioWidget(false)
        ),
      ],
    );
  }

  Widget _vistaMovil(){
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,

      children: [

        _datos(true),
        _buildHorarioWidget(true),
      ],
    );

  }


  @override
  Widget build(BuildContext context){
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

    return Scaffold(
      drawer: MenuEmpresa(current: PageKind.modificarOtrosUsuarios, rol: userRol!),
      body:
      LayoutBuilder(
          builder: (context, constrait){
            if(!isLoadingUser && userRol != UserType.jefe){
              return const NoAccessWidget();
            }

            return
              SingleChildScrollView(
                child: Center(
                    child: Padding(
                      padding: esMovil
                          ? EdgeInsets.only(top:40, bottom: 20, left: 10, right: 10)
                          : EdgeInsets.all(40),
                      child: Column(

                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,

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
                                "MODIFICAR USUARIO",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: esMovil ? 20 : 24,
                                  color: Color(0xFF222B6F),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              Spacer(),
                            ],
                          ),

                          if (esMovil) ... [
                            SizedBox(height: 20),
                            _vistaMovil(),
                          ]else...[
                            SizedBox(height: 40),
                            _vistaOrdenador(),
                          ],

                          SizedBox(height: 40),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ElevatedButton(
                                onPressed: _checkFields,
                                child: Text('Guardar', style: TextStyle(fontSize: 18),),
                              ),
                              ElevatedButton(
                                onPressed: (){
                                  _resetFields();
                                },
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red
                                ),
                                child: Text('Cancelar', style: TextStyle(fontSize: 18)),
                              ),
                            ],
                          ),
                          SizedBox(height: 40),
                        ],
                      ),
                    )

                ),
              );
          }),
    );
  }
}