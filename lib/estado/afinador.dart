import 'package:flutter/foundation.dart';

import '../audio/notas.dart';

/// Lo que se muestra en pantalla en cada momento.
class Lectura {
  final double frecuencia;
  final int notaObjetivo; // MIDI de la nota (o cuerda) con la que se compara
  final double cents; // desviación: negativo, grave; positivo, agudo
  final int? cuerda; // índice de la cuerda (null en modo cromático)

  const Lectura(this.frecuencia, this.notaObjetivo, this.cents, this.cuerda);

  bool get afinada => cents.abs() <= Afinador.toleranciaCents;
}

/// Estado del afinador: instrumento, afinación, cuerda elegida, lectura
/// actual y cuerdas ya afinadas. No depende del micrófono: recibe las
/// frecuencias con [nuevaFrecuencia], y así se puede probar con tests.
class Afinador extends ChangeNotifier {
  /// Margen para dar una nota por afinada, en cents.
  static const toleranciaCents = 5.0;

  /// Tiempo que hay que mantenerse afinado para marcar la cuerda.
  static const tiempoParaMarcar = Duration(milliseconds: 500);

  /// Tras este tiempo sin sonido, se borra la lectura.
  static const tiempoSilencio = Duration(milliseconds: 1500);

  Instrumento _instrumento = Instrumento.guitarra;
  int _afinacion = 0;
  int? _cuerdaManual; // null: la cuerda se detecta sola
  double _la4 = 440;
  bool _notacionLatina = true;

  Lectura? _lectura;
  final Set<int> _afinadas = {};
  final List<double> _ultimas = [];
  Duration? _desdeEnTono;
  int? _cuerdaEnTono; // cuerda (o nota) a la que se refiere _desdeEnTono
  Duration? _ultimoSonido;

  Instrumento get instrumento => _instrumento;
  int get indiceAfinacion => _afinacion;
  int? get cuerdaManual => _cuerdaManual;
  double get la4 => _la4;
  bool get notacionLatina => _notacionLatina;
  Lectura? get lectura => _lectura;
  Set<int> get afinadas => Set.unmodifiable(_afinadas);

  bool get esCromatico => _instrumento == Instrumento.cromatico;

  /// Afinación elegida (null en modo cromático).
  Afinacion? get afinacion => esCromatico ? null : afinaciones[_instrumento]![_afinacion];

  List<int> get cuerdas => afinacion?.cuerdas ?? const [];

  bool get todasAfinadas => cuerdas.isNotEmpty && _afinadas.length == cuerdas.length;

  // ------------------------------------------------------------------ Ajustes

  void elegirInstrumento(Instrumento i) {
    if (i == _instrumento) return;
    _instrumento = i;
    _afinacion = 0;
    _reiniciar();
  }

  void elegirAfinacion(int indice) {
    _afinacion = indice;
    _reiniciar();
  }

  /// Elige una cuerda; si ya estaba elegida, vuelve a la detección automática.
  void elegirCuerda(int? indice) {
    _cuerdaManual = (indice == _cuerdaManual) ? null : indice;
    _lectura = null;
    _ultimas.clear();
    _desdeEnTono = null;
    notifyListeners();
  }

  void cambiarLa4(double hz) {
    _la4 = hz.clamp(430, 450).toDouble();
    _reiniciar();
  }

  void cambiarNotacion({required bool latina}) {
    _notacionLatina = latina;
    notifyListeners();
  }

  void _reiniciar() {
    _cuerdaManual = null;
    _lectura = null;
    _afinadas.clear();
    _ultimas.clear();
    _desdeEnTono = null;
    notifyListeners();
  }

  // ------------------------------------------------------------------ Lecturas

  /// Nueva frecuencia detectada ([frecuencia] null = silencio o ruido).
  /// [ahora] es el tiempo transcurrido (para medir cuánto dura afinada).
  void nuevaFrecuencia(double? frecuencia, Duration ahora) {
    if (frecuencia == null) {
      // Un silencio corta el tiempo que se lleva afinada
      _desdeEnTono = null;
      final ultimo = _ultimoSonido;
      if (_lectura != null && ultimo != null && ahora - ultimo > tiempoSilencio) {
        _lectura = null;
        _ultimas.clear();
        _desdeEnTono = null;
        notifyListeners();
      }
      return;
    }
    _ultimoSonido = ahora;

    // Mediana de las últimas lecturas: quita saltos sueltos (de octava, ruido)
    _ultimas.add(frecuencia);
    if (_ultimas.length > 5) _ultimas.removeAt(0);
    final ordenadas = [..._ultimas]..sort();
    final f = ordenadas[ordenadas.length ~/ 2];

    final int objetivo;
    int? cuerda;
    if (esCromatico) {
      objetivo = midiDeFrecuencia(f, la4: _la4).round();
    } else {
      cuerda = _cuerdaManual ?? cuerdaMasCercana(f, cuerdas, la4: _la4);
      objetivo = cuerdas[cuerda];
    }
    final lectura = Lectura(f, objetivo, centsRespecto(f, objetivo, la4: _la4), cuerda);

    // Una cuerda se marca como afinada tras mantenerse en tono un momento
    // (el tiempo cuenta solo mientras sea la misma cuerda o nota)
    final id = cuerda ?? objetivo;
    if (lectura.afinada && id == _cuerdaEnTono && _desdeEnTono != null) {
      if (cuerda != null && ahora - _desdeEnTono! >= tiempoParaMarcar) _afinadas.add(cuerda);
    } else if (lectura.afinada) {
      _desdeEnTono = ahora;
      _cuerdaEnTono = id;
    } else {
      _desdeEnTono = null;
    }

    _lectura = lectura;
    notifyListeners();
  }

  // ------------------------------------------------------------------ Textos

  String nombre(int midi) => nombreNota(midi, latina: _notacionLatina);
  String nombreConOctava(int midi) => nombreCompleto(midi, latina: _notacionLatina);
}
