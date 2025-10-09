class LawyerWalletModel {
  final String id;
  final String lawyerId;
  final String lawyerName;
  final String lawyerEmail;
  final double currentBalance;
  final double totalEarnings;
  final double totalWithdrawn;
  final double totalFees;
  final int totalConsultations;
  final DateTime createdAt;
  final DateTime updatedAt;

  LawyerWalletModel({
    required this.id,
    required this.lawyerId,
    required this.lawyerName,
    required this.lawyerEmail,
    required this.currentBalance,
    required this.totalEarnings,
    required this.totalWithdrawn,
    required this.totalFees,
    required this.totalConsultations,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LawyerWalletModel.fromMap(Map<String, dynamic> map) {
    return LawyerWalletModel(
      id: map['id'] ?? '',
      lawyerId: map['lawyerId'] ?? '',
      lawyerName: map['lawyerName'] ?? '',
      lawyerEmail: map['lawyerEmail'] ?? '',
      currentBalance: (map['currentBalance'] ?? 0.0).toDouble(),
      totalEarnings: (map['totalEarnings'] ?? 0.0).toDouble(),
      totalWithdrawn: (map['totalWithdrawn'] ?? 0.0).toDouble(),
      totalFees: (map['totalFees'] ?? 0.0).toDouble(),
      totalConsultations: map['totalConsultations'] ?? 0,
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
      updatedAt: map['updatedAt']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'lawyerId': lawyerId,
      'lawyerName': lawyerName,
      'lawyerEmail': lawyerEmail,
      'currentBalance': currentBalance,
      'totalEarnings': totalEarnings,
      'totalWithdrawn': totalWithdrawn,
      'totalFees': totalFees,
      'totalConsultations': totalConsultations,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  LawyerWalletModel copyWith({
    String? id,
    String? lawyerId,
    String? lawyerName,
    String? lawyerEmail,
    double? currentBalance,
    double? totalEarnings,
    double? totalWithdrawn,
    double? totalFees,
    int? totalConsultations,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LawyerWalletModel(
      id: id ?? this.id,
      lawyerId: lawyerId ?? this.lawyerId,
      lawyerName: lawyerName ?? this.lawyerName,
      lawyerEmail: lawyerEmail ?? this.lawyerEmail,
      currentBalance: currentBalance ?? this.currentBalance,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      totalWithdrawn: totalWithdrawn ?? this.totalWithdrawn,
      totalFees: totalFees ?? this.totalFees,
      totalConsultations: totalConsultations ?? this.totalConsultations,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
