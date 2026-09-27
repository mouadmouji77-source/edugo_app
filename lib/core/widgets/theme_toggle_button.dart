import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/theme_provider.dart';

/// Button widget to toggle between light and dark theme
class ThemeToggleButton extends ConsumerWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return IconButton(
      icon: Icon(
        isDark ? Icons.light_mode : Icons.dark_mode,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      tooltip: isDark ? 'Light Mode' : 'Dark Mode',
      onPressed: () {
        ref.read(themeModeProvider.notifier).toggleTheme();
      },
    );
  }
}

