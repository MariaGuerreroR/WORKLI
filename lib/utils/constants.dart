import 'package:flutter/material.dart';

class AppColors {
  // Primary — deep teal
  static const Color primary = Color(0xFF0D7377);
  static const Color primaryLight = Color(0xFF14A0A5);
  static const Color primaryDark = Color(0xFF075053);

  // Secondary — warm amber
  static const Color secondary = Color(0xFFF5A623);
  static const Color secondaryLight = Color(0xFFFBC45E);
  static const Color secondaryDark = Color(0xFFC8830E);

  // Accent — soft coral
  static const Color accent = Color(0xFFE76F51);

  // Status colors
  static const Color success = Color(0xFF2EAA62);
  static const Color warning = Color(0xFFF5A623);
  static const Color error = Color(0xFFE5484D);
  static const Color info = Color(0xFF3B82F6);

  // Neutrals — light
  static const Color background = Color(0xFFF7F8FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE2E8F0);
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);

  // Neutrals — dark
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color textPrimaryDark = Color(0xFFF1F5F9);
  static const Color textSecondaryDark = Color(0xFF94A3B8);

  // Chart palette
  static const List<Color> chartPalette = [
    Color(0xFF0D7377),
    Color(0xFFF5A623),
    Color(0xFFE76F51),
    Color(0xFF3B82F6),
    Color(0xFF2EAA62),
    Color(0xFF8B5CF6),
  ];
}

class AppDimens {
  // Spacing (8px system)
  static const double spaceXs = 4;
  static const double spaceSm = 8;
  static const double spaceMd = 16;
  static const double spaceLg = 24;
  static const double spaceXl = 32;
  static const double spaceXxl = 48;

  // Radii
  static const double radiusS = 8;
  static const double radiusM = 12;
  static const double radiusL = 16;
  static const double radiusXl = 24;

  // Sidebar
  static const double sidebarWidth = 260;
  static const double sidebarCollapsedWidth = 72;
}

class AppStrings {
  static const String appName = 'Workli';
  static const String appTagline = 'Coordinación de investigación académica';

  // Navigation
  static const String dashboard = 'Panel';
  static const String projects = 'Proyectos';
  static const String tasks = 'Tareas';
  static const String documents = 'Documentos';
  static const String chat = 'Chat';
  static const String notifications = 'Notificaciones';
  static const String reports = 'Informes';
  static const String analytics = 'Analíticas';
  static const String profile = 'Perfil';
}

class AppAnimations {
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
}
