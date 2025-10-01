import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payment_model.dart';
import '../constants/app_constants.dart';

class PaymentService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create payment record
  static Future<String> createPayment({
    required String consultationId,
    required String userId,
    required String lawyerId,
    required double amount,
    required String paymentMethod,
    String currency = 'PKR',
    String? paymentGateway,
  }) async {
    try {
      PaymentModel payment = PaymentModel(
        id: '', // Will be set by Firestore
        consultationId: consultationId,
        userId: userId,
        lawyerId: lawyerId,
        amount: amount,
        currency: currency,
        paymentMethod: paymentMethod,
        status: AppConstants.pendingStatus,
        paymentGateway: paymentGateway,
        createdAt: DateTime.now(),
      );

      DocumentReference docRef = await _firestore
          .collection(AppConstants.paymentsCollection)
          .add(payment.toFirestore());

      print('Payment created successfully: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('Error creating payment: $e');
      rethrow;
    }
  }

  // Update payment status
  static Future<void> updatePaymentStatus({
    required String paymentId,
    required String status,
    String? transactionId,
    String? gatewayTransactionId,
    String? failureReason,
  }) async {
    try {
      Map<String, dynamic> updateData = {
        'status': status,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      if (transactionId != null) updateData['transactionId'] = transactionId;
      if (gatewayTransactionId != null)
        updateData['gatewayTransactionId'] = gatewayTransactionId;
      if (failureReason != null) updateData['failureReason'] = failureReason;
      if (status == AppConstants.completedStatus) {
        updateData['completedAt'] = Timestamp.fromDate(DateTime.now());
      }

      await _firestore
          .collection(AppConstants.paymentsCollection)
          .doc(paymentId)
          .update(updateData);

      print('Payment status updated: $paymentId -> $status');
    } catch (e) {
      print('Error updating payment status: $e');
      rethrow;
    }
  }

  // Get payment by ID
  static Future<PaymentModel?> getPaymentById(String paymentId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(AppConstants.paymentsCollection)
          .doc(paymentId)
          .get();

      if (doc.exists) {
        return PaymentModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting payment by ID: $e');
      return null;
    }
  }

  // Get payments by user ID
  static Future<List<PaymentModel>> getPaymentsByUserId(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.paymentsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => PaymentModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting payments by user ID: $e');
      return [];
    }
  }

  // Get payments by lawyer ID
  static Future<List<PaymentModel>> getPaymentsByLawyerId(
    String lawyerId,
  ) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.paymentsCollection)
          .where('lawyerId', isEqualTo: lawyerId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => PaymentModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting payments by lawyer ID: $e');
      return [];
    }
  }

  // Get payments by consultation ID
  static Future<List<PaymentModel>> getPaymentsByConsultationId(
    String consultationId,
  ) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.paymentsCollection)
          .where('consultationId', isEqualTo: consultationId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => PaymentModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting payments by consultation ID: $e');
      return [];
    }
  }

  // Get payments by status
  static Future<List<PaymentModel>> getPaymentsByStatus(String status) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.paymentsCollection)
          .where('status', isEqualTo: status)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => PaymentModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting payments by status: $e');
      return [];
    }
  }

  // Get all payments (Admin only)
  static Future<List<PaymentModel>> getAllPayments() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.paymentsCollection)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => PaymentModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting all payments: $e');
      return [];
    }
  }

  // Get payment statistics
  static Future<Map<String, dynamic>> getPaymentStatistics() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.paymentsCollection)
          .get();

      double totalAmount = 0;
      int completedPayments = 0;
      int pendingPayments = 0;
      int failedPayments = 0;

      for (DocumentSnapshot doc in snapshot.docs) {
        PaymentModel payment = PaymentModel.fromFirestore(doc);

        if (payment.isCompleted) {
          totalAmount += payment.amount;
          completedPayments++;
        } else if (payment.isPending) {
          pendingPayments++;
        } else if (payment.isFailed) {
          failedPayments++;
        }
      }

      return {
        'totalAmount': totalAmount,
        'completedPayments': completedPayments,
        'pendingPayments': pendingPayments,
        'failedPayments': failedPayments,
        'totalPayments': snapshot.docs.length,
      };
    } catch (e) {
      print('Error getting payment statistics: $e');
      return {};
    }
  }

  // Process payment (simulate payment gateway)
  static Future<bool> processPayment({
    required String paymentId,
    required String paymentMethod,
    required double amount,
  }) async {
    try {
      // Simulate payment processing delay
      await Future.delayed(const Duration(seconds: 2));

      // Simulate payment success/failure based on amount
      bool isSuccess = amount > 0 && amount <= 100000; // Max 100k PKR

      if (isSuccess) {
        await updatePaymentStatus(
          paymentId: paymentId,
          status: AppConstants.completedStatus,
          transactionId: 'TXN_${DateTime.now().millisecondsSinceEpoch}',
          gatewayTransactionId: 'GW_${DateTime.now().millisecondsSinceEpoch}',
        );
      } else {
        await updatePaymentStatus(
          paymentId: paymentId,
          status: AppConstants.failedStatus,
          failureReason: 'Payment amount exceeds limit or invalid',
        );
      }

      return isSuccess;
    } catch (e) {
      print('Error processing payment: $e');
      await updatePaymentStatus(
        paymentId: paymentId,
        status: AppConstants.failedStatus,
        failureReason: 'Payment processing error: ${e.toString()}',
      );
      return false;
    }
  }

  // Refund payment
  static Future<bool> refundPayment({
    required String paymentId,
    required double amount,
    String? reason,
  }) async {
    try {
      PaymentModel? payment = await getPaymentById(paymentId);
      if (payment == null || !payment.isCompleted) {
        return false;
      }

      // Simulate refund processing
      await Future.delayed(const Duration(seconds: 1));

      await updatePaymentStatus(
        paymentId: paymentId,
        status: AppConstants.refundedStatus,
        failureReason: reason ?? 'Refund requested by user',
      );

      return true;
    } catch (e) {
      print('Error refunding payment: $e');
      return false;
    }
  }
}
