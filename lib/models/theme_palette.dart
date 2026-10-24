import 'package:flutter/material.dart';

enum CalculatorThemeType {
  onyxGold,
  obsidianCyan,
  emeraldSlate,
  crimsonRuby,
  platinumLight,
}

class PremiumPalette {
  final String name;
  final CalculatorThemeType type;
  final bool isDark;

  // Solid background colors (strictly no gradients)
  final Color backgroundColor;
  final Color displayCardColor;
  final Color numButtonColor;
  final Color numTextColor;
  final Color funcButtonColor;
  final Color funcTextColor;
  final Color opButtonColor;
  final Color opTextColor;
  final Color equalButtonColor;
  final Color equalTextColor;
  final Color accentColor;
  final Color secondaryTextColor;
  final Color menuBackgroundColor;
  final Color rippleColor;

  const PremiumPalette({
    required this.name,
    required this.type,
    required this.isDark,
    required this.backgroundColor,
    required this.displayCardColor,
    required this.numButtonColor,
    required this.numTextColor,
    required this.funcButtonColor,
    required this.funcTextColor,
    required this.opButtonColor,
    required this.opTextColor,
    required this.equalButtonColor,
    required this.equalTextColor,
    required this.accentColor,
    required this.secondaryTextColor,
    required this.menuBackgroundColor,
    required this.rippleColor,
  });

  static const PremiumPalette onyxGold = PremiumPalette(
    name: 'Onyx & Gold',
    type: CalculatorThemeType.onyxGold,
    isDark: true,
    backgroundColor: Color(0xFF0D0D11),
    displayCardColor: Color(0xFF15151B),
    numButtonColor: Color(0xFF1E1E26),
    numTextColor: Color(0xFFF6F6F9),
    funcButtonColor: Color(0xFF2A2B36),
    funcTextColor: Color(0xFFDCDCE5),
    opButtonColor: Color(0xFFCBA135),
    opTextColor: Color(0xFF0D0D11),
    equalButtonColor: Color(0xFFE2B742),
    equalTextColor: Color(0xFF0D0D11),
    accentColor: Color(0xFFD4AF37),
    secondaryTextColor: Color(0xFF8E8E9B),
    menuBackgroundColor: Color(0xFF1A1A22),
    rippleColor: Color(0x33D4AF37),
  );

  static const PremiumPalette obsidianCyan = PremiumPalette(
    name: 'Obsidian & Cyan',
    type: CalculatorThemeType.obsidianCyan,
    isDark: true,
    backgroundColor: Color(0xFF080C14),
    displayCardColor: Color(0xFF101724),
    numButtonColor: Color(0xFF172032),
    numTextColor: Color(0xFFF0F5FA),
    funcButtonColor: Color(0xFF1F2B42),
    funcTextColor: Color(0xFF80D8FF),
    opButtonColor: Color(0xFF00B4D8),
    opTextColor: Color(0xFF080C14),
    equalButtonColor: Color(0xFF00E5FF),
    equalTextColor: Color(0xFF080C14),
    accentColor: Color(0xFF00B4D8),
    secondaryTextColor: Color(0xFF7E92AB),
    menuBackgroundColor: Color(0xFF131D2D),
    rippleColor: Color(0x3300B4D8),
  );

  static const PremiumPalette emeraldSlate = PremiumPalette(
    name: 'Emerald & Slate',
    type: CalculatorThemeType.emeraldSlate,
    isDark: true,
    backgroundColor: Color(0xFF09120D),
    displayCardColor: Color(0xFF101E17),
    numButtonColor: Color(0xFF172920),
    numTextColor: Color(0xFFF1F8F4),
    funcButtonColor: Color(0xFF20382C),
    funcTextColor: Color(0xFFA7F3D0),
    opButtonColor: Color(0xFF10B981),
    opTextColor: Color(0xFF09120D),
    equalButtonColor: Color(0xFF34D399),
    equalTextColor: Color(0xFF09120D),
    accentColor: Color(0xFF10B981),
    secondaryTextColor: Color(0xFF7B9B88),
    menuBackgroundColor: Color(0xFF13231A),
    rippleColor: Color(0x3310B981),
  );

  static const PremiumPalette crimsonRuby = PremiumPalette(
    name: 'Crimson & Ruby',
    type: CalculatorThemeType.crimsonRuby,
    isDark: true,
    backgroundColor: Color(0xFF0B0B0D),
    displayCardColor: Color(0xFF161519),
    numButtonColor: Color(0xFF201F25),
    numTextColor: Color(0xFFFDF8F9),
    funcButtonColor: Color(0xFF2E2C36),
    funcTextColor: Color(0xFFFFB3BA),
    opButtonColor: Color(0xFFE63946),
    opTextColor: Color(0xFFFFFFFF),
    equalButtonColor: Color(0xFFFF4D5A),
    equalTextColor: Color(0xFFFFFFFF),
    accentColor: Color(0xFFE63946),
    secondaryTextColor: Color(0xFF9E8F94),
    menuBackgroundColor: Color(0xFF1B1920),
    rippleColor: Color(0x33E63946),
  );

  static const PremiumPalette platinumLight = PremiumPalette(
    name: 'Platinum Minimalist',
    type: CalculatorThemeType.platinumLight,
    isDark: false,
    backgroundColor: Color(0xFFF3F4F8),
    displayCardColor: Color(0xFFFFFFFF),
    numButtonColor: Color(0xFFE6E8EF),
    numTextColor: Color(0xFF18191E),
    funcButtonColor: Color(0xFFDADDE8),
    funcTextColor: Color(0xFF2B3347),
    opButtonColor: Color(0xFF2563EB),
    opTextColor: Color(0xFFFFFFFF),
    equalButtonColor: Color(0xFF1D4ED8),
    equalTextColor: Color(0xFFFFFFFF),
    accentColor: Color(0xFF2563EB),
    secondaryTextColor: Color(0xFF6B7280),
    menuBackgroundColor: Color(0xFFFFFFFF),
    rippleColor: Color(0x222563EB),
  );

  static List<PremiumPalette> get allThemes => [
        onyxGold,
        obsidianCyan,
        emeraldSlate,
        crimsonRuby,
        platinumLight,
      ];

  static PremiumPalette fromType(CalculatorThemeType type) {
    switch (type) {
      case CalculatorThemeType.onyxGold:
        return onyxGold;
      case CalculatorThemeType.obsidianCyan:
        return obsidianCyan;
      case CalculatorThemeType.emeraldSlate:
        return emeraldSlate;
      case CalculatorThemeType.crimsonRuby:
        return crimsonRuby;
      case CalculatorThemeType.platinumLight:
        return platinumLight;
    }
  }
}
