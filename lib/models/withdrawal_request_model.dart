class WithdrawalRequestModel {
  final String id;
  final String lawyerId;
  final String lawyerName;
  final String lawyerEmail;
  final double amount;
  final double fees;
  final double netAmount;
  final String bankName;
  final String accountNumber;
  final String iban;
  final String accountHolderName;
  final String status; // pending, approved, rejected, completed
  final String? rejectionReason;
  final DateTime requestedAt;
  final DateTime? processedAt;
  final String? processedBy;
  final String? notes;

  WithdrawalRequestModel({
    required this.id,
    required this.lawyerId,
    required this.lawyerName,
    required this.lawyerEmail,
    required this.amount,
    required this.fees,
    required this.netAmount,
    required this.bankName,
    required this.accountNumber,
    required this.iban,
    required this.accountHolderName,
    required this.status,
    this.rejectionReason,
    required this.requestedAt,
    this.processedAt,
    this.processedBy,
    this.notes,
  });

  factory WithdrawalRequestModel.fromMap(Map<String, dynamic> map) {
    return WithdrawalRequestModel(
      id: map['id'] ?? '',
      lawyerId: map['lawyerId'] ?? '',
      lawyerName: map['lawyerName'] ?? '',
      lawyerEmail: map['lawyerEmail'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      fees: (map['fees'] ?? 0.0).toDouble(),
      netAmount: (map['netAmount'] ?? 0.0).toDouble(),
      bankName: map['bankName'] ?? '',
      accountNumber: map['accountNumber'] ?? '',
      iban: map['iban'] ?? '',
      accountHolderName: map['accountHolderName'] ?? '',
      status: map['status'] ?? 'pending',
      rejectionReason: map['rejectionReason'],
      requestedAt: map['requestedAt'] is DateTime
          ? map['requestedAt'] as DateTime
          : (map['requestedAt']?.toDate() ?? DateTime.now()),
      processedAt: map['processedAt'] is DateTime
          ? map['processedAt'] as DateTime
          : map['processedAt']?.toDate(),
      processedBy: map['processedBy'],
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'lawyerId': lawyerId,
      'lawyerName': lawyerName,
      'lawyerEmail': lawyerEmail,
      'amount': amount,
      'fees': fees,
      'netAmount': netAmount,
      'bankName': bankName,
      'accountNumber': accountNumber,
      'iban': iban,
      'accountHolderName': accountHolderName,
      'status': status,
      'rejectionReason': rejectionReason,
      'requestedAt': requestedAt,
      'processedAt': processedAt,
      'processedBy': processedBy,
      'notes': notes,
    };
  }

  WithdrawalRequestModel copyWith({
    String? id,
    String? lawyerId,
    String? lawyerName,
    String? lawyerEmail,
    double? amount,
    double? fees,
    double? netAmount,
    String? bankName,
    String? accountNumber,
    String? iban,
    String? accountHolderName,
    String? status,
    String? rejectionReason,
    DateTime? requestedAt,
    DateTime? processedAt,
    String? processedBy,
    String? notes,
  }) {
    return WithdrawalRequestModel(
      id: id ?? this.id,
      lawyerId: lawyerId ?? this.lawyerId,
      lawyerName: lawyerName ?? this.lawyerName,
      lawyerEmail: lawyerEmail ?? this.lawyerEmail,
      amount: amount ?? this.amount,
      fees: fees ?? this.fees,
      netAmount: netAmount ?? this.netAmount,
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      iban: iban ?? this.iban,
      accountHolderName: accountHolderName ?? this.accountHolderName,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      requestedAt: requestedAt ?? this.requestedAt,
      processedAt: processedAt ?? this.processedAt,
      processedBy: processedBy ?? this.processedBy,
      notes: notes ?? this.notes,
    );
  }
}
