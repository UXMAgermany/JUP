import 'package:flutter/material.dart';

class SharedThemeData {
  static NavigationBarThemeData navigationBarTheme = NavigationBarThemeData(
    indicatorColor: Colors.transparent,
    iconTheme: WidgetStateProperty.resolveWith<IconThemeData>((states) {
      if (states.contains(WidgetState.selected)) {
        return const IconThemeData(
          color: ThemeLightColors.primary,
        ); // selected icon color
      }
      return const IconThemeData(
        color: ThemeLightColors.onSurface,
      ); // unselected icon color
    }),
  );
}

class ThemeLightColors {
  static const primary = Color(0xFF63568F);
  static const primaryContainer = Color(0xFFE8DDFF);
  static const onPrimary = Color(0xFFFFFFFF);
  static const onPrimaryContainer = Color(0xFF4B3E76);
  static const inversePrimary = Color(0xFFCEBDFF);
  static const secondary = Color(0xFF4A5C92);
  static const onSecondary = Color(0xFFFFFFFF);
  static const secondaryContainer = Color(0xFFDBE1FF);
  static const onSecondaryContainer = Color(0xFF324478);
  static const surface = Color(0xFFFEF7FF);
  static const surfaceDim = Color(0xFFDED8E0);
  static const surfaceBright = Color(0xFFFEF7FF);
  static const surfaceContainer = Color(0xFFF2ECF4);
  static const surfaceContainerLow = Color(0xFFF8F1FA);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainerHigh = Color(0xFFECE6EE);
  static const surfaceContainerHighest = Color(0xFFE7E0E8);
  static const inverseSurface = Color(0xFF322F35);
  static const error = Color(0xFFBA1A1A);
  static const onError = Color(0xFFFFFFFF);
  static const errorContainer = Color(0xFFFFDAD6);
  static const onErrorContainer = Color(0xFF93000A);
  static const onSurface = Color(0xFF1D1B20);
  static const onSurfaceVariant = Color(0xFF44464F);
  static const outline = Color(0xFF757780);
  static const outlineVariant = Color(0xFFC5C6D0);
  static const tertiaryContainer = Color(0xFFFFDF96);
  static const onTertiaryContainer = Color(0xFF5A4400);
}

class ThemeDarkColors {
  static const primary = Color(0xFFCEBDFF);
  static const primaryContainer = Color(0xFF4B3E76);
  static const onPrimary = Color(0xFF35275E);
  static const onPrimaryContainer = Color(0xFFE8DDFF);
  static const inversePrimary = Color(0xFF63568F);
  static const secondary = Color(0xFFB3C5FF);
  static const onSecondary = Color(0xFF1A2E60);
  static const secondaryContainer = Color(0xFF324478);
  static const onSecondaryContainer = Color(0xFFDBE1FF);
  static const surface = Color(0xFF141218);
  static const surfaceDim = Color(0xFF141218);
  static const surfaceBright = Color(0xFF3B383E);
  static const surfaceContainer = Color(0xFF211F24);
  static const surfaceContainerLow = Color(0xFF1D1B20);
  static const surfaceContainerLowest = Color(0xFF0F0D13);
  static const surfaceContainerHigh = Color(0xFF2B292F);
  static const surfaceContainerHighest = Color(0xFF36343A);
  static const inverseSurface = Color(0xFFE7E0E8);
  static const error = Color(0xFFFFB4AB);
  static const onError = Color(0xFF690005);
  static const errorContainer = Color(0xFF93000A);
  static const onErrorContainer = Color(0xFFFFDAD6);
  static const onSurface = Color(0xFFE7E0E8);
  static const onSurfaceVariant = Color(0xFFC5C6D0);
  static const outline = Color(0xFF8F9099);
  static const outlineVariant = Color(0xFF44464F);
  static const tertiaryContainer = Color(0xFF564400);
  static const onTertiaryContainer = Color(0xFFFFDF96);
}

class ThemeTextStyles {
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: "Rubik",
    fontSize: 16,
  );

  static const TextStyle labelLarge = TextStyle(
    fontFamily: "WorkSans",
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );
}

const TextTheme textTheme = TextTheme(
  headlineLarge: TextStyle(
    fontFamily: "Rubik",
    fontWeight: FontWeight.w400,
    fontSize: 32.0,
    height: 1.25,
  ),
  headlineMedium: TextStyle(
    fontFamily: "Rubik",
    fontWeight: FontWeight.w400,
    fontSize: 28.0,
    height: 1.28,
  ),
  headlineSmall: TextStyle(
    fontFamily: "Rubik",
    fontWeight: FontWeight.w400,
    fontSize: 24.0,
    height: 1.33,
  ),
  titleLarge: TextStyle(
    fontFamily: "WorkSans",
    fontWeight: FontWeight.w400,
    fontSize: 22.0,
    height: 1.27,
  ),
  titleMedium: TextStyle(
    fontFamily: "WorkSans",
    fontWeight: FontWeight.w500,
    fontSize: 16.0,
    height: 1.5,
    letterSpacing: 0.15,
  ),
  titleSmall: TextStyle(
    fontFamily: "WorkSans",
    fontWeight: FontWeight.w500,
    fontSize: 14.0,
    height: 1.42,
    letterSpacing: 0.1,
  ),
  bodyLarge: TextStyle(
    fontFamily: "WorkSans",
    fontWeight: FontWeight.w400,
    fontSize: 16.0,
    height: 1.5,
    letterSpacing: 0.25,
  ),
  bodyMedium: TextStyle(
    fontFamily: "WorkSans",
    fontWeight: FontWeight.w400,
    fontSize: 14.0,
    height: 1.42,
    letterSpacing: 0.2,
  ),
  bodySmall: TextStyle(
    fontFamily: "WorkSans",
    fontWeight: FontWeight.w400,
    fontSize: 12.0,
    height: 1.33,
    letterSpacing: 0.2,
  ),
  labelLarge: TextStyle(
    fontFamily: "WorkSans",
    fontWeight: FontWeight.w500,
    fontSize: 14.0,
    height: 1.42,
    letterSpacing: 0.1,
  ),
  labelMedium: TextStyle(
    fontFamily: "WorkSans",
    fontWeight: FontWeight.w500,
    fontSize: 12.0,
    height: 1.33,
    letterSpacing: 0.1,
  ),
  labelSmall: TextStyle(
    fontFamily: "WorkSans",
    fontWeight: FontWeight.w500,
    fontSize: 11.0,
    height: 1.45,
    letterSpacing: 0.5,
  ),
  displayLarge: TextStyle(
    fontFamily: "Rubik",
    fontSize: 57.0,
    fontWeight: FontWeight.w400,
    height: 1.12,
    letterSpacing: -0.25,
  ),
  displayMedium: TextStyle(
    fontFamily: "Rubik",
    fontSize: 45.0,
    fontWeight: FontWeight.w400,
    height: 1.15,
  ),
  displaySmall: TextStyle(
    fontFamily: "Rubik",
    fontSize: 36.0,
    fontWeight: FontWeight.w400,
    height: 1.12,
  ),
);

var lightTheme = ThemeData(
  scaffoldBackgroundColor: Colors.transparent,
  useMaterial3: true,
  textTheme: textTheme,
  colorScheme: const ColorScheme(
    primary: ThemeLightColors.primary,
    primaryContainer: ThemeLightColors.primaryContainer,
    inversePrimary: ThemeLightColors.inversePrimary,
    secondary: ThemeLightColors.secondary,
    secondaryContainer: ThemeLightColors.secondaryContainer,
    onSecondaryContainer: ThemeLightColors.onSecondaryContainer,
    surface: ThemeLightColors.surface,
    surfaceDim: ThemeLightColors.surfaceDim,
    surfaceBright: ThemeLightColors.surfaceBright,
    surfaceContainer: ThemeLightColors.surfaceContainer,
    surfaceContainerLow: ThemeLightColors.surfaceContainerLow,
    surfaceContainerLowest: ThemeLightColors.surfaceContainerLowest,
    surfaceContainerHigh: ThemeLightColors.surfaceContainerHigh,
    surfaceContainerHighest: ThemeLightColors.surfaceContainerHighest,
    inverseSurface: ThemeLightColors.inverseSurface,
    error: ThemeLightColors.error,
    errorContainer: ThemeLightColors.errorContainer,
    onPrimary: ThemeLightColors.onPrimary,
    onPrimaryContainer: ThemeLightColors.onPrimaryContainer,
    onSecondary: ThemeLightColors.onSecondary,
    onSurface: ThemeLightColors.onSurface,
    onSurfaceVariant: ThemeLightColors.onSurfaceVariant,
    onError: ThemeLightColors.onError,
    onErrorContainer: ThemeLightColors.onErrorContainer,
    tertiaryContainer: ThemeLightColors.tertiaryContainer,
    onTertiaryContainer: ThemeLightColors.onTertiaryContainer,
    brightness: Brightness.light,
    outline: ThemeLightColors.outline,
    outlineVariant: ThemeLightColors.outlineVariant,
  ),
  appBarTheme: const AppBarTheme(
    surfaceTintColor: ThemeLightColors.onSurface,
    backgroundColor: Colors.transparent,
  ),
  dividerTheme: const DividerThemeData(color: ThemeLightColors.outlineVariant),
  navigationBarTheme: NavigationBarThemeData(
    indicatorColor: ThemeLightColors.secondaryContainer,
    overlayColor: WidgetStateProperty.all(Colors.transparent),
    iconTheme: WidgetStateProperty.resolveWith<IconThemeData>((states) {
      if (states.contains(WidgetState.selected)) {
        return const IconThemeData(
          color: ThemeLightColors.onSecondaryContainer,
        ); // selected icon color
      }
      return const IconThemeData(
        color: ThemeLightColors.onSurfaceVariant,
      ); // unselected icon color
    }),
    labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((states) {
      if (states.contains(WidgetState.selected)) {
        return const TextStyle(
          color: ThemeLightColors.onSecondaryContainer,
        ); // selected text color
      }
      return const TextStyle(
        color: ThemeLightColors.onSurfaceVariant,
      ); // unselected text color
    }),
  ),
  bottomSheetTheme: const BottomSheetThemeData(
    surfaceTintColor: Colors.transparent,
    backgroundColor: ThemeLightColors.surface,
  ),
  dropdownMenuTheme: DropdownMenuThemeData(
    inputDecorationTheme: InputDecorationTheme(
      constraints: BoxConstraints.tight(const Size.fromHeight(40)),
      contentPadding: const EdgeInsets.only(left: 16, bottom: 16),
      border: OutlineInputBorder(
        borderSide: const BorderSide(color: ThemeLightColors.outline),
        borderRadius: BorderRadius.circular(24),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: ThemeLightColors.outline),
        borderRadius: BorderRadius.circular(24),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: ThemeLightColors.outline),
        borderRadius: BorderRadius.circular(24),
      ),
      filled: true,
      fillColor: ThemeLightColors.surfaceDim,
    ),
  ),
  dialogTheme: DialogThemeData(backgroundColor: ThemeLightColors.surfaceDim),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: ThemeLightColors.primary,
      foregroundColor: ThemeLightColors.onPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
    ),
  ),
  switchTheme: SwitchThemeData(
    trackColor: WidgetStateProperty.resolveWith<Color>((states) {
      if (states.contains(WidgetState.selected)) {
        return ThemeLightColors.primary;
      }
      return ThemeLightColors.surfaceBright;
    }),
    thumbIcon: WidgetStateProperty.resolveWith<Icon?>((
      Set<WidgetState> states,
    ) {
      if (states.contains(WidgetState.selected)) {
        return const Icon(Icons.check, color: ThemeLightColors.primary);
      } else {
        return const Icon(Icons.close, color: ThemeLightColors.surfaceBright);
      }
    }),
  ),
  segmentedButtonTheme: SegmentedButtonThemeData(
    style: ButtonStyle(
      side: WidgetStateProperty.all<BorderSide>(
        const BorderSide(color: ThemeLightColors.surfaceContainerHighest),
      ),
      backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.selected)) {
          return ThemeLightColors.surfaceContainerHigh;
        }
        return ThemeLightColors.surfaceBright;
      }),
      foregroundColor: WidgetStateProperty.all<Color>(
        ThemeLightColors.onSurface,
      ),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      minimumSize: const Size(20, 40),
      textStyle: ThemeTextStyles.labelLarge.copyWith(
        fontWeight: FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      foregroundColor: ThemeLightColors.onSurfaceVariant,
      backgroundColor: ThemeLightColors.surface,
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      textStyle: ThemeTextStyles.labelLarge.copyWith(
        color: ThemeLightColors.primary,
      ),
    ),
  ),
  tabBarTheme: const TabBarThemeData(
    dividerColor: ThemeLightColors.outlineVariant,
    labelColor: ThemeLightColors.primary,
    unselectedLabelColor: ThemeLightColors.onSurfaceVariant,
  ),
  inputDecorationTheme: InputDecorationThemeData(
    errorMaxLines: 3,
    border: OutlineInputBorder(
      borderSide: const BorderSide(color: ThemeDarkColors.outline, width: 1),
      borderRadius: BorderRadius.circular(4),
    ),
  ),
);

var darkTheme = ThemeData(
  scaffoldBackgroundColor: Colors.transparent,
  textTheme: textTheme,
  colorScheme: const ColorScheme(
    brightness: Brightness.dark,
    primary: ThemeDarkColors.primary,
    primaryContainer: ThemeDarkColors.primaryContainer,
    inversePrimary: ThemeDarkColors.inversePrimary,
    secondary: ThemeDarkColors.secondary,
    secondaryContainer: ThemeDarkColors.secondaryContainer,
    onSecondaryContainer: ThemeDarkColors.onSecondaryContainer,
    surface: ThemeDarkColors.surface,
    surfaceDim: ThemeDarkColors.surfaceDim,
    surfaceBright: ThemeDarkColors.surfaceBright,
    surfaceContainer: ThemeDarkColors.surfaceContainer,
    surfaceContainerLow: ThemeDarkColors.surfaceContainerLow,
    surfaceContainerLowest: ThemeDarkColors.surfaceContainerLowest,
    surfaceContainerHigh: ThemeDarkColors.surfaceContainerHigh,
    surfaceContainerHighest: ThemeDarkColors.surfaceContainerHighest,
    inverseSurface: ThemeDarkColors.inverseSurface,
    error: ThemeDarkColors.error,
    errorContainer: ThemeDarkColors.errorContainer,
    onPrimary: ThemeDarkColors.onPrimary,
    onPrimaryContainer: ThemeDarkColors.onPrimaryContainer,
    onSecondary: ThemeDarkColors.onSecondary,
    onSurface: ThemeDarkColors.onSurface,
    onSurfaceVariant: ThemeDarkColors.onSurfaceVariant,
    onError: ThemeDarkColors.onError,
    onErrorContainer: ThemeDarkColors.onErrorContainer,
    tertiaryContainer: ThemeDarkColors.tertiaryContainer,
    onTertiaryContainer: ThemeDarkColors.onTertiaryContainer,
    outline: ThemeDarkColors.outline,
    outlineVariant: ThemeDarkColors.outlineVariant,
  ),
  useMaterial3: true,
  navigationBarTheme: NavigationBarThemeData(
    indicatorColor: ThemeDarkColors.secondaryContainer,
    overlayColor: WidgetStateProperty.all(Colors.transparent),
    iconTheme: WidgetStateProperty.resolveWith<IconThemeData>((states) {
      if (states.contains(WidgetState.selected)) {
        return const IconThemeData(
          color: ThemeDarkColors.onSecondaryContainer,
        ); // selected icon color
      }
      return const IconThemeData(
        color: ThemeDarkColors.onSurfaceVariant,
      ); // unselected icon color
    }),
    labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((states) {
      if (states.contains(WidgetState.selected)) {
        return const TextStyle(
          color: ThemeDarkColors.onSecondaryContainer,
          // fontWeight: FontWeight.w500,
        ); // selected text color
      }
      return const TextStyle(
        color: ThemeDarkColors.onSurfaceVariant,
        // fontWeight: FontWeight.w500,
      ); // unselected text color
    }),
  ),
  bottomSheetTheme: const BottomSheetThemeData(
    surfaceTintColor: Colors.transparent,
    backgroundColor: ThemeDarkColors.surface,
  ),
  dropdownMenuTheme: DropdownMenuThemeData(
    inputDecorationTheme: InputDecorationTheme(
      constraints: BoxConstraints.tight(const Size.fromHeight(40)),
      contentPadding: const EdgeInsets.only(left: 16, bottom: 16),
      border: OutlineInputBorder(
        borderSide: const BorderSide(color: ThemeDarkColors.outline),
        borderRadius: BorderRadius.circular(24),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: ThemeDarkColors.outline),
        borderRadius: BorderRadius.circular(24),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: ThemeDarkColors.outline),
        borderRadius: BorderRadius.circular(24),
      ),
      filled: true,
      fillColor: ThemeDarkColors.surfaceDim,
    ),
  ),
  dialogTheme: DialogThemeData(backgroundColor: ThemeDarkColors.surfaceDim),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: ThemeDarkColors.primary,
      foregroundColor: ThemeDarkColors.onPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
    ),
  ),
  switchTheme: SwitchThemeData(
    trackColor: WidgetStateProperty.resolveWith<Color>((states) {
      if (states.contains(WidgetState.selected)) {
        return ThemeDarkColors.primary;
      }
      return ThemeDarkColors.surfaceBright;
    }),
    thumbIcon: WidgetStateProperty.resolveWith<Icon?>((
      Set<WidgetState> states,
    ) {
      if (states.contains(WidgetState.selected)) {
        return const Icon(Icons.check, color: ThemeDarkColors.primary);
      } else {
        return const Icon(Icons.close, color: ThemeDarkColors.surfaceBright);
      }
    }),
  ),
  segmentedButtonTheme: SegmentedButtonThemeData(
    style: ButtonStyle(
      side: WidgetStateProperty.all<BorderSide>(
        const BorderSide(color: ThemeDarkColors.surfaceContainerHighest),
      ),
      backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.selected)) {
          return ThemeDarkColors.surfaceContainerHigh;
        }
        return ThemeDarkColors.surfaceBright;
      }),
      foregroundColor: WidgetStateProperty.all<Color>(
        ThemeDarkColors.onSurface,
      ),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      minimumSize: const Size(50, 40),
      textStyle: ThemeTextStyles.labelLarge,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  ),
  dividerTheme: const DividerThemeData(color: ThemeLightColors.outlineVariant),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      foregroundColor: ThemeDarkColors.onSurface,
      backgroundColor: ThemeDarkColors.surface,
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      textStyle: ThemeTextStyles.labelLarge.copyWith(
        color: ThemeLightColors.primary,
      ),
    ),
  ),
  tabBarTheme: const TabBarThemeData(
    dividerColor: ThemeLightColors.outlineVariant,
    labelColor: ThemeDarkColors.primary,
    unselectedLabelColor: ThemeDarkColors.onSurface,
  ),
  appBarTheme: const AppBarTheme(
    surfaceTintColor: ThemeDarkColors.onSurface,
    backgroundColor: Colors.transparent,
  ),
  sliderTheme: const SliderThemeData(
    inactiveTrackColor: ThemeDarkColors.surface,
  ),
  chipTheme: ChipThemeData(backgroundColor: Colors.transparent),
  inputDecorationTheme: InputDecorationThemeData(
    errorMaxLines: 3,
    border: OutlineInputBorder(
      borderSide: const BorderSide(color: ThemeDarkColors.outline, width: 1),
      borderRadius: BorderRadius.circular(4),
    ),
  ),
);
