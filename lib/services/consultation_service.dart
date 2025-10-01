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
      ConsultationModel consultation = ConsultationModel(
        id: '', // Will be set by Firestore
        userId: userId,
        lawyerId: lawyerId,
        type: type,
        category: category,
        city: city,
        description: description,
        price: price,
        status: AppConstants.pendingStatus,
        scheduledAt: scheduledAt,
        createdAt: DateTime.now(),
      );

      DocumentReference docRef = await _firestore
          .collection(AppConstants.consultationsCollection)
          .add(consultation.toFirestore());

      print('Consultation created successfully: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('Error creating consultation: $e');
      rethrow;
    }
  }

  // Get consultations by user ID
  static Future<List<ConsultationModel>> getConsultationsByUserId(
    String userId,
  ) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.consultationsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ConsultationModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting consultations by user ID: $e');
      return [];
    }
  }

  // Get consultations by lawyer ID
  static Future<List<ConsultationModel>> getConsultationsByLawyerId(
    String lawyerId,
  ) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.consultationsCollection)
          .where('lawyerId', isEqualTo: lawyerId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ConsultationModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting consultations by lawyer ID: $e');
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
