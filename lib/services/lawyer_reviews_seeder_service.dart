import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_constants.dart';

class LawyerReviewsSeederService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Seed reviews for all lawyers
  static Future<void> seedAllLawyersReviews() async {
    try {
      print('🌱 Seeding reviews for all lawyers...');

      // Get all lawyers from Firestore
      QuerySnapshot lawyersSnapshot = await _firestore
          .collection(AppConstants.lawyersCollection)
          .get();

      if (lawyersSnapshot.docs.isEmpty) {
        print('⚠️ No lawyers found in database');
        return;
      }

      print('📊 Found ${lawyersSnapshot.docs.length} lawyers');

      // Show sample lawyer info
      var sampleLawyer =
          lawyersSnapshot.docs.first.data() as Map<String, dynamic>;
      print(
        '📝 Sample lawyer: ${sampleLawyer['name']} (ID: ${lawyersSnapshot.docs.first.id})',
      );

      // Sample reviews data
      final sampleReviews = [
        {
          'clientName': 'Ahmad Hassan',
          'clientEmail': 'ahmad@example.com',
          'rating': 5.0,
          'comment':
              'Excellent service! Lawyer helped me with my property dispute efficiently. Highly recommended.',
          'consultationType': 'Property Law',
        },
        {
          'clientName': 'Fatima Ali',
          'clientEmail': 'fatima@example.com',
          'rating': 4.5,
          'comment':
              'Professional approach and clear communication. Got my case resolved in time.',
          'consultationType': 'Family Law',
        },
        {
          'clientName': 'Muhammad Usman',
          'clientEmail': 'usman@example.com',
          'rating': 4.0,
          'comment':
              'Good understanding of my business legal requirements. Will consult again.',
          'consultationType': 'Business Law',
        },
        {
          'clientName': 'Sara Khan',
          'clientEmail': 'sara@example.com',
          'rating': 5.0,
          'comment':
              'Best lawyer in town! Patient listening and excellent advice.',
          'consultationType': 'Civil Law',
        },
        {
          'clientName': 'Omar Sheikh',
          'clientEmail': 'omar@example.com',
          'rating': 4.5,
          'comment':
              'Very helpful in understanding my case. Professional and courteous.',
          'consultationType': 'Criminal Law',
        },
        {
          'clientName': 'Ayesha Malik',
          'clientEmail': 'ayesha@example.com',
          'rating': 4.8,
          'comment':
              'Outstanding legal advice! Very knowledgeable and patient.',
          'consultationType': 'Corporate Law',
        },
        {
          'clientName': 'Hassan Ali',
          'clientEmail': 'hassan@example.com',
          'rating': 4.2,
          'comment':
              'Good service, helped me understand my legal rights clearly.',
          'consultationType': 'Immigration Law',
        },
        {
          'clientName': 'Zainab Ahmed',
          'clientEmail': 'zainab@example.com',
          'rating': 4.9,
          'comment': 'Exceptional lawyer! Very professional and reliable.',
          'consultationType': 'Tax Law',
        },
        {
          'clientName': 'Ali Raza',
          'clientEmail': 'ali@example.com',
          'rating': 4.3,
          'comment':
              'Great consultation experience. Clear explanations and good advice.',
          'consultationType': 'Employment Law',
        },
        {
          'clientName': 'Nida Khan',
          'clientEmail': 'nida@example.com',
          'rating': 4.7,
          'comment':
              'Excellent lawyer! Very helpful and professional approach.',
          'consultationType': 'Intellectual Property',
        },
      ];

      int totalReviewsAdded = 0;

      // Add reviews for each lawyer
      for (var lawyerDoc in lawyersSnapshot.docs) {
        String lawyerId = lawyerDoc.id;
        Map<String, dynamic> lawyerData =
            lawyerDoc.data() as Map<String, dynamic>;
        String lawyerName = lawyerData['name'] ?? 'Unknown Lawyer';

        print('📝 Adding reviews for lawyer: $lawyerName ($lawyerId)');

        // Add 3-7 random reviews for each lawyer
        int numberOfReviews = Random().nextInt(5) + 3; // 3 to 7 reviews

        for (int i = 0; i < numberOfReviews; i++) {
          var reviewData =
              sampleReviews[Random().nextInt(sampleReviews.length)];

          // Create unique client ID for each review
          String clientId = 'client_${lawyerId}_${i + 1}';

          // Add some variation to ratings
          double rating =
              (reviewData['rating'] as double) +
              (Random().nextDouble() - 0.5) * 0.5;
          rating = rating.clamp(1.0, 5.0);

          Map<String, dynamic> review = {
            'lawyerId': lawyerId,
            'clientId': clientId,
            'clientName': reviewData['clientName'],
            'clientEmail': reviewData['clientEmail'],
            'rating': rating,
            'comment': reviewData['comment'],
            'consultationType': reviewData['consultationType'],
            'consultationId': 'consultation_${lawyerId}_${i + 1}',
            'createdAt': Timestamp.fromDate(
              DateTime.now().subtract(Duration(days: Random().nextInt(90) + 1)),
            ),
            'updatedAt': null,
          };

          await _firestore
              .collection(AppConstants.reviewsCollection)
              .add(review);

          totalReviewsAdded++;
          print(
            '✅ Added review ${i + 1} for $lawyerName: ${review['clientName']} (${review['rating']} stars)',
          );
        }

        print('✅ Added $numberOfReviews reviews for $lawyerName');
      }

      print(
        '🎉 Successfully added $totalReviewsAdded reviews for ${lawyersSnapshot.docs.length} lawyers',
      );

      // Verify reviews were added
      QuerySnapshot verifySnapshot = await _firestore
          .collection(AppConstants.reviewsCollection)
          .get();
      print(
        '🔍 Verification: Total reviews in database: ${verifySnapshot.docs.length}',
      );
    } catch (e) {
      print('❌ Error seeding lawyer reviews: $e');
    }
  }

  // Seed reviews for a specific lawyer
  static Future<void> seedLawyerReviews(String lawyerId) async {
    try {
      print('🌱 Seeding reviews for lawyer: $lawyerId');

      final sampleReviews = [
        {
          'clientName': 'Ahmad Hassan',
          'clientEmail': 'ahmad@example.com',
          'rating': 5.0,
          'comment':
              'Excellent service! Lawyer helped me with my property dispute efficiently. Highly recommended.',
          'consultationType': 'Property Law',
        },
        {
          'clientName': 'Fatima Ali',
          'clientEmail': 'fatima@example.com',
          'rating': 4.5,
          'comment':
              'Professional approach and clear communication. Got my case resolved in time.',
          'consultationType': 'Family Law',
        },
        {
          'clientName': 'Muhammad Usman',
          'clientEmail': 'usman@example.com',
          'rating': 4.0,
          'comment':
              'Good understanding of my business legal requirements. Will consult again.',
          'consultationType': 'Business Law',
        },
        {
          'clientName': 'Sara Khan',
          'clientEmail': 'sara@example.com',
          'rating': 5.0,
          'comment':
              'Best lawyer in town! Patient listening and excellent advice.',
          'consultationType': 'Civil Law',
        },
        {
          'clientName': 'Omar Sheikh',
          'clientEmail': 'omar@example.com',
          'rating': 4.5,
          'comment':
              'Very helpful in understanding my case. Professional and courteous.',
          'consultationType': 'Criminal Law',
        },
      ];

      // Add 3-5 random reviews
      int numberOfReviews = Random().nextInt(3) + 3; // 3 to 5 reviews

      for (int i = 0; i < numberOfReviews; i++) {
        var reviewData = sampleReviews[Random().nextInt(sampleReviews.length)];

        // Create unique client ID for each review
        String clientId = 'client_${lawyerId}_${i + 1}';

        // Add some variation to ratings
        double rating =
            (reviewData['rating'] as double) +
            (Random().nextDouble() - 0.5) * 0.5;
        rating = rating.clamp(1.0, 5.0);

        Map<String, dynamic> review = {
          'lawyerId': lawyerId,
          'clientId': clientId,
          'clientName': reviewData['clientName'],
          'clientEmail': reviewData['clientEmail'],
          'rating': rating,
          'comment': reviewData['comment'],
          'consultationType': reviewData['consultationType'],
          'consultationId': 'consultation_${lawyerId}_${i + 1}',
          'createdAt': Timestamp.fromDate(
            DateTime.now().subtract(Duration(days: Random().nextInt(30) + 1)),
          ),
          'updatedAt': null,
        };

        await _firestore.collection(AppConstants.reviewsCollection).add(review);
      }

      print('✅ Added $numberOfReviews reviews for lawyer: $lawyerId');
    } catch (e) {
      print('❌ Error seeding reviews for lawyer $lawyerId: $e');
    }
  }

  // Clear all reviews (for testing)
  static Future<void> clearAllReviews() async {
    try {
      print('🗑️ Clearing all reviews...');

      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.reviewsCollection)
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }

      print('✅ All reviews cleared');
    } catch (e) {
      print('❌ Error clearing reviews: $e');
    }
  }
}
