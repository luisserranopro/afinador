import 'package:afinador/audio/notas.dart';
import 'package:afinador/estado/afinador.dart';
import 'package:flutter_test/flutter_test.dart';

Duration ms(int n) => Duration(milliseconds: n);

void main() {
  test('detecta la cuerda sola y calcula los cents', () {
    final a = Afinador();
    a.nuevaFrecuencia(111.0, ms(0)); // La2 (110 Hz) un poco alto
    expect(a.lectura!.cuerda, 1);
    expect(a.lectura!.notaObjetivo, 45);
    expect(a.lectura!.cents, closeTo(15.7, 0.1));
    expect(a.lectura!.afinada, isFalse);
  });

  test('una cuerda se marca como afinada tras medio segundo en tono', () {
    final a = Afinador();
    a.nuevaFrecuencia(82.41, ms(0));
    expect(a.afinadas, isEmpty);
    a.nuevaFrecuencia(82.40, ms(300));
    expect(a.afinadas, isEmpty);
    a.nuevaFrecuencia(82.42, ms(600));
    expect(a.afinadas, {0});
  });

  test('salirse de tono reinicia la cuenta', () {
    final a = Afinador();
    a.nuevaFrecuencia(82.41, ms(0));
    for (var i = 1; i <= 5; i++) {
      a.nuevaFrecuencia(84.0, ms(i * 50)); // la mediana se va de tono
    }
    a.nuevaFrecuencia(82.41, ms(700));
    expect(a.afinadas, isEmpty);
  });

  test('con una cuerda elegida a mano, compara siempre con ella', () {
    final a = Afinador()..elegirCuerda(5); // Mi agudo
    a.nuevaFrecuencia(82.41, ms(0)); // suena el Mi grave
    expect(a.lectura!.cuerda, 5);
    expect(a.lectura!.cents, closeTo(-2400, 1)); // dos octavas por debajo
    a.elegirCuerda(5); // tocarla otra vez vuelve a automático
    expect(a.cuerdaManual, isNull);
  });

  test('modo cromático: la nota más cercana, sin cuerdas', () {
    final a = Afinador()..elegirInstrumento(Instrumento.cromatico);
    a.nuevaFrecuencia(466.16, ms(0)); // La♯4
    expect(a.lectura!.notaObjetivo, 70);
    expect(a.lectura!.cuerda, isNull);
    expect(a.nombreConOctava(70), 'La♯4');
  });

  test('ukelele estándar: la cuerda de Sol agudo', () {
    final a = Afinador()..elegirInstrumento(Instrumento.ukelele);
    a.nuevaFrecuencia(392.0, ms(0));
    expect(a.lectura!.cuerda, 0);
    expect(a.lectura!.notaObjetivo, 67);
  });

  test('cambiar el La de referencia cambia los cents', () {
    final a = Afinador()
      ..elegirInstrumento(Instrumento.cromatico)
      ..cambiarLa4(442);
    a.nuevaFrecuencia(440.0, ms(0));
    expect(a.lectura!.cents, closeTo(-7.85, 0.05));
  });

  test('la lectura se borra tras un rato de silencio', () {
    final a = Afinador();
    a.nuevaFrecuencia(110.0, ms(0));
    a.nuevaFrecuencia(null, ms(1000));
    expect(a.lectura, isNotNull);
    a.nuevaFrecuencia(null, ms(1600));
    expect(a.lectura, isNull);
  });

  test('la mediana ignora un salto suelto de octava', () {
    final a = Afinador();
    for (final f in [110.0, 110.1, 220.0, 110.0, 109.9]) {
      a.nuevaFrecuencia(f, ms(0));
    }
    expect(a.lectura!.frecuencia, closeTo(110, 0.2));
  });

  test('al pasar a otra cuerda hay que aguantar afinada otra vez', () {
    final a = Afinador();
    // 6ª (Mi2) afinada durante 600 ms: se marca
    for (var t = 0; t <= 600; t += 50) {
      a.nuevaFrecuencia(82.41, ms(t));
    }
    expect(a.afinadas, {0});
    // Se pasa a la 5ª (La2) afinada: no se marca en la primera lectura
    for (var t = 650; t <= 850; t += 50) {
      a.nuevaFrecuencia(110.0, ms(t));
    }
    expect(a.afinadas.contains(1), isFalse);
    for (var t = 900; t <= 1500; t += 50) {
      a.nuevaFrecuencia(110.0, ms(t));
    }
    expect(a.afinadas, {0, 1});
  });

  test('un silencio corta el tiempo afinada', () {
    final a = Afinador();
    a.nuevaFrecuencia(110.0, ms(0));
    a.nuevaFrecuencia(null, ms(300));
    a.nuevaFrecuencia(110.0, ms(600));
    expect(a.afinadas, isEmpty);
  });
}
