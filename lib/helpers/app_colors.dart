import 'package:flutter/material.dart';

class AppColors {
  // ─── Primary Brand ───
  static const Color primary = Color(0xFF2E7D32);
  static const Color primaryDark = Color(0xFF1B5E20);
  static const Color primaryLight = Color(0xFF4CAF50);
  static const Color primaryLighter = Color(0xFF66BB6A);
  static const Color accent = Color(0xFFA5D6A7);

  // ─── Gradients ───
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1B5E20), Color(0xFF43A047)],
  );

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1A3A1A), Color(0xFF2E7D32)],
  );

  // ─── Light Mode ───
  static const Color lightBackground = Color(0xFFF4FAF4);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF1A2E1A);
  static const Color lightTextSecondary = Color(0xFF5A7A5A);
  static const Color lightDivider = Color(0xFFE8F5E9);
  static const Color lightBorder = Color(0xFFC8E6C9);
  static const Color lightInputFill = Color(0xFFF9FFF9);

  // ─── Dark Mode ───
  static const Color darkBackground = Color(0xFF0F1A0F);
  static const Color darkSurface = Color(0xFF182018);
  static const Color darkCard = Color(0xFF1E2D1E);
  static const Color darkCardElevated = Color(0xFF243024);
  static const Color darkTextPrimary = Color(0xFFF0F7F0);
  static const Color darkTextSecondary = Color(0xFF8EBA8E);
  static const Color darkDivider = Color(0xFF2A3D2A);
  static const Color darkBorder = Color(0xFF2E4D2E);
  static const Color darkInputFill = Color(0xFF192619);

  // ─── Status ───
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFE53935);
  static const Color info = Color(0xFF29B6F6);

  // ─── Nutrients ───
  static const Color proteinColor = Color(0xFFEF5350);
  static const Color carbsColor = Color(0xFF42A5F5);
  static const Color fatColor = Color(0xFFFFA726);
  static const Color calorieColor = Color(0xFF4CAF50);
  static const Color waterColor = Color(0xFF26C6DA);

  // ─── Status Badge ───
  static const Color statusPending = Color(0xFFFF8F00);
  static const Color statusForwarded = Color(0xFF1565C0);
  static const Color statusRejected = Color(0xFFC62828);
  static const Color statusFilled = Color(0xFF6A1B9A);
  static const Color statusApproved = Color(0xFF2E7D32);
}
