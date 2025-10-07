class CaseInfo {
  final String caseType;
  final String description;
  final String city;
  final String urgency;
  final String budget;
  final String experience;
  final String specialization;
  final String contactPreference;
  final String? additionalInfo;

  CaseInfo({
    required this.caseType,
    required this.description,
    required this.city,
    required this.urgency,
    required this.budget,
    required this.experience,
    required this.specialization,
    required this.contactPreference,
    this.additionalInfo,
  });

  Map<String, dynamic> toMap() {
    return {
      'caseType': caseType,
      'description': description,
      'city': city,
      'urgency': urgency,
      'budget': budget,
      'experience': experience,
      'specialization': specialization,
      'contactPreference': contactPreference,
      'additionalInfo': additionalInfo,
    };
  }

  factory CaseInfo.fromMap(Map<String, dynamic> map) {
    return CaseInfo(
      caseType: map['caseType'] ?? '',
      description: map['description'] ?? '',
      city: map['city'] ?? '',
      urgency: map['urgency'] ?? '',
      budget: map['budget'] ?? '',
      experience: map['experience'] ?? '',
      specialization: map['specialization'] ?? '',
      contactPreference: map['contactPreference'] ?? '',
      additionalInfo: map['additionalInfo'],
    );
  }
}
