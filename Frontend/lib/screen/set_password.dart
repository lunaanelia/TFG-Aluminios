import 'package:aluminios/repository/auth_repository.dart';
import 'package:aluminios/utils/mensajes.dart';
import 'package:aluminios/utils/toast_manager.dart';
import 'package:flutter/material.dart';

import '../utils/check_user.dart';

class SetPassword extends StatefulWidget {
  final String uid;
  final String token;

  const SetPassword({super.key, required this.uid, required this.token});

  @override
  State<SetPassword> createState() => _SetPasswordState();
}

class _SetPasswordState extends State<SetPassword> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  bool _errorPassword = false;
  bool _errorConfirm = false;

  bool _isObscure = true;
  bool _isObscureC = true;
  AuthRepository authRepository = AuthRepository();

  void _checkPassword() async {

    setState(() {
      _errorPassword = false;
      _errorConfirm = false;
    });

    if (_password.text.isEmpty || _confirm.text.isEmpty) {
      setState(() {
        _errorPassword = _password.text.isEmpty ;
        _errorConfirm = _confirm.text.isEmpty;
      });
      ToastManager.show(context, camposVacios, success: false);
    }


    if (_password.text.isNotEmpty) {
      var (valido, mensaje) = checkPassword(_password.text);
      setState(() {
        _errorPassword = !valido;
      });
      if (!valido) {
        ToastManager.show(context, mensaje, success: false);
      }
      else if(!_errorConfirm && _password.text != _confirm.text){
        setState(() {
          _errorPassword = true;
          _errorPassword = true;
        });
        ToastManager.show(context, passwordDiferente, success: false);

      }
    }

    if(!_errorConfirm && !_errorPassword){
      bool exito = await authRepository.confirmarPassword(
          widget.uid,
          widget.token,
          _password.text
      );

      if(mounted) {
        if (exito) {
          ToastManager.show(
              context, "Contraseña cambiada con exito", success: true);

          Navigator.pushNamed(context, 'login/');

          debugPrint("ha sifo exito");
        }
        else {
          ToastManager.show(
              context, "Se ha producido un error, intentelo más tarde",
              success: false);
        }
      }
    }


  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body:  LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,

                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                              '../assets/imagenes/logo-color.png', width: 150),
                        ],
                      ),
                      SizedBox(height: 40),
                      const Text(
                        "Bienvenido",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                          color: Color(0xFF222B6F),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 40),
                      const Text("Crea tu nueva contraseña."),
                      SizedBox(height: 40),
                      SizedBox(
                        width: 400,
                        child: TextField(
                          controller: _password,
                          obscureText: _isObscure,
                          cursorColor: Color(0xFF222B6F),
                          decoration: InputDecoration(
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _isObscure = !_isObscure;
                                });
                              },
                              icon: Icon(
                                _isObscure ? Icons.visibility_off : Icons
                                    .visibility, color: Color(0xFF222B6F),),
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
                              borderSide: const BorderSide(
                                color: Color(0xFF222B6F),
                                width: 2.0,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            labelText: 'Contraseña',
                            labelStyle: TextStyle(
                              color: _errorPassword ? Colors.red : Color(
                                  0xFF222B6F),
                            ),
                            errorText: _errorPassword ? '' : null,

                            errorBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                color: Colors.red,
                                width: 2.0,
                              ),
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                          ),
                        ),

                      ),

                      SizedBox(height: 40),
                      SizedBox(
                        width: 400,
                        child: TextField(
                          controller: _confirm,
                          obscureText: _isObscureC,
                          cursorColor: Color(0xFF222B6F),
                          decoration: InputDecoration(
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _isObscureC = !_isObscureC;
                                });
                              },
                              icon: Icon(
                                _isObscureC ? Icons.visibility_off : Icons
                                    .visibility, color: Color(0xFF222B6F),),
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
                              borderSide: const BorderSide(
                                color: Color(0xFF222B6F),
                                width: 2.0,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            labelText: 'Confirmar contraseña',
                            labelStyle: TextStyle(
                              color: _errorConfirm ? Colors.red : Color(
                                  0xFF222B6F),
                            ),
                            errorText: _errorConfirm ? '' : null,

                            errorBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                color: Colors.red,
                                width: 2.0,
                              ),
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 40),
                      ElevatedButton(
                          onPressed: _checkPassword,
                          child: const Text("Guardar Contraseña")
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
          ),
    );
  }
}