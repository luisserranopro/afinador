import 'dart:math';
import 'dart:typed_data';

import 'package:afinador/audio/notas.dart';
import 'package:afinador/audio/yin.dart';
import 'package:flutter_test/flutter_test.dart';

/// Señal parecida a una cuerda pulsada: fundamental, armónicos y algo de ruido.
Float64List cuerda(double f, {List<double> armonicos = const [1, 0.6, 0.35, 0.25, 0.15, 0.1], double ruido = 0.02}) {
  final azar = Random(f.round());
  const sr = 44100.0;
  final x = Float64List(4096);
  for (var i = 0; i < x.length; i++) {
    var v = 0.0;
    for (var k = 0; k < armonicos.length; k++) {
      v += armonicos[k] * sin(2 * pi * f * (k + 1) * i / sr);
    }
    // Ruido aproximadamente normal
    var n = 0.0;
    for (var j = 0; j < 6; j++) {
      n += azar.nextDouble();
    }
    x[i] = 0.4 * v + ruido * (n - 3) / sqrt(0.5);
  }
  return x;
}

double centsEntre(double a, double b) => 1200 * log(a / b) / ln2;

void main() {
  const detector = DetectorTono();

  group('Detección de tono (YIN)', () {
    test('acierta las cuerdas de guitarra y ukelele con error menor de 2 cents', () {
      for (final f in [82.41, 110.0, 146.83, 196.0, 246.94, 329.63, 261.63, 392.0, 440.0, 659.25, 1046.5]) {
        final tono = detector.detectar(cuerda(f));
        expect(tono, isNotNull, reason: '$f Hz');
        expect(centsEntre(tono!.frecuencia, f).abs(), lessThan(2), reason: '$f Hz → ${tono.frecuencia}');
      }
    });

    test('no se equivoca de octava aunque el segundo armónico suene más', () {
      for (final f in [82.41, 110.0, 196.0]) {
        final tono = detector.detectar(cuerda(f, armonicos: const [0.15, 1, 0.8, 0.5, 0.3], ruido: 0.03));
        expect(centsEntre(tono!.frecuencia, f).abs(), lessThan(5), reason: '$f Hz');
      }
    });

    test('con silencio no devuelve nada', () {
      final azar = Random(1);
      final silencio = Float64List.fromList(List.generate(4096, (_) => (azar.nextDouble() - 0.5) * 0.004));
      expect(detector.detectar(silencio), isNull);
    });

    test('las muestras necesarias caben en el búfer de 4096', () {
      expect(detector.muestrasNecesarias, lessThanOrEqualTo(4096));
    });
  });

  group('Notas', () {
    test('La4 es 440 Hz y el Mi grave de la guitarra 82,41 Hz', () {
      expect(frecuenciaDeMidi(69), closeTo(440, 1e-9));
      expect(frecuenciaDeMidi(40), closeTo(82.41, 0.01));
    });

    test('cents: 445 Hz está unos 20 cents alto respecto a La4', () {
      expect(centsRespecto(445, 69), closeTo(19.56, 0.01));
      expect(centsRespecto(440, 69), closeTo(0, 1e-9));
    });

    test('con La a 442 Hz cambia la referencia', () {
      expect(centsRespecto(442, 69, la4: 442), closeTo(0, 1e-9));
      expect(frecuenciaDeMidi(69, la4: 442), 442);
    });

    test('nombres en las dos notaciones', () {
      expect(nombreCompleto(69, latina: true), 'La4');
      expect(nombreCompleto(69, latina: false), 'A4');
      expect(nombreCompleto(40, latina: true), 'Mi2');
      expect(nombreCompleto(61, latina: false), 'C♯4');
    });

    test('cuerda más cercana de la guitarra', () {
      final estandar = afinaciones[Instrumento.guitarra]!.first.cuerdas;
      expect(cuerdaMasCercana(83, estandar), 0); // Mi grave
      expect(cuerdaMasCercana(150, estandar), 2); // Re
      expect(cuerdaMasCercana(330, estandar), 5); // Mi agudo
    });
  });
}
