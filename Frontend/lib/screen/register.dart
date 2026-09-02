import 'package:aluminios/repository/auth_repository.dart';
import 'package:aluminios/utils/check_user.dart';
import 'package:aluminios/utils/mensajes.dart';
import 'package:flutter/material.dart';
import '../repository/user_repository.dart';
import '../models/usuario.dart';
import '../utils/toast_manager.dart';


class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterState();
}

class _RegisterState extends State<RegisterPage>{
  final TextEditingController _telf = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _passwordComfirm = TextEditingController();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _apellidos = TextEditingController();
  final TextEditingController _email = TextEditingController();

  bool _isObscure = true;
  bool _isObscureC = true;

  bool _telefonoError = false;
  bool _passwordError = false;
  bool _nameError = false;
  bool _apellidosError = false;
  bool _emailError = false;
  bool _passwordConfirmError = false;

  final UserRepository _userRepository = UserRepository();
  final AuthRepository authRepository = AuthRepository();

  void _checkFields() async {
    setState(() {
      _telefonoError = _telf.text.isEmpty;
      _passwordError = _password.text.isEmpty;
      _passwordConfirmError = _passwordComfirm.text.isEmpty;
      _nameError = _name.text.isEmpty;
      _apellidosError = _apellidos.text.isEmpty;
      _emailError = _email.text.isEmpty;
    });

    if (_telefonoError || _passwordError || _passwordConfirmError || _nameError || _emailError ||
        _apellidosError) {

      ToastManager.show(context, camposVacios, success:false);
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

    if (!_passwordError) {
      var (valido, mensaje) = checkPassword(_password.text);
      setState(() {
        _passwordError = !valido;
      });
      if (!valido) {
        ToastManager.show(context, mensaje, success: false);
      }
      else if(!_passwordConfirmError && _password.text != _passwordComfirm.text){
          setState(() {
            _passwordError = true;
            _passwordConfirmError = true;
          });
          ToastManager.show(context, passwordDiferente, success: false);

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


    if (!_nameError && !_passwordError && !_passwordConfirmError && !_apellidosError && !_emailError &&
        !_telefonoError) {
      String telf = _telf.text;
      String email = _email.text;
      String firstName = _name.text;
      String lastName = _apellidos.text;
      String password = _password.text;

      try{
        await _userRepository.registerUser(firstName, lastName, telf, email, password);

        if(mounted){
          try{
           await Future.delayed(const Duration(milliseconds: 500));
            Usuario user = await authRepository.login(telf, password);

            if(mounted){
              if(user.rol=="cliente"){
                Navigator.pushNamed(context, '/');
              }
              else {
                Navigator.pushNamed(context, 'empresa/');
              }
            }

          }catch(e){
            debugPrint("Login error $e");
            if (mounted) {
              ToastManager.show(context, "Usuario creado", success: true);
              Navigator.pushReplacementNamed(context, '/');
            }
          }

        }
      }catch(e){
        debugPrint("Error executing the register user endpoint: $e");
        ToastManager.show(context, yaExiste, success: false);
        setState(() {
          _telefonoError = true;
          _emailError = true;
        });
      }

    }
  }
  
  @override
  Widget build(BuildContext context){
    final screenWidth = MediaQuery.of(context).size.width;

    bool esMovil = screenWidth < 600;

    return Scaffold(
      body:
      LayoutBuilder(
          builder: (context, constraints){
            return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            if(!esMovil)
                              Container(
                                width: screenWidth*0.5,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF222B6F),
                                ),
                                padding: EdgeInsets.all(40.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Image.asset('assets/imagenes/logo-blanco.png', width: screenWidth*0.25),
                                      ],
                                    ),
                                    SizedBox(height: 40),
                                    Wrap(
                                      alignment: WrapAlignment.center,
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      spacing: 8.0,
                                      runSpacing: 0.0,
                                      children: [
                                        Text(
                                          "Bienvenido a ",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 24,
                                            color: Color(0xFFE8ECF3),
                                          ),
                                        ),
                                        Text(
                                          "ALUMNIOS AYALA",
                                          style: TextStyle(
                                            fontStyle: FontStyle.italic,
                                            fontWeight: FontWeight.bold,

                                            fontSize: 24,
                                            color: Color(0xFFE8ECF3),
                                          ),
                                        ),
                                      ],
                                    ),

                                    SizedBox(height: 40),
                                    Wrap(
                                      alignment: WrapAlignment.center,
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      spacing: 8.0,
                                      runSpacing: 0.0,
                                      children: [
                                        Text(
                                          '¿Ya tienes cuenta?',
                                          style: TextStyle(
                                            color: Color(0xFFE8ECF3),
                                            fontSize: 16,
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pushNamed(context, 'login/');
                                          },
                                          style: TextButton.styleFrom(
                                            padding: EdgeInsets.zero,
                                            minimumSize: Size(0, 0),
                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          ),
                                          child: Text(
                                            "Pulsa aquí para iniciar sesión",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFFE8ECF3),
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                           
                            
                            SizedBox(
                              width: esMovil ? screenWidth : screenWidth * 0.5,
                              child: Center(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(horizontal: screenWidth*0.07),
                                    child: Column(
                                       mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.center,

                                      children: [
                                        if(esMovil)...[

                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Image.asset('../assets/imagenes/logo-color.png', width: screenWidth*0.25),
                                            ],
                                          ),
                                        ],

                                        SizedBox(height: 40),

                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.start,
                                          children: [
                                            IconButton(
                                                  onPressed: (){Navigator.pop(context);},
                                                  icon: Icon(Icons.arrow_back_ios_new_outlined, color: Color(0xFF222B6F),)
                                              ),
                                            Spacer(),
                                            Text(
                                              "CREAR CUENTA",
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 24,
                                                color: Color(0xFF222B6F),
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                            Spacer(),
                                          ],
                                        ),

                                        SizedBox(height: 40),
                                        TextField(
                                          key: const Key("nombre"),
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
                                          key: const Key("apellidos"),
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
                                          key: const Key("telefono"),
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
                                          key: const Key("email"),
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
                                        SizedBox(height: 40),
                                        TextField(
                                          key: const Key("contrasena"),
                                          controller: _password,
                                          obscureText: _isObscure,
                                          cursorColor: Color(0xFF222B6F),
                                          decoration: InputDecoration(
                                            suffixIcon: IconButton(
                                              onPressed: (){
                                                setState(() {
                                                  _isObscure = !_isObscure;
                                                });
                                              },
                                              icon: Icon(_isObscure ? Icons.visibility_off : Icons.visibility, color: Color(0xFF222B6F),),
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
                                            labelText: 'Contraseña',
                                            labelStyle: TextStyle(
                                              color: _passwordError ? Colors.red : Color(0xFF222B6F),
                                            ),
                                            errorText: _passwordError ? '' : null,

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
                                          key: const Key("confirmar"),
                                          controller: _passwordComfirm,
                                          obscureText: _isObscureC,
                                          cursorColor: Color(0xFF222B6F),
                                          decoration: InputDecoration(
                                            suffixIcon: IconButton(
                                              onPressed: (){
                                                setState(() {
                                                  _isObscureC = !_isObscureC;
                                                });
                                              },
                                              icon: Icon(_isObscureC ? Icons.visibility_off : Icons.visibility, color: Color(0xFF222B6F),),
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
                                            labelText: 'Confirmar contraseña',
                                            labelStyle: TextStyle(
                                              color: _passwordError ? Colors.red : Color(0xFF222B6F),
                                            ),
                                            errorText: _passwordError ? '' : null,

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
                                        ElevatedButton(
                                          key: const Key("crear"),
                                          onPressed: _checkFields,
                                          child: Text('Crear'),
                                        ),
                                        SizedBox(height: 40),

                                        if(esMovil)
                                          Wrap(
                                            alignment: WrapAlignment.center,
                                            crossAxisAlignment: WrapCrossAlignment.center,
                                            spacing: 8.0,
                                            runSpacing: 0.0,
                                            children: [
                                              Text(
                                                '¿Ya tienes cuenta?',
                                                style: TextStyle(
                                                  color: Color(0xFF222B6F),
                                                  fontSize: 16,
                                                ),
                                              ),
                                              TextButton(
                                                key: const Key("irLogin"),
                                                onPressed: () {
                                                  Navigator.pushNamed(context, 'login/');
                                                },
                                                style: TextButton.styleFrom(
                                                  padding: EdgeInsets.zero,
                                                  minimumSize: Size(0, 0),
                                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                ),
                                                child: Text(
                                                  "Pulsa aquí para iniciar sesión",
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF222B6F),
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  )

                              ),
                            )
                            
                          ],
                        ),
                  ),
                ),
            );
          }),
    );


  }
}