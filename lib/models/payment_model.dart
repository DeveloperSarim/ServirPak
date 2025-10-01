import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentModel {
  final String id;
  final String consultationId;
  final String userId;
  final String lawyerId;
  final double amount;
  final String currency;
  final String
  paymentMethod; // 'card', 'bank_transfer', 'easypaisa', 'jazzcash'
  final String status; // 'pending', 'completed', 'failed', 'refunded'
  final String? transactionId;
  final String? paymentGateway; // 'stripe', 'paypal', 'local'
  final String? gatewayTransactionId;
  final String? failureReason;
  final DateTime createdAt;
  final DateTime? completedAt;
  final DateTime? updatedAt;

  PaymentModel({
    required this.id,
    required this.consultationId,
    required this.userId,
    required this.lawyerId,
    required this.amount,
    required this.currency,
    required this.paymentMethod,
    required this.status,
    this.transactionId,
    this.paymentGateway,
    this.gatewayTransactionId,
    this.failureReason,
    required this.createdAt,
    this.completedAt,
    this.updatedAt,
  });

  factory PaymentModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return PaymentModel(
      id: doc.id,
      consultationId: data['consultationId'] ?? '',
      userId: data['userId'] ?? '',
      lawyerId: data['lawyerId'] ?? '',
      amount: (data['amount'] ?? 0.0).toDouble(),
      currency: data['currency'] ?? 'PKR',
      paymentMethod: data['paymentMethod'] ?? 'card',
      status: data['status'] ?? 'pending',
      transactionId: data['transactionId'],
      paymentGateway: data['paymentGateway'],
      gatewayTransactionId: data['gatewayTransactionId'],
      failureReason: data['failureReason'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'consultationId': consultationId,
      'userId': userId,
      'lawyerId': lawyerId,
      'amount': amount,
      'currency': currency,
      'paymentMethod': paymentMethod,
      'status': status,
      'transactionId': transactionId,
      'paymentGateway': paymentGateway,
      'gatewayTransactionId': gatewayTransactionId,
      'failureReason': failureReason,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null
          ? Timestamp.fromDate(completedAt!)
          : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  PaymentModel copyWith({
    String? id,
    String? consultationId,
    String? userId,
    String? lawyerId,
    double? amount,
    String? currency,
    String? paymentMethod,
    String? status,
    String? transactionId,
    String? paymentGateway,
    String? gatewayTransactionId,
    String? failureReason,
    DateTime? createdAt,
    DateTime? completedAt,
    DateTime? updatedAt,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      consultationId: consultationId ?? this.consultationId,
      userId: userId ?? this.userId,
      lawyerId: lawyerId ?? this.lawyerId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      transactionId: transactionId ?? this.transactionId,
      paymentGateway: paymentGateway ?? this.paymentGateway,
      gatewayTransactionId: gatewayTransactionId ?? this.gatewayTransactionId,
      failureReason: failureReason ?? this.failureReason,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isPending => status == 'pending';
  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';
  bool get isRefunded => status == 'refunded';
  bool get isCardPayment => paymentMethod == 'card';
  bool get isBankTransfer => paymentMethod == 'bank_transfer';
  bool get isEasyPaisa => paymentMethod == 'easypaisa';
  bool get isJazzCash => paymentMethod == 'jazzcash';
}
