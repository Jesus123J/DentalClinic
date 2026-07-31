import 'package:flutter/material.dart';

import '../../data/repositories/odontogram_repository.dart';
import '../../domain/entities/tooth_state.dart';

/// Dibuja una pieza dental con sus cinco caras, como el grafico del
/// odontograma oficial (NTS 150-MINSA-2019): un cuadrado dividido en
/// cuatro triangulos (vestibular, lingual, mesial, distal) y el centro
/// (oclusal/incisal). Cada cara se puede tocar por separado.
class ToothWidget extends StatelessWidget {
  const ToothWidget({
    super.key,
    required this.tooth,
    required this.states,
    required this.onTapSurface,
    this.size = 34,
    this.labelOnTop = true,
  });

  final String tooth;

  /// Hallazgos del paciente indexados por "pieza|cara".
  final Map<String, ToothState> states;

  final void Function(String tooth, ToothSurface surface) onTapSurface;
  final double size;

  /// Si el numero de pieza va arriba (arcada superior) o abajo.
  final bool labelOnTop;

  ToothState? _state(ToothSurface s) =>
      states[OdontogramRepository.key(tooth, s)];

  @override
  Widget build(BuildContext context) {
    final whole = _state(ToothSurface.completa);
    final label = Text(
      tooth,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );

    final drawing = SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          // Caras: cada triangulo/centro detecta su propio toque
          Positioned.fill(
            child: CustomPaint(
              painter: _ToothPainter(
                surfaces: {
                  for (final s in ToothSurface.values)
                    if (s != ToothSurface.completa)
                      s: _state(s)?.status ?? ToothStatus.sano,
                },
                whole: whole?.status,
                borderColor: Theme.of(context).dividerColor,
              ),
            ),
          ),
          Positioned.fill(
            child: _SurfaceHitArea(
              size: size,
              onTap: (surface) => onTapSurface(tooth, surface),
            ),
          ),
        ],
      ),
    );

    final tooltip = _buildTooltip();
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: labelOnTop
          ? [label, const SizedBox(height: 2), drawing]
          : [drawing, const SizedBox(height: 2), label],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: tooltip == null
          ? content
          : Tooltip(message: tooltip, child: content),
    );
  }

  String? _buildTooltip() {
    final lines = <String>[];
    final whole = _state(ToothSurface.completa);
    if (whole != null) {
      lines.add('Pieza completa: ${whole.status.label}'
          '${whole.note == null || whole.note!.isEmpty ? '' : ' - ${whole.note}'}');
    }
    for (final s in ToothSurface.values) {
      if (s == ToothSurface.completa) continue;
      final st = _state(s);
      if (st != null) {
        lines.add('${s.label}: ${st.status.label}'
            '${st.note == null || st.note!.isEmpty ? '' : ' - ${st.note}'}');
      }
    }
    if (lines.isEmpty) return null;
    return 'Pieza $tooth\n${lines.join('\n')}';
  }
}

/// Detecta que cara se toco segun la posicion dentro del cuadrado.
class _SurfaceHitArea extends StatelessWidget {
  const _SurfaceHitArea({required this.size, required this.onTap});

  final double size;
  final void Function(ToothSurface) onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (details) {
        final p = details.localPosition;
        final third = size / 3;
        // El centro (tercio medio) es la cara oclusal
        if (p.dx > third && p.dx < size - third &&
            p.dy > third && p.dy < size - third) {
          onTap(ToothSurface.oclusal);
          return;
        }
        // Fuera del centro: el triangulo se decide por las diagonales
        final aboveMainDiagonal = p.dy < p.dx;
        final aboveAntiDiagonal = p.dy < size - p.dx;
        if (aboveMainDiagonal && aboveAntiDiagonal) {
          onTap(ToothSurface.vestibular); // arriba
        } else if (!aboveMainDiagonal && !aboveAntiDiagonal) {
          onTap(ToothSurface.lingual); // abajo
        } else if (aboveMainDiagonal && !aboveAntiDiagonal) {
          onTap(ToothSurface.distal); // derecha
        } else {
          onTap(ToothSurface.mesial); // izquierda
        }
      },
      child: const SizedBox.expand(),
    );
  }
}

class _ToothPainter extends CustomPainter {
  _ToothPainter({
    required this.surfaces,
    required this.whole,
    required this.borderColor,
  });

  final Map<ToothSurface, ToothStatus> surfaces;
  final ToothStatus? whole;
  final Color borderColor;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final third = w / 3;
    final center = Rect.fromLTWH(third, third, third, third);

    Color fill(ToothSurface s) {
      final st = surfaces[s];
      return st == null || st == ToothStatus.sano
          ? Colors.transparent
          : st.color.withValues(alpha: 0.9);
    }

    void tri(List<Offset> pts, Color color) {
      if (color == Colors.transparent) return;
      final path = Path()..addPolygon(pts, true);
      canvas.drawPath(path, Paint()..color = color);
    }

    // Triangulos exteriores (recortando el centro con los vertices del cuadro)
    tri([
      Offset.zero, Offset(w, 0), center.topRight, center.topLeft,
    ], fill(ToothSurface.vestibular));
    tri([
      Offset(0, h), Offset(w, h), center.bottomRight, center.bottomLeft,
    ], fill(ToothSurface.lingual));
    tri([
      Offset.zero, Offset(0, h), center.bottomLeft, center.topLeft,
    ], fill(ToothSurface.mesial));
    tri([
      Offset(w, 0), Offset(w, h), center.bottomRight, center.topRight,
    ], fill(ToothSurface.distal));

    // Cara oclusal (centro)
    final oclusal = fill(ToothSurface.oclusal);
    if (oclusal != Colors.transparent) {
      canvas.drawRect(center, Paint()..color = oclusal);
    }

    // Lineas del dibujo
    final line = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), line);
    canvas.drawRect(center, line);
    canvas.drawLine(Offset.zero, center.topLeft, line);
    canvas.drawLine(Offset(w, 0), center.topRight, line);
    canvas.drawLine(Offset(0, h), center.bottomLeft, line);
    canvas.drawLine(Offset(w, h), center.bottomRight, line);

    // Estado de la pieza completa: se marca sobre todo el dibujo
    if (whole != null && whole != ToothStatus.sano) {
      final color = whole!.color;
      if (whole == ToothStatus.extraido) {
        final x = Paint()
          ..color = color
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke;
        canvas.drawLine(Offset.zero, Offset(w, h), x);
        canvas.drawLine(Offset(w, 0), Offset(0, h), x);
      } else if (whole == ToothStatus.endodoncia) {
        // trazo vertical, como el conducto
        canvas.drawLine(
          Offset(w / 2, 0),
          Offset(w / 2, h),
          Paint()
            ..color = color
            ..strokeWidth = 3,
        );
      } else {
        canvas.drawRect(
          Rect.fromLTWH(0, 0, w, h),
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_ToothPainter old) =>
      old.surfaces != surfaces || old.whole != whole;
}
