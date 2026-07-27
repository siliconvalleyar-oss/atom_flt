import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../editor/editor_controller.dart';
import '../theme/theme_provider.dart';
import '../services/version_service.dart';

class StatusBar extends StatelessWidget {
  const StatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    final editor = context.watch<EditorController>();
    final theme = context.watch<ThemeProvider>();
    final colors = Theme.of(context).colorScheme;

    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: theme.isDarkMode
            ? const Color(0xFF252525)
            : const Color(0xFFF0F0F0),
        border: Border(
          top: BorderSide(
            color: theme.isDarkMode
                ? const Color(0xFF333333)
                : const Color(0xFFE0E0E0),
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Ln ${editor.currentLine}, Col ${editor.currentColumn}',
            style: TextStyle(
              fontSize: 12,
              color: colors.onSurface.withValues(alpha: 0.6),
              fontFamily: 'monospace',
            ),
          ),
          const Spacer(),
          Text(
            editor.fileName,
            style: TextStyle(
              fontSize: 12,
              color: colors.onSurface.withValues(alpha: 0.6),
            ),
          ),
          if (editor.isModified)
            Text(
              ' ●',
              style: TextStyle(
                fontSize: 12,
                color: colors.primary,
              ),
            ),
          const SizedBox(width: 16),
          Text(
            'UTF-8',
            style: TextStyle(
              fontSize: 12,
              color: colors.onSurface.withValues(alpha: 0.6),
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'v${VersionService.version}',
            style: TextStyle(
              fontSize: 12,
              color: colors.primary.withValues(alpha: 0.8),
              fontFamily: 'monospace',
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => context.read<ThemeProvider>().toggleTheme(),
            child: Icon(
              theme.isDarkMode ? Icons.light_mode : Icons.dark_mode,
              size: 14,
              color: colors.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
