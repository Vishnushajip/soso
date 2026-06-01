import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Reusable ScaffoldMessenger wrapper to show premium SnackBars.
/// Automatically cleans technical error prefixes and auto-dismisses after 3 seconds.
class AppSnackBar {
  AppSnackBar._();

  static String _cleanMessage(String message) {
    return message
        .replaceAll('StateError: ', '')
        .replaceAll('Bad state: ', '')
        .replaceAll('Exception: ', '')
        .trim();
  }

  static void showError(BuildContext context, String message) {
    final cleaned = _cleanMessage(message);
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          cleaned,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 14,
          ),
        ),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  static void showSuccess(BuildContext context, String message) {
    final cleaned = _cleanMessage(message);
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          cleaned,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 14,
          ),
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
