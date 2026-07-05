import 'package:flutter/material.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class KitchenWishWellApp extends StatelessWidget {
  const KitchenWishWellApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '厨房许愿池',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: appRouter,
    );
  }
}
