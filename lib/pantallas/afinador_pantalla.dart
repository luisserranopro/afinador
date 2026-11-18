import 'package:flutter/material.dart';

import '../audio/microfono.dart';
import '../audio/notas.dart';
import '../estado/afinador.dart';
import '../estado/preferencias.dart';
import '../i18n.dart';
import '../widgets/aguja.dart';

const colorFondo = Color(0xFF111827);
const colorTarjeta = Color(0xFF1F2937);
const colorTexto = Color(0xFFF3F4F6);
const colorSuave = Color(0xFF9CA3AF);

class AfinadorPantalla extends StatefulWidget {
  /// Para los tests: permite arrancar sin micrófono.
  final bool usarMicrofono;

  const AfinadorPantalla({super.key, this.usarMicrofono = true});

  @override
  State<AfinadorPantalla> createState() => _AfinadorPantallaState();
}

class _AfinadorPantallaState extends State<AfinadorPantalla> with WidgetsBindingObserver {
  final Afinador _afinador = Afinador();
  final Stopwatch _reloj = Stopwatch()..start();
  Microfono? _microfono;

  /// null: aún no se sabe; false: sin permiso.
  bool? _permiso;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _afinador.addListener(_alCambiar);
    Preferencias.cargar(_afinador, sigue: () => mounted);
    if (widget.usarMicrofono) {
      _microfono = Microfono(alDetectar: (f) => _afinador.nuevaFrecuencia(f, _reloj.elapsed));
      _empezar();
    }
  }

  void _alCambiar() {
    if (mounted) setState(() {});
  }

  Future<void> _empezar() async {
    final ok = await _microfono?.iniciar() ?? false;
    if (mounted) setState(() => _permiso = ok);
  }

  /// El micrófono se apaga al salir de la app y se vuelve a encender al volver.
  @override
  void didChangeAppLifecycleState(AppLifecycleState estado) {
    if (_microfono == null) return;
    if (estado == AppLifecycleState.resumed) {
      // Solo se reanuda si ya había permiso; si no, se pide con el botón
      // (así no se repite el diálogo del sistema en bucle).
      if (_permiso == true) _empezar();
    } else if (estado == AppLifecycleState.paused || estado == AppLifecycleState.hidden) {
      _microfono!.parar();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _afinador.removeListener(_alCambiar);
    _microfono?.dispose();
    _afinador.dispose();
    super.dispose();
  }

  void _cambiarAjuste(void Function() cambio) {
    cambio();
    Preferencias.guardar(_afinador);
  }

  void _ajustes() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: colorTarjeta,
      builder: (contexto) => StatefulBuilder(
        builder: (contexto, refrescar) {
          void cambiar(void Function() c) {
            _cambiarAjuste(c);
            refrescar(() {});
          }

          final la4 = _afinador.la4;
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(Tx.ajustes,
                      style: const TextStyle(color: colorTexto, fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 20),
                  Text(Tx.referencia, style: const TextStyle(color: colorTexto, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(Tx.referenciaAyuda, style: const TextStyle(color: colorSuave, fontSize: 13)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton.filledTonal(
                        tooltip: '−1 Hz',
                        onPressed: la4 <= 430 ? null : () => cambiar(() => _afinador.cambiarLa4(la4 - 1)),
                        icon: const Icon(Icons.remove_rounded),
                      ),
                      Expanded(
                        child: Text(
                          '${la4.toStringAsFixed(0)} Hz',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: colorTexto, fontSize: 24, fontWeight: FontWeight.w800),
                        ),
                      ),
                      IconButton.filledTonal(
                        tooltip: '+1 Hz',
                        onPressed: la4 >= 450 ? null : () => cambiar(() => _afinador.cambiarLa4(la4 + 1)),
                        icon: const Icon(Icons.add_rounded),
                      ),
                    ],
                  ),
                  if (la4 != 440)
                    Center(
                      child: TextButton(
                        onPressed: () => cambiar(() => _afinador.cambiarLa4(440)),
                        child: const Text('440 Hz'),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Text(Tx.notacion, style: const TextStyle(color: colorTexto, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<bool>(
                      segments: [
                        ButtonSegment(value: true, label: Text(Tx.latina)),
                        ButtonSegment(value: false, label: Text(Tx.inglesa)),
                      ],
                      selected: {_afinador.notacionLatina},
                      onSelectionChanged: (s) => cambiar(() => _afinador.cambiarNotacion(latina: s.first)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _acercaDe() {
    showAboutDialog(
      context: context,
      applicationName: 'Diapasón',
      applicationVersion: '1.0.0',
      applicationIcon: Image.asset('assets/images/logo.png', width: 56, height: 56),
      children: [Text(Tx.textoAcercaDe, style: const TextStyle(height: 1.5))],
    );
  }

  @override
  Widget build(BuildContext context) {
    final a = _afinador;
    return Scaffold(
      backgroundColor: colorFondo,
      appBar: AppBar(
        backgroundColor: colorFondo,
        foregroundColor: colorTexto,
        title: const Text('Diapasón', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(tooltip: Tx.ajustes, onPressed: _ajustes, icon: const Icon(Icons.tune_rounded)),
          IconButton(tooltip: Tx.acercaDe, onPressed: _acercaDe, icon: const Icon(Icons.info_outline_rounded)),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: SegmentedButton<Instrumento>(
                  showSelectedIcon: false,
                  segments: [
                    for (final i in Instrumento.values)
                      ButtonSegment(value: i, label: Text(Tx.instrumento(i))),
                  ],
                  selected: {a.instrumento},
                  onSelectionChanged: (s) => _cambiarAjuste(() => a.elegirInstrumento(s.first)),
                ),
              ),
            ),
            if (!a.esCromatico) _selectorAfinacion(a),
            Expanded(child: _permiso == false ? _sinPermiso() : _pantallaPrincipal(a)),
            if (!a.esCromatico) _Cuerdas(afinador: a),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _selectorAfinacion(Afinador a) {
    final lista = afinaciones[a.instrumento]!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: DropdownButtonFormField<int>(
        initialValue: a.indiceAfinacion,
        key: ValueKey(a.instrumento), // se reinicia al cambiar de instrumento
        isExpanded: true,
        dropdownColor: colorTarjeta,
        decoration: InputDecoration(
          filled: true,
          fillColor: colorTarjeta,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
        style: const TextStyle(color: colorTexto, fontSize: 15),
        items: [
          for (var i = 0; i < lista.length; i++)
            DropdownMenuItem(
              value: i,
              child: Text(
                '${Tx.afinacion(lista[i])} · ${lista[i].cuerdas.map(a.nombre).join(' ')}',
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
        onChanged: (i) {
          if (i != null) _cambiarAjuste(() => a.elegirAfinacion(i));
        },
      ),
    );
  }

  Widget _sinPermiso() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.mic_off_rounded, size: 56, color: colorSuave),
            const SizedBox(height: 16),
            Text(Tx.sinPermisoTitulo,
                style: const TextStyle(color: colorTexto, fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(Tx.sinPermisoTexto,
                textAlign: TextAlign.center, style: const TextStyle(color: colorSuave, height: 1.5)),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _empezar,
              icon: const Icon(Icons.mic_rounded),
              label: Text(Tx.darPermiso),
            ),
            const SizedBox(height: 12),
            Text(Tx.permisoAjustes,
                textAlign: TextAlign.center, style: const TextStyle(color: colorSuave, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _pantallaPrincipal(Afinador a) {
    final l = a.lectura;
    final afinada = l?.afinada ?? false;
    final color = l == null ? colorSuave : (afinada ? colorAfinado : colorDesafinado);

    final String pista;
    if (l == null) {
      pista = a.esCromatico ? Tx.tocaUnaNota : Tx.tocaUnaCuerda;
    } else if (afinada) {
      pista = Tx.afinada;
    } else if (a.esCromatico) {
      pista = l.cents < 0 ? Tx.grave : Tx.aguda;
    } else {
      pista = l.cents < 0 ? Tx.subeCuerda : Tx.bajaCuerda;
    }

    return LayoutBuilder(builder: (context, medidas) {
      final ancho = medidas.maxWidth.clamp(0.0, 460.0);
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Center(
          child: SizedBox(
            width: ancho,
            child: Column(
              children: [
                // Nota
                SizedBox(
                  height: 100,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        l == null ? '—' : a.nombre(l.notaObjetivo),
                        style: TextStyle(color: color, fontSize: 76, fontWeight: FontWeight.w900, height: 1),
                      ),
                      if (l != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 10),
                          child: Text(
                            '${octava(l.notaObjetivo)}',
                            style: TextStyle(color: color, fontSize: 28, fontWeight: FontWeight.w700),
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  l == null ? Tx.escuchando : '${l.frecuencia.toStringAsFixed(1)} Hz',
                  style: const TextStyle(color: colorSuave, fontSize: 15),
                ),
                const SizedBox(height: 16),
                Aguja(cents: l?.cents),
                const SizedBox(height: 4),
                Text(
                  l == null ? ' ' : '${l.cents >= 0 ? '+' : '−'}${l.cents.abs().toStringAsFixed(0)} cents',
                  style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    key: ValueKey(pista),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (afinada) const Icon(Icons.check_circle_rounded, color: colorAfinado, size: 20),
                        if (l != null && !afinada)
                          Icon(l.cents < 0 ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                              color: color, size: 20),
                        if (l != null) const SizedBox(width: 6),
                        Flexible(
                          child: Text(pista,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: color, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ),
                ),
                if (a.todasAfinadas)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      Tx.todoAfinado,
                      style: const TextStyle(color: colorAfinado, fontWeight: FontWeight.w800),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

/// Fila de cuerdas: se iluminan al detectarlas y se marcan cuando están
/// afinadas. Tocar una la fija; tocarla otra vez vuelve a automático.
class _Cuerdas extends StatelessWidget {
  final Afinador afinador;

  const _Cuerdas({required this.afinador});

  @override
  Widget build(BuildContext context) {
    final a = afinador;
    final cuerdas = a.cuerdas;
    final activa = a.cuerdaManual ?? a.lectura?.cuerda;
    final manual = a.cuerdaManual;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          Text(
            manual == null ? Tx.automatico : Tx.cuerdaElegida(a.nombre(cuerdas[manual])),
            textAlign: TextAlign.center,
            style: const TextStyle(color: colorSuave, fontSize: 12.5),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (var i = 0; i < cuerdas.length; i++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _BotonCuerda(
                      numero: cuerdas.length - i, // la más grave es la 6ª (o la 4ª)
                      nota: a.nombre(cuerdas[i]),
                      octava: octava(cuerdas[i]),
                      activa: activa == i,
                      fijada: manual == i,
                      afinada: a.afinadas.contains(i),
                      onTap: () => a.elegirCuerda(i),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BotonCuerda extends StatelessWidget {
  final int numero;
  final String nota;
  final int octava;
  final bool activa;
  final bool fijada;
  final bool afinada;
  final VoidCallback onTap;

  const _BotonCuerda({
    required this.numero,
    required this.nota,
    required this.octava,
    required this.activa,
    required this.fijada,
    required this.afinada,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borde = fijada ? colorDesafinado : (activa ? colorTexto : Colors.transparent);
    return Semantics(
      button: true,
      selected: fijada,
      label: '$nota$octava',
      child: Material(
        color: afinada ? colorAfinado.withValues(alpha: 0.18) : colorTarjeta,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 72,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borde, width: 2),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(Tx.cuerdaNumero(numero), style: const TextStyle(color: colorSuave, fontSize: 11)),
                FittedBox(
                  child: Text(
                    nota,
                    style: TextStyle(
                      color: afinada ? colorAfinado : colorTexto,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                afinada
                    ? const Icon(Icons.check_rounded, size: 14, color: colorAfinado)
                    : Text('$octava', style: const TextStyle(color: colorSuave, fontSize: 11)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
