import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String name;
  final String phone;
  final String role;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? profileImage;
  final Map<String, dynamic>? additionalInfo;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.phone,
    required this.role,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.profileImage,
    this.additionalInfo,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      role: data['role'] ?? 'user',
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      profileImage: data['profileImage'],
      additionalInfo: data['additionalInfo'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'phone': phone,
      'role': role,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'profileImage': profileImage,
      'additionalInfo': additionalInfo,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? phone,
    String? role,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? profileImage,
    Map<String, dynamic>? additionalInfo,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      profileImage: profileImage ?? this.profileImage,
      additionalInfo: additionalInfo ?? this.additionalInfo,
    );
  }

  bool get isAdmin => role == 'admin';
  bool get isLawyer => role == 'lawyer';
  bool get isUser => role == 'user';
  bool get isApproved => status == 'approved';
  bool get isVerified => status == 'verified';
  bool get isPending => status == 'pending';
  bool get isRejected => status == 'rejected';
}
