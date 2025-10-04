import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../constants/app_constants.dart';

class ConsultationNotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static int _lastConsultationCount = 0;

  // Show notification when new consultation arrives
  static void showNewConsultationNotification(
    BuildContext context,
    String lawyerName,
    String category,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.notifications_active, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'New Consultation Request!',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('$lawyerName - $category'),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF8B4513),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () {
            // Navigate to consultations screen
            Navigator.pushNamed(context, '/lawyer-consultations');
          },
        ),
      ),
    );
  }

  // Check for new consultations and show notification
  static void checkForNewConsultations(BuildContext context) async {
    try {
      final session = await AuthService.getSavedUserSession();
      if (session.isEmpty) return;

      String lawyerId = session['userId'] as String;

      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.consultationsCollection)
          .where('lawyerId', isEqualTo: lawyerId)
          .where('status', isEqualTo: AppConstants.pendingStatus)
          .get();

      int currentCount = snapshot.docs.length;

      if (currentCount > _lastConsultationCount && _lastConsultationCount > 0) {
        // New consultation arrived
        if (snapshot.docs.isNotEmpty) {
          var latestDoc = snapshot.docs.first;
          var data = latestDoc.data() as Map<String, dynamic>;

          showNewConsultationNotification(
            context,
            data['category'] ?? 'Unknown Category',
            data['type'] ?? 'Unknown Type',
          );
        }
      }

      _lastConsultationCount = currentCount;
    } catch (e) {
      print('Error checking for new consultations: $e');
    }
  }

  // Reset notification count (call when lawyer opens consultations screen)
  static void resetNotificationCount() {
    _lastConsultationCount = 0;
  }
}
