import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/theme_provider.dart';
import 'theme/app_theme.dart';
import 'editor/editor_screen.dart';

class AtomFlApp extends StatelessWidget {
  const AtomFlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (_, theme, child) => MaterialApp(
        title: 'atom_flt',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: theme.themeMode,
        home: const EditorScreen(),
      ),
    );
  }
}
