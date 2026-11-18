import 'dart:async';
import 'dart:typed_data';

import 'package:record/record.dart';

import 'yin.dart';

/// Escucha el micrófono y llama a [alDetectar] con la frecuencia que suena
/// (o null si hay silencio) unas 20 veces por segundo.
///
/// El micrófono entrega trozos de audio PCM de 16 bits. Se guardan en un
/// búfer de las últimas 4096 muestras y, cada 2048 muestras nuevas (unos
/// 46 ms), se analiza el búfer con YIN.
class Microfono {
  static const muestrasPorSegundo = 44100;
  static const _tamanoBufer = 4096;
  static const _cadaCuantas = 2048;

  final void Function(double? frecuencia) alDetectar;
  final DetectorTono _detector = const DetectorTono(muestrasPorSegundo: 44100);
  final AudioRecorder _grabadora = AudioRecorder();
  final Float64List _bufer = Float64List(_tamanoBufer);
  int _nuevas = 0;
  StreamSubscription<Uint8List>? _suscripcion;
  Future<bool>? _iniciando; // arranque en curso (para no arrancar dos veces)
  Future<void>? _parando;
  int? _byteSuelto; // byte que sobró del trozo anterior (si llegó impar)
  bool _cerrado = false;

  Microfono({required this.alDetectar});

  bool get escuchando => _suscripcion != null;

  /// Pide permiso y empieza a escuchar. Devuelve false si no hay permiso.
  /// Si ya se está arrancando, devuelve ese mismo arranque.
  Future<bool> iniciar() => _iniciando ??= _iniciar().whenComplete(() => _iniciando = null);

  Future<bool> _iniciar() async {
    await _parando; // si se estaba parando, esperar a que acabe
    if (_cerrado) return false;
    if (escuchando) return true;
    if (!await _grabadora.hasPermission()) return false;
    if (_cerrado) return false;
    final datos = await _grabadora.startStream(const RecordConfig(
      encoder: AudioEncoder.pcm16bits,
      sampleRate: muestrasPorSegundo,
      numChannels: 1,
      // Sin filtros del sistema: alteran el sonido de la cuerda
      autoGain: false,
      echoCancel: false,
      noiseSuppress: false,
    ));
    if (_cerrado) {
      await _grabadora.stop();
      return false;
    }
    _byteSuelto = null;
    _suscripcion = datos.listen(
      _recibir,
      onError: (Object _) => parar(),
      onDone: () => _suscripcion = null,
      cancelOnError: true,
    );
    return true;
  }

  void _recibir(Uint8List trozo) {
    if (_cerrado) return;
    // Si el trozo anterior acabó en medio de una muestra, se completa ahora
    var bytes = trozo;
    final suelto = _byteSuelto;
    if (suelto != null) {
      bytes = Uint8List(trozo.length + 1)
        ..[0] = suelto
        ..setRange(1, trozo.length + 1, trozo);
      _byteSuelto = null;
    }
    if (bytes.length.isOdd) _byteSuelto = bytes.last;

    final datos = ByteData.sublistView(bytes);
    final n = bytes.length ~/ 2;
    if (n == 0) return;

    if (n >= _tamanoBufer) {
      // Trozo muy grande: nos quedamos con el final
      for (var i = 0; i < _tamanoBufer; i++) {
        _bufer[i] = datos.getInt16((n - _tamanoBufer + i) * 2, Endian.little) / 32768;
      }
    } else {
      // Desplazar lo que había y añadir lo nuevo al final
      _bufer.setRange(0, _tamanoBufer - n, _bufer, n);
      for (var i = 0; i < n; i++) {
        _bufer[_tamanoBufer - n + i] = datos.getInt16(i * 2, Endian.little) / 32768;
      }
    }

    _nuevas += n;
    if (_nuevas >= _cadaCuantas) {
      _nuevas = 0;
      alDetectar(_detector.detectar(_bufer)?.frecuencia);
    }
  }

  /// Deja de escuchar (y espera a que termine un arranque en curso).
  Future<void> parar() => _parando ??= _parar().whenComplete(() => _parando = null);

  Future<void> _parar() async {
    await _iniciando;
    final s = _suscripcion;
    _suscripcion = null;
    await s?.cancel();
    try {
      if (await _grabadora.isRecording()) await _grabadora.stop();
    } catch (_) {}
  }

  Future<void> dispose() async {
    _cerrado = true;
    await parar();
    await _grabadora.dispose();
  }
}
