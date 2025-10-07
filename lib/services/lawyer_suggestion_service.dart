import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/lawyer_model.dart';
import '../constants/app_constants.dart';

class LawyerSuggestionService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Search lawyers based on case information
  static Future<List<LawyerModel>> findLawyersForCase({
    required String caseType,
    required String city,
    String? specialization,
    String? experience,
    String? budget,
  }) async {
    try {
      print('🔍 LawyerSuggestionService: Searching for lawyers...');
      print('   Case Type: $caseType');
      print('   City: $city');
      print('   Specialization: $specialization');

      Query query = _firestore
          .collection(AppConstants.lawyersCollection)
          .where('status', isEqualTo: AppConstants.verifiedStatus);

      // Add city filter if provided
      if (city.isNotEmpty) {
        query = query.where('city', isEqualTo: city);
      }

      // Add specialization filter if provided
      if (specialization != null && specialization.isNotEmpty) {
        query = query.where('specialization', isEqualTo: specialization);
      }

      QuerySnapshot snapshot = await query.get();
      print(
        '🔍 LawyerSuggestionService: Found ${snapshot.docs.length} lawyers in database',
      );

      List<LawyerModel> lawyers = snapshot.docs
          .map((doc) => LawyerModel.fromFirestore(doc))
          .toList();

      // Filter by experience if provided
      if (experience != null && experience.isNotEmpty) {
        lawyers = _filterByExperience(lawyers, experience);
      }

      // Filter by budget if provided
      if (budget != null && budget.isNotEmpty) {
        lawyers = _filterByBudget(lawyers, budget);
      }

      // Sort by rating (highest first)
      lawyers.sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));

      // If no verified lawyers found, try to get any lawyers
      if (lawyers.isEmpty) {
        print(
          '🔍 LawyerSuggestionService: No verified lawyers found, trying to get any lawyers...',
        );
        QuerySnapshot allSnapshot = await _firestore
            .collection(AppConstants.lawyersCollection)
            .get();

        print(
          '🔍 LawyerSuggestionService: Found ${allSnapshot.docs.length} total lawyers in database',
        );

        lawyers = allSnapshot.docs
            .map((doc) => LawyerModel.fromFirestore(doc))
            .toList();
      }

      return lawyers.take(5).toList(); // Return top 5 lawyers
    } catch (e) {
      print('❌ Error finding lawyers: $e');
      return [];
    }
  }

  // Filter lawyers by experience
  static List<LawyerModel> _filterByExperience(
    List<LawyerModel> lawyers,
    String experience,
  ) {
    return lawyers.where((lawyer) {
      final lawyerExp = int.tryParse(lawyer.experience) ?? 0;
      final requiredExp = int.tryParse(experience) ?? 0;
      return lawyerExp >= requiredExp;
    }).toList();
  }

  // Filter lawyers by budget
  static List<LawyerModel> _filterByBudget(
    List<LawyerModel> lawyers,
    String budget,
  ) {
    return lawyers.where((lawyer) {
      if (lawyer.consultationFee == null) return true;

      final lawyerFee = double.tryParse(lawyer.consultationFee!) ?? 0;
      final maxBudget = double.tryParse(budget) ?? 0;

      return lawyerFee <= maxBudget;
    }).toList();
  }

  // Get all specializations
  static Future<List<String>> getAllSpecializations() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.lawyersCollection)
          .where('status', isEqualTo: AppConstants.verifiedStatus)
          .get();

      Set<String> specializations = {};
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final specialization = data['specialization'] as String?;
        if (specialization != null && specialization.isNotEmpty) {
          specializations.add(specialization);
        }
      }

      return specializations.toList()..sort();
    } catch (e) {
      print('❌ Error getting specializations: $e');
      return [];
    }
  }

  // Get all cities
  static Future<List<String>> getAllCities() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.lawyersCollection)
          .where('status', isEqualTo: AppConstants.verifiedStatus)
          .get();

      Set<String> cities = {};
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final city = data['city'] as String?;
        if (city != null && city.isNotEmpty) {
          cities.add(city);
        }
      }

      return cities.toList()..sort();
    } catch (e) {
      print('❌ Error getting cities: $e');
      return [];
    }
  }

  // Get lawyer details by ID
  static Future<LawyerModel?> getLawyerById(String lawyerId) async {
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
      print('❌ Error getting lawyer by ID: $e');
      return null;
    }
  }

  // Create sample lawyers for testing if database is empty
  static Future<void> createSampleLawyers() async {
    try {
      print('🔍 LawyerSuggestionService: Creating sample lawyers...');

      final sampleLawyers = [
        {
          'name': 'Ahmed Ali Khan',
          'email': 'ahmed.ali@servirpak.com',
          'phone': '+92-300-1234567',
          'specialization': 'Criminal Law',
          'experience': '8',
          'barCouncilNumber': 'BC-001',
          'status': AppConstants.verifiedStatus,
          'rating': 4.8,
          'totalCases': 150,
          'city': 'Karachi',
          'province': 'Sindh',
          'consultationFee': '5000',
          'bio': 'Experienced criminal lawyer with 8 years of practice.',
          'languages': ['English', 'Urdu'],
          'address': 'Clifton, Karachi',
        },
        {
          'name': 'Sara Ahmed',
          'email': 'sara.ahmed@servirpak.com',
          'phone': '+92-300-9876543',
          'specialization': 'Family Law',
          'experience': '6',
          'barCouncilNumber': 'BC-002',
          'status': AppConstants.verifiedStatus,
          'rating': 4.6,
          'totalCases': 120,
          'city': 'Lahore',
          'province': 'Punjab',
          'consultationFee': '4000',
          'bio': 'Specialized in family law and divorce cases.',
          'languages': ['English', 'Urdu', 'Punjabi'],
          'address': 'Gulberg, Lahore',
        },
        {
          'name': 'Muhammad Hassan',
          'email': 'm.hassan@servirpak.com',
          'phone': '+92-300-5555555',
          'specialization': 'Property Law',
          'experience': '10',
          'barCouncilNumber': 'BC-003',
          'status': AppConstants.verifiedStatus,
          'rating': 4.9,
          'totalCases': 200,
          'city': 'Islamabad',
          'province': 'Federal',
          'consultationFee': '6000',
          'bio': 'Expert in property disputes and real estate law.',
          'languages': ['English', 'Urdu'],
          'address': 'F-8, Islamabad',
        },
      ];

      for (var lawyerData in sampleLawyers) {
        try {
          await _firestore
              .collection(AppConstants.lawyersCollection)
              .add(lawyerData);
          print('✅ Created sample lawyer: ${lawyerData['name']}');
        } catch (e) {
          print('❌ Error creating sample lawyer ${lawyerData['name']}: $e');
        }
      }

      print('🎉 Sample lawyers created successfully!');
    } catch (e) {
      print('❌ Error creating sample lawyers: $e');
    }
  }
}
