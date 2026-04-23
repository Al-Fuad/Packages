import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

extension ContextExtension on BuildContext {
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  void showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }
}

extension DateTimeExtension on DateTime {
  String toFormattedDate() => DateFormat('dd MMM yyyy').format(this);
  String toFormattedDateTime() => DateFormat('dd MMM yyyy, hh:mm a').format(this);
  String timeAgo() {
    final now = DateTime.now();
    final diff = now.difference(this);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}

extension StringExtension on String {
  String get capitalize => isEmpty ? '' : this[0].toUpperCase() + substring(1);
  bool get isValidEmail => RegExp(r"^[w-.]+@([w-]+.)+[w-]{2,4}$").hasMatch(this);
}

extension NumberExtension on num {
  String get toCurrency => NumberFormat.currency(symbol: r'$').format(this);
  String get toCompact => NumberFormat.compact().format(this);
}
