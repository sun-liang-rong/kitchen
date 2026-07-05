import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitchen_wish_well/app.dart';
import 'package:kitchen_wish_well/features/wish_detail/presentation/pages/wish_detail_page.dart';
import '../../test_session.dart';

void main() {
  testWidgets('shows a friendly state when wish is missing', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          boundSessionOverride,
          notificationsOverride,
          seededWishPoolOverride,
        ],
        child: const MaterialApp(
          home: WishDetailPage(wishId: 'missing-wish'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('愿望详情'), findsOneWidget);
    expect(find.text('愿望不存在、已被删除，或当前账号没有权限查看。'), findsOneWidget);
  });

  testWidgets('responds confirms and fulfills from detail page',
      (tester) async {
    tester.view.physicalSize = const Size(430, 1200);
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

    await tester.tap(find.text('可乐鸡翅').first);
    await tester.pumpAndSettle();

    expect(find.text('愿望详情'), findsOneWidget);
    await tester.tap(find.text('我接住'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('今晚我来实现'));
    await tester.tap(find.text('发给她'));
    await tester.pumpAndSettle();

    expect(find.text('她同意了'), findsNothing);
    expect(find.text('已认领'), findsWidgets);

    await tester.tap(find.text('吃完啦').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('今天很好吃'));
    await tester.tap(find.text('记录兑现').last);
    await tester.pumpAndSettle();

    expect(find.text('已兑现'), findsWidgets);
  });
}
