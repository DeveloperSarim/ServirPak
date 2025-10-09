import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/withdrawal_request_model.dart';
import 'lawyer_wallet_service.dart';

class WithdrawalService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'withdrawal_requests';
  static const double _minimumWithdrawal = 10000.0; // 10k minimum
  static const double _feePercentage = 0.05; // 5% fees

  /// Create withdrawal request
  static Future<bool> createWithdrawalRequest({
    required String lawyerId,
    required String lawyerName,
    required String lawyerEmail,
    required double amount,
    required String bankName,
    required String accountNumber,
    required String iban,
    required String accountHolderName,
    String? notes,
  }) async {
    try {
      // Check minimum withdrawal amount
      if (amount < _minimumWithdrawal) {
        print('❌ Withdrawal amount must be at least $_minimumWithdrawal');
        return false;
      }

      // Check lawyer wallet balance
      var wallet = await LawyerWalletService.getWallet(lawyerId);
      if (wallet == null || wallet.currentBalance < amount) {
        print('❌ Insufficient balance for withdrawal');
        return false;
      }

      // Calculate fees
      double fees = amount * _feePercentage;
      double netAmount = amount - fees;

      // Create withdrawal request
      String requestId = _firestore.collection(_collection).doc().id;

      WithdrawalRequestModel withdrawalRequest = WithdrawalRequestModel(
        id: requestId,
        lawyerId: lawyerId,
        lawyerName: lawyerName,
        lawyerEmail: lawyerEmail,
        amount: amount,
        fees: fees,
        netAmount: netAmount,
        bankName: bankName,
        accountNumber: accountNumber,
        iban: iban,
        accountHolderName: accountHolderName,
        status: 'pending',
        requestedAt: DateTime.now(),
        notes: notes,
      );

      await _firestore
          .collection(_collection)
          .doc(requestId)
          .set(withdrawalRequest.toMap());

      // Add transaction record
      await _addWithdrawalTransaction(
        lawyerId: lawyerId,
        requestId: requestId,
        amount: amount,
        fees: fees,
        netAmount: netAmount,
        status: 'pending',
      );

      print('✅ Withdrawal request created: $requestId');
      return true;
    } catch (e) {
      print('❌ Error creating withdrawal request: $e');
      return false;
    }
  }

  /// Get lawyer's withdrawal requests
  static Future<List<WithdrawalRequestModel>> getLawyerWithdrawals(
    String lawyerId,
  ) async {
    try {
      QuerySnapshot withdrawals = await _firestore
          .collection(_collection)
          .where('lawyerId', isEqualTo: lawyerId)
          .orderBy('requestedAt', descending: true)
          .get();

      return withdrawals.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return WithdrawalRequestModel.fromMap(data);
      }).toList();
    } catch (e) {
      print('❌ Error getting lawyer withdrawals: $e');
      return [];
    }
  }

  /// Get all withdrawal requests (for admin)
  static Future<List<WithdrawalRequestModel>> getAllWithdrawals() async {
    try {
      QuerySnapshot withdrawals = await _firestore
          .collection(_collection)
          .orderBy('requestedAt', descending: true)
          .get();

      return withdrawals.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return WithdrawalRequestModel.fromMap(data);
      }).toList();
    } catch (e) {
      print('❌ Error getting all withdrawals: $e');
      return [];
    }
  }

  /// Get pending withdrawal requests
  static Future<List<WithdrawalRequestModel>> getPendingWithdrawals() async {
    try {
      QuerySnapshot withdrawals = await _firestore
          .collection(_collection)
          .where('status', isEqualTo: 'pending')
          .orderBy('requestedAt', descending: true)
          .get();

      return withdrawals.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return WithdrawalRequestModel.fromMap(data);
      }).toList();
    } catch (e) {
      print('❌ Error getting pending withdrawals: $e');
      return [];
    }
  }

  /// Approve withdrawal request
  static Future<bool> approveWithdrawal({
    required String requestId,
    required String processedBy,
    String? notes,
  }) async {
    try {
      // Get withdrawal request
      DocumentSnapshot requestDoc = await _firestore
          .collection(_collection)
          .doc(requestId)
          .get();

      if (!requestDoc.exists) {
        print('❌ Withdrawal request not found');
        return false;
      }

      Map<String, dynamic> data = requestDoc.data() as Map<String, dynamic>;
      String lawyerId = data['lawyerId'];
      double amount = (data['amount'] ?? 0.0).toDouble();

      // Update withdrawal request status
      await _firestore.collection(_collection).doc(requestId).update({
        'status': 'approved',
        'processedAt': FieldValue.serverTimestamp(),
        'processedBy': processedBy,
        'notes': notes,
      });

      // Update lawyer wallet balance
      bool walletUpdated = await LawyerWalletService.updateWalletBalance(
        lawyerId: lawyerId,
        amount: amount,
        type: 'withdrawal',
      );

      if (!walletUpdated) {
        // Revert withdrawal request status
        await _firestore.collection(_collection).doc(requestId).update({
          'status': 'pending',
          'processedAt': null,
          'processedBy': null,
        });
        return false;
      }

      // Update transaction record
      await _updateWithdrawalTransaction(
        requestId: requestId,
        status: 'approved',
        processedBy: processedBy,
        notes: notes,
      );

      print('✅ Withdrawal request approved: $requestId');
      return true;
    } catch (e) {
      print('❌ Error approving withdrawal: $e');
      return false;
    }
  }

  /// Reject withdrawal request
  static Future<bool> rejectWithdrawal({
    required String requestId,
    required String processedBy,
    required String rejectionReason,
    String? notes,
  }) async {
    try {
      // Update withdrawal request status
      await _firestore.collection(_collection).doc(requestId).update({
        'status': 'rejected',
        'rejectionReason': rejectionReason,
        'processedAt': FieldValue.serverTimestamp(),
        'processedBy': processedBy,
        'notes': notes,
      });

      // Update transaction record
      await _updateWithdrawalTransaction(
        requestId: requestId,
        status: 'rejected',
        processedBy: processedBy,
        notes: notes,
      );

      print('✅ Withdrawal request rejected: $requestId');
      return true;
    } catch (e) {
      print('❌ Error rejecting withdrawal: $e');
      return false;
    }
  }

  /// Complete withdrawal request
  static Future<bool> completeWithdrawal({
    required String requestId,
    required String processedBy,
    String? notes,
  }) async {
    try {
      // Update withdrawal request status
      await _firestore.collection(_collection).doc(requestId).update({
        'status': 'completed',
        'processedAt': FieldValue.serverTimestamp(),
        'processedBy': processedBy,
        'notes': notes,
      });

      // Update transaction record
      await _updateWithdrawalTransaction(
        requestId: requestId,
        status: 'completed',
        processedBy: processedBy,
        notes: notes,
      );

      print('✅ Withdrawal request completed: $requestId');
      return true;
    } catch (e) {
      print('❌ Error completing withdrawal: $e');
      return false;
    }
  }

  /// Add withdrawal transaction record
  static Future<void> _addWithdrawalTransaction({
    required String lawyerId,
    required String requestId,
    required double amount,
    required double fees,
    required double netAmount,
    required String status,
  }) async {
    try {
      await _firestore.collection('lawyer_wallet_transactions').add({
        'lawyerId': lawyerId,
        'type': 'withdrawal_request',
        'amount': amount,
        'fees': fees,
        'netAmount': netAmount,
        'requestId': requestId,
        'status': status,
        'description': 'Withdrawal request created',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Error adding withdrawal transaction: $e');
    }
  }

  /// Update withdrawal transaction record
  static Future<void> _updateWithdrawalTransaction({
    required String requestId,
    required String status,
    required String processedBy,
    String? notes,
  }) async {
    try {
      QuerySnapshot transactions = await _firestore
          .collection('lawyer_wallet_transactions')
          .where('requestId', isEqualTo: requestId)
          .get();

      for (var doc in transactions.docs) {
        await doc.reference.update({
          'status': status,
          'processedBy': processedBy,
          'notes': notes,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('❌ Error updating withdrawal transaction: $e');
    }
  }

  /// Get withdrawal statistics
  static Future<Map<String, dynamic>> getWithdrawalStats() async {
    try {
      QuerySnapshot withdrawals = await _firestore
          .collection(_collection)
          .get();

      double totalRequested = 0;
      double totalApproved = 0;
      double totalRejected = 0;
      double totalCompleted = 0;
      double totalFees = 0;
      int pendingCount = 0;

      for (var doc in withdrawals.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String status = data['status'] ?? 'pending';
        double amount = (data['amount'] ?? 0.0).toDouble();
        double fees = (data['fees'] ?? 0.0).toDouble();

        totalRequested += amount;
        totalFees += fees;

        switch (status) {
          case 'pending':
            pendingCount++;
            break;
          case 'approved':
            totalApproved += amount;
            break;
          case 'rejected':
            totalRejected += amount;
            break;
          case 'completed':
            totalCompleted += amount;
            break;
        }
      }

      return {
        'totalRequested': totalRequested,
        'totalApproved': totalApproved,
        'totalRejected': totalRejected,
        'totalCompleted': totalCompleted,
        'totalFees': totalFees,
        'pendingCount': pendingCount,
        'totalRequests': withdrawals.docs.length,
      };
    } catch (e) {
      print('❌ Error getting withdrawal stats: $e');
      return {};
    }
  }
}
