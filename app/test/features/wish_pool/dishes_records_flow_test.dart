import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitchen_wish_well/app.dart';
import '../../test_session.dart';

void main() {
  testWidgets('fulfillment appears in records and home dishes', (tester) async {
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
    await tester.tap(find.text('我接住'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('今晚我来实现'));
    await tester.tap(find.text('发给她'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('吃完啦').first);
    await tester.pumpAndSettle();
    expect(find.text('这次完成了哪些搭手'), findsOneWidget);
    await tester.tap(find.text('洗菜').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('记录兑现').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    await tester.tap(find.text('记录'));
    await tester.pumpAndSettle();
    expect(find.text('兑现记录'), findsOneWidget);
    expect(find.text('可乐鸡翅'), findsWidgets);
    expect(find.textContaining('搭手：饭后收桌'), findsOneWidget);
    expect(find.textContaining('搭手：洗菜'), findsNothing);

    await tester.tap(find.text('菜库'));
    await tester.pumpAndSettle();
    expect(find.text('我们家的菜'), findsOneWidget);
    expect(find.text('可乐鸡翅'), findsWidgets);

    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText).first, '可乐');
    await tester.pumpAndSettle();
    expect(find.text('可乐鸡翅'), findsWidgets);
    expect(find.text('番茄鸡蛋面'), findsNothing);

    await tester.tap(find.byIcon(Icons.clear));
    await tester.pumpAndSettle();

    await tester.tap(find.text('今晚就吃'));
    await tester.pumpAndSettle();
    expect(find.textContaining('可乐鸡翅'), findsWidgets);

    await tester.tap(find.text('菜库'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.filter_list));
    await tester.pumpAndSettle();
    await tester.tap(find.text('简单').last);
    await tester.tap(find.text('应用'));
    await tester.pumpAndSettle();
    expect(find.text('番茄鸡蛋面'), findsWidgets);
    expect(find.text('简单'), findsWidgets);

    await tester.tap(find.byIcon(Icons.filter_list));
    await tester.pumpAndSettle();
    await tester.tap(find.text('重置'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('新增'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText).first, '青椒肉丝');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(find.text('青椒肉丝'), findsWidgets);
  });
}
