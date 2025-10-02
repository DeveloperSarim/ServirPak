import 'package:flutter/material.dart';

class AppTheme {
  // Primary Colors
  static const Color primaryColor = Color(0xFF8B4513); // Saddle Brown
  static const Color primaryLightColor = Color(0xFFA0522D); // Sienna
  static const Color primaryDarkColor = Color(0xFF6B4423); // Dark Brown
  static const Color secondaryColor = Color(0xFFD4AF37); // Gold
  static const Color accentColor = Color(0xFF2E8B57); // Sea Green

  // Neutral Colors
  static const Color backgroundColor = Color(0xFFF8F9FA);
  static const Color surfaceColor = Colors.white;
  static const Color errorColor = Color(0xFFE53E3E);
  static const Color successColor = Color(0xFF38A169);
  static const Color warningColor = Color(0xFFDD6B20);
  static const Color infoColor = Color(0xFF3182CE);

  // Text Colors
  static const Color textPrimaryColor = Color(0xFF2C1810);
  static const Color textSecondaryColor = Color(0xFF6B7280);
  static const Color textTertiaryColor = Color(0xFF9CA3AF);

  // Lawyer Theme Colors
  static const Color lawyerPrimaryColor = Color(0xFF1E3A8A); // Blue
  static const Color lawyerSecondaryColor = Color(0xFF3B82F6);
  static const Color lawyerAccentColor = Color(0xFF10B981);

  // User Theme Colors
  static const Color userPrimaryColor = Color(0xFF8B4513); // Saddle Brown
  static const Color userSecondaryColor = Color(0xFFA0522D);
  static const Color userAccentColor = Color(0xFFD4AF37);

  // Admin Theme Colors
  static const Color adminPrimaryColor = Color(0xFF7C2D12); // Dark Red
  static const Color adminSecondaryColor = Color(0xFFDC2626);
  static const Color adminAccentColor = Color(0xFFF59E0B);

  // Dark Theme Colors
  static const Color darkBackgroundColor = Color(0xFF1A1A1A);
  static const Color darkSurfaceColor = Color(0xFF2C2C2C);
  static const Color darkTextPrimaryColor = Color(0xFFE0E0E0);
  static const Color darkTextSecondaryColor = Color(0xFFB0B0B0);
  static const Color darkTextTertiaryColor = Color(0xFF808080);

  // Theme Data
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primarySwatch: _createMaterialColor(primaryColor),
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,
        background: backgroundColor,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimaryColor,
        onBackground: textPrimaryColor,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(8),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: textTertiaryColor,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: surfaceColor,
        selectedIconTheme: IconThemeData(color: primaryColor),
        selectedLabelTextStyle: TextStyle(color: primaryColor),
        unselectedIconTheme: IconThemeData(color: textTertiaryColor),
        unselectedLabelTextStyle: TextStyle(color: textTertiaryColor),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textPrimaryColor,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: textPrimaryColor,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textPrimaryColor,
        ),
        headlineLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: textPrimaryColor,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimaryColor,
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimaryColor,
        ),
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimaryColor,
        ),
        titleMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textPrimaryColor,
        ),
        titleSmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textPrimaryColor,
        ),
        bodyLarge: TextStyle(fontSize: 16, color: textPrimaryColor),
        bodyMedium: TextStyle(fontSize: 14, color: textSecondaryColor),
        bodySmall: TextStyle(fontSize: 12, color: textTertiaryColor),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textPrimaryColor,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textSecondaryColor,
        ),
        labelSmall: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: textTertiaryColor,
        ),
      ),
    );
  }

  // Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primarySwatch: _createMaterialColor(primaryColor),
      primaryColor: primaryColor,
      scaffoldBackgroundColor: darkBackgroundColor,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: darkSurfaceColor,
        background: darkBackgroundColor,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: darkTextPrimaryColor,
        onBackground: darkTextPrimaryColor,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkSurfaceColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        color: darkSurfaceColor,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(8),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkSurfaceColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: darkTextTertiaryColor,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: darkSurfaceColor,
        selectedIconTheme: IconThemeData(color: primaryColor),
        selectedLabelTextStyle: TextStyle(color: primaryColor),
        unselectedIconTheme: IconThemeData(color: darkTextTertiaryColor),
        unselectedLabelTextStyle: TextStyle(color: darkTextTertiaryColor),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: darkTextPrimaryColor,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: darkTextPrimaryColor,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: darkTextPrimaryColor,
        ),
        headlineLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: darkTextPrimaryColor,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: darkTextPrimaryColor,
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: darkTextPrimaryColor,
        ),
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: darkTextPrimaryColor,
        ),
        titleMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: darkTextPrimaryColor,
        ),
        titleSmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: darkTextPrimaryColor,
        ),
        bodyLarge: TextStyle(fontSize: 16, color: darkTextPrimaryColor),
        bodyMedium: TextStyle(fontSize: 14, color: darkTextSecondaryColor),
        bodySmall: TextStyle(fontSize: 12, color: darkTextTertiaryColor),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: darkTextPrimaryColor,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: darkTextSecondaryColor,
        ),
        labelSmall: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: darkTextTertiaryColor,
        ),
      ),
    );
  }

  // Lawyer Theme
  static ThemeData get lawyerTheme {
    return lightTheme.copyWith(
      primaryColor: lawyerPrimaryColor,
      colorScheme: lightTheme.colorScheme.copyWith(
        primary: lawyerPrimaryColor,
        secondary: lawyerSecondaryColor,
      ),
      appBarTheme: lightTheme.appBarTheme.copyWith(
        backgroundColor: lawyerPrimaryColor,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: lightTheme.elevatedButtonTheme.style?.copyWith(
          backgroundColor: MaterialStateProperty.all(lawyerPrimaryColor),
        ),
      ),
      bottomNavigationBarTheme: lightTheme.bottomNavigationBarTheme.copyWith(
        selectedItemColor: lawyerPrimaryColor,
      ),
      navigationRailTheme: lightTheme.navigationRailTheme.copyWith(
        selectedIconTheme: const IconThemeData(color: lawyerPrimaryColor),
        selectedLabelTextStyle: const TextStyle(color: lawyerPrimaryColor),
      ),
    );
  }

  // User Theme
  static ThemeData get userTheme {
    return lightTheme.copyWith(
      primaryColor: userPrimaryColor,
      colorScheme: lightTheme.colorScheme.copyWith(
        primary: userPrimaryColor,
        secondary: userSecondaryColor,
      ),
      appBarTheme: lightTheme.appBarTheme.copyWith(
        backgroundColor: userPrimaryColor,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: lightTheme.elevatedButtonTheme.style?.copyWith(
          backgroundColor: MaterialStateProperty.all(userPrimaryColor),
        ),
      ),
      bottomNavigationBarTheme: lightTheme.bottomNavigationBarTheme.copyWith(
        selectedItemColor: userPrimaryColor,
      ),
      navigationRailTheme: lightTheme.navigationRailTheme.copyWith(
        selectedIconTheme: const IconThemeData(color: userPrimaryColor),
        selectedLabelTextStyle: const TextStyle(color: userPrimaryColor),
      ),
    );
  }

  // Admin Theme
  static ThemeData get adminTheme {
    return lightTheme.copyWith(
      primaryColor: adminPrimaryColor,
      colorScheme: lightTheme.colorScheme.copyWith(
        primary: adminPrimaryColor,
        secondary: adminSecondaryColor,
      ),
      appBarTheme: lightTheme.appBarTheme.copyWith(
        backgroundColor: adminPrimaryColor,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: lightTheme.elevatedButtonTheme.style?.copyWith(
          backgroundColor: MaterialStateProperty.all(adminPrimaryColor),
        ),
      ),
      bottomNavigationBarTheme: lightTheme.bottomNavigationBarTheme.copyWith(
        selectedItemColor: adminPrimaryColor,
      ),
      navigationRailTheme: lightTheme.navigationRailTheme.copyWith(
        selectedIconTheme: const IconThemeData(color: adminPrimaryColor),
        selectedLabelTextStyle: const TextStyle(color: adminPrimaryColor),
      ),
    );
  }

  // Helper method to create MaterialColor
  static MaterialColor _createMaterialColor(Color color) {
    List strengths = <double>[.05];
    Map<int, Color> swatch = {};
    final int r = color.red, g = color.green, b = color.blue;

    for (int i = 1; i < 10; i++) {
      strengths.add(0.1 * i);
    }
    for (var strength in strengths) {
      final double ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    }
    return MaterialColor(color.value, swatch);
  }

  // Get theme based on user role
  static ThemeData getThemeForRole(String role) {
    switch (role.toLowerCase()) {
      case 'lawyer':
        return lawyerTheme;
      case 'user':
        return userTheme;
      case 'admin':
        return adminTheme;
      default:
        return lightTheme;
    }
  }

  // Custom gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryColor, primaryLightColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient lawyerGradient = LinearGradient(
    colors: [lawyerPrimaryColor, lawyerSecondaryColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient userGradient = LinearGradient(
    colors: [userPrimaryColor, userSecondaryColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient adminGradient = LinearGradient(
    colors: [adminPrimaryColor, adminSecondaryColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Get gradient based on user role
  static LinearGradient getGradientForRole(String role) {
    switch (role.toLowerCase()) {
      case 'lawyer':
        return lawyerGradient;
      case 'user':
        return userGradient;
      case 'admin':
        return adminGradient;
      default:
        return primaryGradient;
    }
  }

  // Status colors
  static const Map<String, Color> statusColors = {
    'pending': warningColor,
    'accepted': successColor,
    'rejected': errorColor,
    'completed': infoColor,
    'cancelled': textTertiaryColor,
    'verified': successColor,
    'approved': successColor,
  };

  // Get status color
  static Color getStatusColor(String status) {
    return statusColors[status.toLowerCase()] ?? textTertiaryColor;
  }

  // Consultation type colors
  static const Map<String, Color> consultationTypeColors = {
    'free': successColor,
    'paid': infoColor,
    'premium': warningColor,
  };

  // Get consultation type color
  static Color getConsultationTypeColor(String type) {
    return consultationTypeColors[type.toLowerCase()] ?? textTertiaryColor;
  }
}
