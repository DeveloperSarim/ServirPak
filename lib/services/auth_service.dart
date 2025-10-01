import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/lawyer_model.dart';
import '../constants/app_constants.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  static User? get currentUser => _auth.currentUser;

  // Get current user stream
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  static Future<UserModel?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      print('🔐 AuthService: Signing in with email: $email');

      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      print(
        '🔐 AuthService: Firebase auth successful, UID: ${userCredential.user?.uid}',
      );

      if (userCredential.user != null) {
        UserModel? userModel = await getUserById(userCredential.user!.uid);
        print(
          '🔐 AuthService: User model from Firestore: ${userModel?.email}, Role: ${userModel?.role}, Status: ${userModel?.status}',
        );

        if (userModel != null) {
          await _saveUserSession(userModel);
          print('🔐 AuthService: User session saved');
          return userModel;
        } else {
          print('❌ AuthService: User model is null, creating default user');
          // Create a default user model if Firestore data is not found
          UserModel defaultUser = UserModel(
            id: userCredential.user!.uid,
            email: userCredential.user!.email ?? email,
            name: userCredential.user!.displayName ?? 'User',
            phone: '',
            role: AppConstants.userRole,
            status: AppConstants.pendingStatus,
            additionalInfo: {'city': ''},
            createdAt: DateTime.now(),
          );

          // Save to Firestore
          await _firestore
              .collection(AppConstants.usersCollection)
              .doc(userCredential.user!.uid)
              .set(defaultUser.toFirestore());

          await _saveUserSession(defaultUser);
          print('🔐 AuthService: Default user created and session saved');
          return defaultUser;
        }
      }
      return null;
    } catch (e) {
      print('❌ AuthService: Sign in error: $e');
      rethrow;
    }
  }

  // Sign up with email and password
  static Future<UserModel?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String role,
    String? city,
  }) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      if (userCredential.user != null) {
        // Create user document in Firestore
        UserModel userModel = UserModel(
          id: userCredential.user!.uid,
          email: email,
          name: name,
          phone: phone,
          role: role,
          status: role == AppConstants.adminRole
              ? AppConstants.verifiedStatus
              : AppConstants.pendingStatus,
          createdAt: DateTime.now(),
          additionalInfo: city != null ? {'city': city} : null,
        );

        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(userCredential.user!.uid)
            .set(userModel.toFirestore());

        await _saveUserSession(userModel);
        return userModel;
      }
      return null;
    } catch (e) {
      print('Sign up error: $e');
      rethrow;
    }
  }

  // Sign out
  static Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _clearUserSession();
    } catch (e) {
      print('Sign out error: $e');
      rethrow;
    }
  }

  // Get user by ID
  static Future<UserModel?> getUserById(String userId) async {
    try {
      print('👤 AuthService: Getting user by ID: $userId');

      DocumentSnapshot doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .get();

      print('👤 AuthService: Firestore doc exists: ${doc.exists}');

      if (doc.exists) {
        UserModel userModel = UserModel.fromFirestore(doc);
        print(
          '👤 AuthService: User model created: ${userModel.email}, Role: ${userModel.role}, Status: ${userModel.status}',
        );
        return userModel;
      }

      // If user document doesn't exist, try to create it from Firebase Auth user
      print(
        '👤 AuthService: User document not found, trying to create from Firebase Auth',
      );
      User? firebaseUser = _auth.currentUser;
      if (firebaseUser != null && firebaseUser.uid == userId) {
        return await _createUserDocumentFromFirebaseUser(firebaseUser);
      }

      print('👤 AuthService: User document not found and no Firebase user');
      return null;
    } catch (e) {
      print('❌ AuthService: Get user error: $e');
      return null;
    }
  }

  // Create user document from Firebase Auth user
  static Future<UserModel?> _createUserDocumentFromFirebaseUser(
    User firebaseUser,
  ) async {
    try {
      print(
        '👤 AuthService: Creating user document for Firebase user: ${firebaseUser.email}',
      );

      // Determine role and status based on email
      String role = AppConstants.userRole;
      String status = AppConstants.verifiedStatus;

      if (firebaseUser.email == 'admin@servipak.com') {
        role = AppConstants.adminRole;
        status = AppConstants.verifiedStatus;
      } else if (firebaseUser.email == 'lawyer1@servipak.com' ||
          firebaseUser.email == 'lawyer2@servipak.com') {
        role = AppConstants.lawyerRole;
        status = AppConstants.verifiedStatus;
      } else if (firebaseUser.email == 'user1@servipak.com' ||
          firebaseUser.email == 'user2@servipak.com') {
        role = AppConstants.userRole;
        status = AppConstants.verifiedStatus;
      }

      // Create user document
      UserModel userModel = UserModel(
        id: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        name:
            firebaseUser.displayName ??
            firebaseUser.email?.split('@')[0] ??
            'User',
        phone: '+92-300-0000000',
        role: role,
        status: status,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(firebaseUser.uid)
          .set(userModel.toFirestore());

      print(
        '✅ AuthService: Created user document: ${userModel.email}, Role: ${userModel.role}, Status: ${userModel.status}',
      );
      return userModel;
    } catch (e) {
      print('❌ AuthService: Error creating user document: $e');
      return null;
    }
  }

  // Get lawyer by user ID
  static Future<LawyerModel?> getLawyerByUserId(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(AppConstants.lawyersCollection)
          .doc(userId)
          .get();

      if (doc.exists) {
        return LawyerModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Get lawyer error: $e');
      return null;
    }
  }

  // Update user profile
  static Future<void> updateUserProfile({
    required String userId,
    String? name,
    String? phone,
    String? profileImage,
  }) async {
    try {
      Map<String, dynamic> updateData = {
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      if (name != null) updateData['name'] = name;
      if (phone != null) updateData['phone'] = phone;
      if (profileImage != null) updateData['profileImage'] = profileImage;

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update(updateData);
    } catch (e) {
      print('Update user profile error: $e');
      rethrow;
    }
  }

  // Update user status (Admin only)
  static Future<void> updateUserStatus({
    required String userId,
    required String status,
  }) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({
            'status': status,
            'updatedAt': Timestamp.fromDate(DateTime.now()),
          });
    } catch (e) {
      print('Update user status error: $e');
      rethrow;
    }
  }

  // Create lawyer profile
  static Future<void> createLawyerProfile({
    required String userId,
    required String specialization,
    required String experience,
    required String barCouncilNumber,
    String? bio,
    List<String>? languages,
    String? address,
    String? city,
    String? province,
    Map<String, String>? documentUrls,
  }) async {
    try {
      UserModel? user = await getUserById(userId);
      if (user == null) throw Exception('User not found');

      LawyerModel lawyer = LawyerModel(
        id: userId,
        userId: userId,
        email: user.email,
        name: user.name,
        phone: user.phone,
        specialization: specialization,
        experience: experience,
        barCouncilNumber: barCouncilNumber,
        status: AppConstants.pendingStatus,
        createdAt: DateTime.now(),
        bio: bio,
        languages: languages ?? [],
        address: address,
        city: city,
        province: province,
        documentUrls: documentUrls ?? {},
        kycDocuments: documentUrls?.keys.toList() ?? [],
      );

      await _firestore
          .collection(AppConstants.lawyersCollection)
          .doc(userId)
          .set(lawyer.toFirestore());
    } catch (e) {
      print('Create lawyer profile error: $e');
      rethrow;
    }
  }

  // Update lawyer status (Admin only)
  static Future<void> updateLawyerStatus({
    required String userId,
    required String status,
  }) async {
    try {
      await _firestore
          .collection(AppConstants.lawyersCollection)
          .doc(userId)
          .update({
            'status': status,
            'updatedAt': Timestamp.fromDate(DateTime.now()),
          });
    } catch (e) {
      print('Update lawyer status error: $e');
      rethrow;
    }
  }

  // Save user session
  static Future<void> _saveUserSession(UserModel user) async {
    try {
      print(
        '💾 AuthService: Saving user session - ID: ${user.id}, Role: ${user.role}',
      );
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.userIdKey, user.id);
      await prefs.setString(AppConstants.userRoleKey, user.role);
      print('💾 AuthService: User session saved successfully');
    } catch (e) {
      print('❌ AuthService: Save user session error: $e');
    }
  }

  // Clear user session
  static Future<void> _clearUserSession() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.userIdKey);
      await prefs.remove(AppConstants.userRoleKey);
    } catch (e) {
      print('Clear user session error: $e');
    }
  }

  // Get saved user session
  static Future<Map<String, String?>> getSavedUserSession() async {
    try {
      print('📱 AuthService: Getting saved user session...');
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString(AppConstants.userIdKey);
      String? userRole = prefs.getString(AppConstants.userRoleKey);

      print('📱 AuthService: Saved session - UserID: $userId, Role: $userRole');

      return {'userId': userId, 'userRole': userRole};
    } catch (e) {
      print('❌ AuthService: Get saved user session error: $e');
      return {'userId': null, 'userRole': null};
    }
  }

  // Check if user is first time
  static Future<bool> isFirstTime() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.getBool(AppConstants.isFirstTimeKey) ?? true;
    } catch (e) {
      print('Check first time error: $e');
      return true;
    }
  }

  // Set first time to false
  static Future<void> setFirstTimeFalse() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.isFirstTimeKey, false);
    } catch (e) {
      print('Set first time false error: $e');
    }
  }
}
