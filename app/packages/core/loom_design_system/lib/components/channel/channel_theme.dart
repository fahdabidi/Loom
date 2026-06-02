import 'package:flutter/material.dart';

import '../../tokens/colors.dart';

class LoomChannelTheme {
  const LoomChannelTheme({
    required this.themeId,
    required this.name,
    required this.primary,
    required this.secondary,
    required this.background,
    required this.surface,
    required this.text,
    required this.accent,
  });

  factory LoomChannelTheme.fromHex({
    required String themeId,
    required String name,
    required String primaryHex,
    required String secondaryHex,
    required String backgroundHex,
    required String surfaceHex,
    required String textHex,
    required String accentHex,
  }) {
    return LoomChannelTheme(
      themeId: themeId,
      name: name,
      primary: _colorFromHex(primaryHex, LoomColors.ink),
      secondary: _colorFromHex(secondaryHex, LoomColors.aqua),
      background: _colorFromHex(backgroundHex, LoomColors.surface),
      surface: _colorFromHex(surfaceHex, Colors.white),
      text: _colorFromHex(textHex, LoomColors.ink),
      accent: _colorFromHex(accentHex, LoomColors.aqua),
    );
  }

  final String themeId;
  final String name;
  final Color primary;
  final Color secondary;
  final Color background;
  final Color surface;
  final Color text;
  final Color accent;

  static const fallback = LoomChannelTheme(
    themeId: 'loom-default',
    name: 'Loom Default',
    primary: LoomColors.ink,
    secondary: LoomColors.aqua,
    background: LoomColors.surface,
    surface: Colors.white,
    text: LoomColors.ink,
    accent: LoomColors.aqua,
  );
}

Color _colorFromHex(String value, Color fallback) {
  final cleaned = value.trim().replaceFirst('#', '');
  if (cleaned.length != 6) {
    return fallback;
  }
  final parsed = int.tryParse('FF$cleaned', radix: 16);
  return parsed == null ? fallback : Color(parsed);
}
