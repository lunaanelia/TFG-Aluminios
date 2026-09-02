import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aluminios/screen/register.dart';

void main() {


  testWidgets('Existen los campos', (WidgetTester tester) async {

    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: RegisterPage(),
      ),
    );

    expect(find.byKey(const Key('nombre')), findsOneWidget);
    expect(find.byKey(const Key('apellidos')), findsOneWidget);
    expect(find.byKey(const Key('email')), findsOneWidget);
    expect(find.byKey(const Key('telefono')), findsOneWidget);
    expect(find.byKey(const Key('contrasena')), findsOneWidget);
    expect(find.byKey(const Key('confirmar')), findsOneWidget);

    final boton = find.byKey(const Key('crear'));
    expect(boton, findsOneWidget);
    expect(
        tester.widget<ElevatedButton>(boton).onPressed,
        isNotNull
    );


  });

  testWidgets('Error si los campos están vacíos', (WidgetTester tester) async {

    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: RegisterPage(),
      ),
    );

    await tester.tap(find.byKey(const Key('crear')));

    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(seconds: 3));


    final nombreField = tester.widget<TextField>(
        find.byKey(const Key('nombre'))
    );
    expect(nombreField.decoration?.errorText, isNotNull);

    final apellidoField = tester.widget<TextField>(
        find.byKey(const Key('apellidos'))
    );
    expect(apellidoField.decoration?.errorText, isNotNull);
    final emailField = tester.widget<TextField>(
        find.byKey(const Key('email'))
    );
    expect(emailField.decoration?.errorText, isNotNull);

   final telefonoField = tester.widget<TextField>(
        find.byKey(const Key('telefono'))
    );
    expect(telefonoField.decoration?.errorText, isNotNull);

    final passwordField = tester.widget<TextField>(
        find.byKey(const Key('contrasena'))
    );
    expect(passwordField.decoration?.errorText, isNotNull);
  });

  testWidgets('Muestra error si formato email no es correcto', (WidgetTester tester) async {

    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: RegisterPage(),
      ),
    );

    await tester.enterText(find.byKey(const Key('nombre')), 'test1234');
    await tester.enterText(find.byKey(const Key('apellidos')), 'test1234');
    await tester.enterText(find.byKey(const Key('telefono')), '111222333');
    await tester.enterText(find.byKey(const Key('email')), 'malformato');
    await tester.enterText(find.byKey(const Key('contrasena')), 'test1234');
    await tester.tap(find.byKey(const Key('crear')));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(seconds: 3));


    final emailField = tester.widget<TextField>(
        find.byKey(const Key('email'))
    );
    expect(emailField.decoration?.errorText, isNotNull);
  });

  testWidgets('Muestra error si formato telefono no es correcto', (WidgetTester tester) async {

    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: RegisterPage(),
      ),
    );

    await tester.enterText(find.byKey(const Key('nombre')), 'test1234');
    await tester.enterText(find.byKey(const Key('apellidos')), 'test1234');
    await tester.enterText(find.byKey(const Key('telefono')), '11122233');
    await tester.enterText(find.byKey(const Key('email')), 'formato@gmail.com');
    await tester.enterText(find.byKey(const Key('contrasena')), 'test1234');
    await tester.tap(find.byKey(const Key('crear')));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(seconds: 3));


    final telefonoField = tester.widget<TextField>(
        find.byKey(const Key('telefono'))
    );
    expect(telefonoField.decoration?.errorText, isNotNull);
  });

}