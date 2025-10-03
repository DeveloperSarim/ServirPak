import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/review_model.dart';
import '../constants/app_constants.dart';

class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all reviews for a specific lawyer
  Future<List<ReviewModel>> getLawyerReviews(String lawyerId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.reviewsCollection)
          .where('lawyerId', isEqualTo: lawyerId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ReviewModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting lawyer reviews: $e');
      return [];
    }
  }

  // Add a new review
  Future<String?> addReview({
    required String lawyerId,
    required String clientId,
    required String clientName,
    required String clientEmail,
    required double rating,
    required String comment,
    String? consultationType,
    String? consultationId,
  }) async {
    try {
      DocumentReference docRef = await _firestore
          .collection(AppConstants.reviewsCollection)
          .add({
            'lawyerId': lawyerId,
            'clientId': clientId,
            'clientName': clientName,
            'clientEmail': clientEmail,
            'rating': rating,
            'comment': comment,
            'consultationType': consultationType,
            'consultationId': consultationId,
            'createdAt': Timestamp.now(),
            'updatedAt': null,
          });

      return docRef.id;
    } catch (e) {
      print('Error adding review: $e');
      return null;
    }
  }

  // Update an existing review
  Future<bool> updateReview(
    String reviewId, {
    double? rating,
    String? comment,
  }) async {
    try {
      Map<String, dynamic> updateData = {'updatedAt': Timestamp.now()};

      if (rating != null) updateData['rating'] = rating;
      if (comment != null) updateData['comment'] = comment;

      await _firestore
          .collection(AppConstants.reviewsCollection)
          .doc(reviewId)
          .update(updateData);

      return true;
    } catch (e) {
      print('Error updating review: $e');
      return false;
    }
  }

  // Delete a review
  Future<bool> deleteReview(String reviewId) async {
    try {
      await _firestore
          .collection(AppConstants.reviewsCollection)
          .doc(reviewId)
          .delete();

      return true;
    } catch (e) {
      print('Error deleting review: $e');
      return false;
    }
  }

  // Get average rating for a lawyer
  Future<double> getLawyerAverageRating(String lawyerId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.reviewsCollection)
          .where('lawyerId', isEqualTo: lawyerId)
          .get();

      if (snapshot.docs.isEmpty) return 0.0;

      double totalRating = 0;
      for (var doc in snapshot.docs) {
        final rating = (doc.data() as Map<String, dynamic>)['rating'] as double;
        totalRating += rating;
      }

      return totalRating / snapshot.docs.length;
    } catch (e) {
      print('Error getting average rating: $e');
      return 0.0;
    }
  }

  // Get review count for a lawyer
  Future<int> getLawyerReviewCount(String lawyerId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.reviewsCollection)
          .where('lawyerId', isEqualTo: lawyerId)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      print('Error getting review count: $e');
      return 0;
    }
  }

  // Check if client has reviewed this lawyer
  Future<bool> hasClientReviewed(String lawyerId, String clientId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.reviewsCollection)
          .where('lawyerId', isEqualTo: lawyerId)
          .where('clientId', isEqualTo: clientId)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking if client reviewed: $e');
      return false;
    }
  }

  // Seed sample reviews for testing
  Future<void> seedSampleReviews(String lawyerId) async {
    try {
      final reviews = [
        {
          'lawyerId': lawyerId,
          'clientId': 'client_001',
          'clientName': 'Ahmad Hassan',
          'clientEmail': 'ahmad@example.com',
          'rating': 5.0,
          'comment':
              'Excellent service! Lawyer helped me with my property dispute efficiently. Highly recommended.',
          'consultationType': 'Property Law',
          'createdAt': Timestamp.fromDate(
            DateTime.now().subtract(Duration(days: Random().nextInt(30) + 1)),
          ),
        },
        {
          'lawyerId': lawyerId,
          'clientId': 'client_002',
          'clientName': 'Fatima Ali',
          'clientEmail': 'fatima@example.com',
          'rating': 4.5,
          'comment':
              'Professional approach and clear communication. Got my case resolved in time.',
          'consultationType': 'Family Law',
          'createdAt': Timestamp.fromDate(
            DateTime.now().subtract(Duration(days: Random().nextInt(30) + 1)),
          ),
        },
        {
          'lawyerId': lawyerId,
          'clientId': 'client_003',
          'clientName': 'Muhammad Usman',
          'clientEmail': 'usman@example.com',
          'rating': 4.0,
          'comment':
              'Good understanding of my business legal requirements. Will consult again.',
          'consultationType': 'Business Law',
          'createdAt': Timestamp.fromDate(
            DateTime.now().subtract(Duration(days: Random().nextInt(30) + 1)),
          ),
        },
        {
          'lawyerId': lawyerId,
          'clientId': 'client_004',
          'clientName': 'Sara Khan',
          'clientEmail': 'sara@example.com',
          'rating': 5.0,
          'comment':
              'Best lawyer in town! Patient listening and excellent advice.',
          'consultationType': 'Civil Law',
          'createdAt': Timestamp.fromDate(
            DateTime.now().subtract(Duration(days: Random().nextInt(30) + 1)),
          ),
        },
        {
          'lawyerId': lawyerId,
          'clientId': 'client_005',
          'clientName': 'Omar Sheikh',
          'clientEmail': 'omar@example.com',
          'rating': 4.5,
          'comment':
              'Very helpful in understanding my case. Professional and courteous.',
          'consultationType': 'Criminal Law',
          'createdAt': Timestamp.fromDate(
            DateTime.now().subtract(Duration(days: Random().nextInt(30) + 1)),
          ),
        },
      ];

      // Add reviews to Firestore
      for (var reviewData in reviews) {
        await _firestore
            .collection(AppConstants.reviewsCollection)
            .add(reviewData);
      }

      print('✅ Sample reviews added for lawyer: $lawyerId');
    } catch (e) {
      print('❌ Error seeding sample reviews: $e');
    }
  }
}
