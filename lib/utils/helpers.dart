import 'package:intl/intl.dart';

class Helpers {
  static String formatDate(DateTime date) {
    return DateFormat('d MMM yyyy', 'es').format(date);
  }

  static String formatDateShort(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  static String formatTime(DateTime time) {
    return DateFormat('HH:mm').format(time);
  }

  static String formatDateTime(DateTime dt) {
    return DateFormat('d MMM yyyy, HH:mm', 'es').format(dt);
  }

  static String formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'es',
      symbol: '\$',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  static String formatNumber(double value, {int decimals = 0}) {
    return NumberFormat.decimalPatternDigits(
      locale: 'es',
      decimalDigits: decimals,
    ).format(value);
  }

  static String formatPercent(double value, {int decimals = 0}) {
    return '${formatNumber(value, decimals: decimals)}%';
  }

  static String timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Hace un momento';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
    if (diff.inDays < 7) return 'Hace ${diff.inDays} días';
    if (diff.inDays < 30) return 'Hace ${(diff.inDays / 7).floor()} sem';
    if (diff.inDays < 365) return 'Hace ${(diff.inDays / 30).floor()} meses';
    return 'Hace ${(diff.inDays / 365).floor()} años';
  }

  static String daysUntil(DateTime? date) {
    if (date == null) return 'Sin fecha';
    final diff = date.difference(DateTime.now()).inDays;
    if (diff < 0) return 'Vencido hace ${-diff} días';
    if (diff == 0) return 'Vence hoy';
    return 'Faltan $diff días';
  }

  static String truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  static String initialsFromName(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}
