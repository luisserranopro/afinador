import 'dart:math';
import 'dart:typed_data';

/// Resultado de analizar un trozo de sonido.
class Tono {
  final double frecuencia; // Hz
  final double claridad; // 0 (ruido) a 1 (tono muy limpio)

  const Tono(this.frecuencia, this.claridad);
}

/// Detecta la frecuencia fundamental de un sonido con el algoritmo YIN
/// (de Cheveigné y Kawahara, 2002).
///
/// La idea: un sonido afinado se repite cada "periodo". Se compara la señal
/// consigo misma desplazada τ muestras; cuando τ coincide con el periodo, la
/// diferencia es casi cero. La frecuencia es entonces muestrasPorSegundo / τ.
///
/// Pasos:
/// 1. Diferencia d(τ) = Σ (x[i] − x[i+τ])².
/// 2. Se normaliza (d'(τ) = d(τ)·τ / Σd) para no confundir el periodo con τ=0.
/// 3. Se elige el primer τ cuyo valor baja de un umbral (evita errores de
///    octava: el doble del periodo también da un mínimo, pero llega después).
/// 4. Interpolación parabólica para afinar τ entre dos muestras.
class DetectorTono {
  final double muestrasPorSegundo;
  final double frecuenciaMinima;
  final double frecuenciaMaxima;
  final double umbral;

  /// Muestras que se comparan en cada desplazamiento.
  final int ventana;

  /// Por debajo de este volumen (RMS) se considera silencio.
  final double volumenMinimo;

  const DetectorTono({
    this.muestrasPorSegundo = 44100,
    this.frecuenciaMinima = 60,
    this.frecuenciaMaxima = 1500,
    this.umbral = 0.12,
    this.ventana = 2048,
    this.volumenMinimo = 0.01,
  });

  /// Muestras que hacen falta: la ventana más el periodo más largo.
  int get muestrasNecesarias => ventana + (muestrasPorSegundo / frecuenciaMinima).ceil() + 2;

  /// Devuelve el tono de [x] (valores entre −1 y 1) o null si es silencio o
  /// ruido sin un tono claro.
  Tono? detectar(Float64List x) {
    final tauMin = max(2, (muestrasPorSegundo / frecuenciaMaxima).floor());
    final tauMax = min((muestrasPorSegundo / frecuenciaMinima).ceil(), x.length - ventana - 2);
    if (tauMax <= tauMin + 2) return null;

    // Volumen: si casi no hay sonido, no se intenta
    var energia = 0.0;
    for (var i = 0; i < x.length; i++) {
      energia += x[i] * x[i];
    }
    if (sqrt(energia / x.length) < volumenMinimo) return null;

    // 1 y 2: diferencia normalizada acumulada
    final cmnd = Float64List(tauMax + 2);
    cmnd[0] = 1;
    var acumulado = 0.0;
    for (var tau = 1; tau <= tauMax + 1; tau++) {
      var d = 0.0;
      for (var i = 0; i < ventana; i++) {
        final dif = x[i] - x[i + tau];
        d += dif * dif;
      }
      acumulado += d;
      cmnd[tau] = acumulado > 0 ? d * tau / acumulado : 1;
    }

    // 3: primer mínimo por debajo del umbral
    int? tau;
    for (var t = tauMin; t <= tauMax; t++) {
      if (cmnd[t] < umbral) {
        while (t + 1 <= tauMax && cmnd[t + 1] < cmnd[t]) {
          t++;
        }
        tau = t;
        break;
      }
    }
    if (tau == null) return null;

    // 4: interpolación parabólica entre tau-1, tau y tau+1
    final a = cmnd[tau - 1], b = cmnd[tau], c = cmnd[tau + 1];
    final denominador = a - 2 * b + c;
    final desplazamiento = denominador != 0 ? 0.5 * (a - c) / denominador : 0.0;
    final periodo = tau + desplazamiento;
    return Tono(muestrasPorSegundo / periodo, (1 - b).clamp(0.0, 1.0));
  }
}
