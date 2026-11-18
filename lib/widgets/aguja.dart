import 'dart:math';

import 'package:flutter/material.dart';

const colorAfinado = Color(0xFF3DDC97);
const colorDesafinado = Color(0xFFFFB547);
const colorEscala = Color(0xFF7D8DA6);

/// Medidor de aguja de −50 a +50 cents. La aguja se mueve con suavidad.
/// [cents] null: sin sonido (la aguja descansa en el centro, apagada).
class Aguja extends StatelessWidget {
  final double? cents;

  const Aguja({super.key, required this.cents});

  @override
  Widget build(BuildContext context) {
    final valor = (cents ?? 0).clamp(-50.0, 50.0);
    return AspectRatio(
      aspectRatio: 2,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: valor),
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        builder: (context, v, _) => CustomPaint(
          painter: _PintorAguja(cents: v, activa: cents != null),
        ),
      ),
    );
  }
}

class _PintorAguja extends CustomPainter {
  final double cents;
  final bool activa;

  _PintorAguja({required this.cents, required this.activa});

  static const _anguloMax = 60 * pi / 180; // ±50 cents = ±60º

  @override
  void paint(Canvas canvas, Size s) {
    final centro = Offset(s.width / 2, s.height * 0.95);
    final radio = min(s.width / 2, s.height) * 0.9;

    Offset punto(double c, double r) {
      final a = -pi / 2 + (c / 50) * _anguloMax;
      return centro + Offset(cos(a) * r, sin(a) * r);
    }

    // Zona verde (±5 cents)
    final zona = Paint()
      ..color = colorAfinado.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radio * 0.12;
    final rect = Rect.fromCircle(center: centro, radius: radio * 0.86);
    final inicioZona = -pi / 2 - (5 / 50) * _anguloMax;
    canvas.drawArc(rect, inicioZona, (10 / 50) * _anguloMax, false, zona);

    // Marcas cada 5 cents (largas cada 10)
    final marca = Paint()
      ..color = colorEscala
      ..strokeCap = StrokeCap.round;
    for (var c = -50; c <= 50; c += 5) {
      final larga = c % 10 == 0;
      marca.strokeWidth = larga ? 2.5 : 1.5;
      if (c == 0) {
        marca
          ..color = colorAfinado
          ..strokeWidth = 4;
      } else {
        marca.color = colorEscala;
      }
      canvas.drawLine(punto(c.toDouble(), radio * (larga ? 0.72 : 0.78)), punto(c.toDouble(), radio * 0.92), marca);
    }

    // Etiquetas −50, −25, +25, +50
    for (final c in [-50, -25, 25, 50]) {
      final texto = TextPainter(
        text: TextSpan(
          text: c > 0 ? '+$c' : '$c',
          style: TextStyle(color: colorEscala, fontSize: radio * 0.075),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final p = punto(c.toDouble(), radio * 0.6);
      texto.paint(canvas, p - Offset(texto.width / 2, texto.height / 2));
      texto.dispose();
    }

    // Aguja
    final afinada = activa && cents.abs() <= 5;
    final color = !activa ? colorEscala.withValues(alpha: 0.5) : (afinada ? colorAfinado : colorDesafinado);
    canvas.drawLine(
      centro,
      punto(cents, radio * 0.95),
      Paint()
        ..color = color
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(centro, radio * 0.05, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_PintorAguja old) => old.cents != cents || old.activa != activa;
}
