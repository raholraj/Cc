// ============================================================
// main.dart — APK 3D Asset Extractor — Entry Point
// APK ke andar ke 3D models aur assets extract karo
// bina ek line code decompile kiye!
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Portrait only
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Status bar transparent
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0A0A1A),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(const Apk3dExtractorApp());
}

class Apk3dExtractorApp extends StatelessWidget {
  const Apk3dExtractorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'APK 3D Extractor',
      debugShowCheckedModeBanner: false,

      // ─── Dark theme ───
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0A1A),
        colorScheme: const ColorScheme.dark(
          primary:   Color(0xFF00D4FF),
          secondary: Color(0xFF7C4DFF),
          surface:   Color(0xFF1A1A2E),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0A0A1A),
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        cardTheme: CardTheme(
          color: const Color(0xFF1A1A2E),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: const Color(0xFF1A1A2E),
          contentTextStyle: const TextStyle(color: Colors.white),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFF00D4FF), width: 0.5),
          ),
          behavior: SnackBarBehavior.floating,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00D4FF),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          ),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          displayMedium: TextStyle(color: Colors.white),
          bodyLarge: TextStyle(color: Colors.white70),
          bodyMedium: TextStyle(color: Colors.white54),
          labelLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        dividerTheme: const DividerThemeData(
          color: Colors.white12,
          thickness: 1,
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: Color(0xFF00D4FF),
          linearTrackColor: Colors.white10,
        ),
        iconTheme: const IconThemeData(color: Colors.white70),
      ),

      home: const HomeScreen(),
    );
  }
}
