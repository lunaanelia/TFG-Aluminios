import 'package:aluminios/screen/configuracion.dart';
import 'package:aluminios/screen/confirmacion_presupueto.dart';
import 'package:aluminios/screen/create_cita.dart';
import 'package:aluminios/screen/create_presupuesto.dart';
import 'package:aluminios/screen/create_product.dart';
import 'package:aluminios/screen/envio_proyecto.dart';
import 'package:aluminios/screen/gestion_products.dart';
import 'package:aluminios/screen/listado_compras.dart';
import 'package:aluminios/screen/gestion_proyectos.dart';
import 'package:aluminios/screen/listado_proyectos.dart';
import 'package:aluminios/screen/modification_product.dart';
import 'package:aluminios/screen/revision_proyecto.dart';
import 'package:aluminios/screen/modification_user.dart';
import 'package:aluminios/screen/set_password.dart';
import 'package:aluminios/screen/edit_information.dart';
import 'package:aluminios/screen/gestion_usuario.dart';
import 'package:aluminios/screen/register.dart';
import 'package:aluminios/screen/splash_page.dart';
import 'package:aluminios/screen/tareas_page_boss.dart';
import 'package:aluminios/screen/ver_proyecto.dart';
import 'package:aluminios/widgets/no_access_widget.dart';
import 'package:flutter/material.dart';
import 'screen/login.dart';
import 'screen/home_page_client.dart';
import 'screen/tareas_page.dart';
import 'screen/create_user.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();

  initializeDateFormatting('es_ES', null).then((_) {
    runApp(const MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color myPrimaryColor = Color(0xFF222B6F);

    return MaterialApp(
      title: 'Aluminios Ayala',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: Color(0xFFFFFFFF),
        fontFamily: 'Arial',

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: myPrimaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            )
          )
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontSize: 18.0),
          bodyMedium: TextStyle(fontSize: 18.0),
        ).apply(
          bodyColor: myPrimaryColor,
          displayColor: myPrimaryColor,
          fontFamily: 'Arial',
        ),
        timePickerTheme: TimePickerThemeData(
          backgroundColor: const Color(0xFFF8FAFC),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          helpTextStyle: const TextStyle(
            color: Color(0xFF222B6F),
            fontWeight: FontWeight.bold,
            fontSize: 14,
            letterSpacing: 1.2,
          ),

          hourMinuteShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          hourMinuteColor: const Color(0xFF222B6F).withValues(alpha:0.12),
          hourMinuteTextColor: const Color(0xFF222B6F),

          hourMinuteTextStyle: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
          ),

          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFF222B6F).withValues(alpha:0.08),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: const Color(0xFF222B6F).withValues(alpha:0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF222B6F), width: 2),
            ),
          ),

          entryModeIconColor: Colors.transparent,
        ),

        inputDecorationTheme: InputDecorationTheme(

          floatingLabelStyle: WidgetStateTextStyle.resolveWith((states) {
            if (states.contains(WidgetState.error)) return const TextStyle(color: Colors.red);
            return const TextStyle(color: Color(0xFF222B6F));
          }),

          labelStyle: WidgetStateTextStyle.resolveWith((states) {
            if (states.contains(WidgetState.error)) return const TextStyle(color: Colors.red);
            return const TextStyle(color: Color(0xFF222B6F));
          }),

          hintStyle: const TextStyle(color: Colors.grey),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: myPrimaryColor,  width: 2.0,),
          ),

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: myPrimaryColor,  width: 2.0,),
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: myPrimaryColor, width: 2),
          ),

          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.red,  width: 2.0),
          ),

          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),

          errorStyle: const TextStyle(color: Colors.red),
        ),
      ),

      initialRoute: '/',
      routes: {
        'login/': (context) => LoginPage(),
        'home/':(context) => HomePageClient(),
        '/' : (context) => SplashPage(),
        'misTareas/':(context) => TareasPage(),
        'register/':(context) => RegisterPage(),
        'createUser/': (context) => CreateUserPage(),
        //'prueba/': (context) => SetPassword(uid:'10', token:'0'),
        'forbiden/' : (context) => NoAccessWidget(),
        'gestionUsers/' : (context) => GestionUsuarioPage(),
        'editInformation/' : (context) => EditInformationPage(),
        'gestionProductos/' : (context) => GestionProductsPage(),
        'modificateUser/' : (context) => ModificateUserPage(),
        'createProduct/' : (context) => CreateProductPage(),
        'modificateProduct/' : (context) => ModificationProductPage(),
        'createPresupuesto/' :(context) => CreatePresupuestoPage(),
        'listadoPresupuestos/':(context) => GestionPresupuestosPage(),
        'confirmacionPresupuesto/':(context) => ConfirmacionPresupuestoPage(),
        'listadoProyectos/':(context)=> GestionProyectosPage(),
        'misProyectos/': (context) => ListadoProyectosPage(),
        'crearCita/' : (context) => CreateCitaPage(),
        'modificarProyecto/' : (context) => ModificationProyectPage(),
        'todasTareas/': (context) => TareasPageBoss(),
        'datosEnvio/': (context) => DatosProyectPage(),
        'verProyecto/': (context) => VerProyectPage(),
        'configuracion/':(context) => ConfiguracionPage(),
      },

      onGenerateRoute: (settings) {
        if (settings.name == null) return null;

        if (settings.name!.contains('configurar-password')) {

          final uri = Uri.parse(settings.name!);
          final List<String> segments = uri.pathSegments;


          if (segments.length >= 3) {
            return MaterialPageRoute(
              builder: (context) => SetPassword(
                uid: segments[segments.length - 2],
                token: segments[segments.length - 1],
              ),
            );
          }
        }
      return null;
    },
    );
  }
}
