import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aluminios/screen/login.dart';

void main() {


  testWidgets('Existen los campos', (WidgetTester tester) async {

    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: LoginPage(),
      ),
    );

    expect(find.byKey(const Key('telefono')), findsOneWidget);
    expect(find.byKey(const Key('contrasena')), findsOneWidget);

    final boton = find.byKey(const Key('enviar'));
    expect(boton, findsOneWidget);
    expect(
        tester.widget<ElevatedButton>(boton).onPressed,
        isNotNull
    );
  });

  testWidgets('Error si los campos están vacíos', (WidgetTester tester) async {

        // Para no dar error de overflow
        tester.view.physicalSize = const Size(1920, 1080);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          const MaterialApp(
            home: LoginPage(),
          ),
        );

        await tester.tap(find.byKey(const Key('enviar')));

        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(seconds: 3));


        final telefonoField = tester.widget<TextField>(
            find.byKey(const Key('telefono'))
        );
        expect(telefonoField.decoration?.errorText, isNotNull);

        final passwordField = tester.widget<TextField>(
            find.byKey(const Key('contrasena'))
        );
        expect(passwordField.decoration?.errorText, isNotNull);
      });

  testWidgets('Muestra error si solo el teléfono está vacío', (WidgetTester tester) async {

        tester.view.physicalSize = const Size(1920, 1080);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          const MaterialApp(
            home: LoginPage(),
          ),
        );

        await tester.enterText(find.byKey(const Key('contrasena')), 'test1234');
        await tester.tap(find.byKey(const Key('enviar')));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(seconds: 3));


        final telefonoField = tester.widget<TextField>(
            find.byKey(const Key('telefono'))
        );
        expect(telefonoField.decoration?.errorText, isNotNull);
      });

  testWidgets('Muestra error si solo la contraseña está vacía', (WidgetTester tester) async {

        tester.view.physicalSize = const Size(1920, 1080);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          const MaterialApp(
            home: LoginPage(),
          ),
        );

        await tester.enterText(find.byKey(const Key('telefono')), '600000001');
        await tester.tap(find.byKey(const Key('enviar')));

        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(seconds: 3));


        final passwordField = tester.widget<TextField>(
            find.byKey(const Key('contrasena'))
        );
        expect(passwordField.decoration?.errorText, isNotNull);
      });
}