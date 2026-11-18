import 'package:shared_preferences/shared_preferences.dart';

import '../audio/notas.dart';
import 'afinador.dart';

/// Guarda y recupera los ajustes del afinador en el dispositivo.
class Preferencias {
  /// [sigue] dice si la pantalla sigue abierta al terminar de leer.
  static Future<void> cargar(Afinador a, {bool Function()? sigue}) async {
    final p = await SharedPreferences.getInstance();
    if (sigue != null && !sigue()) return;
    final instrumento = p.getString('instrumento');
    final i = Instrumento.values.where((x) => x.name == instrumento).firstOrNull;
    if (i != null) a.elegirInstrumento(i);
    final afinacion = p.getInt('afinacion') ?? 0;
    if (afinacion > 0 && afinacion < (afinaciones[a.instrumento]?.length ?? 0)) {
      a.elegirAfinacion(afinacion);
    }
    final la4 = p.getDouble('la4');
    if (la4 != null) a.cambiarLa4(la4);
    final latina = p.getBool('notacionLatina');
    if (latina != null) a.cambiarNotacion(latina: latina);
  }

  static Future<void> guardar(Afinador a) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('instrumento', a.instrumento.name);
    await p.setInt('afinacion', a.indiceAfinacion);
    await p.setDouble('la4', a.la4);
    await p.setBool('notacionLatina', a.notacionLatina);
  }
}
