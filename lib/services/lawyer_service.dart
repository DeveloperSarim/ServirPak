import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/lawyer_model.dart';
import '../constants/app_constants.dart';

class LawyerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all verified lawyers
  Future<List<LawyerModel>> getVerifiedLawyers() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.lawyersCollection)
          .where('status', isEqualTo: AppConstants.verifiedStatus)
          .orderBy('name')
          .get();

      return snapshot.docs
          .map((doc) => LawyerModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting verified lawyers: $e');
      return [];
    }
  }

  // Get lawyer by ID
  Future<LawyerModel?> getLawyerById(String lawyerId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(AppConstants.lawyersCollection)
          .doc(lawyerId)
          .get();

      if (doc.exists) {
        return LawyerModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting lawyer by ID: $e');
      return null;
    }
  }

  // Search lawyers by specialization
  Future<List<LawyerModel>> searchLawyersBySpecialization(
    String specialization,
  ) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.lawyersCollection)
          .where('status', isEqualTo: AppConstants.verifiedStatus)
          .where('specialization', isEqualTo: specialization)
          .get();

      return snapshot.docs
          .map((doc) => LawyerModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error searching lawyers by specialization: $e');
      return [];
    }
  }

  // Update lawyer profile
  Future<bool> updateLawyerProfile(
    String lawyerId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _firestore
          .collection(AppConstants.lawyersCollection)
          .doc(lawyerId)
          .update({...data, 'updatedAt': Timestamp.now()});

      return true;
    } catch (e) {
      print('Error updating lawyer profile: $e');
      return false;
    }
  }

  // Seed detailed lawyer data
  Future<void> seedLawyerDetails() async {
    try {
      print('🌱 Seeding lawyer detailed data...');

      final lawyers = [
        {
          'id': 'lawyer_001',
          'userId': 'legal_expert_001',
          'email': 'john.doe@servipak.com',
          'name': 'John Doe',
          'phone': '+92-300-1234567',
          'status': AppConstants.verifiedStatus,
          'specialization': 'Corporate Law',
          'experience': '8 years',
          'barCouncilNumber': 'BC-2023-001',
          'profileImage':
              'https://res.cloudinary.com/dii8rpixj/image/upload/v1234567890/corporate_lawyer.jpg',
          'bio':
              'Experienced corporate lawyer with expertise in mergers, acquisitions, and corporate governance. John has successfully represented numerous multinational corporations.',
          'education':
              'LL.M in Corporate Law from Harvard Law School, LL.B from LUMS',
          'languages': 'English, Urdu',
          'officeAddress':
              'Suite 101, Corporate Plaza, Shahrah-e-Faisal, Karachi',
          'officeHours': 'Mon-Fri: 9 AM - 6 PM',
          'consultationFee': 'PKR 15,000',
          'certifications':
              'Certified Corporate Governance Professional (CCGP)',
          'awards': 'Lawyer of the Year 2022 - Corporate Law Society',
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        },
        {
          'id': 'lawyer_002',
          'userId': 'legal_expert_002',
          'email': 'sarah.ahmed@servipak.com',
          'name': 'Sarah Ahmed',
          'phone': '+92-300-2345678',
          'status': AppConstants.verifiedStatus,
          'specialization': 'Family Law',
          'experience': '12 years',
          'barCouncilNumber': 'BC-2023-002',
          'profileImage':
              'https://res.cloudinary.com/dii8rpixj/image/upload/v1234567890/family_lawyer.jpg',
          'bio':
              'Compassionate family lawyer specializing in divorce, custody, and adoption cases. Sarah believes in amicable solutions and protecting children\'s best interests.',
          'education': 'LL.M in Family Law from LUMS, LL.B from BUITEMS',
          'languages': 'English, Urdu, Sindhi',
          'officeAddress':
              'Flat 205, Family Legal Center, Defence Housing Society, Karachi',
          'officeHours': 'Mon-Sat: 10 AM - 4 PM',
          'consultationFee': 'PKR 10,000',
          'certifications': 'Certified Mediation Specialist (CMS)',
          'awards': 'Outstanding Advocate Award - Sindh Bar Council 2021',
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        },
        {
          'id': 'lawyer_003',
          'userId': 'legal_expert_003',
          'email': 'muhammad.hassan@servipak.com',
          'name': 'Muhammad Hassan',
          'phone': '+92-300-3456789',
          'status': AppConstants.verifiedStatus,
          'specialization': 'Criminal Law',
          'experience': '15 years',
          'barCouncilNumber': 'BC-2023-003',
          'profileImage':
              'https://res.cloudinary.com/dii8rpixj/image/upload/v1234567890/criminal_lawyer.jpg',
          'bio':
              'Expert criminal lawyer with extensive experience in criminal defense and prosecution. Muhammad has handled over 500 criminal cases successfully.',
          'education':
              'LL.M in Criminal Law from Bahria University, LL.B from KU',
          'languages': 'English, Urdu, Punjabi',
          'officeAddress': 'Chamber No. 15, High Court Building, Lahore',
          'officeHours': 'Mon-Fri: 8 AM - 8 PM',
          'consultationFee': 'PKR 20,000',
          'certifications': 'Criminal Law Specialist (CLS)',
          'awards':
              'Distinguished Criminal Lawyer Award - Punjab Bar Council 2020',
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        },
        {
          'id': 'lawyer_004',
          'userId': 'legal_expert_004',
          'email': 'fatima.khan@servipak.com',
          'name': 'Fatima Khan',
          'phone': '+92-300-4567890',
          'status': AppConstants.verifiedStatus,
          'specialization': 'Property Law',
          'experience': '10 years',
          'barCouncilNumber': 'BC-2023-004',
          'profileImage':
              'https://res.cloudinary.com/dii8rpixj/image/upload/v1234567890/property_lawyer.jpg',
          'bio':
              'Specialized property lawyer handling real estate transactions, property disputes, and land acquisition cases across Pakistan.',
          'education': 'LL.M in Property Law from NUST, LL.B from IIUI',
          'languages': 'English, Urdu, Pushto',
          'officeAddress':
              'Office 304, Real Estate Legal Consultancy, Islamabad',
          'officeHours': 'Mon-Thu: 9 AM - 5 PM',
          'consultationFee': 'PKR 12,000',
          'certifications': 'Real Estate Law Specialist (RELS)',
          'awards':
              'Property Law Excellence Award - Islamabad Bar Association 2021',
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        },
        {
          'id': 'lawyer_005',
          'userId': 'legal_expert_005',
          'email': 'omar.sheikh@servipak.com',
          'name': 'Omar Sheikh',
          'phone': '+92-300-5678901',
          'status': AppConstants.verifiedStatus,
          'specialization': 'Tax Law',
          'experience': '7 years',
          'barCouncilNumber': 'BC-2023-005',
          'profileImage':
              'https://res.cloudinary.com/dii8rpixj/image/upload/v1234567890/tax_lawyer.jpg',
          'bio':
              'Tax expert providing comprehensive tax planning and compliance services to individuals and businesses.',
          'education':
              'LL.M in Tax Law from International Islamic University, CPA certified',
          'languages': 'English, Urdu',
          'officeAddress': 'Suite 102, Tax Advisory Center, Gulberg, Lahore',
          'officeHours': 'Mon-Fri: 8:30 AM - 6:30 PM',
          'consultationFee': 'PKR 8,000',
          'certifications': 'Certified Tax Professional (CTP)',
          'awards': 'Tax Advisor of the Year - Lahore Chamber of Commerce 2022',
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        },
      ];

      // Add/update lawyer data
      for (var lawyerData in lawyers) {
        await _firestore
            .collection(AppConstants.lawyersCollection)
            .doc(lawyerData['id'] as String)
            .set(lawyerData, SetOptions(merge: true));

        print('✅ Enhanced lawyer data: ${lawyerData['name']}');
      }

      print('🎉 Lawyer detailed data seeding completed!');
    } catch (e) {
      print('❌ Error seeding lawyer details: $e');
    }
  }
}
