import 'package:flutter/material.dart';

import 'colors.dart';

ThemeData buildLoomTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: LoomColors.moss,
    brightness: Brightness.light,
    surface: LoomColors.surface,
  );

  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: LoomColors.paper,
    appBarTheme: const AppBarTheme(
      backgroundColor: LoomColors.paper,
      foregroundColor: LoomColors.ink,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: LoomColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: LoomColors.line),
      ),
    ),
    textTheme: Typography.blackMountainView.apply(
      bodyColor: LoomColors.ink,
      displayColor: LoomColors.ink,
    ),
    useMaterial3: true,
  );
}
