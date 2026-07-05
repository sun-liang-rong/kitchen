import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../shared/ui/design_tokens.dart';
import '../../domain/spirit_models.dart';

class SpiritMotion extends StatefulWidget {
  const SpiritMotion({
    required this.child,
    required this.style,
    this.width,
    this.height,
    this.active = true,
    this.showShadow = true,
    this.effectScale = 1,
    this.burstKey = 0,
    super.key,
  });

  final Widget child;
  final SpiritStyle style;
  final double? width;
  final double? height;
  final bool active;
  final bool showShadow;
  final double effectScale;
  final int burstKey;

  @override
  State<SpiritMotion> createState() => _SpiritMotionState();
}

class _SpiritMotionState extends State<SpiritMotion>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final AnimationController _burstController;
  late final Animation<double> _motion;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _burstController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    );
    _motion = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutSine,
    );
    if (widget.active) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant SpiritMotion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.burstKey != oldWidget.burstKey) {
      _burstController.forward(from: 0);
    }
    if (widget.active == oldWidget.active) {
      return;
    }
    if (widget.active) {
      _controller.repeat(reverse: true);
    } else {
      _controller.animateTo(
        0.5,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _burstController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = widget.width;
    final height = widget.height;
    return SizedBox(
      width: width,
      height: height,
      child: AnimatedBuilder(
        animation: Listenable.merge([_motion, _burstController]),
        child: widget.child,
        builder: (context, child) {
          final t = _motion.value;
          final burst = _burstController.value;
          final lift = -4 + (t * 8);
          final tilt = -0.045 + (t * 0.09);
          final scale = 0.98 + (t * 0.035);
          final shadowScale = 1.1 - (t * 0.18);
          return Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _SpiritAuraPainter(
                      style: widget.style,
                      progress: t,
                      scale: widget.effectScale,
                      burst: burst,
                    ),
                  ),
                ),
              ),
              if (widget.showShadow)
                Positioned(
                  bottom: 3,
                  child: Transform.scale(
                    scaleX: shadowScale,
                    scaleY: 1,
                    child: Container(
                      width: (width ?? 64) * 0.54,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.inkSoft.withValues(alpha: 0.13),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                    ),
                  ),
                ),
              Transform.translate(
                offset: Offset(0, lift),
                child: Transform.rotate(
                  angle: tilt,
                  child: Transform.scale(
                    scale: scale,
                    child: child,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SpiritAuraPainter extends CustomPainter {
  const _SpiritAuraPainter({
    required this.style,
    required this.progress,
    required this.scale,
    required this.burst,
  });

  final SpiritStyle style;
  final double progress;
  final double scale;
  final double burst;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) {
      return;
    }
    switch (style) {
      case SpiritStyle.flame:
        _paintFlame(canvas, size);
      case SpiritStyle.shadow:
        _paintShadow(canvas, size);
      case SpiritStyle.celestial:
        _paintCelestial(canvas, size);
    }
    _paintBurst(canvas, size);
  }

  void _paintFlame(Canvas canvas, Size size) {
    final shortest = size.shortestSide;
    final center = Offset(size.width / 2, size.height / 2);
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFD166).withValues(alpha: 0.24 * scale),
          const Color(0xFFFF6B35).withValues(alpha: 0.08 * scale),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(center: center, radius: shortest * 0.48),
      );
    canvas.drawCircle(center, shortest * 0.48, glowPaint);

    final sparkPaint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < 9; i++) {
      final phase = (progress + i * 0.137) % 1;
      final side = i.isEven ? -1.0 : 1.0;
      final drift = side * shortest * (0.14 + (i % 3) * 0.055);
      final x = center.dx + drift * (0.72 + phase * 0.28);
      final y = size.height * 0.78 - phase * size.height * 0.82;
      final radius = shortest * (0.018 + (i % 4) * 0.006) * scale;
      final alpha = (1 - phase).clamp(0.0, 1.0) * 0.9;
      sparkPaint.color =
          (i % 3 == 0 ? const Color(0xFFFFE66D) : const Color(0xFFFF7A30))
              .withValues(alpha: alpha);
      canvas.drawCircle(Offset(x, y), radius, sparkPaint);
    }
  }

  void _paintShadow(Canvas canvas, Size size) {
    final shortest = size.shortestSide;
    final center = Offset(size.width / 2, size.height * 0.62);
    final mistPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF5136A3).withValues(alpha: 0.22 * scale),
          const Color(0xFF14101F).withValues(alpha: 0.13 * scale),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCenter(
          center: center,
          width: shortest * 1.15,
          height: shortest * 0.68,
        ),
      );
    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: shortest * (0.82 + progress * 0.18),
        height: shortest * (0.34 + (1 - progress) * 0.08),
      ),
      mistPaint,
    );

    final ribbonPaint = Paint()
      ..color = const Color(0xFF6E56CF).withValues(alpha: 0.28 * scale)
      ..style = PaintingStyle.stroke
      ..strokeWidth = shortest * 0.025
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 3; i++) {
      final offset = (progress + i / 3) % 1;
      final rect = Rect.fromCenter(
        center: center.translate(0, shortest * (0.02 - offset * 0.08)),
        width: shortest * (0.58 + offset * 0.38),
        height: shortest * (0.18 + offset * 0.16),
      );
      canvas.drawArc(rect, 3.4 + i * 0.5, 2.4, false, ribbonPaint);
    }
  }

  void _paintCelestial(Canvas canvas, Size size) {
    final shortest = size.shortestSide;
    final center = Offset(size.width / 2, size.height / 2);
    final ringPaint = Paint()
      ..color = const Color(0xFF7DD3FC).withValues(alpha: 0.42 * scale)
      ..style = PaintingStyle.stroke
      ..strokeWidth = shortest * 0.018;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate((progress - 0.5) * 0.35);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: shortest * 0.96,
        height: shortest * 0.42,
      ),
      ringPaint,
    );
    canvas.restore();

    final starPaint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < 8; i++) {
      final angle = progress * 6.28318 + i * 0.78539;
      final radius = shortest * (0.36 + (i % 2) * 0.08);
      final starCenter = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * 0.62 * math.sin(angle),
      );
      final starRadius = shortest * (0.015 + (i % 3) * 0.004) * scale;
      starPaint.color =
          (i.isEven ? const Color(0xFFFFFFFF) : const Color(0xFF93C5FD))
              .withValues(alpha: 0.45 + (i % 3) * 0.15);
      _paintStar(canvas, starCenter, starRadius, starPaint);
    }
  }

  void _paintStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (var i = 0; i < 8; i++) {
      final angle = -1.5708 + i * 0.78539;
      final r = i.isEven ? radius : radius * 0.42;
      final point = Offset(
        center.dx + r * math.cos(angle),
        center.dy + r * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _paintBurst(Canvas canvas, Size size) {
    if (burst <= 0 || burst >= 1) {
      return;
    }
    final shortest = size.shortestSide;
    final center = Offset(size.width / 2, size.height / 2);
    final eased = Curves.easeOutCubic.transform(burst);
    final fade = 1 - burst;
    final color = switch (style) {
      SpiritStyle.flame => const Color(0xFFFFB020),
      SpiritStyle.shadow => const Color(0xFF8B5CF6),
      SpiritStyle.celestial => const Color(0xFF7DD3FC),
    };
    final ringPaint = Paint()
      ..color = color.withValues(alpha: 0.34 * fade * scale)
      ..style = PaintingStyle.stroke
      ..strokeWidth = shortest * 0.025 * fade;
    canvas.drawCircle(center, shortest * (0.16 + eased * 0.42), ringPaint);

    final particlePaint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < 10; i++) {
      final angle = i * 0.628318 + progress * 0.8;
      final distance = shortest * (0.12 + eased * (0.34 + (i % 3) * 0.035));
      final point = Offset(
        center.dx + math.cos(angle) * distance,
        center.dy + math.sin(angle) * distance,
      );
      particlePaint.color = color.withValues(alpha: fade * 0.88);
      canvas.drawCircle(
        point,
        shortest * (0.014 + (i % 2) * 0.006) * fade * scale,
        particlePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SpiritAuraPainter oldDelegate) {
    return oldDelegate.style != style ||
        oldDelegate.progress != progress ||
        oldDelegate.scale != scale ||
        oldDelegate.burst != burst;
  }
}

class SpiritImage extends StatelessWidget {
  const SpiritImage({
    required this.appearance,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    super.key,
  });

  final String appearance;
  final double? width;
  final double? height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final asset = spiritAssetFor(appearance);
    final fallback = _fallbackAsset(appearance);
    return Image.asset(
      asset,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        if (fallback != asset) {
          return Image.asset(
            fallback,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (context, error, stackTrace) => _VectorFallback(
              width: width,
              height: height,
            ),
          );
        }
        return _VectorFallback(width: width, height: height);
      },
    );
  }

  String _fallbackAsset(String appearance) {
    if (appearance.endsWith('_intimate')) {
      return 'assets/spirit/spirit_intimate.png';
    }
    if (appearance.endsWith('_growing')) {
      return 'assets/spirit/spirit_growing.png';
    }
    return 'assets/spirit/spirit_baby.png';
  }
}

class _VectorFallback extends StatelessWidget {
  const _VectorFallback({this.width, this.height});

  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _SpiritFallbackPainter(),
      ),
    );
  }
}

class _SpiritFallbackPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final shortest = size.shortestSide;
    final center = Offset(size.width / 2, size.height / 2);
    final bodyPaint = Paint()..color = AppColors.primary;
    final glowPaint = Paint()..color = AppColors.butter.withValues(alpha: 0.9);
    final darkPaint = Paint()..color = AppColors.inkSoft;
    final lightPaint = Paint()..color = Colors.white.withValues(alpha: 0.85);

    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(0, shortest * 0.34),
        width: shortest * 0.58,
        height: shortest * 0.12,
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.08),
    );
    canvas.drawCircle(center, shortest * 0.38, glowPaint);
    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(0, shortest * 0.04),
        width: shortest * 0.72,
        height: shortest * 0.84,
      ),
      bodyPaint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(center.dx - shortest * 0.22, center.dy - shortest * 0.24)
        ..lineTo(center.dx - shortest * 0.1, center.dy - shortest * 0.5)
        ..lineTo(center.dx + shortest * 0.02, center.dy - shortest * 0.2)
        ..close(),
      bodyPaint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(center.dx + shortest * 0.22, center.dy - shortest * 0.24)
        ..lineTo(center.dx + shortest * 0.1, center.dy - shortest * 0.5)
        ..lineTo(center.dx - shortest * 0.02, center.dy - shortest * 0.2)
        ..close(),
      bodyPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(0, shortest * 0.18),
        width: shortest * 0.38,
        height: shortest * 0.28,
      ),
      lightPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(-shortest * 0.15, -shortest * 0.06),
        width: shortest * 0.08,
        height: shortest * 0.05,
      ),
      darkPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(shortest * 0.15, -shortest * 0.06),
        width: shortest * 0.08,
        height: shortest * 0.05,
      ),
      darkPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
