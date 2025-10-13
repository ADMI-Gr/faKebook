import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';

// Color base para estudiante ITCA
const Color kItcaOrange = Color(0xFFB72506);
// Color base actual (usuario normal) tomado como azul del app
const Color kUserBlue = Color(0xFF1976D2);

ThemeData _buildTheme(Color primary) {
  final colorScheme = ColorScheme.fromSeed(seedColor: primary);

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    primaryColor: primary,
    scaffoldBackgroundColor: const Color(0xFFF7F8FA),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: colorScheme.primary),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: colorScheme.primary,
      foregroundColor: Colors.white,
    ),
  );
}

final appThemeProvider = Provider<ThemeData>((ref) {
  final user = ref.watch(userProvider);
  final email = user?.email ?? '';
  final isStudent = email.toLowerCase().endsWith('@itca.edu.sv');
  return isStudent ? _buildTheme(kItcaOrange) : _buildTheme(kUserBlue);
});
