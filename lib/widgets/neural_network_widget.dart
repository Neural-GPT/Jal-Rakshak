import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Pure Flutter animated neural network visualization.
/// Mimics the glowing neural net GIF in the design.
/// No external assets needed.
class NeuralNetworkWidget extends StatefulWidget {
  final bool  isActive;
  final double height;

  const NeuralNetworkWidget({
    super.key,
    required this.isActive,
    this.height = 180,
  });

  @override
  State<NeuralNetworkWidget> createState() => _NeuralNetworkWidgetState();
}

class _NeuralNetworkWidgetState extends State<NeuralNetworkWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late AnimationController _flowCtrl;
  late Animation<double>   _pulse;
  late Animation<double>   _flow;

  // Network topology: nodes per layer
  static const layers = [4, 5, 6, 5, 4];

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _flowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    _pulse = CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut);
    _flow  = _flowCtrl;
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _flowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulse, _flow]),
      builder: (_, __) => CustomPaint(
        painter: _NNPainter(
          pulseValue:  _pulse.value,
          flowValue:   _flow.value,
          isActive:    widget.isActive,
          layers:      layers,
        ),
        size: Size(double.infinity, widget.height),
      ),
    );
  }
}

class _NNPainter extends CustomPainter {
  final double        pulseValue;
  final double        flowValue;
  final bool          isActive;
  final List<int>     layers;

  _NNPainter({
    required this.pulseValue,
    required this.flowValue,
    required this.isActive,
    required this.layers,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Compute node positions
    final nodePositions = <List<Offset>>[];
    final xStep = w / (layers.length + 1);

    for (int l = 0; l < layers.length; l++) {
      final x      = xStep * (l + 1);
      final count  = layers[l];
      final yStep  = h / (count + 1);
      final nodes  = <Offset>[];
      for (int n = 0; n < count; n++) {
        nodes.add(Offset(x, yStep * (n + 1)));
      }
      nodePositions.add(nodes);
    }

    // ── Draw connections ─────────────────────────────────────────────────
    for (int l = 0; l < layers.length - 1; l++) {
      for (final src in nodePositions[l]) {
        for (final dst in nodePositions[l + 1]) {
          // Signal traveling along this connection
          final rand   = (src.dy * dst.dx) % 1.0;
          final phase  = (flowValue + rand) % 1.0;

          // Base connection paint
          final basePaint = Paint()
            ..color  = isActive
                ? AppColors.cyan.withOpacity(0.08 + pulseValue * 0.05)
                : Colors.white.withOpacity(0.04)
            ..strokeWidth = 0.6
            ..style  = PaintingStyle.stroke;
          canvas.drawLine(src, dst, basePaint);

          // Animated signal pulse traveling along connection
          if (isActive) {
            final signalPos = Offset(
              src.dx + (dst.dx - src.dx) * phase,
              src.dy + (dst.dy - src.dy) * phase,
            );
            final signalPaint = Paint()
              ..color      = AppColors.cyan.withOpacity(0.6 * (1 - (phase - 0.5).abs() * 2))
              ..strokeWidth = 1.5
              ..style      = PaintingStyle.fill;
            canvas.drawCircle(signalPos, 2.0, signalPaint);
          }
        }
      }
    }

    // ── Draw nodes ───────────────────────────────────────────────────────
    for (int l = 0; l < layers.length; l++) {
      final isMid    = l == layers.length ~/ 2;
      final baseR    = isMid ? 8.0 : 6.0;

      for (int n = 0; n < nodePositions[l].length; n++) {
        final pos   = nodePositions[l][n];
        final phase = (flowValue + l * 0.2 + n * 0.1) % 1.0;
        final glow  = isActive
            ? (math.sin(phase * math.pi * 2) + 1) / 2
            : 0.0;
        final r     = baseR + (isActive ? glow * 2.0 : 0);

        // Glow ring
        if (isActive) {
          canvas.drawCircle(
            pos,
            r + 4,
            Paint()
              ..color    = AppColors.cyan.withOpacity(0.08 + glow * 0.12)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
          );
        }

        // Node fill
        final fillColor = isActive && isMid
            ? Color.lerp(
                AppColors.cyan.withOpacity(0.3),
                AppColors.cyan.withOpacity(0.8),
                glow * pulseValue,
              )!
            : (isActive
                ? AppColors.cyan.withOpacity(0.25 + glow * 0.35)
                : Colors.white.withOpacity(0.08));

        canvas.drawCircle(pos, r, Paint()..color = fillColor);

        // Node border
        canvas.drawCircle(
          pos, r,
          Paint()
            ..color       = isActive
                ? AppColors.cyan.withOpacity(0.5 + glow * 0.5)
                : Colors.white.withOpacity(0.15)
            ..style       = PaintingStyle.stroke
            ..strokeWidth = isMid ? 1.5 : 1.0,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_NNPainter old) =>
      old.pulseValue != pulseValue ||
      old.flowValue  != flowValue  ||
      old.isActive   != isActive;
}
