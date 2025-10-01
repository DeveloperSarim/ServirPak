import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_constants.dart';

class CollectionCreatorService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> createCollections() async {
    try {
      print('🏗️ Creating Firestore collections...');

      // Sign in as admin first
      await _signInAsAdmin();

      // Create users collection with sample data
      await _createUsersCollection();

      // Create lawyers collection
      await _createLawyersCollection();

      // Create KYC documents collection
      await _createKycCollection();

      // Create cities collection
      await _createCitiesCollection();

      // Create other collections
      await _createOtherCollections();

      print('✅ All collections created successfully!');
    } catch (e) {
      print('❌ Error creating collections: $e');
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
      print('✅ Signed in as admin');
    } catch (e) {
      print('⚠️ Admin sign in failed: $e');
      // Create admin user first
      UserCredential adminCredential = await _auth
          .createUserWithEmailAndPassword(
            email: 'admin@servipak.com',
            password: 'admin123',
          );
      print('✅ Created admin user');
    }
  }

  static Future<void> _createUsersCollection() async {
    try {
      // Create admin user document
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc('admin')
          .set({
            'email': 'admin@servipak.com',
            'name': 'Admin User',
            'phone': '+92-300-1234567',
            'role': AppConstants.adminRole,
            'status': AppConstants.verifiedStatus,
            'createdAt': Timestamp.fromDate(DateTime.now()),
          });

      // Create lawyer user document
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc('lawyer1')
          .set({
            'email': 'lawyer1@servipak.com',
            'name': 'Ahmed Ali Khan',
            'phone': '+92-301-2345678',
            'role': AppConstants.lawyerRole,
            'status': AppConstants.verifiedStatus,
            'createdAt': Timestamp.fromDate(DateTime.now()),
          });

      // Create regular user document
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc('user1')
          .set({
            'email': 'user1@servipak.com',
            'name': 'Muhammad Hassan',
            'phone': '+92-303-4567890',
            'role': AppConstants.userRole,
            'status': AppConstants.verifiedStatus,
            'createdAt': Timestamp.fromDate(DateTime.now()),
          });

      print('✅ Users collection created');
    } catch (e) {
      print('❌ Error creating users collection: $e');
    }
  }

  static Future<void> _createLawyersCollection() async {
    try {
      // Create lawyer profile
      await _firestore
          .collection(AppConstants.lawyersCollection)
          .doc('lawyer1')
          .set({
            'userId': 'lawyer1',
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
            'createdAt': Timestamp.fromDate(DateTime.now()),
          });

      print('✅ Lawyers collection created');
    } catch (e) {
      print('❌ Error creating lawyers collection: $e');
    }
  }

  static Future<void> _createKycCollection() async {
    try {
      // Create KYC document
      await _firestore.collection(AppConstants.kycCollection).add({
        'userId': 'lawyer1',
        'lawyerId': 'lawyer1',
        'documentType': AppConstants.cnicDocument,
        'documentName': 'CNIC - Ahmed Ali Khan',
        'documentUrl': 'https://example.com/cnic_ahmed.pdf',
        'status': AppConstants.approvedStatus,
        'uploadedAt': Timestamp.fromDate(DateTime.now()),
      });

      print('✅ KYC collection created');
    } catch (e) {
      print('❌ Error creating KYC collection: $e');
    }
  }

  static Future<void> _createCitiesCollection() async {
    try {
      // Create default cities
      List<Map<String, dynamic>> cities = [
        {'name': 'Lahore', 'province': 'Punjab', 'country': 'Pakistan'},
        {'name': 'Karachi', 'province': 'Sindh', 'country': 'Pakistan'},
        {'name': 'Islamabad', 'province': 'Federal', 'country': 'Pakistan'},
        {'name': 'Rawalpindi', 'province': 'Punjab', 'country': 'Pakistan'},
        {'name': 'Faisalabad', 'province': 'Punjab', 'country': 'Pakistan'},
        {'name': 'Multan', 'province': 'Punjab', 'country': 'Pakistan'},
        {'name': 'Peshawar', 'province': 'KPK', 'country': 'Pakistan'},
        {'name': 'Quetta', 'province': 'Balochistan', 'country': 'Pakistan'},
      ];

      for (var cityData in cities) {
        await _firestore.collection(AppConstants.citiesCollection).add({
          'name': cityData['name'],
          'province': cityData['province'],
          'country': cityData['country'],
          'isActive': true,
          'createdAt': Timestamp.fromDate(DateTime.now()),
        });
      }

      print('✅ Cities collection created');
    } catch (e) {
      print('❌ Error creating cities collection: $e');
    }
  }

  static Future<void> _createOtherCollections() async {
    try {
      // Create consultations collection
      await _firestore.collection(AppConstants.consultationsCollection).add({
        '_dummy': true,
        'createdAt': Timestamp.fromDate(DateTime.now()),
      });

      // Create chat collection
      await _firestore.collection(AppConstants.chatCollection).add({
        '_dummy': true,
        'createdAt': Timestamp.fromDate(DateTime.now()),
      });

      // Create payments collection
      await _firestore.collection(AppConstants.paymentsCollection).add({
        '_dummy': true,
        'createdAt': Timestamp.fromDate(DateTime.now()),
      });

      print('✅ Other collections created');
    } catch (e) {
      print('❌ Error creating other collections: $e');
    }
  }
}
