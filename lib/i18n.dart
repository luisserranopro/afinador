import 'dart:ui';

import 'audio/notas.dart';

/// Idioma de la app: español si el dispositivo está en español; inglés si no.
class Idioma {
  static String? _forzado;

  static void forzar(String? codigo) => _forzado = codigo;

  static String get codigo => _forzado ?? PlatformDispatcher.instance.locale.languageCode;
  static bool get es => codigo == 'es';
}

class Tx {
  static String _t(String es, String en) => Idioma.es ? es : en;

  static String instrumento(Instrumento i) => switch (i) {
        Instrumento.guitarra => _t('Guitarra', 'Guitar'),
        Instrumento.ukelele => _t('Ukelele', 'Ukulele'),
        Instrumento.cromatico => _t('Cromático', 'Chromatic'),
      };
  static String afinacion(Afinacion a) => Idioma.es ? a.nombreEs : a.nombreEn;

  static String get tocaUnaCuerda => _t('Toca una cuerda', 'Play a string');
  static String get tocaUnaNota => _t('Toca una nota', 'Play a note');
  static String get escuchando => _t('Escuchando…', 'Listening…');
  static String get afinada => _t('¡Afinada!', 'In tune!');
  static String get subeCuerda => _t('Grave: tensa la cuerda', 'Flat: tighten the string');
  static String get bajaCuerda => _t('Aguda: destensa la cuerda', 'Sharp: loosen the string');
  static String get grave => _t('Grave', 'Flat');
  static String get aguda => _t('Aguda', 'Sharp');
  static String get automatico => _t('Automático: toca cualquier cuerda', 'Automatic: play any string');
  static String cuerdaElegida(String nota) =>
      _t('Afinando la cuerda $nota · toca otra vez para volver a automático',
          'Tuning the $nota string · tap again for automatic');
  static String get todoAfinado => _t('¡Todas las cuerdas afinadas!', 'All strings in tune!');
  static String cuerdaNumero(int n) => _t('$nª', '$n');

  static String get ajustes => _t('Ajustes', 'Settings');
  static String get referencia => _t('La de referencia', 'Reference pitch (A4)');
  static String get referenciaAyuda => _t(
      'Lo habitual es 440 Hz. Cámbialo para tocar con un piano u orquesta afinados a otra frecuencia.',
      'Usually 440 Hz. Change it to play along with a piano or orchestra tuned differently.');
  static String get notacion => _t('Nombres de las notas', 'Note names');
  static String get latina => 'Do Re Mi';
  static String get inglesa => 'C D E';

  static String get sinPermisoTitulo => _t('Necesito el micrófono', 'Microphone needed');
  static String get sinPermisoTexto => _t(
      'Para afinar, el afinador tiene que escuchar tu instrumento. El sonido no se graba ni sale del móvil.',
      'To tune, the app has to listen to your instrument. Nothing is recorded or leaves your phone.');
  static String get darPermiso => _t('Permitir el micrófono', 'Allow microphone');
  static String get permisoAjustes => _t(
      'Si lo denegaste antes, actívalo en los ajustes del sistema para esta app.',
      'If you denied it before, enable it for this app in your system settings.');

  static String get acercaDe => _t('Acerca de', 'About');
  static String get textoAcercaDe => _t(
      'Afinador para guitarra, ukelele y cromático. El sonido se analiza en el propio móvil: '
          'no se graba ni se envía a ningún sitio. Sin anuncios.',
      'Tuner for guitar, ukulele and chromatic tuning. Sound is analysed on your phone: '
          'nothing is recorded or sent anywhere. No ads.');
}
