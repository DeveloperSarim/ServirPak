import 'package:cloud_firestore/cloud_firestore.dart';

class LawyerModel {
  final String id;
  final String userId;
  final String email;
  final String name;
  final String phone;
  final String specialization;
  final String experience;
  final String barCouncilNumber;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<String> kycDocuments;
  final Map<String, String> documentUrls;
  final String? profileImage;
  final String? bio;
  final double? rating;
  final int? totalCases;
  final List<String>? languages;
  final String? address;
  final String? city;
  final String? province;
  final String? education;
  final String? officeAddress;
  final String? officeHours;
  final String? consultationFee;
  final String? certifications;
  final String? awards;
  final DateTime? firstCaseDate;

  LawyerModel({
    required this.id,
    required this.userId,
    required this.email,
    required this.name,
    required this.phone,
    required this.specialization,
    required this.experience,
    required this.barCouncilNumber,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.kycDocuments = const [],
    this.documentUrls = const {},
    this.profileImage,
    this.bio,
    this.rating,
    this.totalCases,
    this.languages,
    this.address,
    this.city,
    this.province,
    this.education,
    this.officeAddress,
    this.officeHours,
    this.consultationFee,
    this.certifications,
    this.awards,
    this.firstCaseDate,
  });

  factory LawyerModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return LawyerModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      specialization: data['specialization'] ?? '',
      experience: data['experience'] ?? '',
      barCouncilNumber: data['barCouncilNumber'] ?? '',
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      kycDocuments: List<String>.from(data['kycDocuments'] ?? []),
      documentUrls: Map<String, String>.from(data['documentUrls'] ?? {}),
      profileImage: data['profileImage'] ?? '',
      bio: data['bio'],
      rating: data['rating']?.toDouble(),
      totalCases: data['totalCases'],
      languages: data['languages'] is List
          ? List<String>.from(data['languages'])
          : data['languages'] is String
          ? [data['languages'] as String]
          : null,
      address: data['address'],
      city: data['city'],
      province: data['province'],
      education: data['education'],
      officeAddress: data['officeAddress'],
      officeHours: data['officeHours'],
      consultationFee: data['consultationFee'],
      certifications: data['certifications'] is List
          ? (data['certifications'] as List<String>?)?.join(', ')
          : data['certifications'] is String
          ? data['certifications'] as String
          : null,
      awards: data['awards'] is List
          ? (data['awards'] as List<String>?)?.join(', ')
          : data['awards'] is String
          ? data['awards'] as String
          : null,
      firstCaseDate: data['firstCaseDate'] != null
          ? (data['firstCaseDate'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'email': email,
      'name': name,
      'phone': phone,
      'specialization': specialization,
      'experience': experience,
      'barCouncilNumber': barCouncilNumber,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'kycDocuments': kycDocuments,
      'documentUrls': documentUrls,
      'profileImage': profileImage,
      'bio': bio,
      'rating': rating,
      'totalCases': totalCases,
      'languages': languages,
      'address': address,
      'city': city,
      'province': province,
      'education': education,
      'officeAddress': officeAddress,
      'officeHours': officeHours,
      'consultationFee': consultationFee,
      'certifications': certifications,
      'awards': awards,
      'firstCaseDate': firstCaseDate != null
          ? Timestamp.fromDate(firstCaseDate!)
          : null,
    };
  }

  LawyerModel copyWith({
    String? id,
    String? userId,
    String? email,
    String? name,
    String? phone,
    String? specialization,
    String? experience,
    String? barCouncilNumber,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? kycDocuments,
    Map<String, String>? documentUrls,
    String? profileImage,
    String? bio,
    double? rating,
    int? totalCases,
    List<String>? languages,
    String? address,
    String? city,
    String? province,
    String? education,
    String? officeAddress,
    String? officeHours,
    String? consultationFee,
    String? certifications,
    String? awards,
    DateTime? firstCaseDate,
  }) {
    return LawyerModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      specialization: specialization ?? this.specialization,
      experience: experience ?? this.experience,
      barCouncilNumber: barCouncilNumber ?? this.barCouncilNumber,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      kycDocuments: kycDocuments ?? this.kycDocuments,
      documentUrls: documentUrls ?? this.documentUrls,
      profileImage: profileImage ?? this.profileImage,
      bio: bio ?? this.bio,
      rating: rating ?? this.rating,
      totalCases: totalCases ?? this.totalCases,
      languages: languages ?? this.languages,
      address: address ?? this.address,
      city: city ?? this.city,
      province: province ?? this.province,
      education: education ?? this.education,
      officeAddress: officeAddress ?? this.officeAddress,
      officeHours: officeHours ?? this.officeHours,
      consultationFee: consultationFee ?? this.consultationFee,
      certifications: certifications ?? this.certifications,
      awards: awards ?? this.awards,
      firstCaseDate: firstCaseDate ?? this.firstCaseDate,
    );
  }

  bool get isApproved => status == 'approved';
  bool get isVerified => status == 'verified';
  bool get isPending => status == 'pending';
  bool get isRejected => status == 'rejected';
  bool get hasKycDocuments => kycDocuments.isNotEmpty;

  // Calculate experience from first case date to current date
  String get calculatedExperience {
    if (firstCaseDate == null) {
      // Fallback to manual experience if firstCaseDate is not set
      return experience;
    }

    final now = DateTime.now();
    final difference = now.difference(firstCaseDate!);
    final years = (difference.inDays / 365).floor();
    final months = ((difference.inDays % 365) / 30).floor();

    if (years > 0) {
      return months > 0 ? '$years years $months months' : '$years years';
    } else if (months > 0) {
      return '$months months';
    } else {
      return 'Less than 1 month';
    }
  }

  // Get experience in years only (for display purposes)
  int get experienceInYears {
    if (firstCaseDate == null) {
      // Try to parse existing experience string
      final expMatch = RegExp(r'(\d+)').firstMatch(experience);
      return expMatch != null ? int.parse(expMatch.group(1)!) : 0;
    }

    final now = DateTime.now();
    final difference = now.difference(firstCaseDate!);
    return (difference.inDays / 365).floor();
  }
}
