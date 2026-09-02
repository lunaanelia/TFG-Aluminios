import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aluminios/widgets/header.dart';
import 'package:aluminios/screen/create_presupuesto.dart';
import 'package:aluminios/screen/listado_compras.dart';
import 'package:aluminios/screen/listado_proyectos.dart';

void main() {

  testWidgets('Header sin login muestra inicio sesión y registro', (WidgetTester tester) async {

    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home:Scaffold(
          body: Header(name: "", isLoged: false),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.perm_identity));
    await tester.pumpAndSettle();

    expect(find.text("Iniciar Sesión"), findsOneWidget);
    expect(find.text("Crear cuenta"), findsOneWidget);

    expect(find.text("Modificar Datos"), findsNothing);
    expect(find.text("Cerrar Sesión"), findsNothing);
  });

  testWidgets('Header con login muestra modificar datos y cerrar sesión', (WidgetTester tester) async {

    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home:Scaffold(
          body: Header(name: "nombre", isLoged: true),
        ),
      ),
    );

    expect(find.text('nombre'), findsOneWidget);


    await tester.tap(find.byIcon(Icons.perm_identity));
    await tester.pumpAndSettle();

    expect(find.text("Iniciar Sesión"), findsNothing);
    expect(find.text("Crear cuenta"), findsNothing);

    expect(find.text("Modificar Datos"), findsOneWidget);
    expect(find.text("Cerrar Sesión"), findsOneWidget);
  });

  testWidgets('Header muestra opciones presupuesto en menu cesta', (WidgetTester tester) async{
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        routes: {
          'createPresupuesto/': (context) => const CreatePresupuestoPage(),
          'listadoPresupuestos/': (context) => const GestionPresupuestosPage(),
          'misProyectos/': (context) => const ListadoProyectosPage(),
        },

        home:const Scaffold(
          body: Header(name: "nombre", isLoged: true),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.shopping_bag_outlined));
    await tester.pumpAndSettle();

    expect(find.text("Crear Presupuesto"), findsOneWidget);
    expect(find.text("Mis Presupuestos"), findsOneWidget);
    expect(find.text("Mis Proyectos"), findsOneWidget);
  });
}