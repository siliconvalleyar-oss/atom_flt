import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'editor/editor_controller.dart';
import 'theme/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final themeProvider = ThemeProvider();
  await themeProvider.loadPreferences();
  final editorController = EditorController();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: editorController),
      ],
      child: const AtomFlApp(),
    ),
  );
}
