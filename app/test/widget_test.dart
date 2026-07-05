import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kitchen_wish_well/app.dart';
import 'package:kitchen_wish_well/core/router/app_router.dart';
import 'package:kitchen_wish_well/features/auth/domain/auth_models.dart';
import 'package:kitchen_wish_well/features/auth/presentation/providers/session_controller.dart';
import 'package:kitchen_wish_well/features/couple/domain/couple_models.dart';
import 'package:kitchen_wish_well/features/couple/presentation/pages/binding_page.dart';
import 'package:kitchen_wish_well/features/wish_pool/domain/models/kitchen_models.dart';
import 'package:kitchen_wish_well/features/wish_pool/presentation/pages/fulfillment_records_page.dart';
import 'package:kitchen_wish_well/features/wish_pool/presentation/providers/wish_pool_controller.dart';
import 'test_session.dart';

void main() {
  testWidgets('app renders auth page first', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [signedOutSessionOverride],
        child: const KitchenWishWellApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('登录'), findsWidgets);
    expect(find.text('注册'), findsWidgets);
  });

  testWidgets('registering from auth page enters binding guide',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(420, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionControllerProvider
              .overrideWith(() => _RegisterToBindingSessionController()),
        ],
        child: const KitchenWishWellApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('注册'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText).at(0), 'new@example.com');
    await tester.enterText(find.byType(EditableText).at(1), 'secret123');
    await tester.enterText(find.byType(EditableText).at(2), '新人');
    await tester.tap(find.text('注册并进入绑定'));
    await tester.pumpAndSettle();

    expect(find.text('绑定另一半'), findsOneWidget);
    expect(find.text('我的邀请码'), findsOneWidget);
  });

  testWidgets('bound app renders wish pool and creates a wish',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(420, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          boundSessionOverride,
          notificationsOverride,
          seededWishPoolOverride,
        ],
        child: const KitchenWishWellApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('厨房许愿池'), findsOneWidget);
    expect(find.text('许愿'), findsOneWidget);
    expect(find.text('今天的饭点'), findsOneWidget);
    expect(find.text('等你接住'), findsOneWidget);

    await tester.tap(find.text('许愿'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(EditableText).first, '酸辣土豆丝');
    await tester.tap(find.text('丢进许愿池'));
    await tester.pumpAndSettle();

    expect(find.text('酸辣土豆丝'), findsWidgets);
  });

  testWidgets('profile page edits nickname', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(420, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [boundSessionOverride, notificationsOverride],
        child: const KitchenWishWellApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.person_outline).last);
    await tester.pumpAndSettle();
    expect(find.text('我'), findsWidgets);
    expect(find.byType(CircleAvatar), findsWidgets);

    await tester.tap(find.byIcon(Icons.edit));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText).first, '新的我');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(find.text('新的我'), findsOneWidget);
  });

  testWidgets('binding page shows bound partner and confirms unbind',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(420, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [boundSessionOverride],
        child: const MaterialApp(home: BindingPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('已经绑定'), findsOneWidget);
    expect(find.text('她'), findsOneWidget);
    expect(find.text('解除绑定'), findsOneWidget);
    expect(find.text('我的邀请码'), findsNothing);

    await tester.tap(find.text('解除绑定'));
    await tester.pumpAndSettle();
    expect(find.text('确认解除绑定吗'), findsOneWidget);

    await tester.tap(find.text('确认解绑'));
    await tester.pumpAndSettle();

    expect(find.text('还没有绑定'), findsOneWidget);
    expect(find.text('我的邀请码'), findsOneWidget);
  });

  testWidgets('records page shows an empty state before any fulfillment',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(420, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          boundSessionOverride,
          notificationsOverride,
          wishPoolControllerProvider
              .overrideWith(() => _EmptyRecordsController()),
        ],
        child: const MaterialApp(home: FulfillmentRecordsPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('还没有兑现记录'), findsOneWidget);
    expect(find.text('红烧鸡腿'), findsNothing);
    expect(find.text('番茄鸡蛋面'), findsNothing);
  });

  testWidgets('notification page marks an item read',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(420, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          boundSessionOverride,
          notificationsOverride,
          seededWishPoolOverride,
        ],
        child: const KitchenWishWellApp(),
      ),
    );
    await tester.pumpAndSettle();

    appRouter.go('/notifications');
    await tester.pumpAndSettle();

    expect(find.text('有新的吃饭愿望'), findsOneWidget);
    expect(find.text('未读'), findsOneWidget);

    await tester.tap(find.text('有新的吃饭愿望'));
    await tester.pumpAndSettle();
    expect(find.text('未读'), findsNothing);
    expect(find.text('可乐鸡翅'), findsWidgets);
    appRouter.go('/');
  });
}

class _EmptyRecordsController extends WishPoolController {
  @override
  WishPoolState build() {
    return WishPoolState(
      users: const [
        AppUser(id: 'me', nickname: '我', isMe: true),
        AppUser(id: 'partner', nickname: '她', isMe: false),
      ],
      wishes: const [],
      kitchenStatuses: const {},
      fulfillments: const [],
      dishes: const [],
    );
  }
}

class _RegisterToBindingSessionController extends SessionController {
  @override
  Future<SessionState> build() async {
    return const SessionState(
        binding: CoupleBinding(status: CoupleBindingStatus.unbound));
  }

  @override
  Future<void> register(
    String account,
    String password,
    String nickname, {
    UserGender gender = UserGender.unspecified,
  }) async {
    state = AsyncData(
      SessionState(
        token: 'registered-token',
        user: AuthUser(
          id: 'new-user',
          nickname: nickname,
          email: account,
          gender: gender,
        ),
        binding: const CoupleBinding(status: CoupleBindingStatus.unbound),
      ),
    );
  }
}
