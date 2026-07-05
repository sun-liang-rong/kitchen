import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/local_ui_state.dart';
import '../../../../shared/ui/design_tokens.dart';
import '../../domain/spirit_models.dart';
import '../providers/spirit_controller.dart';
import 'spirit_image.dart';
import 'spirit_panel.dart';
import 'spirit_skill_effect.dart';

class SpiritOverlayScaffold extends ConsumerStatefulWidget {
  const SpiritOverlayScaffold({
    required this.child,
    this.bottomOffset = 118,
    super.key,
  });

  final Widget child;
  final double bottomOffset;

  @override
  ConsumerState<SpiritOverlayScaffold> createState() =>
      _SpiritOverlayScaffoldState();
}

class _SpiritOverlayScaffoldState extends ConsumerState<SpiritOverlayScaffold> {
  static const _buttonWidth = 72.0;
  static const _buttonHeight = 82.0;

  Offset? _position;
  bool _isDragging = false;
  bool _isChargingSkill = false;
  _ActiveSpiritSkill? _activeSkill;
  final math.Random _random = math.Random();
  int _burstKey = 0;

  @override
  void initState() {
    super.initState();
    final saved = LocalUiState.readSpiritDock();
    if (saved != null) {
      _position = Offset(saved.x, saved.y);
    }
    ref.listenManual(spiritControllerProvider, (previous, next) {
      final previousMessage = previous?.valueOrNull?.feedbackMessage;
      final message = next.valueOrNull?.feedbackMessage;
      if (message != null && message != previousMessage && mounted) {
        setState(() {
          _burstKey++;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final size = media.size;
    final padding = media.padding;
    final defaultPosition = Offset(
      size.width - padding.right - _buttonWidth - 8,
      size.height - widget.bottomOffset - _buttonHeight,
    );
    final position =
        _clampPosition(_position ?? defaultPosition, size, padding);
    return Stack(
      children: [
        widget.child,
        if (_activeSkill != null)
          SpiritSkillEffect(
            key: ValueKey('${_activeSkill!.id}-${_activeSkill!.phase.name}'),
            style: _activeSkill!.style,
            phase: _activeSkill!.phase,
            origin: _activeSkill!.origin,
            direction: _activeSkill!.direction,
            launchAngle: _activeSkill!.launchAngle,
            launchSpeedFactor: _activeSkill!.launchSpeedFactor,
            power: _activeSkill!.power,
            onCompleted: _finishSkill,
          ),
        Positioned(
          left: position.dx,
          top: position.dy,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _isChargingSkill ? null : _openPanel,
            onLongPressStart: (_) => _startSkillCharge(position),
            onLongPressEnd: (_) => _releaseSkill(position),
            onLongPressCancel: _cancelSkillCharge,
            onPanStart: (_) {
              if (_isChargingSkill) {
                return;
              }
              setState(() {
                _isDragging = true;
              });
            },
            onPanUpdate: (details) {
              if (_isChargingSkill) {
                return;
              }
              setState(() {
                final currentPosition = _position ?? position;
                _position = _clampPosition(
                  currentPosition + details.delta,
                  size,
                  padding,
                );
              });
            },
            onPanEnd: (_) {
              if (_isChargingSkill) {
                return;
              }
              late final Offset snapped;
              setState(() {
                snapped = _snapToEdge(
                  _clampPosition(_position ?? position, size, padding),
                  size,
                  padding,
                );
                _position = snapped;
                _isDragging = false;
                _isChargingSkill = false;
              });
              LocalUiState.saveSpiritDock(snapped.dx, snapped.dy);
            },
            onPanCancel: () {
              setState(() {
                _isDragging = false;
                _isChargingSkill = false;
              });
            },
            child: _SpiritSideButton(
              isDragging: _isDragging,
              isChargingSkill: _isChargingSkill,
              burstKey: _burstKey,
            ),
          ),
        ),
      ],
    );
  }

  Offset _clampPosition(Offset position, Size size, EdgeInsets padding) {
    final minX = padding.left + 8;
    final maxX = size.width - padding.right - _buttonWidth - 8;
    final minY = padding.top + 12;
    final maxY = size.height - padding.bottom - _buttonHeight - 12;
    return Offset(
      position.dx.clamp(minX, maxX),
      position.dy.clamp(minY, maxY),
    );
  }

  Offset _snapToEdge(Offset position, Size size, EdgeInsets padding) {
    final left = padding.left + 8;
    final right = size.width - padding.right - _buttonWidth - 8;
    final targetX =
        position.dx + _buttonWidth / 2 < size.width / 2 ? left : right;
    return _clampPosition(
      Offset(targetX, position.dy),
      size,
      padding,
    );
  }

  void _openPanel() {
    ref.read(spiritControllerProvider.notifier).loadDetails();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (context) {
        return const SpiritPanel();
      },
    );
  }

  void _startSkillCharge(Offset position) {
    if (_isDragging) {
      return;
    }
    final spirit = ref.read(spiritControllerProvider).valueOrNull?.spirit;
    if (spirit == null) {
      return;
    }
    HapticFeedback.mediumImpact();
    final launchAngle = _randomLaunchAngle();
    final speedFactor = 0.9 + _random.nextDouble() * 0.24;
    setState(() {
      _isChargingSkill = true;
      _activeSkill = _ActiveSpiritSkill(
        id: DateTime.now().microsecondsSinceEpoch,
        style: spirit.style,
        phase: SpiritSkillPhase.charging,
        origin: _skillOrigin(position),
        direction: _skillDirection(launchAngle),
        launchAngle: launchAngle,
        launchSpeedFactor: speedFactor,
        power: _skillPower(spirit.level),
      );
    });
  }

  void _releaseSkill(Offset position) {
    if (!_isChargingSkill || _activeSkill == null) {
      return;
    }
    setState(() {
      _isChargingSkill = false;
      _activeSkill = _activeSkill!.copyWith(
        phase: SpiritSkillPhase.casting,
        origin: _skillOrigin(position),
      );
    });
    HapticFeedback.heavyImpact();
  }

  void _cancelSkillCharge() {
    if (!_isChargingSkill) {
      return;
    }
    setState(() {
      _isChargingSkill = false;
      _activeSkill = null;
    });
  }

  void _finishSkill() {
    if (!mounted) {
      return;
    }
    setState(() {
      _activeSkill = null;
    });
  }

  Offset _skillOrigin(Offset position) {
    return Offset(
      position.dx + _buttonWidth / 2,
      position.dy + _buttonHeight * 0.42,
    );
  }

  SpiritSkillDirection _skillDirection(double launchAngle) {
    return math.cos(launchAngle) >= 0
        ? SpiritSkillDirection.leftToRight
        : SpiritSkillDirection.rightToLeft;
  }

  double _randomLaunchAngle() {
    final upwardAngle = math.pi * (0.22 + _random.nextDouble() * 0.28);
    final direction = _random.nextBool() ? 1 : -1;
    return direction == 1 ? -upwardAngle : -(math.pi - upwardAngle);
  }

  double _skillPower(int level) {
    return (1 + (level - 1) * 0.08).clamp(1.0, 1.8);
  }
}

class _SpiritSideButton extends ConsumerWidget {
  const _SpiritSideButton({
    required this.isDragging,
    required this.isChargingSkill,
    required this.burstKey,
  });

  final bool isDragging;
  final bool isChargingSkill;
  final int burstKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(spiritControllerProvider);
    final value = asyncState.valueOrNull;
    final spirit = value?.spirit;
    final isBound = value?.isBound == true;
    final isBusy = asyncState.isLoading || value?.isRefreshing == true;

    return SizedBox(
      width: _SpiritOverlayScaffoldState._buttonWidth,
      height: _SpiritOverlayScaffoldState._buttonHeight,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (isBusy)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else if (!isBound || spirit == null)
            const _DormantSpiritMark()
          else
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SpiritMotion(
                  style: spirit.style,
                  width: 62,
                  height: 62,
                  active: !isDragging,
                  effectScale: isChargingSkill ? 1.28 : 0.86,
                  burstKey: burstKey,
                  child: SpiritImage(
                    appearance: spirit.appearance,
                    width: isChargingSkill ? 68 : 62,
                    height: isChargingSkill ? 68 : 62,
                    fit: BoxFit.contain,
                  ),
                ),
                Text(
                  'Lv.${spirit.level}',
                  maxLines: 1,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.primaryDeep,
                    fontWeight: FontWeight.w800,
                    shadows: const [
                      Shadow(
                        color: Colors.white,
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ActiveSpiritSkill {
  const _ActiveSpiritSkill({
    required this.id,
    required this.style,
    required this.phase,
    required this.origin,
    required this.direction,
    required this.launchAngle,
    required this.launchSpeedFactor,
    required this.power,
  });

  final int id;
  final SpiritStyle style;
  final SpiritSkillPhase phase;
  final Offset origin;
  final SpiritSkillDirection direction;
  final double launchAngle;
  final double launchSpeedFactor;
  final double power;

  _ActiveSpiritSkill copyWith({
    SpiritSkillPhase? phase,
    Offset? origin,
    SpiritSkillDirection? direction,
  }) {
    return _ActiveSpiritSkill(
      id: id,
      style: style,
      phase: phase ?? this.phase,
      origin: origin ?? this.origin,
      direction: direction ?? this.direction,
      launchAngle: launchAngle,
      launchSpeedFactor: launchSpeedFactor,
      power: power,
    );
  }
}

class _TransparentIconBadge extends StatelessWidget {
  const _TransparentIconBadge({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: AppColors.outline),
        boxShadow: [
          BoxShadow(
            color: AppColors.inkSoft.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: SizedBox(
        width: 42,
        height: 42,
        child: Center(
          child: child,
        ),
      ),
    );
  }
}

class _DormantSpiritMark extends StatelessWidget {
  const _DormantSpiritMark();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 42,
          height: 42,
          color: Colors.transparent,
          child: const _TransparentIconBadge(
            child: Icon(
              Icons.auto_awesome_outlined,
              size: 20,
              color: AppColors.textLight,
            ),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          '待唤醒',
          maxLines: 1,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}
