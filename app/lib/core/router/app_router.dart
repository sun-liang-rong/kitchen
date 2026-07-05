import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/session_gate.dart';
import '../../features/dishes/presentation/pages/home_dishes_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/wish_detail/presentation/pages/wish_detail_page.dart';
import '../../features/wish_pool/presentation/pages/create_wish_page.dart';
import '../../features/wish_pool/presentation/pages/fulfillment_records_page.dart';

final appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      pageBuilder: (context, state) =>
          _noTransitionPage(state, const SessionGate()),
      routes: [
        GoRoute(
          path: 'wish/new',
          pageBuilder: (context, state) =>
              _noTransitionPage(state, const CreateWishPage()),
        ),
        GoRoute(
          path: 'wish/:id',
          builder: (context, state) => WishDetailPage(
            wishId: state.pathParameters['id']!,
          ),
        ),
        GoRoute(
          path: 'dishes',
          pageBuilder: (context, state) =>
              _noTransitionPage(state, const HomeDishesPage()),
        ),
        GoRoute(
          path: 'records',
          pageBuilder: (context, state) =>
              _noTransitionPage(state, const FulfillmentRecordsPage()),
        ),
        GoRoute(
          path: 'profile',
          pageBuilder: (context, state) =>
              _noTransitionPage(state, const ProfilePage()),
        ),
        GoRoute(
          path: 'notifications',
          builder: (context, state) => const NotificationsPage(),
        ),
      ],
    ),
  ],
);

Page<void> _noTransitionPage(GoRouterState state, Widget child) {
  return NoTransitionPage<void>(
    key: state.pageKey,
    child: child,
  );
}
