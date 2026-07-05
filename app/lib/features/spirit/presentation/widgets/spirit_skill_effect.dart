import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/spirit_models.dart';

enum SpiritSkillPhase {
  charging,
  casting,
}

enum SpiritSkillDirection {
  leftToRight,
  rightToLeft,
}

class SpiritSkillEffect extends StatefulWidget {
  const SpiritSkillEffect({
    required this.style,
    required this.phase,
    required this.origin,
    required this.direction,
    required this.launchAngle,
    required this.launchSpeedFactor,
    required this.power,
    required this.onCompleted,
    super.key,
  });

  final SpiritStyle style;
  final SpiritSkillPhase phase;
  final Offset origin;
  final SpiritSkillDirection direction;
  final double launchAngle;
  final double launchSpeedFactor;
  final double power;
  final VoidCallback onCompleted;

  @override
  State<SpiritSkillEffect> createState() => _SpiritSkillEffectState();
}

class _SpiritSkillEffectState extends State<SpiritSkillEffect>
    with TickerProviderStateMixin {
  late final AnimationController _chargeController;
  late final AnimationController _castController;

  int get _maxBounces {
    if (widget.power >= 1.56) {
      return 9;
    }
    if (widget.power >= 1.24) {
      return 7;
    }
    return 5;
  }

  double get _projectileRadius => 28 + widget.power * 5;

  @override
  void initState() {
    super.initState();
    _chargeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
    _castController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 3000 + (_maxBounces * 180)),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onCompleted();
        }
      });
    if (widget.phase == SpiritSkillPhase.casting) {
      _castController.forward();
    }
  }

  @override
  void didUpdateWidget(covariant SpiritSkillEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.phase != widget.phase &&
        widget.phase == SpiritSkillPhase.casting) {
      _castController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _chargeController.dispose();
    _castController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Positioned.fill(
        child: AnimatedBuilder(
          animation: Listenable.merge([_chargeController, _castController]),
          builder: (context, child) {
            final size = MediaQuery.of(context).size;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                if (widget.phase == SpiritSkillPhase.charging)
                  _buildCharge(size),
                if (widget.phase == SpiritSkillPhase.casting) _buildCast(size),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCharge(Size screen) {
    final t = _chargeController.value;
    final preview = _simulate(screen, 0.0, previewOnly: true);
    final asset = switch (widget.style) {
      SpiritStyle.flame => 'assets/spirit/skills/skill_fire_charge.png',
      SpiritStyle.shadow => 'assets/spirit/skills/skill_shadow_charge.png',
      SpiritStyle.celestial => 'assets/spirit/skills/skill_star_charge.png',
    };
    final size = 108 + math.sin(t * math.pi * 2) * 10 + widget.power * 10;
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _BouncingSkillPainter(
              style: widget.style,
              phase: SpiritSkillPhase.charging,
              origin: widget.origin,
              current: widget.origin,
              trail: preview.trail,
              impacts: const [],
              progress: t,
              power: widget.power,
              maxBounces: _maxBounces,
            ),
          ),
        ),
        Positioned(
          left: widget.origin.dx - size / 2,
          top: widget.origin.dy - size / 2,
          width: size,
          height: size,
          child: Transform.rotate(
            angle: t * math.pi * 2,
            child: Opacity(
              opacity: 0.92,
              child: Image.asset(
                asset,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return CustomPaint(
                    painter: _SkillAssetFallbackPainter(
                      style: widget.style,
                      charging: true,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCast(Size screen) {
    final raw = _castController.value;
    final simulation = _simulate(screen, raw);
    final isFinal = raw > 0.82 || simulation.bounceCount >= _maxBounces;
    final burstProgress =
        raw < 0.72 ? 0.0 : ((raw - 0.72) / 0.28).clamp(0.0, 1.0);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: _screenDim(raw)),
            ),
          ),
        ),
        Positioned.fill(
          child: CustomPaint(
            painter: _BouncingSkillPainter(
              style: widget.style,
              phase: SpiritSkillPhase.casting,
              origin: widget.origin,
              current: simulation.position,
              trail: simulation.trail,
              impacts: simulation.impacts,
              progress: raw,
              power: widget.power,
              maxBounces: _maxBounces,
              finalBurst: isFinal,
              burstProgress: burstProgress,
            ),
          ),
        ),
        if (!isFinal || burstProgress < 0.72)
          _buildProjectile(simulation.position, simulation.velocity, raw),
        if (burstProgress > 0)
          _buildImpactAsset(simulation.position, burstProgress),
      ],
    );
  }

  Widget _buildProjectile(Offset position, Offset velocity, double progress) {
    final asset = switch (widget.style) {
      SpiritStyle.flame => 'assets/spirit/skills/skill_fire_dragon.png',
      SpiritStyle.shadow => 'assets/spirit/skills/skill_shadow_crescent.png',
      SpiritStyle.celestial => 'assets/spirit/skills/skill_meteor.png',
    };
    final dimensions = switch (widget.style) {
      SpiritStyle.flame => Size(118 + widget.power * 18, 58 + widget.power * 8),
      SpiritStyle.shadow =>
        Size(126 + widget.power * 18, 78 + widget.power * 8),
      SpiritStyle.celestial =>
        Size(104 + widget.power * 14, 68 + widget.power * 8),
    };
    final angle = math.atan2(velocity.dy, velocity.dx);
    final fade = progress < 0.88
        ? 1.0
        : (1 - ((progress - 0.88) / 0.12)).clamp(0.0, 1.0);
    return Positioned(
      left: position.dx - dimensions.width / 2,
      top: position.dy - dimensions.height / 2,
      width: dimensions.width,
      height: dimensions.height,
      child: Opacity(
        opacity: fade,
        child: Transform.rotate(
          angle: angle,
          child: Image.asset(
            asset,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return CustomPaint(
                painter: _SkillAssetFallbackPainter(style: widget.style),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildImpactAsset(Offset center, double progress) {
    final asset = switch (widget.style) {
      SpiritStyle.flame => 'assets/spirit/skills/skill_fire_lotus.png',
      SpiritStyle.shadow => 'assets/spirit/skills/skill_shadow_rift.png',
      SpiritStyle.celestial => 'assets/spirit/skills/skill_star_disk.png',
    };
    final dimensions = switch (widget.style) {
      SpiritStyle.flame =>
        Size(160 + widget.power * 28, 160 + widget.power * 28),
      SpiritStyle.shadow =>
        Size(240 + widget.power * 40, 112 + widget.power * 16),
      SpiritStyle.celestial =>
        Size(180 + widget.power * 32, 180 + widget.power * 32),
    };
    final opacity = progress < 0.2
        ? (progress / 0.2).clamp(0.0, 1.0)
        : (1 - ((progress - 0.2) / 0.8)).clamp(0.0, 1.0);
    return Positioned(
      left: center.dx - dimensions.width / 2,
      top: center.dy - dimensions.height / 2,
      width: dimensions.width,
      height: dimensions.height,
      child: Opacity(
        opacity: opacity,
        child: Transform.scale(
          scale: 0.78 + Curves.easeOutBack.transform(progress) * 0.44,
          child: Image.asset(
            asset,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return CustomPaint(
                painter: _SkillAssetFallbackPainter(style: widget.style),
              );
            },
          ),
        ),
      ),
    );
  }

  _BounceSimulation _simulate(
    Size screen,
    double progress, {
    bool previewOnly = false,
  }) {
    final radius = _projectileRadius;
    final bounds = Rect.fromLTWH(
      radius + 8,
      radius + 10,
      math.max(1, screen.width - radius * 2 - 16),
      math.max(1, screen.height - radius * 2 - 20),
    );
    final totalSeconds = previewOnly ? 1.35 : 3.25 + _maxBounces * 0.18;
    final elapsed = previewOnly ? totalSeconds : totalSeconds * progress;
    final speed = (640 + widget.power * 130) * widget.launchSpeedFactor;
    var velocity = Offset(
      math.cos(widget.launchAngle) * speed,
      math.sin(widget.launchAngle) * speed,
    );
    var position = Offset(
      widget.origin.dx.clamp(bounds.left, bounds.right),
      widget.origin.dy.clamp(bounds.top, bounds.bottom),
    );
    var time = 0.0;
    var bounceCount = 0;
    final trail = <Offset>[position];
    final impacts = <_SkillImpact>[];
    const step = 1 / 60;
    final sampleLimit = previewOnly ? 110 : 260;
    var samples = 0;
    while (time < elapsed && samples < sampleLimit) {
      final dt = math.min(step, elapsed - time);
      var next = position + velocity * dt;
      var wall = _ImpactWall.none;
      if (next.dx <= bounds.left) {
        next = Offset(bounds.left, next.dy);
        velocity = Offset(velocity.dx.abs(), velocity.dy);
        wall = _ImpactWall.left;
      } else if (next.dx >= bounds.right) {
        next = Offset(bounds.right, next.dy);
        velocity = Offset(-velocity.dx.abs(), velocity.dy);
        wall = _ImpactWall.right;
      }
      if (next.dy <= bounds.top) {
        next = Offset(next.dx, bounds.top);
        velocity = Offset(velocity.dx, velocity.dy.abs());
        wall = _ImpactWall.top;
      } else if (next.dy >= bounds.bottom) {
        next = Offset(next.dx, bounds.bottom);
        velocity = Offset(velocity.dx, -velocity.dy.abs());
        wall = _ImpactWall.bottom;
      }
      if (wall != _ImpactWall.none) {
        bounceCount++;
        velocity = velocity * 0.975;
        impacts.add(_SkillImpact(next, wall, bounceCount, time / totalSeconds));
        if (!previewOnly && bounceCount >= _maxBounces) {
          position = next;
          trail.add(position);
          break;
        }
      }
      position = next;
      time += dt;
      samples++;
      if (samples % (previewOnly ? 8 : 3) == 0) {
        trail.add(position);
      }
    }
    return _BounceSimulation(
      position: position,
      velocity: velocity,
      trail: trail,
      impacts: impacts,
      bounceCount: bounceCount,
    );
  }

  double _screenDim(double t) {
    if (t < 0.18) {
      return Curves.easeOut.transform(t / 0.18) * 0.2;
    }
    if (t > 0.82) {
      return (1 - ((t - 0.82) / 0.18)).clamp(0.0, 1.0) * 0.2;
    }
    return 0.2;
  }
}

class _BounceSimulation {
  const _BounceSimulation({
    required this.position,
    required this.velocity,
    required this.trail,
    required this.impacts,
    required this.bounceCount,
  });

  final Offset position;
  final Offset velocity;
  final List<Offset> trail;
  final List<_SkillImpact> impacts;
  final int bounceCount;
}

class _SkillImpact {
  const _SkillImpact(this.position, this.wall, this.count, this.time);

  final Offset position;
  final _ImpactWall wall;
  final int count;
  final double time;
}

enum _ImpactWall {
  none,
  left,
  right,
  top,
  bottom,
}

class _BouncingSkillPainter extends CustomPainter {
  const _BouncingSkillPainter({
    required this.style,
    required this.phase,
    required this.origin,
    required this.current,
    required this.trail,
    required this.impacts,
    required this.progress,
    required this.power,
    required this.maxBounces,
    this.finalBurst = false,
    this.burstProgress = 0,
  });

  final SpiritStyle style;
  final SpiritSkillPhase phase;
  final Offset origin;
  final Offset current;
  final List<Offset> trail;
  final List<_SkillImpact> impacts;
  final double progress;
  final double power;
  final int maxBounces;
  final bool finalBurst;
  final double burstProgress;

  Color get _color => switch (style) {
        SpiritStyle.flame => const Color(0xFFFF7A30),
        SpiritStyle.shadow => const Color(0xFF8B5CF6),
        SpiritStyle.celestial => const Color(0xFF7DD3FC),
      };

  @override
  void paint(Canvas canvas, Size size) {
    if (phase == SpiritSkillPhase.charging) {
      _paintCharge(canvas);
      _paintPrediction(canvas);
      return;
    }
    _paintScreenFlash(canvas, size);
    _paintTrail(canvas);
    _paintImpacts(canvas, size);
    if (finalBurst) {
      _paintFinalBurst(canvas);
    }
  }

  void _paintCharge(Canvas canvas) {
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          _color.withValues(alpha: 0.22 + power * 0.04),
          _color.withValues(alpha: 0.06),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: origin, radius: 124 + power * 28));
    canvas.drawCircle(origin, 124 + power * 28, glow);

    final ring = Paint()
      ..color = _color.withValues(alpha: 0.62)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8 + power;
    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.rotate(progress * math.pi * 2);
    for (var i = 0; i < 3; i++) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: 112 + i * 26 + power * 18,
          height: 34 + i * 8,
        ),
        ring,
      );
      canvas.rotate(math.pi / 3);
    }
    canvas.restore();
  }

  void _paintPrediction(Canvas canvas) {
    if (trail.length < 2) {
      return;
    }
    final paint = Paint()
      ..color = _color.withValues(alpha: 0.36)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4 + power
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < trail.length - 1; i++) {
      if (i.isOdd) {
        canvas.drawLine(trail[i], trail[i + 1], paint);
      }
    }
  }

  void _paintScreenFlash(Canvas canvas, Size size) {
    final flash =
        progress < 0.12 ? 1 - Curves.easeOut.transform(progress / 0.12) : 0.0;
    if (flash <= 0) {
      return;
    }
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.transparent,
          _color.withValues(alpha: 0.12 * flash),
          _color.withValues(alpha: 0.28 * flash),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, paint);
  }

  void _paintTrail(Canvas canvas) {
    if (trail.length < 2) {
      return;
    }
    final path = Path()..moveTo(trail.first.dx, trail.first.dy);
    for (final point in trail.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    final paint = Paint()
      ..color = _color.withValues(alpha: 0.34)
      ..style = PaintingStyle.stroke
      ..strokeWidth =
          style == SpiritStyle.shadow ? 14 + power * 3 : 10 + power * 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, paint);

    final bright = Paint()
      ..color = Colors.white
          .withValues(alpha: style == SpiritStyle.shadow ? 0.18 : 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2 + power
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, bright);

    if (style == SpiritStyle.celestial) {
      _paintConstellation(canvas);
    }
  }

  void _paintConstellation(Canvas canvas) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.55);
    for (var i = 0; i < trail.length; i += 7) {
      _drawStar(canvas, trail[i], 4 + power, paint);
    }
  }

  void _paintImpacts(Canvas canvas, Size size) {
    for (final impact in impacts) {
      final age = ((progress - impact.time) / 0.16).clamp(0.0, 1.0);
      final fade = 1 - age;
      if (fade <= 0) {
        continue;
      }
      final paint = Paint()
        ..color = _color.withValues(alpha: 0.7 * fade)
        ..style = PaintingStyle.stroke
        ..strokeWidth = (5 + power) * fade;
      canvas.drawCircle(impact.position, 18 + age * (42 + power * 8), paint);
      _paintEdgeFlash(canvas, size, impact, fade);
      _paintComboText(canvas, impact, fade);
    }
  }

  void _paintEdgeFlash(
      Canvas canvas, Size size, _SkillImpact impact, double fade) {
    final paint = Paint()..color = _color.withValues(alpha: 0.26 * fade);
    const width = 10.0;
    final rect = switch (impact.wall) {
      _ImpactWall.left => Rect.fromLTWH(0, impact.position.dy - 80, width, 160),
      _ImpactWall.right =>
        Rect.fromLTWH(size.width - width, impact.position.dy - 80, width, 160),
      _ImpactWall.top => Rect.fromLTWH(impact.position.dx - 90, 0, 180, width),
      _ImpactWall.bottom =>
        Rect.fromLTWH(impact.position.dx - 90, size.height - width, 180, width),
      _ImpactWall.none => Rect.zero,
    };
    if (rect != Rect.zero) {
      canvas.drawRect(rect, paint);
    }
  }

  void _paintComboText(Canvas canvas, _SkillImpact impact, double fade) {
    final label = switch (style) {
      SpiritStyle.flame => '炎爆 x${impact.count}',
      SpiritStyle.shadow => '裂斩 x${impact.count}',
      SpiritStyle.celestial => '星陨 x${impact.count}',
    };
    final painter = TextPainter(
      text: TextSpan(
        text: impact.count >= maxBounces ? 'Final Burst' : label,
        style: TextStyle(
          color: Colors.white.withValues(alpha: fade),
          fontSize: impact.count >= maxBounces ? 15 : 12,
          fontWeight: FontWeight.w900,
          shadows: [
            Shadow(color: _color, blurRadius: 10),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      impact.position.translate(12, -28 - (1 - fade) * 18),
    );
  }

  void _paintFinalBurst(Canvas canvas) {
    if (burstProgress <= 0) {
      return;
    }
    final fade = 1 - burstProgress;
    final ring = Paint()
      ..color = _color.withValues(alpha: 0.62 * fade)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (9 + power * 2) * fade;
    canvas.drawCircle(current, 28 + burstProgress * (150 + power * 28), ring);
    final count = 56 + (power * 18).round();
    final particle = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < count; i++) {
      final angle = i * math.pi * 2 / count + burstProgress * 1.2;
      final distance = 24 + burstProgress * (92 + (i % 8) * 12 + power * 18);
      final point = Offset(
        current.dx + math.cos(angle) * distance,
        current.dy + math.sin(angle) * distance,
      );
      particle.color = _color.withValues(alpha: fade * 0.86);
      if (style == SpiritStyle.celestial && i % 3 == 0) {
        _drawStar(canvas, point, 4 + (i % 3).toDouble(), particle);
      } else {
        canvas.drawCircle(point, 3 + (i % 4).toDouble(), particle);
      }
    }
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (var i = 0; i < 8; i++) {
      final angle = -math.pi / 2 + i * math.pi / 4;
      final r = i.isEven ? radius * 1.5 : radius * 0.54;
      final point = Offset(
        center.dx + math.cos(angle) * r,
        center.dy + math.sin(angle) * r,
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

  @override
  bool shouldRepaint(covariant _BouncingSkillPainter oldDelegate) {
    return oldDelegate.style != style ||
        oldDelegate.phase != phase ||
        oldDelegate.current != current ||
        oldDelegate.trail != trail ||
        oldDelegate.impacts != impacts ||
        oldDelegate.progress != progress ||
        oldDelegate.power != power ||
        oldDelegate.maxBounces != maxBounces ||
        oldDelegate.finalBurst != finalBurst ||
        oldDelegate.burstProgress != burstProgress;
  }
}

class _SkillAssetFallbackPainter extends CustomPainter {
  const _SkillAssetFallbackPainter({
    required this.style,
    this.charging = false,
  });

  final SpiritStyle style;
  final bool charging;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final shortest = size.shortestSide;
    if (charging) {
      _paintCharge(canvas, center, shortest);
      return;
    }
    switch (style) {
      case SpiritStyle.flame:
        _paintFireball(canvas, center, shortest);
      case SpiritStyle.shadow:
        _paintSlash(canvas, size);
      case SpiritStyle.celestial:
        _paintMeteor(canvas, size);
    }
  }

  void _paintCharge(Canvas canvas, Offset center, double shortest) {
    final color = switch (style) {
      SpiritStyle.flame => const Color(0xFFFF7A30),
      SpiritStyle.shadow => const Color(0xFF8B5CF6),
      SpiritStyle.celestial => const Color(0xFF7DD3FC),
    };
    final paint = Paint()
      ..color = color.withValues(alpha: 0.58)
      ..style = PaintingStyle.stroke
      ..strokeWidth = shortest * 0.035;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    for (var i = 0; i < 3; i++) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: shortest * (0.92 - i * 0.18),
          height: shortest * (0.36 - i * 0.04),
        ),
        paint,
      );
      canvas.rotate(0.65);
    }
    canvas.restore();
  }

  void _paintFireball(Canvas canvas, Offset center, double shortest) {
    canvas.drawCircle(
      center,
      shortest * 0.42,
      Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.82),
    );
    canvas.drawCircle(
      center.translate(shortest * 0.08, -shortest * 0.08),
      shortest * 0.23,
      Paint()..color = const Color(0xFFFFE66D).withValues(alpha: 0.92),
    );
  }

  void _paintSlash(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF8B5CF6).withValues(alpha: 0.82)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * 0.13
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromLTWH(
        size.width * 0.08,
        size.height * 0.08,
        size.width * 0.84,
        size.height * 0.84,
      ),
      3.55,
      2.45,
      false,
      paint,
    );
  }

  void _paintMeteor(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF7DD3FC).withValues(alpha: 0.64)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * 0.12
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * 0.12, size.height * 0.18),
      Offset(size.width * 0.72, size.height * 0.64),
      paint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.74, size.height * 0.66),
      size.shortestSide * 0.22,
      Paint()..color = const Color(0xFFBAE6FD).withValues(alpha: 0.88),
    );
  }

  @override
  bool shouldRepaint(covariant _SkillAssetFallbackPainter oldDelegate) {
    return oldDelegate.style != style || oldDelegate.charging != charging;
  }
}
