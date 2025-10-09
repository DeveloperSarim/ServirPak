import 'package:cloud_firestore/cloud_firestore.dart';

class UserWalletModel {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final double currentBalance;
  final double totalSpent; // Total amount spent by user on consultations
  final double totalRefunds; // Total amount refunded to user
  final int totalConsultations; // Total consultations booked by user
  final DateTime createdAt;
  final DateTime updatedAt;

  UserWalletModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.currentBalance,
    required this.totalSpent,
    required this.totalRefunds,
    required this.totalConsultations,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserWalletModel.fromMap(Map<String, dynamic> map) {
    return UserWalletModel(
      id: map['id'] as String,
      userId: map['userId'] as String,
      userName: map['userName'] as String,
      userEmail: map['userEmail'] as String,
      currentBalance: (map['currentBalance'] as num).toDouble(),
      totalSpent: (map['totalSpent'] as num).toDouble(),
      totalRefunds: (map['totalRefunds'] as num).toDouble(),
      totalConsultations: (map['totalConsultations'] as num).toInt(),
      createdAt: map['createdAt'] is DateTime
          ? map['createdAt'] as DateTime
          : (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] is DateTime
          ? map['updatedAt'] as DateTime
          : (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'currentBalance': currentBalance,
      'totalSpent': totalSpent,
      'totalRefunds': totalRefunds,
      'totalConsultations': totalConsultations,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  UserWalletModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userEmail,
    double? currentBalance,
    double? totalSpent,
    double? totalRefunds,
    int? totalConsultations,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserWalletModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      currentBalance: currentBalance ?? this.currentBalance,
      totalSpent: totalSpent ?? this.totalSpent,
      totalRefunds: totalRefunds ?? this.totalRefunds,
      totalConsultations: totalConsultations ?? this.totalConsultations,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
