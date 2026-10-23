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
    required this.fieldFill,
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
  /// Input / filter control fill — distinct from [cardSurface] for contrast.
  final Color fieldFill;
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
    fieldFill: Color(0xFFFFFFFF),
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
    cardSurface: AppTheme.cardDark,
    fieldFill: Color(0xFF0E1F36),
    mapScrim: Color(0xD6071422),
    kpiFill: AppTheme.cardDark,
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
    Color? fieldFill,
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
      fieldFill: fieldFill ?? this.fieldFill,
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
      loginBackgroundTop: Color.lerp(
        loginBackgroundTop,
        other.loginBackgroundTop,
        t,
      )!,
      loginBackgroundBottom: Color.lerp(
        loginBackgroundBottom,
        other.loginBackgroundBottom,
        t,
      )!,
      loginCard: Color.lerp(loginCard, other.loginCard, t)!,
      loginTitle: Color.lerp(loginTitle, other.loginTitle, t)!,
      loginSecondaryText: Color.lerp(
        loginSecondaryText,
        other.loginSecondaryText,
        t,
      )!,
      actionLink: Color.lerp(actionLink, other.actionLink, t)!,
      loginButton: Color.lerp(loginButton, other.loginButton, t)!,
      avatarFill: Color.lerp(avatarFill, other.avatarFill, t)!,
      avatarText: Color.lerp(avatarText, other.avatarText, t)!,
      cardSurface: Color.lerp(cardSurface, other.cardSurface, t)!,
      fieldFill: Color.lerp(fieldFill, other.fieldFill, t)!,
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
  static const Color cardDark = Color(0xFF1A446E);
  static const double cardRadius = 12;
  static const double fieldHeight = 48;
  static const EdgeInsets cardPadding = EdgeInsets.all(16);

  static ThemeData get light {
    const Color onSurface = Color(0xFF0F172A);
    const Color onSurfaceVariant = Color(0xFF475569);
    final ColorScheme colorScheme =
        ColorScheme.fromSeed(seedColor: brandPrimary).copyWith(
          primary: brandPrimary,
          onPrimary: Colors.white,
          secondary: brandSecondary,
          onSecondary: Colors.white,
          tertiary: railwayRed,
          onTertiary: Colors.white,
          surface: surfaceLight,
          surfaceBright: surfaceLight,
          surfaceContainerLowest: Colors.white,
          surfaceContainerLow: surfaceLight,
          surfaceContainer: const Color(0xFFF1F5F9),
          surfaceContainerHigh: const Color(0xFFE8EEF7),
          surfaceContainerHighest: const Color(0xFFE8EEF7),
          onSurface: onSurface,
          onSurfaceVariant: onSurfaceVariant,
          outline: const Color(0xFF94A3B8),
          outlineVariant: const Color(0xFFD5DEEB),
          error: railwayRed,
          onError: Colors.white,
        );
    return _applyCommon(
      ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: scaffoldLight,
        extensions: const <ThemeExtension<dynamic>>[AppPalette.light],
      ),
    );
  }

  static ThemeData get dark {
    const Color onSurface = Color(0xFFF2F6FC);
    const Color onSurfaceVariant = Color(0xFFB7C7DC);
    final ColorScheme colorScheme =
        ColorScheme.fromSeed(
          seedColor: brandSecondary,
          brightness: Brightness.dark,
        ).copyWith(
          primary: const Color(0xFF9DC0F0),
          onPrimary: const Color(0xFF071422),
          secondary: const Color(0xFF4C7DC0),
          onSecondary: Colors.white,
          tertiary: const Color(0xFFEC1F24),
          onTertiary: Colors.white,
          surface: const Color(0xFF0E1F36),
          surfaceBright: const Color(0xFF122844),
          surfaceContainerLowest: scaffoldDark,
          surfaceContainerLow: const Color(0xFF0E1F36),
          surfaceContainer: const Color(0xFF122844),
          surfaceContainerHigh: const Color(0xFF163456),
          surfaceContainerHighest: const Color(0xFF1A3A64),
          onSurface: onSurface,
          onSurfaceVariant: onSurfaceVariant,
          outline: const Color(0xFF6B849F),
          outlineVariant: const Color(0xFF2B4568),
          error: const Color(0xFFFF8A93),
          onError: const Color(0xFF071422),
        );
    return _applyCommon(
      ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: scaffoldDark,
        extensions: const <ThemeExtension<dynamic>>[AppPalette.dark],
      ),
    );
  }

  static ThemeData _applyCommon(ThemeData base) {
    final ColorScheme colorScheme = base.colorScheme;
    final bool isDark = colorScheme.brightness == Brightness.dark;
    final AppPalette palette = isDark ? AppPalette.dark : AppPalette.light;
    final Color fieldFill = palette.fieldFill;
    final TextTheme textTheme = base.textTheme.apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    );
    final BorderRadius fieldRadius = BorderRadius.circular(cardRadius);
    final OutlineInputBorder enabledBorder = OutlineInputBorder(
      borderRadius: fieldRadius,
      borderSide: BorderSide(color: colorScheme.outlineVariant),
    );
    final OutlineInputBorder focusedBorder = OutlineInputBorder(
      borderRadius: fieldRadius,
      borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
    );
    final OutlineInputBorder errorBorder = OutlineInputBorder(
      borderRadius: fieldRadius,
      borderSide: BorderSide(color: colorScheme.error),
    );
    final OutlineInputBorder disabledBorder = OutlineInputBorder(
      borderRadius: fieldRadius,
      borderSide: BorderSide(
        color: colorScheme.outlineVariant.withValues(alpha: 0.55),
      ),
    );

    return base.copyWith(
      textTheme: textTheme,
      primaryTextTheme: base.primaryTextTheme.apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      iconTheme: IconThemeData(color: colorScheme.onSurfaceVariant),
      primaryIconTheme: const IconThemeData(color: Colors.white),
      hintColor: palette.mutedText,
      disabledColor: colorScheme.onSurface.withValues(alpha: 0.38),
      dividerColor: colorScheme.outlineVariant.withValues(alpha: 0.7),
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
        fillColor: fieldFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        labelStyle: TextStyle(
          color: palette.mutedText,
          fontWeight: FontWeight.w600,
        ),
        floatingLabelStyle: WidgetStateTextStyle.resolveWith((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.focused)) {
            return TextStyle(
              color: colorScheme.primary,
              fontWeight: FontWeight.w700,
            );
          }
          if (states.contains(WidgetState.error)) {
            return TextStyle(
              color: colorScheme.error,
              fontWeight: FontWeight.w700,
            );
          }
          if (states.contains(WidgetState.disabled)) {
            return TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.45),
              fontWeight: FontWeight.w600,
            );
          }
          return TextStyle(
            color: palette.mutedText,
            fontWeight: FontWeight.w600,
          );
        }),
        hintStyle: TextStyle(
          color: palette.mutedText.withValues(alpha: isDark ? 0.85 : 0.9),
          fontWeight: FontWeight.w500,
        ),
        helperStyle: TextStyle(color: palette.mutedText),
        errorStyle: TextStyle(color: colorScheme.error),
        prefixIconColor: WidgetStateColor.resolveWith((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.focused)) {
            return colorScheme.primary;
          }
          if (states.contains(WidgetState.disabled)) {
            return colorScheme.onSurface.withValues(alpha: 0.38);
          }
          return palette.mutedText;
        }),
        suffixIconColor: WidgetStateColor.resolveWith((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.focused)) {
            return colorScheme.primary;
          }
          if (states.contains(WidgetState.disabled)) {
            return colorScheme.onSurface.withValues(alpha: 0.38);
          }
          return palette.mutedText;
        }),
        border: enabledBorder,
        enabledBorder: enabledBorder,
        focusedBorder: focusedBorder,
        errorBorder: errorBorder,
        focusedErrorBorder: errorBorder.copyWith(
          borderSide: BorderSide(color: colorScheme.error, width: 1.5),
        ),
        disabledBorder: disabledBorder,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          backgroundColor: isDark ? brandSecondary : brandPrimary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: colorScheme.onSurface.withValues(
            alpha: 0.12,
          ),
          disabledForegroundColor: colorScheme.onSurface.withValues(
            alpha: 0.38,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(cardRadius),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(fieldHeight),
          foregroundColor: colorScheme.onSurface,
          disabledForegroundColor: colorScheme.onSurface.withValues(
            alpha: 0.38,
          ),
          side: BorderSide(color: colorScheme.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(cardRadius),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: colorScheme.primary),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: palette.cardSurface,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: colorScheme.onSurfaceVariant,
        textColor: colorScheme.onSurface,
        titleTextStyle: textTheme.titleMedium?.copyWith(
          color: colorScheme.onSurface,
        ),
        subtitleTextStyle: textTheme.bodyMedium?.copyWith(
          color: palette.mutedText,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        disabledColor: colorScheme.onSurface.withValues(alpha: 0.08),
        selectedColor: colorScheme.primary.withValues(alpha: 0.18),
        secondarySelectedColor: colorScheme.primary.withValues(alpha: 0.18),
        labelStyle: TextStyle(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: TextStyle(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        side: BorderSide(color: colorScheme.outlineVariant),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: isDark ? const Color(0xFF0E1F36) : brandPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.cardSurface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: palette.cardSurface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(cardRadius)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isDark
            ? const Color(0xFF122844)
            : surfaceLight,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleMedium?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w800,
        ),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: palette.mutedText,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: palette.cardSurface,
        headerBackgroundColor: isDark ? brandSecondary : brandPrimary,
        headerForegroundColor: Colors.white,
        dayForegroundColor: WidgetStateProperty.resolveWith((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.disabled)) {
            return colorScheme.onSurface.withValues(alpha: 0.38);
          }
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return colorScheme.onSurface;
        }),
        dayBackgroundColor: WidgetStateProperty.resolveWith((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.selected)) {
            return isDark ? brandSecondary : brandPrimary;
          }
          return Colors.transparent;
        }),
        todayForegroundColor: WidgetStatePropertyAll<Color>(
          colorScheme.primary,
        ),
        yearForegroundColor: WidgetStateProperty.resolveWith((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return colorScheme.onSurface;
        }),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: TextStyle(color: colorScheme.onSurface),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: fieldFill,
        ),
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll<Color>(palette.cardSurface),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: palette.cardSurface,
        surfaceTintColor: Colors.transparent,
        textStyle: TextStyle(color: colorScheme.onSurface),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark
            ? const Color(0xFF122844)
            : const Color(0xFF1E293B),
        contentTextStyle: const TextStyle(color: Colors.white),
        actionTextColor: colorScheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        indicatorColor: colorScheme.primary.withValues(alpha: 0.14),
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData?>((
          Set<WidgetState> states,
        ) {
          final bool selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? colorScheme.primary : palette.mutedText,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>((
          Set<WidgetState> states,
        ) {
          final bool selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? colorScheme.primary : palette.mutedText,
          );
        }),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant.withValues(alpha: 0.7),
        space: 1,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: isDark ? brandSecondary : brandPrimary,
        foregroundColor: Colors.white,
      ),
    );
  }
}
