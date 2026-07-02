import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import 'src/rust/frb_generated.dart';
import 'src/rust/api/doomforge.dart' as rust;
import 'app_state.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();
  // Give the Rust side a per-user data dir (replaces Tauri's app_data_dir()).
  final dir = await getApplicationSupportDirectory();
  await rust.setDataDir(dataDir: dir.path);

  final state = AppState();
  await state.load();

  runApp(
    ChangeNotifierProvider<AppState>.value(value: state, child: const DoomForgeApp()),
  );
}
