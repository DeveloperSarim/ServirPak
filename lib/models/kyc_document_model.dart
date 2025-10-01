import 'package:cloud_firestore/cloud_firestore.dart';

class KycDocumentModel {
  final String id;
  final String userId;
  final String lawyerId;
  final String documentType;
  final String documentName;
  final String documentUrl;
  final String status;
  final DateTime uploadedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? reviewNotes;
  final String? rejectionReason;

  KycDocumentModel({
    required this.id,
    required this.userId,
    required this.lawyerId,
    required this.documentType,
    required this.documentName,
    required this.documentUrl,
    required this.status,
    required this.uploadedAt,
    this.reviewedAt,
    this.reviewedBy,
    this.reviewNotes,
    this.rejectionReason,
  });

  factory KycDocumentModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return KycDocumentModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      lawyerId: data['lawyerId'] ?? '',
      documentType: data['documentType'] ?? '',
      documentName: data['documentName'] ?? '',
      documentUrl: data['documentUrl'] ?? '',
      status: data['status'] ?? 'pending',
      uploadedAt: (data['uploadedAt'] as Timestamp).toDate(),
      reviewedAt: data['reviewedAt'] != null
          ? (data['reviewedAt'] as Timestamp).toDate()
          : null,
      reviewedBy: data['reviewedBy'],
      reviewNotes: data['reviewNotes'],
      rejectionReason: data['rejectionReason'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'lawyerId': lawyerId,
      'documentType': documentType,
      'documentName': documentName,
      'documentUrl': documentUrl,
      'status': status,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'reviewedBy': reviewedBy,
      'reviewNotes': reviewNotes,
      'rejectionReason': rejectionReason,
    };
  }

  KycDocumentModel copyWith({
    String? id,
    String? userId,
    String? lawyerId,
    String? documentType,
    String? documentName,
    String? documentUrl,
    String? status,
    DateTime? uploadedAt,
    DateTime? reviewedAt,
    String? reviewedBy,
    String? reviewNotes,
    String? rejectionReason,
  }) {
    return KycDocumentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      lawyerId: lawyerId ?? this.lawyerId,
      documentType: documentType ?? this.documentType,
      documentName: documentName ?? this.documentName,
      documentUrl: documentUrl ?? this.documentUrl,
      status: status ?? this.status,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewNotes: reviewNotes ?? this.reviewNotes,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }

  bool get isApproved => status == 'approved';
  bool get isPending => status == 'pending';
  bool get isRejected => status == 'rejected';
}
