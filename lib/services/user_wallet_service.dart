import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_constants.dart';
import '../models/user_wallet_model.dart';
import 'auth_service.dart';

class UserWalletService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final CollectionReference _userWalletsCollection = _firestore
      .collection(AppConstants.userWalletsCollection);

  // Create or get a user's wallet
  static Future<UserWalletModel> createOrGetWallet(String userId) async {
    try {
      final doc = await _userWalletsCollection.doc(userId).get();

      if (doc.exists) {
        return UserWalletModel.fromMap(doc.data() as Map<String, dynamic>);
      } else {
        // Fetch user details to initialize wallet
        final user = await AuthService.getUserById(userId);
        if (user == null) {
          throw Exception('User not found for wallet creation: $userId');
        }

        final newWallet = UserWalletModel(
          id: userId,
          userId: userId,
          userName: user.name,
          userEmail: user.email,
          currentBalance: 0.0,
          totalSpent: 0.0,
          totalRefunds: 0.0,
          totalConsultations: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _userWalletsCollection.doc(userId).set(newWallet.toMap());
        print('✅ User wallet created for $userId');
        return newWallet;
      }
    } catch (e) {
      print('❌ Error creating or getting user wallet for $userId: $e');
      rethrow;
    }
  }

  // Get a user's wallet by ID
  static Future<UserWalletModel?> getWallet(String userId) async {
    try {
      final doc = await _userWalletsCollection.doc(userId).get();
      if (doc.exists) {
        return UserWalletModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('❌ Error getting user wallet for $userId: $e');
      return null;
    }
  }

  // Add funds to a user's wallet (e.g., for refunds)
  static Future<void> addFundsToWallet({
    required String userId,
    required double amount,
    required String transactionType, // e.g., 'refund', 'deposit'
    String? consultationId,
    String? reason,
    String? paymentId,
  }) async {
    if (amount <= 0) {
      print('⚠️ Cannot add non-positive amount to user wallet.');
      return;
    }

    try {
      await _firestore.runTransaction((transaction) async {
        final walletRef = _userWalletsCollection.doc(userId);
        final walletDoc = await transaction.get(walletRef);

        UserWalletModel wallet;
        if (!walletDoc.exists) {
          // Create wallet if it doesn't exist
          wallet = await createOrGetWallet(userId);
        } else {
          wallet = UserWalletModel.fromMap(
            walletDoc.data() as Map<String, dynamic>,
          );
        }

        final newBalance = wallet.currentBalance + amount;
        final newTotalRefunds =
            wallet.totalRefunds + (transactionType == 'refund' ? amount : 0);

        transaction.update(walletRef, {
          'currentBalance': newBalance,
          'totalRefunds': newTotalRefunds,
          'updatedAt': Timestamp.now(),
        });

        // Add a transaction record
        await _addTransactionRecord(
          transaction: transaction,
          userId: userId,
          amount: amount,
          type: transactionType,
          description:
              reason ?? '$transactionType for consultation $consultationId',
          consultationId: consultationId,
          paymentId: paymentId,
          newBalance: newBalance,
        );
        print(
          '✅ Funds of Rs. $amount added to user $userId wallet. New balance: $newBalance',
        );
      });
    } catch (e) {
      print('❌ Error adding funds to user wallet for $userId: $e');
      rethrow;
    }
  }

  // Deduct funds from a user's wallet (e.g., for booking a consultation)
  static Future<void> deductFundsFromWallet({
    required String userId,
    required double amount,
    required String transactionType, // e.g., 'payment'
    String? consultationId,
    String? reason,
    String? paymentId,
  }) async {
    if (amount <= 0) {
      print('⚠️ Cannot deduct non-positive amount from user wallet.');
      return;
    }

    try {
      await _firestore.runTransaction((transaction) async {
        final walletRef = _userWalletsCollection.doc(userId);
        final walletDoc = await transaction.get(walletRef);

        if (!walletDoc.exists) {
          throw Exception('User wallet not found for deduction: $userId');
        }

        UserWalletModel wallet = UserWalletModel.fromMap(
          walletDoc.data() as Map<String, dynamic>,
        );

        if (wallet.currentBalance < amount) {
          throw Exception('Insufficient balance in user wallet for deduction.');
        }

        final newBalance = wallet.currentBalance - amount;
        final newTotalSpent =
            wallet.totalSpent + (transactionType == 'payment' ? amount : 0);
        final newTotalConsultations =
            wallet.totalConsultations + (transactionType == 'payment' ? 1 : 0);

        transaction.update(walletRef, {
          'currentBalance': newBalance,
          'totalSpent': newTotalSpent,
          'totalConsultations': newTotalConsultations,
          'updatedAt': Timestamp.now(),
        });

        // Add a transaction record
        await _addTransactionRecord(
          transaction: transaction,
          userId: userId,
          amount: -amount, // Negative for deduction
          type: transactionType,
          description:
              reason ?? '$transactionType for consultation $consultationId',
          consultationId: consultationId,
          paymentId: paymentId,
          newBalance: newBalance,
        );
        print(
          '✅ Funds of Rs. $amount deducted from user $userId wallet. New balance: $newBalance',
        );
      });
    } catch (e) {
      print('❌ Error deducting funds from user wallet for $userId: $e');
      rethrow;
    }
  }

  // Get recent wallet transactions for a user
  static Stream<List<Map<String, dynamic>>> getWalletTransactions(
    String userId,
  ) {
    return _userWalletsCollection
        .doc(userId)
        .collection(AppConstants.walletTransactionsCollection)
        .orderBy('timestamp', descending: true)
        .limit(10) // Limit to recent transactions
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  // Private helper to add transaction records
  static Future<void> _addTransactionRecord({
    required Transaction transaction,
    required String userId,
    required double amount,
    required String type,
    required String description,
    String? consultationId,
    String? paymentId,
    required double newBalance,
  }) async {
    final transactionRef = _userWalletsCollection
        .doc(userId)
        .collection(AppConstants.walletTransactionsCollection)
        .doc(); // Auto-generate ID

    transaction.set(transactionRef, {
      'id': transactionRef.id,
      'userId': userId,
      'amount': amount,
      'type': type,
      'description': description,
      'consultationId': consultationId,
      'paymentId': paymentId,
      'timestamp': Timestamp.now(),
      'currentBalanceSnapshot':
          newBalance, // Snapshot of balance after transaction
    });
  }
}
