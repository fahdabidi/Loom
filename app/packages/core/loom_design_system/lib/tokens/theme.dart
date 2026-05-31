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
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: LoomColors.surface,
      modalBackgroundColor: LoomColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
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
    chipTheme: ChipThemeData(
      backgroundColor: LoomColors.surfaceAlt,
      selectedColor: LoomColors.ink,
      disabledColor: LoomColors.line,
      labelStyle: const TextStyle(color: LoomColors.ink),
      secondaryLabelStyle: const TextStyle(color: LoomColors.surface),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: LoomColors.ink,
        foregroundColor: LoomColors.surface,
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: LoomColors.ink,
        minimumSize: const Size(44, 44),
        shape: const CircleBorder(),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: LoomColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: LoomColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: LoomColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: LoomColors.ink, width: 1.4),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: LoomColors.surface,
      elevation: 0,
      indicatorColor: LoomColors.ink,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          color: states.contains(WidgetState.selected)
              ? LoomColors.ink
              : LoomColors.mutedInk,
          fontSize: 12,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w600,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? LoomColors.surface
              : LoomColors.mutedInk,
          size: 22,
        ),
      ),
    ),
    textTheme: Typography.blackMountainView.apply(
      bodyColor: LoomColors.ink,
      displayColor: LoomColors.ink,
    ),
    useMaterial3: true,
  );
}
