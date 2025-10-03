import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_constants.dart';
import '../models/user_model.dart';

class UserSeedService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Seed comprehensive user data
  static Future<void> seedUserData() async {
    try {
      print('🌱 Seeding comprehensive user data...');

      final users = [
        {
          'id': 'user_001',
          'email': 'ahmed.khan@example.com',
          'name': 'Ahmed Khan',
          'phone': '+92-300-1111111',
          'role': AppConstants.userRole,
          'status': 'active',
          'profileImage':
              'https://res.cloudinary.com/dii8rpixj/image/upload/v1703123456/users/ahmed_khan.jpg',
          'additionalInfo': {
            'city': 'Lahore',
            'province': 'Punjab',
            'occupation': 'Software Engineer',
            'emergencyContact': '+92-300-1111112',
            'preferredLanguage': 'Urdu',
            'dateOfBirth': '1990-05-15',
            'gender': 'Male',
            'address': '123 Model Town, Lahore',
            'interests': ['Technology', 'Law', 'Business'],
            'consultationHistory': 3,
            'totalSpent': 15000,
            'lastLogin': DateTime.now().subtract(const Duration(hours: 2)),
          },
          'createdAt': DateTime.now().subtract(const Duration(days: 200)),
          'updatedAt': DateTime.now(),
        },
        {
          'id': 'user_002',
          'email': 'sara.ahmed@example.com',
          'name': 'Sara Ahmed',
          'phone': '+92-300-2222222',
          'role': AppConstants.userRole,
          'status': 'active',
          'profileImage':
              'https://res.cloudinary.com/dii8rpixj/image/upload/v1703123456/users/sara_ahmed.jpg',
          'additionalInfo': {
            'city': 'Karachi',
            'province': 'Sindh',
            'occupation': 'Business Owner',
            'emergencyContact': '+92-300-2222223',
            'preferredLanguage': 'English',
            'dateOfBirth': '1985-08-22',
            'gender': 'Female',
            'address': '456 DHA Phase 2, Karachi',
            'interests': ['Business Law', 'Corporate Law', 'Finance'],
            'consultationHistory': 5,
            'totalSpent': 25000,
            'lastLogin': DateTime.now().subtract(const Duration(minutes: 30)),
          },
          'createdAt': DateTime.now().subtract(const Duration(days: 150)),
          'updatedAt': DateTime.now(),
        },
        {
          'id': 'user_003',
          'email': 'muhammad.hassan@example.com',
          'name': 'Muhammad Hassan',
          'phone': '+92-300-3333333',
          'role': AppConstants.userRole,
          'status': 'active',
          'profileImage':
              'https://res.cloudinary.com/dii8rpixj/image/upload/v1703123456/users/muhammad_hassan.jpg',
          'additionalInfo': {
            'city': 'Islamabad',
            'province': 'Federal',
            'occupation': 'Government Employee',
            'emergencyContact': '+92-300-3333334',
            'preferredLanguage': 'Urdu',
            'dateOfBirth': '1988-12-10',
            'gender': 'Male',
            'address': '789 Blue Area, Islamabad',
            'interests': [
              'Administrative Law',
              'Constitutional Law',
              'Public Policy',
            ],
            'consultationHistory': 2,
            'totalSpent': 8000,
            'lastLogin': DateTime.now().subtract(const Duration(days: 1)),
          },
          'createdAt': DateTime.now().subtract(const Duration(days: 100)),
          'updatedAt': DateTime.now(),
        },
        {
          'id': 'user_004',
          'email': 'fatima.ali@example.com',
          'name': 'Fatima Ali',
          'phone': '+92-300-4444444',
          'role': AppConstants.userRole,
          'status': 'active',
          'profileImage':
              'https://res.cloudinary.com/dii8rpixj/image/upload/v1703123456/users/fatima_ali.jpg',
          'additionalInfo': {
            'city': 'Lahore',
            'province': 'Punjab',
            'occupation': 'Teacher',
            'emergencyContact': '+92-300-4444445',
            'preferredLanguage': 'Urdu',
            'dateOfBirth': '1992-03-18',
            'gender': 'Female',
            'address': '321 Gulberg, Lahore',
            'interests': ['Education Law', 'Family Law', 'Women Rights'],
            'consultationHistory': 1,
            'totalSpent': 5000,
            'lastLogin': DateTime.now().subtract(const Duration(hours: 5)),
          },
          'createdAt': DateTime.now().subtract(const Duration(days: 80)),
          'updatedAt': DateTime.now(),
        },
        {
          'id': 'user_005',
          'email': 'omar.sheikh@example.com',
          'name': 'Omar Sheikh',
          'phone': '+92-300-5555555',
          'role': AppConstants.userRole,
          'status': 'active',
          'profileImage':
              'https://res.cloudinary.com/dii8rpixj/image/upload/v1703123456/users/omar_sheikh.jpg',
          'additionalInfo': {
            'city': 'Karachi',
            'province': 'Sindh',
            'occupation': 'Doctor',
            'emergencyContact': '+92-300-5555556',
            'preferredLanguage': 'English',
            'dateOfBirth': '1987-07-25',
            'gender': 'Male',
            'address': '654 Clifton, Karachi',
            'interests': ['Medical Law', 'Malpractice Law', 'Healthcare'],
            'consultationHistory': 4,
            'totalSpent': 20000,
            'lastLogin': DateTime.now().subtract(const Duration(minutes: 15)),
          },
          'createdAt': DateTime.now().subtract(const Duration(days: 120)),
          'updatedAt': DateTime.now(),
        },
        {
          'id': 'user_006',
          'email': 'zainab.khan@example.com',
          'name': 'Zainab Khan',
          'phone': '+92-300-6666666',
          'role': AppConstants.userRole,
          'status': 'active',
          'profileImage':
              'https://res.cloudinary.com/dii8rpixj/image/upload/v1703123456/users/zainab_khan.jpg',
          'additionalInfo': {
            'city': 'Islamabad',
            'province': 'Federal',
            'occupation': 'Student',
            'emergencyContact': '+92-300-6666667',
            'preferredLanguage': 'Urdu',
            'dateOfBirth': '2000-11-08',
            'gender': 'Female',
            'address': '987 F-8, Islamabad',
            'interests': ['Student Rights', 'Education Law', 'Youth Issues'],
            'consultationHistory': 1,
            'totalSpent': 3000,
            'lastLogin': DateTime.now().subtract(const Duration(hours: 3)),
          },
          'createdAt': DateTime.now().subtract(const Duration(days: 60)),
          'updatedAt': DateTime.now(),
        },
        {
          'id': 'user_007',
          'email': 'ali.hussain@example.com',
          'name': 'Ali Hussain',
          'phone': '+92-300-7777777',
          'role': AppConstants.userRole,
          'status': 'active',
          'profileImage':
              'https://res.cloudinary.com/dii8rpixj/image/upload/v1703123456/users/ali_hussain.jpg',
          'additionalInfo': {
            'city': 'Lahore',
            'province': 'Punjab',
            'occupation': 'Engineer',
            'emergencyContact': '+92-300-7777778',
            'preferredLanguage': 'English',
            'dateOfBirth': '1983-09-14',
            'gender': 'Male',
            'address': '147 Johar Town, Lahore',
            'interests': [
              'Intellectual Property',
              'Patent Law',
              'Technology Law',
            ],
            'consultationHistory': 6,
            'totalSpent': 30000,
            'lastLogin': DateTime.now().subtract(const Duration(minutes: 45)),
          },
          'createdAt': DateTime.now().subtract(const Duration(days: 180)),
          'updatedAt': DateTime.now(),
        },
        {
          'id': 'user_008',
          'email': 'maryam.ahmed@example.com',
          'name': 'Maryam Ahmed',
          'phone': '+92-300-8888888',
          'role': AppConstants.userRole,
          'status': 'active',
          'profileImage':
              'https://res.cloudinary.com/dii8rpixj/image/upload/v1703123456/users/maryam_ahmed.jpg',
          'additionalInfo': {
            'city': 'Karachi',
            'province': 'Sindh',
            'occupation': 'Banker',
            'emergencyContact': '+92-300-8888889',
            'preferredLanguage': 'English',
            'dateOfBirth': '1986-04-30',
            'gender': 'Female',
            'address': '258 Defence, Karachi',
            'interests': ['Banking Law', 'Financial Law', 'Corporate Law'],
            'consultationHistory': 3,
            'totalSpent': 18000,
            'lastLogin': DateTime.now().subtract(const Duration(hours: 1)),
          },
          'createdAt': DateTime.now().subtract(const Duration(days: 90)),
          'updatedAt': DateTime.now(),
        },
        {
          'id': 'user_009',
          'email': 'hassan.malik@example.com',
          'name': 'Hassan Malik',
          'phone': '+92-300-9999999',
          'role': AppConstants.userRole,
          'status': 'active',
          'profileImage':
              'https://res.cloudinary.com/dii8rpixj/image/upload/v1703123456/users/hassan_malik.jpg',
          'additionalInfo': {
            'city': 'Islamabad',
            'province': 'Federal',
            'occupation': 'Entrepreneur',
            'emergencyContact': '+92-300-9999990',
            'preferredLanguage': 'Urdu',
            'dateOfBirth': '1984-01-12',
            'gender': 'Male',
            'address': '369 Blue Area, Islamabad',
            'interests': ['Startup Law', 'Business Law', 'Contract Law'],
            'consultationHistory': 8,
            'totalSpent': 40000,
            'lastLogin': DateTime.now().subtract(const Duration(minutes: 20)),
          },
          'createdAt': DateTime.now().subtract(const Duration(days: 250)),
          'updatedAt': DateTime.now(),
        },
        {
          'id': 'user_010',
          'email': 'aisha.khan@example.com',
          'name': 'Aisha Khan',
          'phone': '+92-300-0000000',
          'role': AppConstants.userRole,
          'status': 'active',
          'profileImage':
              'https://res.cloudinary.com/dii8rpixj/image/upload/v1703123456/users/aisha_khan.jpg',
          'additionalInfo': {
            'city': 'Lahore',
            'province': 'Punjab',
            'occupation': 'Artist',
            'emergencyContact': '+92-300-0000001',
            'preferredLanguage': 'Urdu',
            'dateOfBirth': '1991-06-20',
            'gender': 'Female',
            'address': '741 Model Town, Lahore',
            'interests': ['Copyright Law', 'Intellectual Property', 'Art Law'],
            'consultationHistory': 2,
            'totalSpent': 10000,
            'lastLogin': DateTime.now().subtract(const Duration(hours: 4)),
          },
          'createdAt': DateTime.now().subtract(const Duration(days: 70)),
          'updatedAt': DateTime.now(),
        },
      ];

      // Add/update user data
      for (var userData in users) {
        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(userData['id'] as String)
            .set(userData, SetOptions(merge: true));

        print('✅ Enhanced user data: ${userData['name']}');
      }

      print('🎉 User data seeding completed!');
    } catch (e) {
      print('❌ Error seeding user data: $e');
      rethrow;
    }
  }

  // Seed consultation data
  static Future<void> seedConsultationData() async {
    try {
      print('🌱 Seeding consultation data...');

      final consultations = [
        {
          'id': 'consultation_001',
          'userId': 'user_001',
          'lawyerId': 'lawyer_001',
          'type': 'Online Consultation',
          'status': 'Completed',
          'subject': 'Criminal Defense Consultation',
          'description': 'Need legal advice regarding a criminal case',
          'scheduledAt': DateTime.now().subtract(const Duration(days: 5)),
          'duration': 60,
          'fee': 5000,
          'rating': 5,
          'feedback': 'Excellent service, very professional and helpful.',
          'createdAt': DateTime.now().subtract(const Duration(days: 6)),
          'updatedAt': DateTime.now().subtract(const Duration(days: 5)),
        },
        {
          'id': 'consultation_002',
          'userId': 'user_002',
          'lawyerId': 'lawyer_002',
          'type': 'In-Person Meeting',
          'status': 'Scheduled',
          'subject': 'Family Law - Divorce Case',
          'description': 'Consultation for divorce proceedings',
          'scheduledAt': DateTime.now().add(const Duration(days: 2)),
          'duration': 90,
          'fee': 4000,
          'rating': null,
          'feedback': null,
          'createdAt': DateTime.now().subtract(const Duration(days: 3)),
          'updatedAt': DateTime.now().subtract(const Duration(days: 3)),
        },
        {
          'id': 'consultation_003',
          'userId': 'user_003',
          'lawyerId': 'lawyer_003',
          'type': 'Phone Consultation',
          'status': 'Completed',
          'subject': 'Corporate Law - Business Setup',
          'description': 'Legal advice for starting a new business',
          'scheduledAt': DateTime.now().subtract(const Duration(days: 10)),
          'duration': 45,
          'fee': 8000,
          'rating': 4,
          'feedback': 'Good advice, helped clarify business structure.',
          'createdAt': DateTime.now().subtract(const Duration(days: 12)),
          'updatedAt': DateTime.now().subtract(const Duration(days: 10)),
        },
        {
          'id': 'consultation_004',
          'userId': 'user_004',
          'lawyerId': 'lawyer_004',
          'type': 'Online Consultation',
          'status': 'Completed',
          'subject': 'Property Law - Land Dispute',
          'description': 'Property boundary dispute resolution',
          'scheduledAt': DateTime.now().subtract(const Duration(days: 15)),
          'duration': 75,
          'fee': 3500,
          'rating': 5,
          'feedback': 'Very knowledgeable about property laws.',
          'createdAt': DateTime.now().subtract(const Duration(days: 17)),
          'updatedAt': DateTime.now().subtract(const Duration(days: 15)),
        },
        {
          'id': 'consultation_005',
          'userId': 'user_005',
          'lawyerId': 'lawyer_005',
          'type': 'In-Person Meeting',
          'status': 'Completed',
          'subject': 'Immigration Law - Visa Application',
          'description': 'Help with work visa application process',
          'scheduledAt': DateTime.now().subtract(const Duration(days: 8)),
          'duration': 120,
          'fee': 6000,
          'rating': 4,
          'feedback': 'Professional service, helped with documentation.',
          'createdAt': DateTime.now().subtract(const Duration(days: 10)),
          'updatedAt': DateTime.now().subtract(const Duration(days: 8)),
        },
      ];

      // Add consultation data
      for (var consultationData in consultations) {
        await _firestore
            .collection('consultations')
            .doc(consultationData['id'] as String)
            .set(consultationData, SetOptions(merge: true));

        print('✅ Consultation data: ${consultationData['subject']}');
      }

      print('🎉 Consultation data seeding completed!');
    } catch (e) {
      print('❌ Error seeding consultation data: $e');
      rethrow;
    }
  }

  // Seed chat data
  static Future<void> seedChatData() async {
    try {
      print('🌱 Seeding chat data...');

      final chats = [
        {
          'id': 'chat_001',
          'userId': 'user_001',
          'lawyerId': 'lawyer_001',
          'consultationId': 'consultation_001',
          'lastMessage': 'Thank you for the consultation, it was very helpful.',
          'lastMessageTime': DateTime.now().subtract(const Duration(hours: 2)),
          'unreadCount': 0,
          'status': 'active',
          'createdAt': DateTime.now().subtract(const Duration(days: 6)),
          'updatedAt': DateTime.now().subtract(const Duration(hours: 2)),
        },
        {
          'id': 'chat_002',
          'userId': 'user_002',
          'lawyerId': 'lawyer_002',
          'consultationId': 'consultation_002',
          'lastMessage': 'I will prepare the documents for our meeting.',
          'lastMessageTime': DateTime.now().subtract(
            const Duration(minutes: 30),
          ),
          'unreadCount': 1,
          'status': 'active',
          'createdAt': DateTime.now().subtract(const Duration(days: 3)),
          'updatedAt': DateTime.now().subtract(const Duration(minutes: 30)),
        },
        {
          'id': 'chat_003',
          'userId': 'user_003',
          'lawyerId': 'lawyer_003',
          'consultationId': 'consultation_003',
          'lastMessage':
              'The business structure looks good, proceed with registration.',
          'lastMessageTime': DateTime.now().subtract(const Duration(days: 1)),
          'unreadCount': 0,
          'status': 'completed',
          'createdAt': DateTime.now().subtract(const Duration(days: 12)),
          'updatedAt': DateTime.now().subtract(const Duration(days: 1)),
        },
      ];

      // Add chat data
      for (var chatData in chats) {
        await _firestore
            .collection('chats')
            .doc(chatData['id'] as String)
            .set(chatData, SetOptions(merge: true));

        print('✅ Chat data: ${chatData['id']}');
      }

      print('🎉 Chat data seeding completed!');
    } catch (e) {
      print('❌ Error seeding chat data: $e');
      rethrow;
    }
  }

  // Comprehensive seed all data
  static Future<void> seedAllData() async {
    try {
      print('🚀 Starting comprehensive data seeding...');

      // Seed users first
      await seedUserData();

      // Seed consultations
      await seedConsultationData();

      // Seed chats
      await seedChatData();

      print('🎉 All data seeding completed successfully!');
    } catch (e) {
      print('❌ Error in comprehensive data seeding: $e');
      rethrow;
    }
  }
}
