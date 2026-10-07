import 'package:flutter/material.dart';

@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.loginBackgroundTop,
    required this.loginBackgroundBottom,
    required this.loginCard,
    required this.loginTitle,
    required this.loginSecondaryText,
    required this.actionLink,
    required this.loginButton,
    required this.avatarFill,
    required this.avatarText,
    required this.cardSurface,
    required this.mapScrim,
    required this.kpiFill,
    required this.mutedText,
    required this.borderSubtle,
    required this.success,
    required this.navBarFill,
  });

  final Color loginBackgroundTop;
  final Color loginBackgroundBottom;
  final Color loginCard;
  final Color loginTitle;
  final Color loginSecondaryText;
  final Color actionLink;
  final Color loginButton;
  final Color avatarFill;
  final Color avatarText;
  final Color cardSurface;
  final Color mapScrim;
  final Color kpiFill;
  final Color mutedText;
  final Color borderSubtle;
  final Color success;
  final Color navBarFill;

  static const AppPalette light = AppPalette(
    loginBackgroundTop: Color(0xFFF5F7FA),
    loginBackgroundBottom: Color(0xFFC3CFE2),
    loginCard: Color(0xFF1E4F8A),
    loginTitle: Color(0xFFFFFFFF),
    loginSecondaryText: Color(0xFFD6E4F5),
    actionLink: Color(0xFFFFFFFF),
    loginButton: Color(0xFFC1121F),
    avatarFill: Color(0xFFD6E4F5),
    avatarText: Color(0xFF0B2F63),
    cardSurface: AppTheme.surfaceLight,
    mapScrim: Color(0xE6F7F9FC),
    kpiFill: AppTheme.surfaceLight,
    mutedText: Color(0xFF475569),
    borderSubtle: Color(0x1A0B2F63),
    success: Color(0xFF198754),
    navBarFill: AppTheme.surfaceLight,
  );

  static const AppPalette dark = AppPalette(
    loginBackgroundTop: Color(0xFF071422),
    loginBackgroundBottom: Color(0xFF0B2F63),
    loginCard: Color(0xFF12315A),
    loginTitle: Color(0xFFF2F6FC),
    loginSecondaryText: Color(0xFFB7C7DC),
    actionLink: Color(0xFF9DC0F0),
    loginButton: Color(0xFFEC1F24),
    avatarFill: Color(0xFF1A3A64),
    avatarText: Color(0xFFF2F6FC),
    cardSurface: Color(0xFF122844),
    mapScrim: Color(0xD6071422),
    kpiFill: Color(0xFF122844),
    mutedText: Color(0xFFB7C7DC),
    borderSubtle: Color(0x33FFFFFF),
    success: Color(0xFF34D399),
    navBarFill: Color(0xFF0E1F36),
  );

  static AppPalette of(BuildContext context) {
    return Theme.of(context).extension<AppPalette>() ??
        (Theme.of(context).brightness == Brightness.dark ? dark : light);
  }

  @override
  AppPalette copyWith({
    Color? loginBackgroundTop,
    Color? loginBackgroundBottom,
    Color? loginCard,
    Color? loginTitle,
    Color? loginSecondaryText,
    Color? actionLink,
    Color? loginButton,
    Color? avatarFill,
    Color? avatarText,
    Color? cardSurface,
    Color? mapScrim,
    Color? kpiFill,
    Color? mutedText,
    Color? borderSubtle,
    Color? success,
    Color? navBarFill,
  }) {
    return AppPalette(
      loginBackgroundTop: loginBackgroundTop ?? this.loginBackgroundTop,
      loginBackgroundBottom:
          loginBackgroundBottom ?? this.loginBackgroundBottom,
      loginCard: loginCard ?? this.loginCard,
      loginTitle: loginTitle ?? this.loginTitle,
      loginSecondaryText: loginSecondaryText ?? this.loginSecondaryText,
      actionLink: actionLink ?? this.actionLink,
      loginButton: loginButton ?? this.loginButton,
      avatarFill: avatarFill ?? this.avatarFill,
      avatarText: avatarText ?? this.avatarText,
      cardSurface: cardSurface ?? this.cardSurface,
      mapScrim: mapScrim ?? this.mapScrim,
      kpiFill: kpiFill ?? this.kpiFill,
      mutedText: mutedText ?? this.mutedText,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      success: success ?? this.success,
      navBarFill: navBarFill ?? this.navBarFill,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) {
      return this;
    }
    return AppPalette(
      loginBackgroundTop:
          Color.lerp(loginBackgroundTop, other.loginBackgroundTop, t)!,
      loginBackgroundBottom:
          Color.lerp(loginBackgroundBottom, other.loginBackgroundBottom, t)!,
      loginCard: Color.lerp(loginCard, other.loginCard, t)!,
      loginTitle: Color.lerp(loginTitle, other.loginTitle, t)!,
      loginSecondaryText:
          Color.lerp(loginSecondaryText, other.loginSecondaryText, t)!,
      actionLink: Color.lerp(actionLink, other.actionLink, t)!,
      loginButton: Color.lerp(loginButton, other.loginButton, t)!,
      avatarFill: Color.lerp(avatarFill, other.avatarFill, t)!,
      avatarText: Color.lerp(avatarText, other.avatarText, t)!,
      cardSurface: Color.lerp(cardSurface, other.cardSurface, t)!,
      mapScrim: Color.lerp(mapScrim, other.mapScrim, t)!,
      kpiFill: Color.lerp(kpiFill, other.kpiFill, t)!,
      mutedText: Color.lerp(mutedText, other.mutedText, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      success: Color.lerp(success, other.success, t)!,
      navBarFill: Color.lerp(navBarFill, other.navBarFill, t)!,
    );
  }
}

class AppTheme {
  const AppTheme._();

  static const Color brandPrimary = Color(0xFF0B2F63);
  static const Color brandSecondary = Color(0xFF1E4F8A);
  static const Color railwayRed = Color(0xFFC1121F);
  static const Color scaffoldLight = Color(0xFFF3F5F8);
  static const Color surfaceLight = Color(0xFFF8FAFC);
  static const Color scaffoldDark = Color(0xFF071422);

  static ThemeData get light {
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: brandPrimary,
    ).copyWith(
      primary: brandPrimary,
      onPrimary: Colors.white,
      secondary: brandSecondary,
      onSecondary: Colors.white,
      tertiary: railwayRed,
      surface: surfaceLight,
      surfaceBright: surfaceLight,
      surfaceContainerLowest: surfaceLight,
      surfaceContainerLow: surfaceLight,
      onSurface: const Color(0xFF0F172A),
      surfaceContainerHighest: const Color(0xFFE8EEF7),
      outlineVariant: const Color(0xFFD5DEEB),
    );
    return _applyCommon(
      ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: scaffoldLight,
        extensions: const <ThemeExtension<dynamic>>[AppPalette.light],
      ),
    );
  }

  static ThemeData get dark {
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: brandSecondary,
      brightness: Brightness.dark,
    ).copyWith(
      primary: const Color(0xFF7BA3D9),
      onPrimary: const Color(0xFF071422),
      secondary: const Color(0xFF4C7DC0),
      onSecondary: Colors.white,
      tertiary: const Color(0xFFEC1F24),
      surface: const Color(0xFF0E1F36),
      onSurface: const Color(0xFFF2F6FC),
      surfaceContainerHighest: const Color(0xFF122844),
      outlineVariant: const Color(0xFF2B4568),
    );
    return _applyCommon(
      ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: scaffoldDark,
        extensions: const <ThemeExtension<dynamic>>[AppPalette.dark],
      ),
    );
  }

  static ThemeData _applyCommon(ThemeData base) {
    final ColorScheme colorScheme = base.colorScheme;
    final bool isDark = colorScheme.brightness == Brightness.dark;
    return base.copyWith(
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
      splashFactory: InkRipple.splashFactory,
      visualDensity: VisualDensity.standard,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF122844) : surfaceLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: isDark ? 0 : 0,
        color: isDark ? const Color(0xFF122844) : surfaceLight,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: isDark ? const Color(0xFF0E1F36) : brandPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      bottomSheetTheme: isDark
          ? null
          : const BottomSheetThemeData(
              backgroundColor: surfaceLight,
              surfaceTintColor: Colors.transparent,
            ),
      dialogTheme: isDark
          ? null
          : const DialogThemeData(
              backgroundColor: surfaceLight,
              surfaceTintColor: Colors.transparent,
            ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        indicatorColor: colorScheme.primary.withValues(alpha: 0.14),
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>(
          (Set<WidgetState> states) {
            return TextStyle(
              fontSize: 11,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w700
                  : FontWeight.w500,
            );
          },
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant.withValues(alpha: 0.7),
        space: 1,
      ),
    );
  }
}
