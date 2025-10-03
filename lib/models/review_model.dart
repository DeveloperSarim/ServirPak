import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String id;
  final String lawyerId;
  final String clientId;
  final String clientName;
  final String clientEmail;
  final double rating;
  final String comment;
  final String? consultationType;
  final String? consultationId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ReviewModel({
    required this.id,
    required this.lawyerId,
    required this.clientId,
    required this.clientName,
    required this.clientEmail,
    required this.rating,
    required this.comment,
    this.consultationType,
    this.consultationId,
    required this.createdAt,
    this.updatedAt,
  });

  factory ReviewModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return ReviewModel(
      id: doc.id,
      lawyerId: data['lawyerId'] ?? '',
      clientId: data['clientId'] ?? '',
      clientName: data['clientName'] ?? '',
      clientEmail: data['clientEmail'] ?? '',
      rating: (data['rating'] ?? 0.0).toDouble(),
      comment: data['comment'] ?? '',
      consultationType: data['consultationType'],
      consultationId: data['consultationId'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'lawyerId': lawyerId,
      'clientId': clientId,
      'clientName': clientName,
      'clientEmail': clientEmail,
      'rating': rating,
      'comment': comment,
      'consultationType': consultationType,
      'consultationId': consultationId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  ReviewModel copyWith({
    String? id,
    String? lawyerId,
    String? clientId,
    String? clientName,
    String? clientEmail,
    double? rating,
    String? comment,
    String? consultationType,
    String? consultationId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReviewModel(
      id: id ?? this.id,
      lawyerId: lawyerId ?? this.lawyerId,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      clientEmail: clientEmail ?? this.clientEmail,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      consultationType: consultationType ?? this.consultationType,
      consultationId: consultationId ?? this.consultationId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
