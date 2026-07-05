import 'package:flutter/material.dart';

class AppColors {
  // 背景色系
  static const background = Color(0xFFFFF8F3);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceLow = Color(0xFFFFF0E8);
  static const surfaceContainer = Color(0xFFFFE6DA);
  static const surfaceHigh = Color(0xFFFFD7C6);
  static const paper = Color(0xFFFFFCF8);
  static const inkSoft = Color(0xFF4B403B);

  // 主色系
  static const primary = Color(0xFFF7A989);
  static const primaryDeep = Color(0xFFC87351);
  static const primaryLight = Color(0xFFFBC5AD);
  static const primaryContainer = Color(0xFFFFE8DD);
  static const onPrimary = Color(0xFFFFFFFF);
  static const onPrimaryContainer = Color(0xFF9D583D);

  // 文字色系
  static const text = Color(0xFF2C2C2C);
  static const textMuted = Color(0xFF665953);
  static const textLight = Color(0xFFA8978F);

  // 辅助色系
  static const outline = Color(0x33F7A989);
  static const outlineLight = Color(0x1FF7A989);
  static const mine = Color(0xFFF9C9B4);
  static const partner = Color(0xFFF4B9BC);
  static const sage = Color(0xFF8AAE93);
  static const blueGray = Color(0xFF7D8A93);
  static const sky = Color(0xFFDCEBFA);
  static const cream = Color(0xFFFFF4D8);
  static const peach = Color(0xFFF9C9B4);
  static const coral = Color(0xFFE47F70);
  static const apricot = Color(0xFFFFDCCB);
  static const butter = Color(0xFFFFE7A8);
  static const mint = Color(0xFFDDEDDC);
  static const lavender = Color(0xFFEADFEB);
  static const mocha = Color(0xFFB98A70);

  // 状态色
  static const success = Color(0xFF52C41A);
  static const successLight = Color(0xFFF6FFED);
  static const warning = Color(0xFFFAAD14);
  static const warningLight = Color(0xFFFFFBE6);
  static const info = Color(0xFF1890FF);
  static const infoLight = Color(0xFFE6F7FF);

  // 渐变色
  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF7A989), Color(0xFFFBC5AD)],
  );

  static const accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFF3EC), Color(0xFFFFDFD1)],
  );

  static const coverGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFF7EF), Color(0xFFFFDFCF), Color(0xFFFFF1DF)],
    stops: [0.0, 0.58, 1.0],
  );

  static const paperGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFFFFF), Color(0xFFFFFAF4)],
  );

  static const surfaceGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFFDFC), Color(0xFFFFF8F4)],
  );

  static const shimmerGradient = LinearGradient(
    begin: Alignment(-1.0, -0.3),
    end: Alignment(1.0, 0.3),
    colors: [
      Color(0xFFF5F5F5),
      Color(0xFFE0E0E0),
      Color(0xFFF5F5F5),
    ],
  );
}

class AppSpacing {
  static const xxs = 2.0;
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
}

class AppRadius {
  static const xs = 4.0;
  static const sm = 10.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const full = 999.0;
}

class AppElevation {
  static const none = 0.0;
  static const sm = 2.0;
  static const md = 4.0;
  static const lg = 8.0;
  static const xl = 16.0;
  static const magazineShadow = 26.0;
}

class AppAnimation {
  static const fast = Duration(milliseconds: 150);
  static const normal = Duration(milliseconds: 250);
  static const slow = Duration(milliseconds: 350);
  static const verySlow = Duration(milliseconds: 500);

  static const curve = Curves.easeInOutCubic;
  static const bounceCurve = Curves.elasticOut;
  static const smoothCurve = Curves.easeOutQuart;
}
