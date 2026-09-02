import 'package:aluminios/mixins/user_loader.dart';
import 'package:aluminios/repository/auth_repository.dart';
import 'package:aluminios/utils/check_user.dart';
import 'package:aluminios/utils/mensajes.dart';
import 'package:aluminios/widgets/need_login_widget.dart';
import 'package:aluminios/widgets/no_access_widget.dart';
import 'package:aluminios/widgets/menu_empresa.dart';
import 'package:flutter/material.dart';
import '../repository/user_repository.dart';
import '../utils/toast_manager.dart';
import '../models/horario.dart';
import '../utils/tipos.dart';

class CreateUserPage extends StatefulWidget {
  const CreateUserPage({super.key});

  @override
  State<CreateUserPage> createState() => _CreateUserState();
}

class _CreateUserState extends State<CreateUserPage> with UserLoaderMixin{
  final TextEditingController _telf = TextEditingController();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _apellidos = TextEditingController();
  final TextEditingController _email = TextEditingController();

  bool _telefonoError = false;
  bool _nameError = false;
  bool _apellidosError = false;
  bool _emailError = false;
  bool _horarioError = false;

  final UserRepository _userRepository = UserRepository();
  final AuthRepository authRepository = AuthRepository();

  UserType _rol = UserType.trabajador;

  List<DiaLaboral> semana = [
    DiaLaboral(nombre: "Lunes", turnos: []),
    DiaLaboral(nombre: "Martes", turnos: []),
    DiaLaboral(nombre: "Miercoles", turnos: []),
    DiaLaboral(nombre: "Jueves", turnos: []),
    DiaLaboral(nombre: "Viernes", turnos: []),
    DiaLaboral(nombre: "Sabado", turnos: []),
  ];

  @override
  void initState() {
    super.initState();
    loadCurrentUserData();
  }

  void _checkFields() async {
    setState(() {

      _telefonoError = _telf.text.isEmpty;
      _nameError = _name.text.isEmpty;
      _apellidosError = _apellidos.text.isEmpty;
      _emailError = _email.text.isEmpty;
      _horarioError = semana.every((dia) => dia.turnos.isEmpty);
    });

    debugPrint(_horarioError.toString());

    if (_telefonoError || _nameError || _emailError ||
        _apellidosError || _horarioError) {
      ToastManager.show(context, camposVacios, success: false);
    }

    if (_email.text.isNotEmpty) {
      var (valido, mensaje) = checkEmail(_email.text);
      setState(() {
        _emailError = !valido;
      });
      if (!valido) {
        ToastManager.show(context, mensaje, success: false);
      }
    }

    if(!_telefonoError ){
      var (valido, mensaje) = checkTelefono(_telf.text);
      setState(() {
        _telefonoError = !valido;
      });
      if (!valido) {
        ToastManager.show(context, mensaje, success: false);
      }
    }

    if (!_nameError && !_apellidosError && !_emailError &&  !_telefonoError && !_horarioError) {
      String telf = _telf.text;
      String email = _email.text;
      String firstName = _name.text;
      String lastName = _apellidos.text;

      try{
        var data = await _userRepository.createUser(firstName, lastName, telf, email, _rol.name, semana);

        if(mounted){
          debugPrint("Id: ${data!.id}");
          ToastManager.show(context, 'Usuario creado con exito', success: true);
          setState(() {
            _telf.text = "";
            _email.text = "";
            _name.text = "";
            _apellidos.text = "";
            semana = [
              DiaLaboral(nombre: "Lunes", turnos: []),
              DiaLaboral(nombre: "Martes", turnos: []),
              DiaLaboral(nombre: "Miercoles", turnos: []),
              DiaLaboral(nombre: "Jueves", turnos: []),
              DiaLaboral(nombre: "Viernes", turnos: []),
              DiaLaboral(nombre: "Sabado", turnos: []),
            ];
          });

        }
      }catch(e){
        debugPrint("Error executing the register user endpoint: $e");
        setState(() {
          _telefonoError = true;
          _emailError  = true;
        });
        if(mounted)ToastManager.show(context, yaExiste, success: false);
      }

    }
  }

  void _resetFields() async{
    setState(() {
      _telefonoError = false;
      _nameError = false;
      _apellidosError = false;
      _emailError = false;
      _horarioError = false;

      _telf.text = "";
      _email.text = "";
      _name.text = "";
      _apellidos.text = "";
      semana = [
        DiaLaboral(nombre: "Lunes", turnos: []),
        DiaLaboral(nombre: "Martes", turnos: []),
        DiaLaboral(nombre: "Miercoles", turnos: []),
        DiaLaboral(nombre: "Jueves", turnos: []),
        DiaLaboral(nombre: "Viernes", turnos: []),
        DiaLaboral(nombre: "Sabado", turnos: []),
      ];
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
            color: _horarioError ? Colors.red : Color(0xFF222B6F),
          ),
        ),
        SizedBox(height:esMovil ? 0 : 40),
        ListView.builder(
          itemCount: semana.length,
          shrinkWrap: true,
          itemBuilder: (context, index) {
            final dia = semana[index];
            return Card(
              child: Column(
                children: [
                  ListTile(
                    title: Text(dia.nombre, style: TextStyle( fontSize: 18, color: Color(0xFF222B6F),fontWeight: FontWeight.bold),),

                    trailing: IconButton(
                      icon: Icon(Icons.add_circle_outline, color: Color(0xFF647CB1)),
                      onPressed: () => _agregarTurno(index),
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

  Widget _formulario(){
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
              selected: {_rol},
              showSelectedIcon: false,
              onSelectionChanged: (Set<UserType> newType,) {
                setState(() {
                  _rol= newType.first;
                });
              },

              style: SegmentedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),

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

        SizedBox(height: 40),
        TextField(
          controller: _name,
          cursorColor: Color(0xFF222B6F),
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(
                color: Color(0xFF222B6F),
                width: 2.0,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide:const BorderSide(
                color: Color(0xFF222B6F),
                width: 2.0,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            labelText: 'Nombre',
            labelStyle: TextStyle(
              color: _nameError ? Colors.red : Color(0xFF222B6F),
            ),
            errorText: _nameError ? '' : null,

            errorBorder: OutlineInputBorder(
              borderSide:  const BorderSide(
                color: Colors.red,
                width: 2.0,
              ),
              borderRadius: BorderRadius.circular(10.0),
            ),
          ),
        ),
        SizedBox(height: 40),
        TextField(
          controller: _apellidos,
          cursorColor: Color(0xFF222B6F),
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(
                color: Color(0xFF222B6F),
                width: 2.0,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide:const BorderSide(
                color: Color(0xFF222B6F),
                width: 2.0,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            labelText: 'Apellidos',
            labelStyle: TextStyle(
              color: _apellidosError ? Colors.red : Color(0xFF222B6F),
            ),
            errorText: _apellidosError ? '' : null,

            errorBorder: OutlineInputBorder(
              borderSide:  const BorderSide(
                color: Colors.red,
                width: 2.0,
              ),
              borderRadius: BorderRadius.circular(10.0),
            ),
          ),
        ),
        SizedBox(height: 40),
        TextField(
          controller: _telf,
          cursorColor: Color(0xFF222B6F),
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(
                color: Color(0xFF222B6F),
                width: 2.0,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide:const BorderSide(
                color: Color(0xFF222B6F),
                width: 2.0,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            labelText: 'Teléfono',
            labelStyle: TextStyle(
              color: _telefonoError ? Colors.red : Color(0xFF222B6F),
            ),
            errorText: _telefonoError ? '' : null,

            errorBorder: OutlineInputBorder(
              borderSide:  const BorderSide(
                color: Colors.red,
                width: 2.0,
              ),
              borderRadius: BorderRadius.circular(10.0),
            ),
          ),
        ),
        SizedBox(height: 40),
        TextField(
          controller: _email,
          cursorColor: Color(0xFF222B6F),
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(
                color: Color(0xFF222B6F),
                width: 2.0,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide:const BorderSide(
                color: Color(0xFF222B6F),
                width: 2.0,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            labelText: 'Correo',
            labelStyle: TextStyle(
              color: _emailError ? Colors.red : Color(0xFF222B6F),
            ),
            errorText: _emailError ? '' : null,

            errorBorder: OutlineInputBorder(
              borderSide:  const BorderSide(
                color: Colors.red,
                width: 2.0,
              ),
              borderRadius: BorderRadius.circular(10.0),
            ),
          ),
        ),

      ],
    );
  }

  Widget _vistaOrdenador(){
    return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
              flex: 1,
              child: _formulario()
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
    return  Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,

          children: [

            _formulario(),
            SizedBox(height: 20),
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
      drawer: MenuEmpresa(current: PageKind.crearUsuario, rol: userRol!),
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
                              "CREAR USUARIO",
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


                        SizedBox(height: 40),

                        if (esMovil) ... [
                          _vistaMovil(),
                        ]else
                          _vistaOrdenador(),

                        SizedBox(height: 40),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ElevatedButton(
                              onPressed: _checkFields,
                              child: Text('Crear', style: TextStyle(fontSize: 18),),
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
                      ],
                    ),
                  )

              ),
            );
          }),
    );
  }
}