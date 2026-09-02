import 'package:aluminios/utils/tipos.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../mixins/user_loader.dart';
import 'home_page_client.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with UserLoaderMixin{

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await Future.delayed(
      const Duration(seconds: 1),
    );

    if (!mounted) return;

    if (kIsWeb) {
      final currentFragment = Uri.base.fragment;

      if (currentFragment.contains('configurar-password')) return;
    }

    try {
      await loadCurrentUserData();
    } catch (e) {

      //print("Error de sesión en móvil: $e");
    }

    if (!mounted) return;

    if (userName != null) {
      if (userRol == UserType.cliente){
        Navigator.pushReplacementNamed( context, 'home/',);
      }else if (userRol == UserType.administrativo){
        Navigator.pushReplacementNamed( context, 'listadoProyectos/',);
      }else{
        Navigator.pushReplacementNamed(context, 'misTareas/',);
      }
    } else {
      if(kIsWeb){ // Es web
        Navigator.pushReplacementNamed( context, 'home/',);
      }else{ // Es movil
        Navigator.pushReplacementNamed( context, 'login/',);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Image.asset(
          'assets/imagenes/logo-color.png',
          width: 200,
        ),
      ),
    );
  }
}