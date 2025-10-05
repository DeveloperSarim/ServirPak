import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/consultation_model.dart';
import '../constants/app_constants.dart';

class ConsultationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create new consultation
  static Future<String> createConsultation({
    required String userId,
    required String lawyerId,
    required String type,
    required String category,
    required String city,
    required String description,
    required double price,
    required DateTime scheduledAt,
  }) async {
    try {
      print('🔍 ConsultationService: Creating consultation');
      print('🔍 User ID: $userId');
      print('🔍 Lawyer ID: $lawyerId');
      print('🔍 Type: $type');
      print('🔍 Category: $category');
      print('🔍 Collection: ${AppConstants.consultationsCollection}');

      ConsultationModel consultation = ConsultationModel(
        id: '', // Will be set by Firestore
        userId: userId,
        lawyerId: lawyerId,
        type: type,
        category: category,
        city: city,
        description: description,
        price: price,
        platformFee: price * 0.05, // 5% platform fee
        totalAmount: price + (price * 0.05), // Total amount
        consultationDate: scheduledAt.toString().split(' ')[0], // Date
        consultationTime: scheduledAt.toString().split(' ')[1], // Time
        meetingLink: '', // Will be generated later
        status: AppConstants.pendingStatus,
        scheduledAt: scheduledAt,
        createdAt: DateTime.now(),
      );

      print('🔍 Consultation data: ${consultation.toFirestore()}');

      DocumentReference docRef = await _firestore
          .collection(AppConstants.consultationsCollection)
          .add(consultation.toFirestore());

      print('✅ Consultation created successfully: ${docRef.id}');

      // Verify the consultation was created
      DocumentSnapshot createdDoc = await docRef.get();
      if (createdDoc.exists) {
        print('✅ Verification: Consultation document exists in database');
        print('✅ Document data: ${createdDoc.data()}');
      } else {
        print('❌ Verification: Consultation document not found in database');
      }

      return docRef.id;
    } catch (e) {
      print('❌ Error creating consultation: $e');
      rethrow;
    }
  }

  // Get consultations by user ID
  static Future<List<ConsultationModel>> getConsultationsByUserId(
    String userId,
  ) async {
    try {
      print('🔍 ConsultationService: Getting consultations for user: $userId');
      print('🔍 Collection: ${AppConstants.consultationsCollection}');

      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.consultationsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      print('🔍 Query result: ${snapshot.docs.length} documents found');

      List<ConsultationModel> consultations = snapshot.docs.map((doc) {
        print('🔍 Document ID: ${doc.id}, Data: ${doc.data()}');
        return ConsultationModel.fromFirestore(doc);
      }).toList();

      print(
        '✅ ConsultationService: Returning ${consultations.length} consultations',
      );
      return consultations;
    } catch (e) {
      print('❌ Error getting consultations by user ID: $e');
      return [];
    }
  }

  // Get consultations by lawyer ID
  static Future<List<ConsultationModel>> getConsultationsByLawyerId(
    String lawyerId,
  ) async {
    try {
      print(
        '🔍 ConsultationService: Getting consultations for lawyer: $lawyerId',
      );
      print('🔍 Collection: ${AppConstants.consultationsCollection}');

      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.consultationsCollection)
          .where('lawyerId', isEqualTo: lawyerId)
          .orderBy('createdAt', descending: true)
          .get();

      print('🔍 Query result: ${snapshot.docs.length} documents found');

      if (snapshot.docs.isNotEmpty) {
        print('🔍 First document data: ${snapshot.docs.first.data()}');
      }

      List<ConsultationModel> consultations = snapshot.docs.map((doc) {
        print('🔍 Document ID: ${doc.id}, Data: ${doc.data()}');
        return ConsultationModel.fromFirestore(doc);
      }).toList();

      print(
        '✅ ConsultationService: Returning ${consultations.length} consultations for lawyer',
      );
      return consultations;
    } catch (e) {
      print('❌ Error getting consultations by lawyer ID: $e');
      return [];
    }
  }

  // Get consultation by ID
  static Future<ConsultationModel?> getConsultationById(
    String consultationId,
  ) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(AppConstants.consultationsCollection)
          .doc(consultationId)
          .get();

      if (doc.exists) {
        return ConsultationModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting consultation by ID: $e');
      return null;
    }
  }

  // Update consultation status
  static Future<void> updateConsultationStatus({
    required String consultationId,
    required String status,
    String? notes,
  }) async {
    try {
      Map<String, dynamic> updateData = {
        'status': status,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      if (notes != null) updateData['notes'] = notes;
      if (status == AppConstants.completedStatus) {
        updateData['completedAt'] = Timestamp.fromDate(DateTime.now());
      }

      await _firestore
          .collection(AppConstants.consultationsCollection)
          .doc(consultationId)
          .update(updateData);

      print('Consultation status updated: $consultationId -> $status');
    } catch (e) {
      print('Error updating consultation status: $e');
      rethrow;
    }
  }

  // Update consultation payment
  static Future<void> updateConsultationPayment({
    required String consultationId,
    required String paymentId,
  }) async {
    try {
      await _firestore
          .collection(AppConstants.consultationsCollection)
          .doc(consultationId)
          .update({
            'paymentId': paymentId,
            'updatedAt': Timestamp.fromDate(DateTime.now()),
          });

      print('Consultation payment updated: $consultationId');
    } catch (e) {
      print('Error updating consultation payment: $e');
      rethrow;
    }
  }

  // Get consultations by status
  static Future<List<ConsultationModel>> getConsultationsByStatus(
    String status,
  ) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.consultationsCollection)
          .where('status', isEqualTo: status)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ConsultationModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting consultations by status: $e');
      return [];
    }
  }

  // Get consultations by city
  static Future<List<ConsultationModel>> getConsultationsByCity(
    String city,
  ) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.consultationsCollection)
          .where('city', isEqualTo: city)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ConsultationModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting consultations by city: $e');
      return [];
    }
  }

  // Get consultations by category
  static Future<List<ConsultationModel>> getConsultationsByCategory(
    String category,
  ) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.consultationsCollection)
          .where('category', isEqualTo: category)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ConsultationModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting consultations by category: $e');
      return [];
    }
  }

  // Get all consultations (Admin only)
  static Future<List<ConsultationModel>> getAllConsultations() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.consultationsCollection)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ConsultationModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting all consultations: $e');
      return [];
    }
  }

  // Delete consultation
  static Future<void> deleteConsultation(String consultationId) async {
    try {
      await _firestore
          .collection(AppConstants.consultationsCollection)
          .doc(consultationId)
          .delete();

      print('Consultation deleted successfully: $consultationId');
    } catch (e) {
      print('Error deleting consultation: $e');
      rethrow;
    }
  }
}
