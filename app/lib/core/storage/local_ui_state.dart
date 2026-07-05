import 'package:hive_flutter/hive_flutter.dart';

class LocalUiState {
  const LocalUiState._();

  static const boxName = 'local_ui_state';
  static const _spiritDockXKey = 'spirit_dock_x';
  static const _spiritDockYKey = 'spirit_dock_y';

  static Box<Object?>? get _box {
    if (!Hive.isBoxOpen(boxName)) {
      return null;
    }
    return Hive.box<Object?>(boxName);
  }

  static Future<void> initialize() async {
    await Hive.initFlutter();
    await Hive.openBox<Object?>(boxName);
  }

  static ({double x, double y})? readSpiritDock() {
    final box = _box;
    if (box == null) {
      return null;
    }
    final x = box.get(_spiritDockXKey);
    final y = box.get(_spiritDockYKey);
    if (x is num && y is num) {
      return (x: x.toDouble(), y: y.toDouble());
    }
    return null;
  }

  static Future<void> saveSpiritDock(double x, double y) async {
    final box = _box;
    if (box == null) {
      return;
    }
    await box.put(_spiritDockXKey, x);
    await box.put(_spiritDockYKey, y);
  }
}
