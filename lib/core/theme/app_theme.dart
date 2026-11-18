// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,       // orange #f37022
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.primary,
          onPrimary: Colors.white,
          secondary: AppColors.accent,
          surface: AppColors.surface,
          error: AppColors.error,
        ),
        scaffoldBackgroundColor: AppColors.background,
        iconTheme: const IconThemeData(
          color: Colors.black,
        ),
        primaryIconTheme: const IconThemeData(
          color: Colors.black,
        ),

        // ── AppBar ──────────────────────────────────────────────────────────
        // Height 52px, orange background — matches RN Header exactly
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 4,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          iconTheme: IconThemeData(color: Colors.black),
          toolbarHeight: 52,
        ),

        // ── Primary Button (orange, 55px tall, r=10) ─────────────────────
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(55),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            textStyle: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
            ),
          ),
        ),

        // ── Secondary Button (grey #999, 55px tall, r=10) ────────────────
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: AppColors.buttonSecondary,
            minimumSize: const Size.fromHeight(55),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            side: BorderSide.none,
            textStyle: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
            ),
          ),
        ),

        // ── Text Button (link style) ──────────────────────────────────────
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            textStyle: const TextStyle(fontSize: 14),
          ),
        ),

        // ── Input fields ─────────────────────────────────────────────────
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          errorStyle: const TextStyle(fontSize: 12),
        ),

        // ── Cards ────────────────────────────────────────────────────────
        // Matches RN car card: white bg, 1px #d9d8d9 border, r=5
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
            side: const BorderSide(color: AppColors.cardBorder, width: 1),
          ),
          color: AppColors.surface,
          margin: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        ),

        // ── Chips ────────────────────────────────────────────────────────
        chipTheme: ChipThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: const BorderSide(color: Color(0xFFDDDDDD)),
          ),
        ),

        // ── Drawer ───────────────────────────────────────────────────────
        drawerTheme: const DrawerThemeData(
          backgroundColor: AppColors.surface,
          width: 280,
        ),

        // ── Divider ──────────────────────────────────────────────────────
        dividerTheme: const DividerThemeData(
          color: AppColors.divider,
          thickness: 1,
        ),

        // ── List Tiles (drawer items) ─────────────────────────────────────
        listTileTheme: const ListTileThemeData(
          iconColor: Colors.black,
        ),

        // ── Action Icons ──────────────────────────────────────────────────
        actionIconTheme: ActionIconThemeData(
          backButtonIconBuilder: (BuildContext context) => const Icon(Icons.arrow_back, color: Colors.black),
          closeButtonIconBuilder: (BuildContext context) => const Icon(Icons.close, color: Colors.black),
          drawerButtonIconBuilder: (BuildContext context) => const Icon(Icons.menu, color: Colors.black),
          endDrawerButtonIconBuilder: (BuildContext context) => const Icon(Icons.menu, color: Colors.black),
        ),
      );
}
