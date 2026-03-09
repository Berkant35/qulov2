import 'package:flutter/material.dart';

abstract final class AppColors {
  // ─── Background & Surface ───
  static const background = Color(0xFF0D0D0D);
  static const scaffold = Color(0xFF121212);
  static const surface = Color(0xFF1A1A1A);
  static const surfaceElevated = Color(0xFF242424);
  static const surfaceInput = Color(0xFF2A2A2A);

  // ─── Primary (Mor Neon) ───
  static const primary = Color(0xFFBB86FC);
  static const primaryDark = Color(0xFF9C27B0);
  static const primaryLight = Color(0xFFE1BEE7);
  static const primarySurface = Color(0x1ABB86FC);

  // ─── Secondary (Yesil Neon) ───
  static const secondary = Color(0xFF69F0AE);
  static const secondaryDark = Color(0xFF4CAF50);
  static const secondaryLight = Color(0xFFB9F6CA);
  static const secondarySurface = Color(0x1A69F0AE);

  // ─── Semantic ───
  static const error = Color(0xFFCF6679);
  static const success = Color(0xFF69F0AE);
  static const warning = Color(0xFFFFB74D);
  static const info = Color(0xFF64B5F6);

  // ─── Text ───
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFB0B0B0);
  static const textHint = Color(0xFF666666);

  // ─── Border & Divider ───
  static const border = Color(0xFF2A2A2A);
  static const divider = Color(0xFF2A2A2A);

  // ─── Badge ───
  static const Color gold = Color(0xFFFFD700);
  static const Color silver = Color(0xFFC0C0C0);
  static const Color bronze = Color(0xFFCD7F32);

  // ─── Gradients ───
  static const purpleGradient = LinearGradient(
    colors: [Color(0xFFBB86FC), Color(0xFF9C27B0)],
  );

  static const greenGradient = LinearGradient(
    colors: [Color(0xFF69F0AE), Color(0xFF4CAF50)],
  );

  static const primaryButtonGradient = LinearGradient(
    colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2)],
  );
}

/// Light theme colors
abstract final class AppColorsLight {
  // ─── Background & Surface ───
  static const background = Color(0xFFFAFAFA);
  static const scaffold = Color(0xFFFFFFFF);
  static const surface = Color(0xFFF5F5F5);
  static const surfaceElevated = Color(0xFFFFFFFF);
  static const surfaceInput = Color(0xFFF0F0F0);

  // ─── Text ───
  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF666666);
  static const textHint = Color(0xFF999999);

  // ─── Border & Divider ───
  static const border = Color(0xFFE0E0E0);
  static const divider = Color(0xFFE0E0E0);
}
