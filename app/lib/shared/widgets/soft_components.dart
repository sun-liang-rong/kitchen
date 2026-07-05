import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/notifications/presentation/providers/notifications_controller.dart';
import '../ui/design_tokens.dart';

class SoftCard extends StatelessWidget {
  const SoftCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color = AppColors.surface,
    this.borderColor,
    this.onTap,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final Color? borderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: borderColor ?? AppColors.outline.withValues(alpha: 0.55),
          width: 0.7,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12A9371F),
            blurRadius: 22,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );

    if (onTap == null) {
      return card;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: card,
      ),
    );
  }
}

class SoftChip extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final background =
        selected ? AppColors.primaryContainer : AppColors.surfaceLow;
    final foreground =
        selected ? AppColors.onPrimaryContainer : AppColors.textMuted;
    final child = AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 12 : 16,
        vertical: dense ? 7 : 10,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.55)
              : AppColors.outline.withValues(alpha: 0.55),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: foreground,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
          ),
        ],
      ),
    );

    if (onTap == null) {
      return child;
    }

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.full),
      onTap: onTap,
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
            color.withValues(alpha: 0.14),
            AppColors.surface,
            AppColors.surfaceLow,
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -14,
            bottom: -18,
            child: Icon(
              icon,
              size: height * 0.9,
              color: color.withValues(alpha: 0.16),
            ),
          ),
          Positioned(
            left: 10,
            top: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.82),
                borderRadius: BorderRadius.circular(AppRadius.full),
                border: Border.all(
                  color: AppColors.outline.withValues(alpha: 0.35),
                ),
              ),
              child: Text(
                _shortDishLabel(title),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ),
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: height * 0.68,
                  height: height * 0.68,
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.92),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryDeep.withValues(alpha: 0.1),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: height * 0.5,
                  height: height * 0.5,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withValues(alpha: 0.18)),
                  ),
                ),
                Text(
                  foodMark,
                  style: TextStyle(fontSize: height * 0.28, height: 1),
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
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: centerTitle
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  textAlign: centerTitle ? TextAlign.center : TextAlign.start,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.text,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                  ),
                ],
              ],
            ),
          ),
          ...actions,
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
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.outline, width: 0.7),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x12A9371F),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                label: '许愿池',
                selected: current == 'pool',
                onTap: () => context.go('/'),
              ),
              _NavItem(
                icon: Icons.menu_book_outlined,
                label: '菜库',
                selected: current == 'dishes',
                onTap: () => context.go('/dishes'),
              ),
              _CreateWishNavItem(onTap: () => context.push('/wish/new')),
              _NavItem(
                icon: Icons.history_edu_outlined,
                label: '记录',
                selected: current == 'records',
                onTap: () => context.go('/records'),
              ),
              _NavItem(
                icon: Icons.person_outline,
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

class _CreateWishNavItem extends StatelessWidget {
  const _CreateWishNavItem({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.full),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 46,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppRadius.full),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryDeep.withValues(alpha: 0.24),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child:
                  const Icon(Icons.add, color: AppColors.onPrimary, size: 24),
            ),
            const SizedBox(height: 3),
            Text(
              '许愿',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.primaryDeep,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primaryDeep : AppColors.blueGray;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.full),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 34,
              height: 28,
              decoration: BoxDecoration(
                color:
                    selected ? AppColors.primaryContainer : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Icon(icon,
                  color: selected ? AppColors.primary : color, size: 18),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
