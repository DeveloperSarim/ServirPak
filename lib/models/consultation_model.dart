import 'package:cloud_firestore/cloud_firestore.dart';

class ConsultationModel {
  final String id;
  final String userId;
  final String lawyerId;
  final String type; // 'free', 'paid', 'premium'
  final String category; // 'criminal', 'family', 'property', etc.
  final String city;
  final String description;
  final double price;
  final double platformFee; // 5% platform fee
  final double totalAmount; // price + platformFee
  final String consultationDate; // Date of consultation
  final String consultationTime; // Time of consultation
  final String meetingLink; // Google Meet/Zoom link
  final String
  status; // 'pending', 'accepted', 'rejected', 'completed', 'cancelled'
  final DateTime scheduledAt;
  final DateTime? completedAt;
  final String? notes;
  final String? paymentId;
  final String? cancellationReason; // New field for cancellation reason
  final DateTime createdAt;
  final DateTime? updatedAt;

  ConsultationModel({
    required this.id,
    required this.userId,
    required this.lawyerId,
    required this.type,
    required this.category,
    required this.city,
    required this.description,
    required this.price,
    required this.platformFee,
    required this.totalAmount,
    required this.consultationDate,
    required this.consultationTime,
    required this.meetingLink,
    required this.status,
    required this.scheduledAt,
    this.completedAt,
    this.notes,
    this.paymentId,
    this.cancellationReason,
    required this.createdAt,
    this.updatedAt,
  });

  factory ConsultationModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return ConsultationModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      lawyerId: data['lawyerId'] ?? '',
      type: data['type'] ?? 'free',
      category: data['category'] ?? '',
      city: data['city'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      platformFee: (data['platformFee'] ?? 0.0).toDouble(),
      totalAmount: (data['totalAmount'] ?? 0.0).toDouble(),
      consultationDate: data['consultationDate'] ?? '',
      consultationTime: data['consultationTime'] ?? '',
      meetingLink: data['meetingLink'] ?? '',
      status: data['status'] ?? 'pending',
      scheduledAt: (data['scheduledAt'] as Timestamp).toDate(),
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      notes: data['notes'],
      paymentId: data['paymentId'],
      cancellationReason: data['cancellationReason'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'lawyerId': lawyerId,
      'type': type,
      'category': category,
      'city': city,
      'description': description,
      'price': price,
      'platformFee': platformFee,
      'totalAmount': totalAmount,
      'consultationDate': consultationDate,
      'consultationTime': consultationTime,
      'meetingLink': meetingLink,
      'status': status,
      'scheduledAt': Timestamp.fromDate(scheduledAt),
      'completedAt': completedAt != null
          ? Timestamp.fromDate(completedAt!)
          : null,
      'notes': notes,
      'paymentId': paymentId,
      'cancellationReason': cancellationReason,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  ConsultationModel copyWith({
    String? id,
    String? userId,
    String? lawyerId,
    String? type,
    String? category,
    String? city,
    String? description,
    double? price,
    double? platformFee,
    double? totalAmount,
    String? consultationDate,
    String? consultationTime,
    String? meetingLink,
    String? status,
    DateTime? scheduledAt,
    DateTime? completedAt,
    String? notes,
    String? paymentId,
    String? cancellationReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ConsultationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      lawyerId: lawyerId ?? this.lawyerId,
      type: type ?? this.type,
      category: category ?? this.category,
      city: city ?? this.city,
      description: description ?? this.description,
      price: price ?? this.price,
      platformFee: platformFee ?? this.platformFee,
      totalAmount: totalAmount ?? this.totalAmount,
      consultationDate: consultationDate ?? this.consultationDate,
      consultationTime: consultationTime ?? this.consultationTime,
      meetingLink: meetingLink ?? this.meetingLink,
      status: status ?? this.status,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      completedAt: completedAt ?? this.completedAt,
      notes: notes ?? this.notes,
      paymentId: paymentId ?? this.paymentId,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isFree => type == 'free';
  bool get isPaid => type == 'paid';
  bool get isPremium => type == 'premium';
  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
}
