import 'package:flutter/material.dart';

class NotificationService {
  // ============================================================
  // SHOW RIDE REQUEST
  // ============================================================

  static void showRideRequestNotification({
    required BuildContext context,
    required VoidCallback onTap,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(
              Icons.local_taxi,
              color: Colors.white,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'New ride request available!',
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'VIEW',
          onPressed: onTap,
        ),
        duration: const Duration(
          seconds: 8,
        ),
      ),
    );
  }

  // ============================================================
  // SHOW GENERAL NOTIFICATION
  // ============================================================

  static void showNotification({
    required BuildContext context,
    required String title,
    required String message,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(message),
          ],
        ),
      ),
    );
  }
}