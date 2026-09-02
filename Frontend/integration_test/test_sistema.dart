import 'package:aluminios/screen/confirmacion_presupueto.dart';
import 'package:aluminios/screen/create_cita.dart';
import 'package:aluminios/screen/create_presupuesto.dart';
import 'package:aluminios/screen/gestion_proyectos.dart';
import 'package:aluminios/screen/home_page_client.dart';
import 'package:aluminios/screen/listado_compras.dart';
import 'package:aluminios/screen/listado_proyectos.dart';
import 'package:aluminios/screen/revision_proyecto.dart';
import 'package:aluminios/screen/tareas_page.dart';
import 'package:aluminios/screen/ver_proyecto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:aluminios/main.dart' as app;

Future<void> seleccionarHora(
    WidgetTester tester, {
      required Key campoKey,
      required int hora,
      required int minuto,
    }) async {

  await tester.tap(find.byKey(campoKey));
  await tester.pumpAndSettle();

  final iconoTeclado = find.byIcon(Icons.keyboard_outlined);
  if (iconoTeclado.evaluate().isNotEmpty) {
    await tester.tap(iconoTeclado);
    await tester.pumpAndSettle();
  }

  final campos = find.byWidgetPredicate(
        (widget) => widget is TextField && widget.key == null,
  );
  expect(campos, findsNWidgets(2));

  await tester.enterText(campos.at(0), hora.toString().padLeft(2, '0'));
  await tester.enterText(campos.at(1), minuto.toString().padLeft(2, '0'));
  await tester.pumpAndSettle();

  final confirmarButton = find.text('OK');
  expect(confirmarButton, findsOneWidget);
  await tester.tap(confirmarButton);
  await tester.pumpAndSettle();
}


void main(){
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Gestión de citas', (){
    testWidgets('Login como jefe y creación de cita disponible', (WidgetTester tester) async{
      // Tamaño de pantalla grande
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // Inicio de la app
      app.main();
      await tester.pump();
      await Future.delayed(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // Login usuario jefe
     final tlfnField =  find.byKey(const Key('telefono'));
      final passwordField =  find.byKey(const Key('contrasena'));
      final enviarButton = find.byKey(const Key('enviar'));

      expect(tlfnField, findsOneWidget);

      await tester.enterText(tlfnField, '111222331');
      await tester.enterText(passwordField, 'test1234');
      await tester.tap(enviarButton);
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      
      // debe de estar en pagina mis tarea
      expect(find.byType(TareasPage), findsOneWidget);

      // va a pagina gestion de citas
      final botonMenu = find.byIcon(Icons.menu);
      expect(botonMenu, findsOneWidget);
      await tester.tap(botonMenu);
      await tester.pumpAndSettle();

      final gestionCitas = find.byKey(const Key('gestionCitas'));
      expect(gestionCitas, findsOneWidget);
      await tester.tap(gestionCitas);
      await tester.pumpAndSettle();
      expect(find.byType(CreateCitaPage), findsOneWidget);

      // crea una nueva cita
      final plusCita = find.byKey(const Key('crearCita'));
      expect(plusCita, findsOneWidget);
      await tester.tap(plusCita);
      await tester.pumpAndSettle();

      // Escribir fecha
      final fecha = DateTime.now().add(const Duration(days:15));
      final showFecha = find.byKey(const Key('fechaController'));
      expect(showFecha, findsOneWidget);

      await tester.tap(showFecha);
      await tester.pumpAndSettle();

      // Se selecciona el mes
      final mesActual = DateTime.now().month;
      if (fecha.month != mesActual) {
        final siguienteMesButton = find.byIcon(Icons.chevron_right);
        await tester.tap(siguienteMesButton);
        await tester.pumpAndSettle();
      }

      // Se selecciona el dia
      await tester.tap(find.text(fecha.day.toString()).last);
      await tester.pumpAndSettle();

      final confirmarButton = find.text('OK');
      expect(confirmarButton, findsOneWidget);
      await tester.tap(confirmarButton);
      await tester.pumpAndSettle();


      // escribir hora de inicio
      await seleccionarHora(
        tester,
        campoKey: const Key('horaIni'),
        hora: 11,
        minuto: 0,
      );

      // escribir hora de fin
     await seleccionarHora(
        tester,
        campoKey: const Key('horaFin'),
        hora: 11,
        minuto: 30,
      );

      // guardar cita
      final guardarButton = find.byKey(const Key('guardarCita'));
      expect(guardarButton, findsOneWidget);
      await tester.tap(guardarButton);
      await tester.pumpAndSettle();

      // comporabar que esta la cita en el listado
        // 1 --> aparece el toastmanager
      expect(find.text('Cita creada correctamente'), findsOneWidget);

        // 2 --> aparece con el horario

      await tester.pumpAndSettle(const Duration(seconds: 2));

      final horarioEsperado = find.text('Horario: 11:00:00 a 11:30:00');
      expect(horarioEsperado, findsOneWidget);

      // 3 --> aparece con libre
      final itemCita = find.ancestor(
        of: horarioEsperado,
        matching: find.byType(Card),
      );
      expect(itemCita, findsOneWidget);

      expect(
        find.descendant(of: itemCita, matching: find.text('LIBRE')),
        findsOneWidget,
      );

      // Cierra sesion
      await tester.tap(botonMenu);
      await tester.pumpAndSettle();
      final cerrarSesion = find.byKey(const Key('cerrarSesion'));
      expect(cerrarSesion, findsOneWidget);
      await tester.tap(cerrarSesion);
      await tester.pumpAndSettle();
    });

    });

  group('Gestion de proyecto', (){
    testWidgets('Creacion de proyecto', (WidgetTester tester) async{
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // Inicio de la app
      app.main();
      await tester.pump();
      await Future.delayed(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // Login usuario cliente
      final tlfnField =  find.byKey(const Key('telefono'));
      final passwordField =  find.byKey(const Key('contrasena'));
      final enviarButton = find.byKey(const Key('enviar'));

      expect(tlfnField, findsOneWidget);

      await tester.enterText(tlfnField, '111222332');
      await tester.enterText(passwordField, 'test1234');
      await tester.tap(enviarButton);
      await tester.pumpAndSettle(const Duration(seconds: 4));


      // debe de estar en pagina home
      expect(find.byType(HomePageClient), findsOneWidget);

      // va a pagina crear presupeustos
      final botonGestion = find.byIcon(Icons.shopping_bag_outlined);
      expect(botonGestion, findsOneWidget);
      await tester.tap(botonGestion);
      await tester.pumpAndSettle();

      final crearPresupuesto = find.byKey(const Key('crearPresupuesto'));
      expect(crearPresupuesto, findsOneWidget);
      await tester.tap(crearPresupuesto);
      await tester.pumpAndSettle();
      expect(find.byType(CreatePresupuestoPage), findsOneWidget);

      // añadir producto Ventana Test al presupuesto
      final dropdownProducto = find.byType(DropdownButtonFormField<int>).first;
      expect(dropdownProducto, findsOneWidget);
      await tester.tap(dropdownProducto);
      await tester.pumpAndSettle();

      final opcionProducto = find.textContaining('Ventana Test');
      expect(opcionProducto, findsWidgets);
      await tester.tap(opcionProducto.last);
      await tester.pumpAndSettle();

      final opcionBlanco = find.widgetWithText(OutlinedButton, 'Blanco');
      expect(opcionBlanco, findsOneWidget);
      await tester.tap(opcionBlanco);
      await tester.pumpAndSettle();

      final campoAncho = find.byKey(Key('anchoField'));
      final campoAlto = find.byKey(Key('altoField'));
      await tester.enterText(campoAncho, '100');
      await tester.enterText(campoAlto, '150');
      await tester.pumpAndSettle();

      final botonAnadir = find.widgetWithText(ElevatedButton, 'Añadir al presupuesto');
      expect(botonAnadir, findsOneWidget);
      await tester.tap(botonAnadir);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Compruaba que aparezca el la venta con las medias introdiciodas.
      // Es decir que haya un producto en el presipuesto
      expect(find.text('Ventana Test'), findsOneWidget);
      expect(find.textContaining('Medidas : 100.00 x 150.00'), findsOneWidget);

      expect(find.text('No hay productos añadidos al presupuesto.'), findsNothing);

      // pagina ir confirmacion presupuesto
      final botonConfirmar = find.byKey(Key('botonConfirmar'));
      expect(botonConfirmar, findsOneWidget);
      await tester.tap(botonConfirmar);
      await tester.pumpAndSettle();

      expect(find.byType(ConfirmacionPresupuestoPage), findsOneWidget);

      // incluir dierccion `numero
      final campoDireccion = find.byKey(Key('direccionField'));

      await tester.enterText(campoDireccion, 'Calle Julio Romero de Torres, Estepa');
      await tester.pump(const Duration(milliseconds: 1200));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final primeraSugerencia = find.byType(ListTile).first;
      expect(primeraSugerencia, findsOneWidget);
      await tester.tap(primeraSugerencia);
      await tester.pumpAndSettle();

      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Numero
      final numeroField = find.byKey(Key('numeroField'));
      await tester.enterText(numeroField, '19');
      await tester.pumpAndSettle();

      // selecionar metodo recogida
      final dropdownEntrega = find.byType(DropdownButton<String>);
      expect(dropdownEntrega, findsOneWidget);
      await tester.tap(dropdownEntrega);
      await tester.pumpAndSettle();

      final primeraOpcionEntrega = find.byType(DropdownMenuItem<String>).first;
      await tester.tap(find.text(
        (tester.widget<DropdownMenuItem<String>>(primeraOpcionEntrega).child as Text).data!,
      ).last);
      await tester.pumpAndSettle();

      //pagar en taller
      final botonPagar = find.byKey(Key('Pagar'));
      expect(botonPagar, findsOneWidget);
      await tester.tap(botonPagar);
      await tester.pumpAndSettle();

      if (find.text('Todos los campos deben estar rellenos').evaluate().isNotEmpty) {
        debugPrint('FALLO: _checkFields() devolvió false, revisar qué campo quedó vacío');
      }
      if (find.text('Confirmar Pedido').evaluate().isNotEmpty) {
        debugPrint('OK: el diálogo de pago se abrió correctamente');
      }

      final botonPagarTaller = find.byKey(Key('pagarTaller'));
      expect(botonPagarTaller, findsOneWidget);
      await tester.tap(botonPagarTaller);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.byType(VerProyectPage), findsOneWidget);

      // Cierra sesion
      final botonMenu = find.byIcon(Icons.perm_identity);
      expect(botonMenu, findsOneWidget);
      await tester.tap(botonMenu, warnIfMissed: false);
      await tester.pumpAndSettle();

      final cerrarSesion = find.byKey(const Key('cerrarSesion'));
      expect(cerrarSesion, findsOneWidget);
      await tester.tap(cerrarSesion);
      await tester.pumpAndSettle();
    });

    testWidgets('Avance del proyecto', (WidgetTester tester) async{
        tester.view.physicalSize = const Size(1920, 1080);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
        // Inicio de la app
        app.main();
        await tester.pump();
        await Future.delayed(const Duration(seconds: 3));
        await tester.pumpAndSettle();

        // Login usuario jefe
        final tlfnField =  find.byKey(const Key('telefono'));
        final passwordField =  find.byKey(const Key('contrasena'));
        final enviarButton = find.byKey(const Key('enviar'));

        expect(tlfnField, findsOneWidget);

        await tester.enterText(tlfnField, '111222331');
        await tester.enterText(passwordField, 'test1234');
        await tester.tap(enviarButton);
        await tester.pumpAndSettle(const Duration(seconds: 2));


        // debe de estar en pagina mis tarea
        expect(find.byType(TareasPage), findsOneWidget);

        final botonMenu = find.byIcon(Icons.menu);
        expect(botonMenu, findsOneWidget);

        // Ir pantalla todos proyectos
        await tester.tap(botonMenu);
        await tester.pumpAndSettle();
        final proyectosBoton = find.byKey(const Key('proyectos'));
        expect(proyectosBoton, findsOneWidget);
        await tester.tap(proyectosBoton);
        await tester.pumpAndSettle();

        expect(find.byType(GestionProyectosPage), findsOneWidget);

        // buscar proyecto de cliente test en calle Test 1 estado REVISION
        final direccionProyecto = find.text('Dirección: Calle Test 1');
        expect(direccionProyecto, findsOneWidget);

        final cardProyecto = find.ancestor(
          of: direccionProyecto,
          matching: find.byType(Card),
        );
        expect(cardProyecto, findsOneWidget);

        expect(
          find.descendant(of: cardProyecto, matching: find.textContaining('cliente')),
          findsOneWidget,
        );

        // pulsar en revisar
        final botonEditar = find.descendant(
          of: cardProyecto,
          matching: find.byIcon(Icons.edit_outlined),
        );
        expect(botonEditar, findsOneWidget);
        await tester.tap(botonEditar);
        await tester.pumpAndSettle();

        expect(find.byType(ModificationProyectPage), findsOneWidget);

        // aceptar revisión
        final confirmacion = find.byKey(const Key('confirmarBoton'));
        expect(confirmacion, findsOneWidget);
        await tester.tap(confirmacion);
        await tester.pumpAndSettle();

        final dialogoConfirmacion = find.byType(AlertDialog);
        expect(dialogoConfirmacion, findsOneWidget);

        final botonConfirmarDialogo = find.descendant(
          of: dialogoConfirmacion,
          matching: find.widgetWithText(ElevatedButton, 'Confirmar'),
        );
        expect(botonConfirmarDialogo, findsOneWidget);
        await tester.tap(botonConfirmarDialogo);
        await tester.pumpAndSettle(const Duration(seconds: 4));

        // pedir materiales
        final pedirMateriales = find.byKey(const Key('materialesPedidos'));
        expect(pedirMateriales, findsOneWidget);
        await tester.tap(pedirMateriales);
        await tester.pumpAndSettle(const Duration(seconds: 4));

        // recibir materiales

        final recibirMateriales = find.byKey(const Key('materialesRecibidos'));
        expect(recibirMateriales, findsOneWidget);
        await tester.tap(recibirMateriales);
        await tester.pumpAndSettle(const Duration(seconds: 4));

        // comprobar en estado de produccion

        await tester.tap(botonMenu);
        await tester.pumpAndSettle();
        await tester.tap(proyectosBoton);
        await tester.pumpAndSettle();
        expect(find.byType(GestionProyectosPage), findsOneWidget);

        final cardProyecto2 = find.ancestor(
          of: direccionProyecto,
          matching: find.byType(Card),
        );
        expect(cardProyecto2, findsOneWidget);

        expect(
          find.descendant(of: cardProyecto2, matching: find.textContaining('cliente')),
          findsOneWidget,
        );

        expect(
          find.descendant(of: cardProyecto2, matching: find.textContaining('En Producción')),
          findsOneWidget,
        );

        // Cierra sesion
        await tester.tap(botonMenu);
        await tester.pumpAndSettle();
        final cerrarSesion = find.byKey(const Key('cerrarSesion'));
        expect(cerrarSesion, findsOneWidget);
        await tester.tap(cerrarSesion);
        await tester.pumpAndSettle();
    });

    testWidgets('Cancelacion de proyecto', (WidgetTester tester) async{
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // Inicio de la app
      app.main();
      await tester.pump();
      await Future.delayed(const Duration(seconds: 3));
      await tester.pumpAndSettle();//await tester.idle();

      // Login usuario cliente
      final tlfnField =  find.byKey(const Key('telefono'));
      final passwordField =  find.byKey(const Key('contrasena'));
      final enviarButton = find.byKey(const Key('enviar'));

      expect(tlfnField, findsOneWidget);

      await tester.enterText(tlfnField, '111222332');
      await tester.enterText(passwordField, 'test1234');
      await tester.tap(enviarButton);
      await tester.pumpAndSettle(const Duration(seconds: 4));


      // debe de estar en pagina home
      expect(find.byType(HomePageClient), findsOneWidget);

      // va a pagina gestion de presupuestos
      final botonGestion = find.byIcon(Icons.shopping_bag_outlined);
      expect(botonGestion, findsOneWidget);
      await tester.tap(botonGestion);
      await tester.pumpAndSettle();

      final listadoPresupuesto = find.byKey(const Key('listadoPresupuesto'));
      expect(listadoPresupuesto, findsOneWidget);
      await tester.tap(listadoPresupuesto);
      await tester.pumpAndSettle();
      expect(find.byType(GestionPresupuestosPage), findsOneWidget);

      // numero de presupuestos que hay
      final tarjetasAntes = find.textContaining('Presupuesto ');
      final numeroPresupuestos = tarjetasAntes.evaluate().length;
      debugPrint('Presupuestos antes de borrar: $numeroPresupuestos');
      expect(numeroPresupuestos, greaterThan(0)); // por si acaso está vacío, el test debe fallar aquí, no más adelante

      // cancelar el primero que se encuentre
      final botonBorrarPrimero = find.byIcon(Icons.delete_outline_outlined).first;
      await tester.ensureVisible(botonBorrarPrimero);
      await tester.tap(botonBorrarPrimero);
      await tester.pumpAndSettle();

      final botonConfirmarBorrado = find.byKey(Key('confirmar'));
      expect(botonConfirmarBorrado, findsOneWidget);
      await tester.tap(botonConfirmarBorrado);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // comprobar que en el listaod aparecce uno menos

      final tarjetasDespues = find.textContaining('Presupuesto ');
      final numeroDespues = tarjetasDespues.evaluate().length;
      debugPrint('Presupuestos después de borrar: $numeroDespues');
      expect(numeroDespues, equals(numeroPresupuestos - 1));

      // ir a mis priyectos
      await tester.ensureVisible(botonGestion);
      await tester.pumpAndSettle();

      await tester.tap(botonGestion);
      await tester.pumpAndSettle();

      final listadoProyecto = find.byKey(const Key('listadoProyectos'));
      expect(listadoProyecto, findsOneWidget);
      await tester.tap(listadoProyecto);
      await tester.pumpAndSettle();
      expect(find.byType(ListadoProyectosPage), findsOneWidget);

      // buscar el de estado produccion
      final direccionProyecto = find.text('Dirección: Calle Test 1');
      final cardProyecto = find.ancestor(
        of: direccionProyecto,
        matching: find.byType(Card),
      );
      expect(cardProyecto, findsOneWidget);


      expect(
        find.descendant(of: cardProyecto, matching: find.textContaining('En Producción')),
        findsOneWidget,
      );

      // cancelarlo no se ve.
      expect(
        find.descendant(of: cardProyecto, matching: find.widgetWithText(ElevatedButton, 'Cancelar')),
        findsNothing,
      );

      // Cierra sesion
      final botonMenu = find.byIcon(Icons.perm_identity);
      expect(botonMenu, findsOneWidget);
      await tester.ensureVisible(botonMenu);
      await tester.pumpAndSettle();

      await tester.tap(botonMenu);
      await tester.pumpAndSettle();

      final cerrarSesion = find.byKey(const Key('cerrarSesion'));
      expect(cerrarSesion, findsOneWidget);
      await tester.tap(cerrarSesion);
      await tester.pumpAndSettle();
    });

  });

  group('Tareas', (){
    testWidgets('Desbloqueo de una tarea', (WidgetTester tester) async{
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // Inicio de la app
      app.main();
      await tester.pump();
      await Future.delayed(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // Login usuario jefe
      final tlfnField =  find.byKey(const Key('telefono'));
      final passwordField =  find.byKey(const Key('contrasena'));
      final enviarButton = find.byKey(const Key('enviar'));

      expect(tlfnField, findsOneWidget);

      await tester.enterText(tlfnField, '111222331');
      await tester.enterText(passwordField, 'test1234');
      await tester.tap(enviarButton);
      await tester.pumpAndSettle(const Duration(seconds: 4));


      // debe de estar en pagina mis tarea
      expect(find.byType(TareasPage), findsOneWidget);

      // identificar tarea desbloqueada
      // comporbar que la siguiente tarea esta bloqueada

      final todasTarjetasMontaje = find.ancestor(
        of: find.text('TAREA DE MONTAR PROYECTO'),
        matching: find.byType(Container),
      );
      expect(todasTarjetasMontaje, findsNWidgets(2));

      Finder? tarjetaDesbloqueada;
      Finder? tarjetaBloqueada;

      for (var i = 0; i < todasTarjetasMontaje.evaluate().length; i++) {
        final tarjeta = todasTarjetasMontaje.at(i);
        final tieneBadge = find.descendant(of: tarjeta, matching: find.text('BLOQUEADA')).evaluate().isNotEmpty;
        if (tieneBadge) {
          tarjetaBloqueada = tarjeta;
        } else {
          tarjetaDesbloqueada = tarjeta;
        }
      }


      expect(tarjetaDesbloqueada, isNotNull);
      expect(tarjetaBloqueada, isNotNull);

      // iniciar tarea
      final botonIniciar = find.descendant(
        of: tarjetaDesbloqueada!,
        matching: find.widgetWithText(ElevatedButton, 'Iniciar tarea'),
      );
      expect(botonIniciar, findsOneWidget);
      await tester.ensureVisible(botonIniciar);
      await tester.tap(botonIniciar);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // teminar tarea
      final tarjetaActualizada = find.ancestor(
        of: find.text('TAREA DE MONTAR PROYECTO'),
        matching: find.byType(Container),
      ).first;

      final botonTerminar = find.descendant(
        of: tarjetaActualizada,
        matching: find.widgetWithText(ElevatedButton, 'Terminar tarea'),
      );
      expect(botonTerminar, findsOneWidget);

      await tester.ensureVisible(botonTerminar);
      await tester.tap(botonTerminar);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // comprbar que la siguiente se ha desbloqueado
      final tarjetaDespues = find.ancestor(
        of: find.text('TAREA DE MONTAR PROYECTO'), // ajusta al texto real de tarea.tipo.text
        matching: find.byType(Container),
      );
      expect(tarjetaDespues, findsOneWidget);

      expect(
        find.descendant(of: tarjetaDespues, matching: find.text('BLOQUEADA')),
        findsNothing,
      );
      expect(
        find.descendant(of: tarjetaDespues, matching: find.widgetWithText(ElevatedButton, 'Iniciar tarea')),
        findsOneWidget,
      );

      // Cierra sesion
      final botonMenu = find.byIcon(Icons.menu);
      expect(botonMenu, findsOneWidget);

      await tester.tap(botonMenu);
      await tester.pumpAndSettle();
      final cerrarSesion = find.byKey(const Key('cerrarSesion'));
      expect(cerrarSesion, findsOneWidget);
      await tester.tap(cerrarSesion);
      await tester.pumpAndSettle();
    });

  });
}