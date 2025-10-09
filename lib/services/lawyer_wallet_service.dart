import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/lawyer_wallet_model.dart';

class LawyerWalletService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'lawyer_wallets';

  /// Create or get lawyer wallet
  static Future<LawyerWalletModel?> createOrGetWallet({
    required String lawyerId,
    required String lawyerName,
    required String lawyerEmail,
  }) async {
    try {
      // Check if wallet already exists
      DocumentSnapshot walletDoc = await _firestore
          .collection(_collection)
          .doc(lawyerId)
          .get();

      if (walletDoc.exists) {
        return LawyerWalletModel.fromMap(
          walletDoc.data() as Map<String, dynamic>,
        );
      }

      // Create new wallet
      LawyerWalletModel newWallet = LawyerWalletModel(
        id: lawyerId,
        lawyerId: lawyerId,
        lawyerName: lawyerName,
        lawyerEmail: lawyerEmail,
        currentBalance: 0.0,
        totalEarnings: 0.0,
        totalWithdrawn: 0.0,
        totalFees: 0.0,
        totalConsultations: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection(_collection)
          .doc(lawyerId)
          .set(newWallet.toMap());

      print('✅ Lawyer wallet created successfully for: $lawyerName');
      return newWallet;
    } catch (e) {
      print('❌ Error creating/getting lawyer wallet: $e');
      return null;
    }
  }

  /// Add payment to lawyer wallet
  static Future<bool> addPaymentToWallet({
    required String lawyerId,
    required double amount,
    required String consultationId,
    required String clientName,
  }) async {
    try {
      // Get current wallet
      LawyerWalletModel? wallet = await getWallet(lawyerId);
      if (wallet == null) {
        print('❌ Wallet not found for lawyer: $lawyerId');
        return false;
      }

      // Calculate fees (5% of amount)
      double fees = amount * 0.05;
      double netAmount = amount - fees;

      // Update wallet balance
      double newBalance = wallet.currentBalance + netAmount;
      double newTotalEarnings = wallet.totalEarnings + amount;
      double newTotalFees = wallet.totalFees + fees;
      int newTotalConsultations = wallet.totalConsultations + 1;

      await _firestore.collection(_collection).doc(lawyerId).update({
        'currentBalance': newBalance,
        'totalEarnings': newTotalEarnings,
        'totalFees': newTotalFees,
        'totalConsultations': newTotalConsultations,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Add transaction record
      await _addTransactionRecord(
        lawyerId: lawyerId,
        type: 'payment',
        amount: amount,
        fees: fees,
        netAmount: netAmount,
        consultationId: consultationId,
        clientName: clientName,
        description: 'Payment received from $clientName',
      );

      print('✅ Payment added to lawyer wallet: $netAmount (Fees: $fees)');
      return true;
    } catch (e) {
      print('❌ Error adding payment to wallet: $e');
      return false;
    }
  }

  /// Get lawyer wallet
  static Future<LawyerWalletModel?> getWallet(String lawyerId) async {
    try {
      DocumentSnapshot walletDoc = await _firestore
          .collection(_collection)
          .doc(lawyerId)
          .get();

      if (walletDoc.exists) {
        return LawyerWalletModel.fromMap(
          walletDoc.data() as Map<String, dynamic>,
        );
      }
      return null;
    } catch (e) {
      print('❌ Error getting lawyer wallet: $e');
      return null;
    }
  }

  /// Update wallet balance (for withdrawals)
  static Future<bool> updateWalletBalance({
    required String lawyerId,
    required double amount,
    required String type, // 'withdrawal' or 'refund'
  }) async {
    try {
      LawyerWalletModel? wallet = await getWallet(lawyerId);
      if (wallet == null) {
        print('❌ Wallet not found for lawyer: $lawyerId');
        return false;
      }

      double newBalance = wallet.currentBalance - amount;
      double newTotalWithdrawn = wallet.totalWithdrawn + amount;

      if (newBalance < 0) {
        print('❌ Insufficient balance for withdrawal');
        return false;
      }

      await _firestore.collection(_collection).doc(lawyerId).update({
        'currentBalance': newBalance,
        'totalWithdrawn': newTotalWithdrawn,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Wallet balance updated: $type $amount');
      return true;
    } catch (e) {
      print('❌ Error updating wallet balance: $e');
      return false;
    }
  }

  /// Get wallet transactions
  static Future<List<Map<String, dynamic>>> getWalletTransactions(
    String lawyerId,
  ) async {
    try {
      QuerySnapshot transactions = await _firestore
          .collection('lawyer_wallet_transactions')
          .where('lawyerId', isEqualTo: lawyerId)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      return transactions.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('❌ Error getting wallet transactions: $e');
      return [];
    }
  }

  /// Add transaction record
  static Future<void> _addTransactionRecord({
    required String lawyerId,
    required String type,
    required double amount,
    required double fees,
    required double netAmount,
    required String consultationId,
    required String clientName,
    required String description,
  }) async {
    try {
      await _firestore.collection('lawyer_wallet_transactions').add({
        'lawyerId': lawyerId,
        'type': type,
        'amount': amount,
        'fees': fees,
        'netAmount': netAmount,
        'consultationId': consultationId,
        'clientName': clientName,
        'description': description,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Error adding transaction record: $e');
    }
  }

  /// Get all lawyer wallets (for admin)
  static Future<List<LawyerWalletModel>> getAllWallets() async {
    try {
      QuerySnapshot wallets = await _firestore
          .collection(_collection)
          .orderBy('updatedAt', descending: true)
          .get();

      return wallets.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return LawyerWalletModel.fromMap(data);
      }).toList();
    } catch (e) {
      print('❌ Error getting all wallets: $e');
      return [];
    }
  }

  /// Get wallet statistics
  static Future<Map<String, dynamic>> getWalletStats() async {
    try {
      QuerySnapshot wallets = await _firestore.collection(_collection).get();

      double totalBalance = 0;
      double totalEarnings = 0;
      double totalWithdrawn = 0;
      double totalFees = 0;
      int totalLawyers = wallets.docs.length;

      for (var doc in wallets.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        totalBalance += (data['currentBalance'] ?? 0.0).toDouble();
        totalEarnings += (data['totalEarnings'] ?? 0.0).toDouble();
        totalWithdrawn += (data['totalWithdrawn'] ?? 0.0).toDouble();
        totalFees += (data['totalFees'] ?? 0.0).toDouble();
      }

      return {
        'totalBalance': totalBalance,
        'totalEarnings': totalEarnings,
        'totalWithdrawn': totalWithdrawn,
        'totalFees': totalFees,
        'totalLawyers': totalLawyers,
      };
    } catch (e) {
      print('❌ Error getting wallet stats: $e');
      return {};
    }
  }
}
