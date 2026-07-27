import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:atom_flt/theme/theme_provider.dart';
import 'package:atom_flt/editor/editor_controller.dart';
import 'package:atom_flt/app.dart';

void main() {
  testWidgets('App renders without error', (tester) async {
    final themeProvider = ThemeProvider();
    final editorController = EditorController();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: themeProvider),
          ChangeNotifierProvider.value(value: editorController),
        ],
        child: const AtomFlApp(),
      ),
    );

    expect(find.byType(AtomFlApp), findsOneWidget);
    expect(find.text('Untitled'), findsWidgets);
  });
}
