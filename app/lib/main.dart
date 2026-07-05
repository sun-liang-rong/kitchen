import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/storage/local_ui_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalUiState.initialize();
  runApp(const ProviderScope(child: KitchenWishWellApp()));
}
