// (Este archivo evita que `flutter create` genere el test de ejemplo del
// contador, que no compila con esta app.)
import 'package:afinador/i18n.dart';
import 'package:afinador/main.dart';
import 'package:afinador/widgets/aguja.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    Idioma.forzar('es');
    SharedPreferences.setMockInitialValues({});
  });
  tearDown(() => Idioma.forzar(null));

  testWidgets('pantalla principal sin micrófono: instrumentos y cuerdas', (tester) async {
    await tester.pumpWidget(const DiapasonApp(usarMicrofono: false));
    await tester.pumpAndSettle();
    expect(find.text('Guitarra'), findsOneWidget);
    expect(find.text('Ukelele'), findsOneWidget);
    expect(find.text('Cromático'), findsOneWidget);
    expect(find.text('Toca una cuerda'), findsOneWidget);
    // Las 6 cuerdas de la guitarra estándar
    expect(find.text('6ª'), findsOneWidget);
    expect(find.text('1ª'), findsOneWidget);
  });

  testWidgets('en modo cromático no hay cuerdas', (tester) async {
    await tester.pumpWidget(const DiapasonApp(usarMicrofono: false));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cromático'));
    await tester.pumpAndSettle();
    expect(find.text('6ª'), findsNothing);
    expect(find.text('Toca una nota'), findsOneWidget);
  });

  testWidgets('la aguja se dibuja con y sin sonido', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Column(children: [
          SizedBox(width: 300, child: Aguja(cents: null)),
          SizedBox(width: 300, child: Aguja(cents: 12)),
        ]),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.byType(Aguja), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });
}
