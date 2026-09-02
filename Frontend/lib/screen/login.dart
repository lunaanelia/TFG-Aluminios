import 'package:aluminios/repository/user_repository.dart';
import 'package:aluminios/utils/mensajes.dart';
import 'package:aluminios/utils/toast_manager.dart';
import 'package:flutter/material.dart';
import '../repository/auth_repository.dart';
import '../models/usuario.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginState();
}

class _LoginState extends State<LoginPage>{
  final TextEditingController _telf = TextEditingController();
  final TextEditingController _password = TextEditingController();

  bool _isObscure = true;
  bool _telefonoError = false;
  bool _passwordError = false;

  AuthRepository authRepository = AuthRepository();
  UserRepository userRepository = UserRepository();

  void _checkFields() async{
    setState(() {
      _telefonoError = _telf.text.isEmpty;
      _passwordError = _password.text.isEmpty;
    });

    if(_telefonoError || _passwordError){
      ToastManager.show(context, camposVacios, success: false);
    }else{
      String telefono =  _telf.text.replaceAll(' ', '');
      String password = _password.text;

      try{
        Usuario user = await authRepository.login(telefono, password);
        if(mounted){
          debugPrint("Login exitoso: ${user.firstName} con ID: ${user.id} y rol ${user.rol}");
          if(user.rol=="cliente"){
            Navigator.pushNamed(context, '/');
          }
          else if(user.rol == "administrativo"){
            Navigator.pushNamed(context, 'listadoProyectos/');
          }else{
            Navigator.pushNamed(context, 'misTareas/');

          }
        }

      }catch(e){
        debugPrint("Login error: $e");

        setState(() {
          _telefonoError = true;
          _passwordError = true;
        });

        if (mounted) ToastManager.show(context, "El teléfono o la contraseña son incorrectos", success: false);

      }
    }
  }

  void _checkTelf(){
    setState(() {
      _telefonoError = _telf.text.isEmpty;
      _passwordError = false;

    });

    if(_telefonoError){
      ToastManager.show(context, "Debe indicar el telefono", success: true);
    }else{
      userRepository.resetPassword(_telf.text);
      ToastManager.show(context, "Por favor revise el correo con el que inico sesión.", success: true);
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
                                          //Image.asset('../assets/imagenes/logo-blanco.png', width: screenWidth*0.25),
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
                                            '¿Todavía no tienes cuenta?',
                                            style: TextStyle(
                                              color: Color(0xFFE8ECF3),
                                              fontSize: 16,
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pushNamed(context, 'register/');
                                            },
                                            style: TextButton.styleFrom(
                                              padding: EdgeInsets.zero,
                                              minimumSize: Size(0, 0),
                                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            ),
                                            child: Text(
                                              "Puedes crearte una aquí",
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
                            child:  Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: screenWidth*0.07),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,

                                    children: [
                                      if(esMovil)
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Image.asset('assets/imagenes/logo-color.png', width: screenWidth*0.25),
                                          ],
                                        ),
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
                                            "INICIAR SESIÓN",
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
                                      ElevatedButton(
                                        key: const Key("enviar"),
                                        onPressed: _checkFields,
                                        child: Text('Enviar'),
                                      ),
                                      SizedBox(height: 40),
                                      TextButton(
                                        onPressed: _checkTelf,
                                        child: Text(
                                          '¿Has olvidado la contraseña?',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF222B6F),
                                            fontSize: 16,
                                          ),
                                        ),
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
                                              '¿Todavía no tienes cuenta?',
                                              style: TextStyle(
                                                color: Color(0xFF222B6F),
                                                fontSize: 16,
                                              ),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pushNamed(context, 'register/');
                                              },
                                              style: TextButton.styleFrom(
                                                padding: EdgeInsets.zero,
                                                minimumSize: Size(0, 0),
                                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              ),
                                              child: Text(
                                                "Puedes crearte una aquí",
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
                  )
              ),
            );
          }
          ),
    );


  }
}