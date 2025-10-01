import 'package:cloud_firestore/cloud_firestore.dart';

class CityModel {
  final String id;
  final String name;
  final String province;
  final String country;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  CityModel({
    required this.id,
    required this.name,
    required this.province,
    required this.country,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
  });

  factory CityModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return CityModel(
      id: doc.id,
      name: data['name'] ?? '',
      province: data['province'] ?? '',
      country: data['country'] ?? 'Pakistan',
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'province': province,
      'country': country,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  CityModel copyWith({
    String? id,
    String? name,
    String? province,
    String? country,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CityModel(
      id: id ?? this.id,
      name: name ?? this.name,
      province: province ?? this.province,
      country: country ?? this.country,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
