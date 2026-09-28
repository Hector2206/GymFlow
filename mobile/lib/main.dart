import 'package:flutter/material.dart';

import 'pages/splash_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    const GymFlowApp(),
  );
}

class GymFlowApp extends StatelessWidget {
  const GymFlowApp({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFB58A2A);
    const goldDark = Color(0xFF8A6814);

    const background = Color(0xFFF8F5EF);
    const surface = Color(0xFFFFFDF8);
    const fieldBackground = Color(0xFFF4EFE6);

    const textPrimary = Color(0xFF2F2A24);
    const textSecondary = Color(0xFF777067);

    const border = Color(0xFFE5DDCF);

    return MaterialApp(
      debugShowCheckedModeBanner: false,

      title: 'GymFlow',

      theme: ThemeData(
        useMaterial3: true,

        brightness: Brightness.light,

        scaffoldBackgroundColor: background,

        colorScheme: ColorScheme.fromSeed(
          seedColor: gold,
          brightness: Brightness.light,
        ).copyWith(
          primary: gold,
          secondary: goldDark,
          surface: surface,
          error: const Color(0xFFC21B2E),
        ),

        appBarTheme: const AppBarTheme(
          backgroundColor: surface,
          foregroundColor: textPrimary,
          elevation: 0,
          centerTitle: false,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          iconTheme: IconThemeData(
            color: goldDark,
          ),
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: fieldBackground,

          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),

          labelStyle: const TextStyle(
            color: textSecondary,
            fontSize: 13,
          ),

          hintStyle: const TextStyle(
            color: Color(0xFFA39A8D),
            fontSize: 13,
          ),

          prefixIconColor: goldDark,
          suffixIconColor: goldDark,

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(
              color: border,
            ),
          ),

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(
              color: border,
            ),
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(
              color: gold,
              width: 1.4,
            ),
          ),

          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(
              color: Color(0xFFC21B2E),
            ),
          ),

          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(
              color: Color(0xFFC21B2E),
              width: 1.4,
            ),
          ),

          errorStyle: const TextStyle(
            color: Color(0xFFB81E32),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: gold,
            foregroundColor: surface,
            elevation: 0,

            minimumSize: const Size(
              0,
              52,
            ),

            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                13,
              ),
            ),

            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),

        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: goldDark,

            side: const BorderSide(
              color: Color(0xFFD8C8A5),
            ),

            minimumSize: const Size(
              0,
              52,
            ),

            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                13,
              ),
            ),

            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        dividerTheme: const DividerThemeData(
          color: border,
          thickness: 1,
          space: 1,
        ),

        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: surface,

          contentTextStyle: const TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.w600,
          ),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              14,
            ),
          ),
        ),

        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.w700,
          ),

          headlineMedium: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.w700,
          ),

          titleLarge: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.w700,
          ),

          titleMedium: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.w600,
          ),

          bodyLarge: TextStyle(
            color: textPrimary,
          ),

          bodyMedium: TextStyle(
            color: textSecondary,
          ),

          bodySmall: TextStyle(
            color: textSecondary,
          ),
        ),
      ),

      home: const SplashPage(),
    );
  }
}