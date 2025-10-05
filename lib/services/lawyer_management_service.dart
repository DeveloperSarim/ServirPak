import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/lawyer_model.dart';
import '../models/user_model.dart';
import '../constants/app_constants.dart';

class LawyerManagementService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Clear all existing lawyers and users
  static Future<void> clearAllLawyersAndUsers() async {
    try {
      print('🗑️ Clearing all existing lawyers and users...');

      // Clear lawyers collection
      QuerySnapshot lawyers = await _firestore
          .collection(AppConstants.lawyersCollection)
          .get();
      for (DocumentSnapshot doc in lawyers.docs) {
        await doc.reference.delete();
        print('✅ Deleted lawyer: ${doc.id}');
      }

      // Clear users collection
      QuerySnapshot users = await _firestore
          .collection(AppConstants.usersCollection)
          .get();
      for (DocumentSnapshot doc in users.docs) {
        await doc.reference.delete();
        print('✅ Deleted user: ${doc.id}');
      }

      // Clear KYC documents
      QuerySnapshot kycDocs = await _firestore
          .collection(AppConstants.kycCollection)
          .get();
      for (DocumentSnapshot doc in kycDocs.docs) {
        await doc.reference.delete();
        print('✅ Deleted KYC doc: ${doc.id}');
      }

      print('🎉 All lawyers and users cleared successfully!');
    } catch (e) {
      print('❌ Error clearing lawyers and users: $e');
      rethrow;
    }
  }

  // Create new lawyers with passwords
  static Future<void> createNewLawyersWithPasswords() async {
    try {
      print('⚖️ Creating new lawyers with passwords...');

      final List<Map<String, dynamic>> newLawyers = [
        {
          'email': 'ahmed.khan@servipak.com',
          'password': 'lawyer123',
          'name': 'Ahmed Ali Khan',
          'phone': '+92-300-1234567',
          'specialization': 'Criminal Law',
          'experience': '8 years',
          'barCouncilNumber': 'BC-2023-001',
          'bio':
              'Experienced criminal defense lawyer with 8+ years of practice.',
          'city': 'Lahore',
          'province': 'Punjab',
          'address': '123 Main Street, Gulberg, Lahore',
          'rating': 4.8,
          'totalCases': 200,
          'languages': ['Urdu', 'English', 'Punjabi'],
        },
        {
          'email': 'fatima.sheikh@servipak.com',
          'password': 'lawyer123',
          'name': 'Fatima Sheikh',
          'phone': '+92-300-2345678',
          'specialization': 'Family Law',
          'experience': '6 years',
          'barCouncilNumber': 'BC-2023-002',
          'bio': 'Specialized in family law and divorce cases.',
          'city': 'Karachi',
          'province': 'Sindh',
          'address': '456 Clifton Road, Karachi',
          'rating': 4.9,
          'totalCases': 150,
          'languages': ['Urdu', 'English', 'Sindhi'],
        },
        {
          'email': 'muhammad.hassan@servipak.com',
          'password': 'lawyer123',
          'name': 'Muhammad Hassan',
          'phone': '+92-300-3456789',
          'specialization': 'Property Law',
          'experience': '10 years',
          'barCouncilNumber': 'BC-2023-003',
          'bio':
              'Property law expert with extensive experience in real estate.',
          'city': 'Islamabad',
          'province': 'Federal',
          'address': '789 Blue Area, Islamabad',
          'rating': 4.7,
          'totalCases': 300,
          'languages': ['Urdu', 'English'],
        },
        {
          'email': 'sara.ahmed@servipak.com',
          'password': 'lawyer123',
          'name': 'Sara Ahmed',
          'phone': '+92-300-4567890',
          'specialization': 'Business Law',
          'experience': '5 years',
          'barCouncilNumber': 'BC-2023-004',
          'bio':
              'Corporate lawyer specializing in business transactions and contracts.',
          'city': 'Lahore',
          'province': 'Punjab',
          'address': '321 DHA Phase 2, Lahore',
          'rating': 4.6,
          'totalCases': 120,
          'languages': ['Urdu', 'English'],
        },
        {
          'email': 'omar.sheikh@servipak.com',
          'password': 'lawyer123',
          'name': 'Omar Sheikh',
          'phone': '+92-300-5678901',
          'specialization': 'Tax Law',
          'experience': '7 years',
          'barCouncilNumber': 'BC-2023-005',
          'bio':
              'Tax expert providing comprehensive tax planning and compliance services.',
          'city': 'Lahore',
          'province': 'Punjab',
          'address': 'Suite 102, Tax Advisory Center, Gulberg, Lahore',
          'rating': 4.5,
          'totalCases': 180,
          'languages': ['Urdu', 'English'],
        },
        {
          'email': 'aisha.malik@servipak.com',
          'password': 'lawyer123',
          'name': 'Aisha Malik',
          'phone': '+92-300-6789012',
          'specialization': 'Labor Law',
          'experience': '4 years',
          'barCouncilNumber': 'BC-2023-006',
          'bio':
              'Labor law specialist helping employees with workplace rights.',
          'city': 'Karachi',
          'province': 'Sindh',
          'address': '654 Saddar, Karachi',
          'rating': 4.4,
          'totalCases': 90,
          'languages': ['Urdu', 'English', 'Sindhi'],
        },
        {
          'email': 'hassan.ali@servipak.com',
          'password': 'lawyer123',
          'name': 'Hassan Ali',
          'phone': '+92-300-7890123',
          'specialization': 'Immigration Law',
          'experience': '6 years',
          'barCouncilNumber': 'BC-2023-007',
          'bio':
              'Immigration lawyer helping with visa and citizenship matters.',
          'city': 'Islamabad',
          'province': 'Federal',
          'address': '987 F-8, Islamabad',
          'rating': 4.3,
          'totalCases': 110,
          'languages': ['Urdu', 'English'],
        },
        {
          'email': 'zainab.khan@servipak.com',
          'password': 'lawyer123',
          'name': 'Zainab Khan',
          'phone': '+92-300-8901234',
          'specialization': 'Intellectual Property',
          'experience': '5 years',
          'barCouncilNumber': 'BC-2023-008',
          'bio':
              'IP lawyer specializing in patents, trademarks, and copyrights.',
          'city': 'Lahore',
          'province': 'Punjab',
          'address': '147 Model Town, Lahore',
          'rating': 4.2,
          'totalCases': 80,
          'languages': ['Urdu', 'English'],
        },
      ];

      for (var lawyerData in newLawyers) {
        try {
          // Create Firebase Auth user
          UserCredential userCredential = await _auth
              .createUserWithEmailAndPassword(
                email: lawyerData['email'],
                password: lawyerData['password'],
              );

          String userId = userCredential.user!.uid;

          // Create user document
          UserModel user = UserModel(
            id: userId,
            email: lawyerData['email'],
            name: lawyerData['name'],
            phone: lawyerData['phone'],
            role: AppConstants.lawyerRole,
            status: AppConstants.verifiedStatus, // Directly verified
            createdAt: DateTime.now(),
          );

          await _firestore
              .collection(AppConstants.usersCollection)
              .doc(userId)
              .set(user.toFirestore());

          // Create lawyer document
          LawyerModel lawyer = LawyerModel(
            id: userId,
            userId: userId,
            email: lawyerData['email'],
            name: lawyerData['name'],
            phone: lawyerData['phone'],
            specialization: lawyerData['specialization'],
            experience: lawyerData['experience'],
            barCouncilNumber: lawyerData['barCouncilNumber'],
            status: AppConstants.verifiedStatus,
            bio: lawyerData['bio'],
            rating: lawyerData['rating'].toDouble(),
            totalCases: lawyerData['totalCases'],
            languages: List<String>.from(lawyerData['languages']),
            address: lawyerData['address'],
            city: lawyerData['city'],
            province: lawyerData['province'],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          await _firestore
              .collection(AppConstants.lawyersCollection)
              .doc(userId)
              .set(lawyer.toFirestore());

          print(
            '✅ Created lawyer: ${lawyerData['name']} (${lawyerData['email']})',
          );
          print('   Password: ${lawyerData['password']}');
        } catch (e) {
          print('❌ Error creating lawyer ${lawyerData['email']}: $e');
        }
      }

      print('🎉 All new lawyers created successfully!');
    } catch (e) {
      print('❌ Error creating new lawyers: $e');
      rethrow;
    }
  }

  // Complete process: Clear old and create new
  static Future<void> replaceAllLawyers() async {
    try {
      await clearAllLawyersAndUsers();
      await createNewLawyersWithPasswords();
      print('🎉 Lawyer replacement completed successfully!');
    } catch (e) {
      print('❌ Error replacing lawyers: $e');
      rethrow;
    }
  }

  // Get all lawyer credentials
  static Map<String, String> getLawyerCredentials() {
    return {
      'ahmed.khan@servipak.com': 'lawyer123',
      'fatima.sheikh@servipak.com': 'lawyer123',
      'muhammad.hassan@servipak.com': 'lawyer123',
      'sara.ahmed@servipak.com': 'lawyer123',
      'omar.sheikh@servipak.com': 'lawyer123',
      'aisha.malik@servipak.com': 'lawyer123',
      'hassan.ali@servipak.com': 'lawyer123',
      'zainab.khan@servipak.com': 'lawyer123',
    };
  }
}
