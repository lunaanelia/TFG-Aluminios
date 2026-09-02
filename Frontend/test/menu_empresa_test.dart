import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aluminios/widgets/menu_empresa.dart';
import 'package:aluminios/utils/tipos.dart';

void main() {

  Widget buildMenu({required UserType rol, required PageKind current}) {
    return MaterialApp(
      routes: {
        'misTareas/': (_) => const Scaffold(body: Text('Mis Tareas')),
        'todasTareas/': (_) => const Scaffold(body: Text('Todas Tareas')),
        'listadoProyectos/': (_) => const Scaffold(body: Text('Proyectos')),
        'gestionProductos/': (_) => const Scaffold(body: Text('Productos')),
        'gestionUsers/': (_) => const Scaffold(body: Text('Usuarios')),
        'crearCita/': (_) => const Scaffold(body: Text('Citas')),
        'configuracion/': (_) => const Scaffold(body: Text('Configuracion')),
        'createProduct/': (_) => const Scaffold(body: Text('Crear Producto')),
        'createUser/': (_) => const Scaffold(body: Text('Crear Usuario')),
        'listadoPresupuestos/': (_) => const Scaffold(body: Text('Mis Presupuestos')),
        'createPresupuesto/': (_) => const Scaffold(body: Text('Crear Presupuesto')),
        'misProyectos/': (_) => const Scaffold(body: Text('Mis Proyectos')),
        'editInformation/': (_) => const Scaffold(body: Text('Modificar Datos')),
      },
      home: Scaffold(
        drawer: MenuEmpresa(current: current, rol: rol),
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => Scaffold.of(context).openDrawer(),
            child: const Text('Abrir menú'),
          ),
        ),
      ),
    );
  }

  Future<void> abrirMenu(WidgetTester tester) async {
    await tester.tap(find.text('Abrir menú'));
    await tester.pumpAndSettle();
  }

    testWidgets('Menú trabajador muestra sus opciones', (WidgetTester tester) async {

        tester.view.physicalSize = const Size(1920, 1080);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(buildMenu(rol: UserType.trabajador, current: PageKind.mistareas));
        await abrirMenu(tester);

        expect(find.text('Mis tareas'), findsOneWidget);

        expect(find.text('Todas las tareas'), findsNothing);
        expect(find.text('Usuarios'), findsNothing);
        expect(find.text('Crear usuario'), findsNothing);
        expect(find.text('Configuracion'), findsNothing);
        expect(find.text('Proyectos'), findsNothing);
        expect(find.text('Productos'), findsNothing);
        expect(find.text('Crear producto'), findsNothing);
        expect(find.text('Gestión de citas'), findsNothing);
    });

  testWidgets('Menú administrativo muestra sus opciones', (WidgetTester tester) async {

        tester.view.physicalSize = const Size(1920, 1080);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
            buildMenu(rol: UserType.administrativo, current: PageKind.proyectos)
        );
        await abrirMenu(tester);

        expect(find.text('Proyectos'), findsOneWidget);
        expect(find.text('Productos'), findsOneWidget);
        expect(find.text('Crear producto'), findsOneWidget);

        expect(find.text('Todas las tareas'), findsNothing);
        expect(find.text('Mis tareas'), findsNothing);
        expect(find.text('Usuarios'), findsNothing);
        expect(find.text('Configuracion'), findsNothing);
        expect(find.text('Crear usuario'), findsNothing);
        expect(find.text('Gestión de citas'), findsNothing);

  });

  testWidgets('Menú jefe muestra todas las opciones', (WidgetTester tester) async {

        tester.view.physicalSize = const Size(1920, 1080);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
            buildMenu(rol: UserType.jefe, current: PageKind.mistareas)
        );
        await abrirMenu(tester);

        expect(find.text('Mis tareas'), findsOneWidget);
        expect(find.text('Todas las tareas'), findsOneWidget);
        expect(find.text('Proyectos'), findsOneWidget);
        expect(find.text('Productos'), findsOneWidget);
        expect(find.text('Usuarios'), findsOneWidget);
        expect(find.text('Crear producto'), findsOneWidget);
        expect(find.text('Crear usuario'), findsOneWidget);
        expect(find.text('Gestión de citas'), findsOneWidget);
        expect(find.text('Configuracion'), findsOneWidget);
      });

  testWidgets('Menú jefe navega a Todas las Tareas al pulsar', (WidgetTester tester) async {

        tester.view.physicalSize = const Size(1920, 1080);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
            buildMenu(rol: UserType.jefe, current: PageKind.mistareas)
        );
        await abrirMenu(tester);

        await tester.tap(find.text('Todas las tareas'));
        await tester.pumpAndSettle();

        expect(find.text('Todas Tareas'), findsOneWidget);
      });

  testWidgets('Página en la que te encuentras no se puede pulsar', (WidgetTester tester) async {

        tester.view.physicalSize = const Size(1920, 1080);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
            buildMenu(rol: UserType.jefe, current: PageKind.mistareas)
        );
        await abrirMenu(tester);

        final listTile = tester.widget<ListTile>(
            find.widgetWithText(ListTile, 'Mis tareas')
        );
        expect(listTile.onTap, isNull);
      });

  testWidgets('Páginas existen en todos los roles ', (WidgetTester tester) async {

        tester.view.physicalSize = const Size(1920, 1080);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        for (final rol in [UserType.trabajador, UserType.administrativo, UserType.jefe]) {
          await tester.pumpWidget(
              buildMenu(rol: rol, current: PageKind.mistareas)
          );
          await abrirMenu(tester);

          expect(find.text('Cerrar sesión'), findsOneWidget);
          expect(find.text('Modificar datos'), findsOneWidget);
          expect(find.text('Crear presupuesto'), findsOneWidget);
          expect(find.text('Mis presupuestos'), findsOneWidget);
          expect(find.text('Mis proyectos'), findsOneWidget);
        }
      });
}