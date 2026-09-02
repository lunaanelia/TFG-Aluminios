import 'package:aluminios/mixins/user_loader.dart';
import 'package:aluminios/utils/check_user.dart';
import 'package:aluminios/widgets/header.dart';
import 'package:aluminios/models/horario.dart';
import 'package:aluminios/utils/mensajes.dart';
import 'package:aluminios/widgets/menu_empresa.dart';
import 'package:aluminios/widgets/need_login_widget.dart';
import 'package:flutter/material.dart';
import '../repository/user_repository.dart';
import '../widgets/banner_delete.dart';
import '../utils/toast_manager.dart';
import '../utils/tipos.dart';

class EditInformationPage extends StatefulWidget {
  const EditInformationPage({super.key});

  @override
  State<EditInformationPage> createState() => _EditInformationState();
}

class _EditInformationState extends State<EditInformationPage> with UserLoaderMixin{
  final TextEditingController _telf = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirm = TextEditingController();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _apellidos = TextEditingController();
  final TextEditingController _email = TextEditingController();

  final UserRepository _userRepository = UserRepository();

  bool _telefonoError = false;
  bool _nameError = false;
  bool _apellidosError = false;
  bool _emailError = false;
  bool _passwordError = false;
  bool _passwordConfirmError = false;

  List<DiaLaboral> semana = [
    DiaLaboral(nombre: "Lunes", turnos: []),
    DiaLaboral(nombre: "Martes", turnos: []),
    DiaLaboral(nombre: "Miercoles", turnos: []),
    DiaLaboral(nombre: "Jueves", turnos: []),
    DiaLaboral(nombre: "Viernes", turnos: []),
    DiaLaboral(nombre: "Sabado", turnos: []),
  ];

  bool _isObscure = true;
  bool _isObscureConfirm = true;


  @override
  void initState() {
    super.initState();
    _loadData();

  }

  Future <void> _loadData() async{
    await loadCurrentUserData();
    if(mounted) {
      _resetFields();
    }
  }
  void _checkFields() async {
    bool hayCambios = false;

    String nName = _name.text.trim();
    String nApellidos = _apellidos.text.trim();
    String nTelf = _telf.text.trim();
    String nEmail = _email.text.trim();
    String nPass = _password.text;

    if(nEmail.isNotEmpty && nEmail != userEmail){
      var (valido, mensaje) = checkEmail(nEmail);
      if (!valido) {
        setState(() => _emailError = true);
        ToastManager.show(context, mensaje, success: false);
      }
    }
    bool horarioVacio = semana.every((dia) => dia.turnos.isEmpty);

    bool horarioCambiado = false;
    if (userRol == UserType.jefe && !horarioVacio) {
      if(semana.length != userHorario!.length){
        horarioCambiado = true;
      }else{
        for (int i = 0; i < semana.length; i++) {
          if (!semana[i].esIgualA(userHorario![i])) {
            horarioCambiado = true;
            break;
          }
        }
      }

    }

    bool nameChange = nName.isNotEmpty && nName != userName;
    bool apellidosChange = nApellidos.isNotEmpty && nApellidos != userApellidos;
    bool emailChange = nEmail.isNotEmpty && nEmail != userEmail;
    bool tlfChange = nTelf.isNotEmpty && nTelf != userTelf;
    bool passChange = nPass.isNotEmpty;

    if (nameChange || apellidosChange || emailChange || tlfChange || passChange || horarioCambiado) {
      hayCambios = true;
    }

    if (!hayCambios) {
      ToastManager.show(context, "No se han detectado cambios", success: false);
      return;
    }

    if (nTelf.isNotEmpty && nTelf != userTelf) {
      var (valido, mensaje) = checkTelefono(nTelf);
      if (!valido) {
        setState(() {
          _telefonoError = true;
          tlfChange = false;
        }

        );
        ToastManager.show(context, mensaje, success: false);
      }
    }

    if(passChange){
      var (valido, mensaje) = checkPassword(nPass);
      if (!valido) {
        setState(() => _passwordError = true);
        passChange = false;
        ToastManager.show(context, mensaje, success: false);
      }else if (nPass != _confirm.text) {
        setState(() {
          _passwordError = true;
          _passwordConfirmError = true;
          passChange = false;
        });
        ToastManager.show(context, passwordDiferente, success: false);
      }
    }

    hayCambios = false;

    if (nameChange || apellidosChange || emailChange || tlfChange || passChange || horarioCambiado) {
      hayCambios = true;
    }

    if (!hayCambios) {
      return;
    }

    try {
        final resultado = await _userRepository.updateUser( userId!,
        name: nameChange ? nName : null,
        apellidos: apellidosChange ? nApellidos : null,
        email: emailChange ? nEmail : null,
        telefono: tlfChange ? nTelf : null,
        password: passChange ? nPass : null,
        horario: horarioCambiado ? semana : null,
      );

      if (resultado != null) {
        await loadCurrentUserData(forceRefresh: true);
        await _resetFields();
        if(mounted) ToastManager.show(context, "Cambios realizados correctamente", success: true);

      }
    } catch (e) {
      debugPrint("Error en actualización: $e");
      if(mounted) ToastManager.show(context, "Error al actualizar. Revise los datos.", success: false);
    }
  }

  Future<void> _desactivarCuenta(int id) async{
    try{
      final res = await _userRepository.delete(userId!);
      if (mounted){
        ToastManager.show(context, res, success: true);
        _userRepository.logout();
        Navigator.pushNamed(context, '/');
      }
    }catch(e){
      if (mounted) ToastManager.show(context, "$e", success: false);
    }
  }

  Future<void> _resetFields() async{
    setState(() {
      _telefonoError = false;
      _nameError = false;
      _apellidosError = false;
      _emailError = false;
     _passwordConfirmError = false;
     _passwordError = false;

      _telf.text = userTelf ?? '';
      _email.text = userEmail ?? '';
      _name.text = userName ?? '';
      _apellidos.text = userApellidos ?? '';

      _password.clear();
      _confirm.clear();

      if(userHorario!.isNotEmpty){
        semana = userHorario!.map((dia) => dia.copy()).toList();
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
          physics: NeverScrollableScrollPhysics(),
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


  Widget _inputNormal(TextEditingController controller, String label, bool error){
    return TextField(
      controller: controller,
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
        labelText: label,
        labelStyle: TextStyle(
          color: error ? Colors.red : Color(0xFF222B6F),
        ),
        errorText: error ? '' : null,

        errorBorder: OutlineInputBorder(
          borderSide:  const BorderSide(
            color: Colors.red,
            width: 2.0,
          ),
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
    );
  }

  Widget _inputContrasenia(TextEditingController controller, String label, bool obscure, bool isConfirm, bool error){
    return TextField(
      controller: controller,
      obscureText: obscure,
      cursorColor: Color(0xFF222B6F),
      decoration: InputDecoration(
        suffixIcon: IconButton(
          onPressed: (){
            setState(() {
              if(isConfirm) {
                _isObscureConfirm = !_isObscureConfirm;
              }else{
                _isObscure = !_isObscure;
              }

            });
          },
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, color: Color(0xFF222B6F),),
        ),
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
        labelText: label,
        labelStyle: TextStyle(
          color: error ? Colors.red : Color(0xFF222B6F),
        ),
        errorText: error ? '' : null,
        isDense: true,
        errorStyle: const TextStyle(height: 0, fontSize: 0),

        errorBorder: OutlineInputBorder(
          borderSide:  const BorderSide(
            color: Colors.red,
            width: 2.0,
          ),
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
    );
  }

  Widget _formularioMovil(){
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            _inputNormal(_name, 'Nombre', _nameError),
            SizedBox(height: 40,),
            _inputNormal(_apellidos, 'Apellidos', _apellidosError),
            SizedBox(height: 40,),
            _inputNormal(_telf, 'Teléfono', _telefonoError),
            SizedBox(height: 40,),
            _inputNormal(_email, 'Email', _emailError),
            SizedBox(height: 40,),
            _inputContrasenia(_password, 'Contraseña', _isObscure, false,  _passwordError),
            SizedBox(height: 40,),
            _inputContrasenia(_confirm, 'Confirmar contraseña', _isObscureConfirm, true, _passwordConfirmError),
          ],
        );
  }

  Widget _formulario(){
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          flex: 5,
            child:
          Column(
            children: [
              _inputNormal(_name, 'Nombre', _nameError),
              SizedBox(height: 40,),
              _inputNormal(_apellidos, 'Apellidos', _apellidosError),
              SizedBox(height: 40,),
              _inputNormal(_telf, 'Teléfono', _telefonoError),
            ],
          )
        ),
        Spacer(flex: 1,),
        Expanded(
          flex: 5,
          child: Column(
          children: [
            _inputNormal(_email, 'Email', _emailError),
            SizedBox(height: 40,),
            _inputContrasenia(_password, 'Contraseña', _isObscure, false, _passwordError),
            SizedBox(height: 40,),
            _inputContrasenia(_confirm, 'Confirmar contraseña', _isObscureConfirm, true, _passwordConfirmError),
          ],
        ),),
      ],
    );
  }

  Widget _esCliente(bool esMovil){
    return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
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
                'MODIFICACIÓN DE DATOS',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Color(0xFF222B6F),
                ),
              ),
            ],

          ),
          SizedBox(height: 40,),
          if(esMovil)...[
            _formularioMovil()
          ]
          else ...[
            _formulario(),
          ]
        ]
    );
  }

  Widget _esJefe( bool esMovil){
    if (esMovil){
      return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,

          children: [
            _formularioMovil(),
            SizedBox(height: esMovil ? 30 : 40),
            _buildHorarioWidget(esMovil),
          ]
      );
    }else{
      return Row(

        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
              flex: 1,
              child: Column(
                children: [
                  Text(
                    "",
                    style: TextStyle(
                      fontSize: 18,
                      color: Color(0xFF222B6F),
                      fontWeight: FontWeight.w100,
                    ),
                  ),
                  SizedBox(height: 40),
                  _formularioMovil()
                ],
              )
          ),
          const SizedBox(width: 40),
          Expanded(
              flex: 1,
              child: _buildHorarioWidget(esMovil)
          ),
        ],
      );
    }
  }

  Widget _esEmpresa(bool esMovil){
    return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,

        children: [

          SizedBox(height: esMovil ? 20 : 100,),
          if (userRol == UserType.jefe)
          _esJefe(esMovil)
          else if(esMovil)
            _formularioMovil()
          else
            _formulario()
        ]
    );
  }

  @override
  Widget build(BuildContext context){
    final screenWidth = MediaQuery.of(context).size.width;

    bool esMovil = screenWidth < 600;

    if (isLoadingUser){
      return const Center(
        child: CircularProgressIndicator( color: Color(0xFF222B6F),),
      );
    }

    if(userName == null){
      return NeedLoginWidget();
    }


    return Scaffold(
      drawer: (userRol != null && userRol != UserType.cliente)
          ? MenuEmpresa(current: PageKind.modificardatos, rol: userRol!)
          : null,
      body:
      LayoutBuilder(
          builder: (context, constraints){
            return
              SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(

                      minHeight: constraints.maxHeight,
                    ),
                    child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Padding(
                            padding: esMovil
                                ? EdgeInsets.only(top:40, bottom: 20, left: 10, right: 10)
                                : EdgeInsets.symmetric(horizontal: /*userRol == UserType.cliente ? screenWidth*0.07 : */ 40, vertical: 40),
                             child: Column(
                             mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,

                              children: [


                                if(userRol == UserType.cliente)...[
                                  _esCliente(esMovil)
                                ]else...[

                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      IconButton(
                                          onPressed: (){
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
                                        'MODIFICACIÓN DE DATOS',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: esMovil ? 20 :24,
                                          color: Color(0xFF222B6F),
                                        ),
                                      ),
                                      Spacer(),
                                    ],
                                  ),
                                  _esEmpresa(esMovil)
                                ],

                                SizedBox(height: 60),
                                SizedBox(
                                  width: double.infinity,
                                  child: Wrap(
                                    alignment: WrapAlignment.spaceEvenly,
                                    runAlignment: WrapAlignment.center,
                                    spacing: 12.0,
                                    runSpacing: 12.0,
                                    children: [
                                      ElevatedButton(
                                        onPressed: _checkFields,
                                        child: const Text('Guardar', style: TextStyle(fontSize: 18)),
                                      ),

                                      if (userRol == UserType.cliente)
                                        ElevatedButton(
                                          onPressed: () {
                                            mostrarDialogoConfirmacion(
                                              context: context,
                                              mensaje: "¿Estas seguro que eliminar la cuenta?. Perderás el acceso a tus proyectos y presupuestos no confirmados.",
                                              id: userId!,
                                              accionBorrar: (idParaBorrar) async {
                                                await _desactivarCuenta(idParaBorrar);
                                              },
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                            foregroundColor: Colors.white,
                                          ),
                                          child: const Text('Eliminar cuenta', style: TextStyle(fontSize: 18)),
                                        ),

                                      OutlinedButton(
                                        onPressed: () {
                                          _resetFields();
                                        },
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(color: Colors.red, width: 1.5),
                                        ),
                                        child: const Text('Cancelar', style: TextStyle(color: Colors.red, fontSize: 18)),
                                      ),

                                    ],
                                  ),
                                ),
                                SizedBox(height: 40),

                              ],
                            ),
                          )
                        ]
                     )
                  )
              );
          }),
    );


  }
}