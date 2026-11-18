import 'dart:math';

// Notas en números MIDI: el La central (La4, 440 Hz) es el 69 y cada
// semitono suma 1. Un "cent" es la centésima parte de un semitono.

const _nombresLatinos = ['Do', 'Do♯', 'Re', 'Re♯', 'Mi', 'Fa', 'Fa♯', 'Sol', 'Sol♯', 'La', 'La♯', 'Si'];
const _nombresIngleses = ['C', 'C♯', 'D', 'D♯', 'E', 'F', 'F♯', 'G', 'G♯', 'A', 'A♯', 'B'];

/// Frecuencia de la nota [midi] con el La4 afinado a [la4] Hz.
double frecuenciaDeMidi(num midi, {double la4 = 440}) => la4 * pow(2, (midi - 69) / 12).toDouble();

/// Nota (con decimales) que corresponde a [frecuencia].
double midiDeFrecuencia(double frecuencia, {double la4 = 440}) =>
    69 + 12 * log(frecuencia / la4) / ln2;

/// Diferencia en cents entre [frecuencia] y la nota [midi]. Positivo: alta.
double centsRespecto(double frecuencia, int midi, {double la4 = 440}) =>
    1200 * log(frecuencia / frecuenciaDeMidi(midi, la4: la4)) / ln2;

/// "La" o "A" según la notación.
String nombreNota(int midi, {required bool latina}) =>
    (latina ? _nombresLatinos : _nombresIngleses)[midi % 12];

/// Octava en notación científica: el La4 es el La de 440 Hz.
int octava(int midi) => midi ~/ 12 - 1;

/// "La4" / "A4"
String nombreCompleto(int midi, {required bool latina}) =>
    '${nombreNota(midi, latina: latina)}${octava(midi)}';

enum Instrumento { guitarra, ukelele, cromatico }

/// Una afinación: las notas de cada cuerda, de la más grave (o la de arriba
/// en el ukelele) a la más aguda.
class Afinacion {
  final String nombreEs;
  final String nombreEn;
  final List<int> cuerdas; // números MIDI

  const Afinacion(this.nombreEs, this.nombreEn, this.cuerdas);
}

const afinaciones = <Instrumento, List<Afinacion>>{
  Instrumento.guitarra: [
    Afinacion('Estándar', 'Standard', [40, 45, 50, 55, 59, 64]), // Mi La Re Sol Si Mi
    Afinacion('Drop D (Re)', 'Drop D', [38, 45, 50, 55, 59, 64]),
    Afinacion('Medio tono abajo', 'Half step down', [39, 44, 49, 54, 58, 63]),
    Afinacion('Un tono abajo', 'Full step down', [38, 43, 48, 53, 57, 62]),
    Afinacion('DADGAD', 'DADGAD', [38, 45, 50, 55, 57, 62]),
    Afinacion('Open G (Sol abierto)', 'Open G', [38, 43, 50, 55, 59, 62]),
  ],
  Instrumento.ukelele: [
    Afinacion('Estándar (Sol agudo)', 'Standard (high G)', [67, 60, 64, 69]), // Sol Do Mi La
    Afinacion('Sol grave', 'Low G', [55, 60, 64, 69]),
    Afinacion('Barítono', 'Baritone', [50, 55, 59, 64]),
  ],
  Instrumento.cromatico: [],
};

/// Índice de la cuerda de [cuerdas] más cercana a [frecuencia].
int cuerdaMasCercana(double frecuencia, List<int> cuerdas, {double la4 = 440}) {
  final m = midiDeFrecuencia(frecuencia, la4: la4);
  var mejor = 0;
  var menorDistancia = double.infinity;
  for (var i = 0; i < cuerdas.length; i++) {
    final d = (cuerdas[i] - m).abs();
    if (d < menorDistancia) {
      menorDistancia = d;
      mejor = i;
    }
  }
  return mejor;
}
