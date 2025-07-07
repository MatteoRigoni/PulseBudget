import 'package:flutter/material.dart';

enum SnackBarType { success, error, warning, info }

class CustomSnackBar {
  static void show(
    BuildContext context, {
    required String message,
    SnackBarType type = SnackBarType.info,
    Duration duration = const Duration(seconds: 2),
    IconData? icon,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    Color backgroundColor;
    IconData defaultIcon;
    switch (type) {
      case SnackBarType.success:
        backgroundColor = colorScheme.primary;
        defaultIcon = Icons.check_circle_outline;
        break;
      case SnackBarType.error:
        backgroundColor = colorScheme.error;
        defaultIcon = Icons.error_outline;
        break;
      case SnackBarType.warning:
        backgroundColor = Colors.orange;
        defaultIcon = Icons.warning_amber_outlined;
        break;
      case SnackBarType.info:
      default:
        backgroundColor = colorScheme.secondary;
        defaultIcon = Icons.info_outline;
        break;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon ?? defaultIcon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        duration: duration,
        elevation: 2,
      ),
    );
  }
}
