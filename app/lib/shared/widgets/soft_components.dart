import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/notifications/presentation/providers/notifications_controller.dart';
import '../../core/config/app_config.dart';
import '../../features/auth/domain/auth_models.dart';
import '../ui/design_tokens.dart';

class MagazineScaffold extends StatelessWidget {
  const MagazineScaffold({
    required this.children,
    this.bottomNavigationBar,
    this.padding = const EdgeInsets.fromLTRB(24, 0, 24, 104),
    this.backgroundDecorations = true,
    super.key,
  });

  final List<Widget> children;
  final Widget? bottomNavigationBar;
  final EdgeInsetsGeometry padding;
  final bool backgroundDecorations;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: bottomNavigationBar,
      body: SafeArea(
        child: Stack(
          children: [
            if (backgroundDecorations) const KitchenIllustrationBackground(),
            ListView(
              padding: padding,
              children: children,
            ),
          ],
        ),
      ),
    );
  }
}

class KitchenIllustrationBackground extends StatelessWidget {
  const KitchenIllustrationBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: 18,
            left: -12,
            child: _ghostIcon(Icons.restaurant_menu_rounded, 92,
                AppColors.primary.withValues(alpha: 0.055), -0.32),
          ),
          Positioned(
            top: 116,
            right: -22,
            child: _ghostIcon(Icons.rice_bowl_rounded, 104,
                AppColors.mocha.withValues(alpha: 0.055), 0.26),
          ),
          Positioned(
            bottom: 86,
            left: -28,
            child: _ghostIcon(Icons.soup_kitchen_rounded, 116,
                AppColors.partner.withValues(alpha: 0.06), 0.18),
          ),
        ],
      ),
    );
  }

  Widget _ghostIcon(IconData icon, double size, Color color, double angle) {
    return Transform.rotate(
      angle: angle,
      child: Icon(icon, size: size, color: color),
    );
  }
}

class SoftCard extends StatefulWidget {
  const SoftCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color = AppColors.surface,
    this.borderColor,
    this.onTap,
    this.gradient,
    this.elevation = AppElevation.sm,
    this.radius = AppRadius.lg,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final Color? borderColor;
  final VoidCallback? onTap;
  final Gradient? gradient;
  final double elevation;
  final double radius;

  @override
  State<SoftCard> createState() => _SoftCardState();
}

class MagazineHeader extends StatelessWidget {
  const MagazineHeader({
    required this.title,
    this.subtitle,
    this.kicker,
    this.leadingIcon = Icons.flatware_rounded,
    this.actions = const [],
    this.center = false,
    super.key,
  });

  final String title;
  final String? subtitle;
  final String? kicker;
  final IconData leadingIcon;
  final List<Widget> actions;
  final bool center;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 18, 0, 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: AppColors.accentGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.13),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(leadingIcon, color: AppColors.primaryDeep, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
              children: [
                if (kicker != null) ...[
                  Text(
                    kicker!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AppColors.primaryDeep,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 3),
                ],
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: center ? Alignment.center : Alignment.centerLeft,
                  child: Text(
                    title,
                    maxLines: 1,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                        ),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    subtitle!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: center ? TextAlign.center : TextAlign.start,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                  ),
                ],
              ],
            ),
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(width: 8),
            ...actions,
          ],
        ],
      ),
    );
  }
}

class MagazineCoverCard extends StatelessWidget {
  const MagazineCoverCard({
    required this.child,
    this.label,
    this.icon = Icons.auto_awesome,
    this.onTap,
    this.gradient = AppColors.coverGradient,
    super.key,
  });

  final Widget child;
  final String? label;
  final IconData icon;
  final VoidCallback? onTap;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: EdgeInsets.zero,
      gradient: gradient,
      borderColor: Colors.white.withValues(alpha: 0.72),
      radius: AppRadius.xl,
      onTap: onTap,
      child: Stack(
        children: [
          Positioned(
            right: -28,
            top: -32,
            child: Container(
              width: 132,
              height: 132,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.28),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 18,
            bottom: 14,
            child: Transform.rotate(
              angle: 0.2,
              child: Icon(
                icon,
                size: 86,
                color: AppColors.primaryDeep.withValues(alpha: 0.08),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (label != null) ...[
                  SoftChip(label: label!, selected: true, icon: icon),
                  const SizedBox(height: 14),
                ],
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MagazineSectionTitle extends StatelessWidget {
  const MagazineSectionTitle({
    required this.title,
    this.subtitle,
    this.action,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
                ],
              ],
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    required this.label,
    this.icon = Icons.check_rounded,
    this.color = AppColors.primary,
    super.key,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class MagazineEmptyState extends StatelessWidget {
  const MagazineEmptyState({
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.icon = Icons.flatware_rounded,
    super.key,
  });

  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 42),
      radius: AppRadius.xl,
      child: Column(
        children: [
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              gradient: AppColors.accentGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.16),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Icon(icon, color: AppColors.primaryDeep, size: 36),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 22),
            RitualButton(
              onPressed: onAction!,
              icon: Icons.add_circle_rounded,
              label: actionLabel!,
            ),
          ],
        ],
      ),
    );
  }
}

class RitualButton extends StatelessWidget {
  const RitualButton({
    required this.onPressed,
    required this.label,
    this.icon = Icons.auto_awesome,
    this.expanded = false,
    super.key,
  });

  final VoidCallback? onPressed;
  final String label;
  final IconData icon;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final button = DecoratedBox(
      decoration: BoxDecoration(
        gradient: onPressed == null ? null : AppColors.primaryGradient,
        color: onPressed == null ? AppColors.surfaceHigh : null,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: onPressed == null
            ? null
            : [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.28),
                  blurRadius: 20,
                  offset: const Offset(0, 9),
                ),
              ],
      ),
      child: FilledButton.icon(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          minimumSize: Size(expanded ? double.infinity : 156, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
        ),
        icon: Icon(icon),
        label: Text(label),
      ),
    );
    if (!expanded) {
      return button;
    }
    return SizedBox(width: double.infinity, child: button);
  }
}

class MagazineBottomActionBar extends StatelessWidget {
  const MagazineBottomActionBar({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        boxShadow: [
          BoxShadow(
            color: const Color(0x24E8C8B4),
            blurRadius: 26,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 10, 20, 16),
        child: Row(children: children),
      ),
    );
  }
}

class _SoftCardState extends State<SoftCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimation.fast,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: AppAnimation.curve),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onTap != null) {
      setState(() => _isPressed = true);
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onTap != null) {
      setState(() => _isPressed = false);
      _controller.reverse();
    }
  }

  void _onTapCancel() {
    if (widget.onTap != null) {
      setState(() => _isPressed = false);
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final elevationMultiplier = _isPressed ? 0.5 : 1.0;

    final card = AnimatedContainer(
      duration: AppAnimation.fast,
      curve: AppAnimation.curve,
      decoration: BoxDecoration(
        color: widget.gradient == null ? widget.color : null,
        gradient: widget.gradient,
        borderRadius: BorderRadius.circular(widget.radius),
        border: Border.all(
          color:
              widget.borderColor ?? AppColors.outline.withValues(alpha: 0.58),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0x26E8C8B4),
            blurRadius: 22 * elevationMultiplier,
            offset: Offset(0, 10 * elevationMultiplier),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: const Color(0x12E8C8B4),
            blurRadius: 42 * elevationMultiplier,
            offset: Offset(0, 18 * elevationMultiplier),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.radius),
        child: Stack(
          children: [
            // 高光效果
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.72),
                      Colors.white.withValues(alpha: 0.08),
                    ],
                  ),
                ),
              ),
            ),
            Padding(padding: widget.padding, child: widget.child),
          ],
        ),
      ),
    );

    if (widget.onTap == null) {
      return card;
    }

    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: widget.onTap,
        child: card,
      ),
    );
  }
}

class SoftChip extends StatefulWidget {
  const SoftChip({
    required this.label,
    this.selected = false,
    this.icon,
    this.onTap,
    this.dense = true,
    super.key,
  });

  final String label;
  final bool selected;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool dense;

  @override
  State<SoftChip> createState() => _SoftChipState();
}

class _SoftChipState extends State<SoftChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimation.fast,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
  }

  @override
  void didUpdateWidget(SoftChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected != oldWidget.selected && widget.selected) {
      _controller.forward().then((_) => _controller.reverse());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final background = widget.selected
        ? AppColors.primaryContainer.withValues(alpha: 0.92)
        : AppColors.surface;
    final foreground =
        widget.selected ? AppColors.onPrimaryContainer : AppColors.textMuted;

    final child = ScaleTransition(
      scale: _scaleAnimation,
      child: AnimatedContainer(
        duration: AppAnimation.normal,
        curve: AppAnimation.curve,
        padding: EdgeInsets.symmetric(
          horizontal: widget.dense ? 14 : 18,
          vertical: widget.dense ? 8 : 11,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: widget.selected
                ? AppColors.primary.withValues(alpha: 0.28)
                : AppColors.outline.withValues(alpha: 0.9),
            width: 1.0,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
          boxShadow: widget.selected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.icon != null) ...[
              AnimatedRotation(
                turns: widget.selected ? 0.05 : 0.0,
                duration: AppAnimation.normal,
                child: Icon(widget.icon, size: 15, color: foreground),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              widget.label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: foreground,
                    fontWeight:
                        widget.selected ? FontWeight.w700 : FontWeight.w500,
                    letterSpacing: 0,
                  ),
            ),
          ],
        ),
      ),
    );

    if (widget.onTap == null) {
      return child;
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: child,
    );
  }
}

class FoodImageTile extends StatelessWidget {
  const FoodImageTile({
    required this.title,
    this.height = 88,
    this.icon = Icons.restaurant,
    super.key,
  });

  final String title;
  final double height;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(title);
    final foodMark = _foodMarkFor(title);
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.18),
            color.withValues(alpha: 0.08),
            AppColors.surface,
            AppColors.surfaceLow.withValues(alpha: 0.6),
          ],
          stops: const [0.0, 0.3, 0.7, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // 背景装饰图标
          Positioned(
            right: -14,
            bottom: -18,
            child: Icon(
              icon,
              size: height * 0.9,
              color: color.withValues(alpha: 0.12),
            ),
          ),
          // 额外的装饰元素
          Positioned(
            left: -20,
            top: -20,
            child: Container(
              width: height * 0.5,
              height: height * 0.5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    color.withValues(alpha: 0.15),
                    color.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          // 标签
          Positioned(
            left: 10,
            top: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(AppRadius.full),
                border: Border.all(
                  color: color.withValues(alpha: 0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                _shortDishLabel(title),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.text,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
              ),
            ),
          ),
          // 中心emoji
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 外层光晕
                Container(
                  width: height * 0.75,
                  height: height * 0.75,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        color.withValues(alpha: 0.0),
                        color.withValues(alpha: 0.05),
                      ],
                    ),
                  ),
                ),
                // 白色背景圆
                Container(
                  width: height * 0.65,
                  height: height * 0.65,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.12),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: color.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
                // 内圈彩色圆
                Container(
                  width: height * 0.52,
                  height: height * 0.52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color.withValues(alpha: 0.15),
                        color.withValues(alpha: 0.08),
                      ],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: color.withValues(alpha: 0.25),
                      width: 1.5,
                    ),
                  ),
                ),
                // Emoji with shadow
                Container(
                  padding: EdgeInsets.all(height * 0.02),
                  child: Text(
                    foodMark,
                    style: TextStyle(
                      fontSize: height * 0.32,
                      height: 1,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          offset: const Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _colorFor(String value) {
    final colors = [
      AppColors.primary,
      AppColors.sage,
      AppColors.blueGray,
      AppColors.peach,
    ];
    return colors[value.hashCode.abs() % colors.length];
  }

  String _foodMarkFor(String value) {
    if (value.contains('鸡') || value.contains('翅')) {
      return '🍗';
    }
    if (value.contains('牛') || value.contains('肉')) {
      return '🥩';
    }
    if (value.contains('鱼') || value.contains('虾')) {
      return '🍤';
    }
    if (value.contains('面') || value.contains('粉')) {
      return '🍜';
    }
    if (value.contains('汤') || value.contains('热乎')) {
      return '🥣';
    }
    if (value.contains('番茄') || value.contains('蛋')) {
      return '🍅';
    }
    if (value.contains('菜') || value.contains('黄瓜')) {
      return '🥬';
    }
    if (value.contains('饭') || value.contains('米')) {
      return '🍚';
    }
    return '🍽️';
  }

  String _shortDishLabel(String value) {
    final firstDish = value.split('+').first.trim();
    if (firstDish.length <= 5) {
      return firstDish;
    }
    return '${firstDish.substring(0, 5)}...';
  }
}

class DishCoverImage extends StatelessWidget {
  const DishCoverImage({
    required this.title,
    this.imageUrl,
    this.height = 88,
    this.icon = Icons.restaurant,
    super.key,
  });

  final String title;
  final String? imageUrl;
  final double height;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final url = _absoluteImageUrl(imageUrl);
    if (url == null) {
      return FoodImageTile(title: title, height: height, icon: icon);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Image.network(
        url,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            FoodImageTile(title: title, height: height, icon: icon),
      ),
    );
  }

  String? _absoluteImageUrl(String? value) {
    final raw = value?.trim();
    if (raw == null || raw.isEmpty) {
      return null;
    }
    final uri = Uri.tryParse(raw);
    if (uri != null && uri.hasScheme) {
      return raw;
    }
    final apiBase = Uri.tryParse(AppConfig.apiBaseUrl);
    if (apiBase == null) {
      return raw;
    }
    return apiBase
        .replace(path: raw.startsWith('/') ? raw : '/$raw')
        .toString();
  }
}

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    required this.gender,
    this.avatarUrl,
    this.radius = 24,
    this.backgroundColor = AppColors.surfaceHigh,
    super.key,
  });

  final UserGender gender;
  final String? avatarUrl;
  final double radius;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final url = _absoluteImageUrl(avatarUrl);
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      backgroundImage: url == null
          ? AssetImage(_assetForGender(gender))
          : NetworkImage(url) as ImageProvider,
    );
  }

  String _assetForGender(UserGender gender) {
    return switch (gender) {
      UserGender.female => 'assets/avatars/avatar_female.png',
      UserGender.male => 'assets/avatars/avatar_male.png',
      UserGender.unspecified => 'assets/avatars/avatar_unspecified.png',
    };
  }

  String? _absoluteImageUrl(String? value) {
    final raw = value?.trim();
    if (raw == null || raw.isEmpty) {
      return null;
    }
    final uri = Uri.tryParse(raw);
    if (uri != null && uri.hasScheme) {
      return raw;
    }
    final apiBase = Uri.tryParse(AppConfig.apiBaseUrl);
    if (apiBase == null) {
      return raw;
    }
    return apiBase
        .replace(path: raw.startsWith('/') ? raw : '/$raw')
        .toString();
  }
}

class WarmTopBar extends StatelessWidget {
  const WarmTopBar({
    required this.title,
    this.subtitle,
    this.leading,
    this.actions = const [],
    this.centerTitle = false,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget> actions;
  final bool centerTitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: centerTitle
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment:
                      centerTitle ? Alignment.center : Alignment.centerLeft,
                  child: Text(
                    title,
                    textAlign: centerTitle ? TextAlign.center : TextAlign.start,
                    maxLines: 1,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.text,
                          fontWeight: FontWeight.w600,
                          fontSize: 28,
                          height: 34 / 28,
                          letterSpacing: 0,
                        ),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    subtitle!,
                    textAlign: centerTitle ? TextAlign.center : TextAlign.start,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                          height: 1.4,
                        ),
                  ),
                ],
              ],
            ),
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(width: 8),
            ...actions,
          ],
        ],
      ),
    );
  }
}

class NotificationBell extends ConsumerWidget {
  const NotificationBell({this.color, super.key});

  final Color? color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(
      notificationsControllerProvider.select(
        (state) => state.valueOrNull?.unreadCount ?? 0,
      ),
    );
    final label = unreadCount > 99 ? '99+' : unreadCount.toString();

    return IconButton(
      tooltip: unreadCount == 0 ? '通知' : '$unreadCount 条未读通知',
      onPressed: () => context.push('/notifications'),
      icon: Badge(
        isLabelVisible: unreadCount > 0,
        backgroundColor: AppColors.coral,
        textColor: AppColors.onPrimary,
        label: Text(label),
        child: Icon(Icons.notifications_none, color: color),
      ),
    );
  }
}

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({required this.current, super.key});

  final String current;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(
            color: AppColors.outline.withValues(alpha: 0.62),
            width: 1.0,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0x24E8C8B4),
            blurRadius: 26,
            offset: const Offset(0, -10),
            spreadRadius: 0,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 82,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                selectedIcon: Icons.home_rounded,
                label: '许愿池',
                selected: current == 'pool',
                onTap: () => context.go('/'),
              ),
              _NavItem(
                icon: Icons.menu_book_outlined,
                selectedIcon: Icons.menu_book_rounded,
                label: '菜库',
                selected: current == 'dishes',
                onTap: () => context.go('/dishes'),
              ),
              _CreateWishNavItem(onTap: () => context.push('/wish/new')),
              _NavItem(
                icon: Icons.history_edu_outlined,
                selectedIcon: Icons.history_edu_rounded,
                label: '记录',
                selected: current == 'records',
                onTap: () => context.go('/records'),
              ),
              _NavItem(
                icon: Icons.person_outline,
                selectedIcon: Icons.person_rounded,
                label: '我的',
                selected: current == 'profile',
                onTap: () => context.go('/profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreateWishNavItem extends StatefulWidget {
  const _CreateWishNavItem({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_CreateWishNavItem> createState() => _CreateWishNavItemState();
}

class _CreateWishNavItemState extends State<_CreateWishNavItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimation.normal,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _controller, curve: AppAnimation.curve),
    );
    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.forward().then((_) => _controller.reverse());
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: RotationTransition(
                turns: _rotationAnimation,
                child: Container(
                  width: 58,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.32),
                        blurRadius: 22,
                        offset: const Offset(0, 10),
                        spreadRadius: -2,
                      ),
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.58),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.add_rounded,
                      color: AppColors.onPrimary, size: 28),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '许愿',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.selectedIcon,
  });

  final IconData icon;
  final IconData? selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimation.fast,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    if (widget.selected) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(_NavItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected != oldWidget.selected) {
      if (widget.selected) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.selected ? AppColors.primary : AppColors.textLight;
    final displayIcon = widget.selected && widget.selectedIcon != null
        ? widget.selectedIcon!
        : widget.icon;

    return GestureDetector(
      onTap: widget.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: AnimatedContainer(
                duration: AppAnimation.normal,
                curve: AppAnimation.curve,
                width: 40,
                height: 32,
                decoration: BoxDecoration(
                  gradient: widget.selected
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primaryContainer.withValues(alpha: 0.95),
                            AppColors.primaryLight.withValues(alpha: 0.46),
                          ],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Icon(
                  displayIcon,
                  color: color,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: AppAnimation.normal,
              curve: AppAnimation.curve,
              style: Theme.of(context).textTheme.labelSmall!.copyWith(
                    color: color,
                    fontWeight:
                        widget.selected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 11,
                  ),
              child: Text(widget.label),
            ),
          ],
        ),
      ),
    );
  }
}
