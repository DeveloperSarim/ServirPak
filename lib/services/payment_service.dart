import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_constants.dart';
import '../models/consultation_model.dart';
import 'lawyer_wallet_service.dart';
import 'google_meet_service.dart';

class PaymentService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Save payment details to Firestore
  static Future<bool> savePayment({
    required String userId,
    required String lawyerId,
    required String lawyerName,
    required String lawyerSpecialization,
    required double consultationFee,
    required double platformFee,
    required double totalAmount,
    required String consultationDate,
    required String consultationTime,
    required String description,
    required String category,
    required String cardLastFour,
    required String cardType,
    required String paymentStatus,
    required String paymentId,
  }) async {
    try {
      print('💾 Saving payment to Firestore...');

      // Create payment document
      Map<String, dynamic> paymentData = {
        'userId': userId,
        'lawyerId': lawyerId,
        'lawyerName': lawyerName,
        'lawyerSpecialization': lawyerSpecialization,
        'consultationFee': consultationFee,
        'platformFee': platformFee,
        'totalAmount': totalAmount,
        'consultationDate': consultationDate,
        'consultationTime': consultationTime,
        'description': description,
        'category': category,
        'cardLastFour': cardLastFour,
        'cardType': cardType,
        'paymentStatus': paymentStatus,
        'paymentId': paymentId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Save to payments collection
      DocumentReference paymentRef = await _firestore
          .collection(AppConstants.paymentsCollection)
          .add(paymentData);

      print('✅ Payment saved with ID: ${paymentRef.id}');

      // Also save to user's payment history
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection('payments')
          .doc(paymentRef.id)
          .set(paymentData);

      print('✅ Payment added to user payment history');

      // Update user's total spent
      await _updateUserTotalSpent(userId, totalAmount);

      // Create consultation if payment is completed
      if (paymentStatus == 'completed') {
        await _createConsultation(
          userId: userId,
          lawyerId: lawyerId,
          lawyerName: lawyerName,
          consultationDate: consultationDate,
          consultationTime: consultationTime,
          description: description,
          category: category,
          consultationFee: consultationFee,
          platformFee: platformFee,
          totalAmount: totalAmount,
          paymentId: paymentId,
        );

        // Add payment to lawyer wallet
        await _addPaymentToLawyerWallet(
          lawyerId: lawyerId,
          lawyerName: lawyerName,
          lawyerEmail: '', // We'll get this from lawyer data
          amount: consultationFee,
          consultationId: paymentRef.id,
          clientName: '', // We'll get this from user data
        );
      }

      return true;
    } catch (e) {
      print('❌ Error saving payment: $e');
      return false;
    }
  }

  // Update user's total spent amount
  static Future<void> _updateUserTotalSpent(
    String userId,
    double amount,
  ) async {
    try {
      DocumentReference userRef = _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId);

      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot userDoc = await transaction.get(userRef);

        if (userDoc.exists) {
          Map<String, dynamic> userData =
              userDoc.data() as Map<String, dynamic>;
          double currentTotal = (userData['totalSpent'] ?? 0.0).toDouble();
          double newTotal = currentTotal + amount;

          transaction.update(userRef, {
            'totalSpent': newTotal,
            'lastPaymentDate': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

          print('💰 Updated user total spent: $newTotal');
        }
      });
    } catch (e) {
      print('❌ Error updating user total spent: $e');
    }
  }

  // Get user's payment history
  static Future<List<Map<String, dynamic>>> getUserPaymentHistory(
    String userId,
  ) async {
    try {
      QuerySnapshot payments = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection('payments')
          .orderBy('createdAt', descending: true)
          .get();

      return payments.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('❌ Error getting payment history: $e');
      return [];
    }
  }

  // Get all payments (admin view)
  static Future<List<Map<String, dynamic>>> getAllPayments() async {
    try {
      QuerySnapshot payments = await _firestore
          .collection(AppConstants.paymentsCollection)
          .orderBy('createdAt', descending: true)
          .get();

      return payments.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('❌ Error getting all payments: $e');
      return [];
    }
  }

  // Get payments by status
  static Future<List<Map<String, dynamic>>> getPaymentsByStatus(
    String status,
  ) async {
    try {
      QuerySnapshot payments = await _firestore
          .collection(AppConstants.paymentsCollection)
          .where('paymentStatus', isEqualTo: status)
          .orderBy('createdAt', descending: true)
          .get();

      return payments.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('❌ Error getting payments by status: $e');
      return [];
    }
  }

  // Update payment status
  static Future<bool> updatePaymentStatus(
    String paymentId,
    String newStatus,
  ) async {
    try {
      await _firestore
          .collection(AppConstants.paymentsCollection)
          .doc(paymentId)
          .update({
            'paymentStatus': newStatus,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      print('✅ Payment status updated to: $newStatus');
      return true;
    } catch (e) {
      print('❌ Error updating payment status: $e');
      return false;
    }
  }

  // Get payment statistics
  static Future<Map<String, dynamic>> getPaymentStatistics() async {
    try {
      QuerySnapshot payments = await _firestore
          .collection(AppConstants.paymentsCollection)
          .get();

      double totalRevenue = 0.0;
      double totalPlatformFee = 0.0;
      int totalPayments = payments.docs.length;
      int successfulPayments = 0;
      int failedPayments = 0;

      for (QueryDocumentSnapshot doc in payments.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        if (data['paymentStatus'] == 'completed') {
          successfulPayments++;
          totalRevenue += (data['totalAmount'] ?? 0.0).toDouble();
          totalPlatformFee += (data['platformFee'] ?? 0.0).toDouble();
        } else if (data['paymentStatus'] == 'failed') {
          failedPayments++;
        }
      }

      return {
        'totalPayments': totalPayments,
        'successfulPayments': successfulPayments,
        'failedPayments': failedPayments,
        'totalRevenue': totalRevenue,
        'totalPlatformFee': totalPlatformFee,
        'successRate': totalPayments > 0
            ? (successfulPayments / totalPayments * 100)
            : 0.0,
      };
    } catch (e) {
      print('❌ Error getting payment statistics: $e');
      return {};
    }
  }

  // Add payment to lawyer wallet
  static Future<void> _addPaymentToLawyerWallet({
    required String lawyerId,
    required String lawyerName,
    required String lawyerEmail,
    required double amount,
    required String consultationId,
    required String clientName,
  }) async {
    try {
      // Get lawyer email if not provided
      if (lawyerEmail.isEmpty) {
        DocumentSnapshot lawyerDoc = await _firestore
            .collection(AppConstants.usersCollection)
            .doc(lawyerId)
            .get();

        if (lawyerDoc.exists) {
          Map<String, dynamic> lawyerData =
              lawyerDoc.data() as Map<String, dynamic>;
          lawyerEmail = lawyerData['email'] ?? '';
        }
      }

      // Get client name if not provided
      if (clientName.isEmpty) {
        // We'll need to get this from the payment data or user data
        clientName = 'Client';
      }

      // Create or get lawyer wallet
      await LawyerWalletService.createOrGetWallet(
        lawyerId: lawyerId,
        lawyerName: lawyerName,
        lawyerEmail: lawyerEmail,
      );

      // Add payment to wallet
      await LawyerWalletService.addPaymentToWallet(
        lawyerId: lawyerId,
        amount: amount,
        consultationId: consultationId,
        clientName: clientName,
      );

      print('✅ Payment added to lawyer wallet: $amount');
    } catch (e) {
      print('❌ Error adding payment to lawyer wallet: $e');
    }
  }

  // Create consultation after successful payment
  static Future<void> _createConsultation({
    required String userId,
    required String lawyerId,
    required String lawyerName,
    required String consultationDate,
    required String consultationTime,
    required String description,
    required String category,
    required double consultationFee,
    required double platformFee,
    required double totalAmount,
    required String paymentId,
  }) async {
    try {
      print('📅 Creating consultation after successful payment...');

      // Generate consultation ID
      String consultationId =
          'consultation_${DateTime.now().millisecondsSinceEpoch}';

      // Generate meeting link
      String meetingLink = GoogleMeetService.generateScheduledMeetingLink(
        lawyerId: lawyerId,
        userId: userId,
        consultationId: consultationId,
        date: consultationDate,
        time: consultationTime,
        lawyerName: lawyerName,
        userName: 'Client', // We'll get this from user data
      );

      // Parse date and time
      DateTime scheduledDateTime = _parseDateTime(
        consultationDate,
        consultationTime,
      );

      // Create consultation model
      final consultation = ConsultationModel(
        id: consultationId,
        userId: userId,
        lawyerId: lawyerId,
        type: 'paid',
        category: category,
        city: 'Lahore', // Default city
        description: description,
        price: consultationFee,
        platformFee: platformFee,
        totalAmount: totalAmount,
        consultationDate: consultationDate,
        consultationTime: consultationTime,
        meetingLink: meetingLink,
        status: AppConstants.pendingStatus,
        scheduledAt: scheduledDateTime,
        paymentId: paymentId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save consultation to Firestore
      await _firestore
          .collection(AppConstants.consultationsCollection)
          .doc(consultationId)
          .set(consultation.toFirestore());

      print('✅ Consultation created successfully with ID: $consultationId');
      print('✅ Meeting link: $meetingLink');
    } catch (e) {
      print('❌ Error creating consultation: $e');
    }
  }

  // Parse date and time to DateTime
  static DateTime _parseDateTime(String date, String time) {
    try {
      // Parse date (format: YYYY-MM-DD)
      List<String> dateParts = date.split('-');
      int year = int.parse(dateParts[0]);
      int month = int.parse(dateParts[1]);
      int day = int.parse(dateParts[2]);

      // Parse time (format: HH:MM)
      List<String> timeParts = time.split(':');
      int hour = int.parse(timeParts[0]);
      int minute = int.parse(timeParts[1]);

      return DateTime(year, month, day, hour, minute);
    } catch (e) {
      print('❌ Error parsing date/time: $e');
      // Return current time + 1 day as fallback
      return DateTime.now().add(const Duration(days: 1));
    }
  }
}
