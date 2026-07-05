import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitchen_wish_well/app.dart';
import '../../test_session.dart';

void main() {
  testWidgets('responds confirms and fulfills from detail page',
      (tester) async {
    tester.view.physicalSize = const Size(430, 1200);
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
