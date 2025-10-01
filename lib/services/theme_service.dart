import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';

  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  ThemeService() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? themeString = prefs.getString(_themeKey);

      if (themeString != null) {
        _themeMode = ThemeMode.values.firstWhere(
          (mode) => mode.toString() == themeString,
          orElse: () => ThemeMode.light,
        );
        notifyListeners();
      }
    } catch (e) {
      print('Error loading theme: $e');
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, mode.toString());

      _themeMode = mode;
      notifyListeners();
    } catch (e) {
      print('Error saving theme: $e');
    }
  }

  Future<void> toggleTheme() async {
    final newMode = _themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    await setThemeMode(newMode);
  }
}

// Brown theme colors
class AppColors {
  // Light theme colors
  static const Color primaryBrown = Color(0xFF8B4513);
  static const Color lightBrown = Color(0xFFA0522D);
  static const Color darkBrown = Color(0xFF6B4423);
  static const Color gold = Color(0xFFD4AF37);

  // Dark theme colors
  static const Color darkPrimaryBrown = Color(0xFF5D2E0A);
  static const Color darkLightBrown = Color(0xFF7A3D11);
  static const Color darkDarkBrown = Color(0xFF4A1F08);
  static const Color darkGold = Color(0xFFB8941F);

  // Common colors
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color grey = Colors.grey;
  static const Color lightGrey = Color(0xFFF8F9FA);
  static const Color darkGrey = Color(0xFF2C2C2C);
}

class AppThemes {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryBrown,
        brightness: Brightness.light,
      ),
      primaryColor: AppColors.primaryBrown,
      scaffoldBackgroundColor: AppColors.lightGrey,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.primaryBrown,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBrown,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryBrown),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.white,
        selectedItemColor: AppColors.primaryBrown,
        unselectedItemColor: AppColors.grey,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.darkPrimaryBrown,
        brightness: Brightness.dark,
      ),
      primaryColor: AppColors.darkPrimaryBrown,
      scaffoldBackgroundColor: AppColors.darkGrey,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkGrey,
        foregroundColor: AppColors.darkGold,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.darkPrimaryBrown,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkGold),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF3C3C3C),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkGrey,
        selectedItemColor: AppColors.darkGold,
        unselectedItemColor: AppColors.grey,
      ),
    );
  }
}
