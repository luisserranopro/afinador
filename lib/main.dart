import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'i18n.dart';
import 'pantallas/afinador_pantalla.dart';
import 'widgets/aguja.dart';

void main() {
  runApp(const DiapasonApp());
}

class DiapasonApp extends StatelessWidget {
  final bool usarMicrofono;

  const DiapasonApp({super.key, this.usarMicrofono = true});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Diapasón',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: colorAfinado, brightness: Brightness.dark)
            .copyWith(primary: colorAfinado, onPrimary: colorFondo, surface: colorFondo),
        scaffoldBackgroundColor: colorFondo,
      ),
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [Locale('en'), Locale('es')],
      locale: Locale(Idioma.es ? 'es' : 'en'),
      home: AfinadorPantalla(usarMicrofono: usarMicrofono),
    );
  }
}
