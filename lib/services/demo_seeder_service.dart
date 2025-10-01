import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/lawyer_model.dart';
import '../models/kyc_document_model.dart';
import '../constants/app_constants.dart';

class DemoSeederService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Demo Users Data
  static final List<Map<String, dynamic>> demoUsers = [
    {
      'email': 'admin@servipak.com',
      'password': 'admin123',
      'name': 'Admin User',
      'phone': '+92-300-1234567',
      'role': AppConstants.adminRole,
      'status': AppConstants.verifiedStatus,
    },
    {
      'email': 'lawyer1@servipak.com',
      'password': 'lawyer123',
      'name': 'Ahmed Ali Khan',
      'phone': '+92-301-2345678',
      'role': AppConstants.lawyerRole,
      'status': AppConstants.verifiedStatus,
    },
    {
      'email': 'lawyer2@servipak.com',
      'password': 'lawyer123',
      'name': 'Fatima Sheikh',
      'phone': '+92-302-3456789',
      'role': AppConstants.lawyerRole,
      'status': AppConstants.pendingStatus,
    },
    {
      'email': 'user1@servipak.com',
      'password': 'user123',
      'name': 'Muhammad Hassan',
      'phone': '+92-303-4567890',
      'role': AppConstants.userRole,
      'status': AppConstants.verifiedStatus,
    },
    {
      'email': 'user2@servipak.com',
      'password': 'user123',
      'name': 'Ayesha Malik',
      'phone': '+92-304-5678901',
      'role': AppConstants.userRole,
      'status': AppConstants.verifiedStatus,
    },
  ];

  // Demo Lawyers Data
  static final List<Map<String, dynamic>> demoLawyers = [
    {
      'email': 'lawyer1@servipak.com',
      'name': 'Ahmed Ali Khan',
      'phone': '+92-301-2345678',
      'specialization': 'Criminal Law',
      'experience': '5 years',
      'barCouncilNumber': 'BC-2023-001',
      'status': AppConstants.verifiedStatus,
      'bio':
          'Experienced criminal lawyer with 5+ years of practice in high-profile cases.',
      'rating': 4.8,
      'totalCases': 150,
      'languages': ['Urdu', 'English', 'Punjabi'],
      'address': '123 Main Street, Gulberg',
      'city': 'Lahore',
      'province': 'Punjab',
    },
    {
      'email': 'lawyer2@servipak.com',
      'name': 'Fatima Sheikh',
      'phone': '+92-302-3456789',
      'specialization': 'Family Law',
      'experience': '3 years',
      'barCouncilNumber': 'BC-2023-002',
      'status': AppConstants.pendingStatus,
      'bio':
          'Specialized in family law and divorce cases with compassionate approach.',
      'rating': 4.5,
      'totalCases': 75,
      'languages': ['Urdu', 'English', 'Sindhi'],
      'address': '456 Park Avenue, Clifton',
      'city': 'Karachi',
      'province': 'Sindh',
    },
  ];

  // Demo KYC Documents Data
  static final List<Map<String, dynamic>> demoKycDocuments = [
    {
      'lawyerId': 'lawyer1@servipak.com',
      'documentType': AppConstants.cnicDocument,
      'documentName': 'CNIC - Ahmed Ali Khan',
      'documentUrl': 'https://example.com/cnic_ahmed.pdf',
      'status': AppConstants.approvedStatus,
    },
    {
      'lawyerId': 'lawyer1@servipak.com',
      'documentType': AppConstants.degreeDocument,
      'documentName': 'LLB Degree - Ahmed Ali Khan',
      'documentUrl': 'https://example.com/degree_ahmed.pdf',
      'status': AppConstants.approvedStatus,
    },
    {
      'lawyerId': 'lawyer1@servipak.com',
      'documentType': AppConstants.licenseDocument,
      'documentName': 'Bar Council License - Ahmed Ali Khan',
      'documentUrl': 'https://example.com/license_ahmed.pdf',
      'status': AppConstants.approvedStatus,
    },
    {
      'lawyerId': 'lawyer2@servipak.com',
      'documentType': AppConstants.cnicDocument,
      'documentName': 'CNIC - Fatima Sheikh',
      'documentUrl': 'https://example.com/cnic_fatima.pdf',
      'status': AppConstants.pendingStatus,
    },
    {
      'lawyerId': 'lawyer2@servipak.com',
      'documentType': AppConstants.degreeDocument,
      'documentName': 'LLB Degree - Fatima Sheikh',
      'documentUrl': 'https://example.com/degree_fatima.pdf',
      'status': AppConstants.pendingStatus,
    },
  ];

  static Future<void> seedDemoData() async {
    try {
      print('🌱 Starting demo data seeding...');

      // Sign in as admin first to get permissions
      await _signInAsAdmin();

      // Create demo users
      await _createDemoUsers();

      // Create demo lawyers
      await _createDemoLawyers();

      // Create demo KYC documents
      await _createDemoKycDocuments();

      print('✅ Demo data seeding completed successfully!');
    } catch (e) {
      print('❌ Error seeding demo data: $e');
      rethrow;
    }
  }

  static Future<void> _signInAsAdmin() async {
    try {
      // Try to sign in with admin credentials
      await _auth.signInWithEmailAndPassword(
        email: 'admin@servipak.com',
        password: 'admin123',
      );
      print('✅ Signed in as admin for seeding');
    } catch (e) {
      print('⚠️ Admin sign in failed, trying to create admin first: $e');
      // If admin doesn't exist, create it first
      try {
        UserCredential adminCredential = await _auth
            .createUserWithEmailAndPassword(
              email: 'admin@servipak.com',
              password: 'admin123',
            );

        // Create admin user document
        UserModel adminUser = UserModel(
          id: adminCredential.user!.uid,
          email: 'admin@servipak.com',
          name: 'Admin User',
          phone: '+92-300-1234567',
          role: AppConstants.adminRole,
          status: AppConstants.verifiedStatus,
          createdAt: DateTime.now(),
        );

        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(adminCredential.user!.uid)
            .set(adminUser.toFirestore());

        print('✅ Created admin user for seeding');
      } catch (createError) {
        print('❌ Failed to create admin user: $createError');
        rethrow;
      }
    }
  }

  static Future<void> _createDemoUsers() async {
    print('👥 Creating demo users...');

    for (var userData in demoUsers) {
      try {
        // Check if user already exists in Firestore
        QuerySnapshot existingUser = await _firestore
            .collection(AppConstants.usersCollection)
            .where('email', isEqualTo: userData['email'])
            .get();

        if (existingUser.docs.isNotEmpty) {
          print('⚠️ User ${userData['email']} already exists, skipping...');
          continue;
        }

        // Create Firebase Auth user
        UserCredential userCredential = await _auth
            .createUserWithEmailAndPassword(
              email: userData['email'],
              password: userData['password'],
            );

        // Create user document in Firestore
        UserModel user = UserModel(
          id: userCredential.user!.uid,
          email: userData['email'],
          name: userData['name'],
          phone: userData['phone'],
          role: userData['role'],
          status: userData['status'],
          createdAt: DateTime.now(),
        );

        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(userCredential.user!.uid)
            .set(user.toFirestore());

        print('✅ Created user: ${userData['email']} (${userData['role']})');
      } catch (e) {
        print('❌ Error creating user ${userData['email']}: $e');
        // Continue with next user even if one fails
      }
    }
  }

  static Future<void> _createDemoLawyers() async {
    print('⚖️ Creating demo lawyers...');

    for (var lawyerData in demoLawyers) {
      try {
        // Check if lawyer already exists
        QuerySnapshot existingLawyer = await _firestore
            .collection(AppConstants.lawyersCollection)
            .where('email', isEqualTo: lawyerData['email'])
            .get();

        if (existingLawyer.docs.isNotEmpty) {
          print('⚠️ Lawyer ${lawyerData['email']} already exists, skipping...');
          continue;
        }

        // Get user ID from email
        QuerySnapshot userQuery = await _firestore
            .collection(AppConstants.usersCollection)
            .where('email', isEqualTo: lawyerData['email'])
            .get();

        if (userQuery.docs.isNotEmpty) {
          String userId = userQuery.docs.first.id;

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
            status: lawyerData['status'],
            createdAt: DateTime.now(),
            bio: lawyerData['bio'],
            rating: lawyerData['rating'],
            totalCases: lawyerData['totalCases'],
            languages: List<String>.from(lawyerData['languages']),
            address: lawyerData['address'],
            city: lawyerData['city'],
            province: lawyerData['province'],
          );

          await _firestore
              .collection(AppConstants.lawyersCollection)
              .doc(userId)
              .set(lawyer.toFirestore());

          print('✅ Created lawyer: ${lawyerData['name']}');
        } else {
          print('⚠️ User not found for lawyer ${lawyerData['email']}');
        }
      } catch (e) {
        print('❌ Error creating lawyer ${lawyerData['name']}: $e');
      }
    }
  }

  static Future<void> _createDemoKycDocuments() async {
    print('📄 Creating demo KYC documents...');

    for (var docData in demoKycDocuments) {
      try {
        // Check if KYC document already exists
        QuerySnapshot existingDoc = await _firestore
            .collection(AppConstants.kycCollection)
            .where('documentName', isEqualTo: docData['documentName'])
            .get();

        if (existingDoc.docs.isNotEmpty) {
          print(
            '⚠️ KYC document ${docData['documentName']} already exists, skipping...',
          );
          continue;
        }

        // Get lawyer ID from email
        QuerySnapshot lawyerQuery = await _firestore
            .collection(AppConstants.lawyersCollection)
            .where('email', isEqualTo: docData['lawyerId'])
            .get();

        if (lawyerQuery.docs.isNotEmpty) {
          String lawyerId = lawyerQuery.docs.first.id;

          // Create KYC document
          KycDocumentModel kycDoc = KycDocumentModel(
            id: '',
            userId: lawyerId,
            lawyerId: lawyerId,
            documentType: docData['documentType'],
            documentName: docData['documentName'],
            documentUrl: docData['documentUrl'],
            status: docData['status'],
            uploadedAt: DateTime.now(),
          );

          await _firestore
              .collection(AppConstants.kycCollection)
              .add(kycDoc.toFirestore());

          print('✅ Created KYC document: ${docData['documentName']}');
        } else {
          print(
            '⚠️ Lawyer not found for KYC document ${docData['documentName']}',
          );
        }
      } catch (e) {
        print('❌ Error creating KYC document ${docData['documentName']}: $e');
      }
    }
  }

  static Future<void> clearDemoData() async {
    try {
      print('🗑️ Clearing demo data...');

      // Clear users collection
      QuerySnapshot users = await _firestore
          .collection(AppConstants.usersCollection)
          .get();
      for (DocumentSnapshot doc in users.docs) {
        await doc.reference.delete();
      }

      // Clear lawyers collection
      QuerySnapshot lawyers = await _firestore
          .collection(AppConstants.lawyersCollection)
          .get();
      for (DocumentSnapshot doc in lawyers.docs) {
        await doc.reference.delete();
      }

      // Clear KYC documents collection
      QuerySnapshot kycDocs = await _firestore
          .collection(AppConstants.kycCollection)
          .get();
      for (DocumentSnapshot doc in kycDocs.docs) {
        await doc.reference.delete();
      }

      print('✅ Demo data cleared successfully!');
    } catch (e) {
      print('❌ Error clearing demo data: $e');
      rethrow;
    }
  }
}
