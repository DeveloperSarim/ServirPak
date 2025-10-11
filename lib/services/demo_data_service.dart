import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_constants.dart';

class DemoDataService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add demo consultations for user
  static Future<void> addDemoConsultationsForUser(String userId) async {
    try {
      final demoConsultations = [
        {
          'userId': userId,
          'lawyerId': 'demo_lawyer_1',
          'type': 'free',
          'category': 'Family Law',
          'description':
              'Need consultation for divorce proceedings and child custody arrangements.',
          'status': 'pending',
          'price': 0.0,
          'city': 'Karachi',
          'scheduledAt': DateTime.now().add(const Duration(days: 2)),
          'createdAt': DateTime.now().subtract(const Duration(days: 1)),
          'updatedAt': DateTime.now(),
        },
        {
          'userId': userId,
          'lawyerId': 'demo_lawyer_2',
          'type': 'paid',
          'category': 'Criminal Law',
          'description':
              'Legal representation needed for traffic violation case.',
          'status': 'accepted',
          'price': 5000.0,
          'city': 'Lahore',
          'scheduledAt': DateTime.now().add(const Duration(days: 5)),
          'createdAt': DateTime.now().subtract(const Duration(hours: 3)),
          'updatedAt': DateTime.now(),
        },
        {
          'userId': userId,
          'lawyerId': 'demo_lawyer_3',
          'type': 'premium',
          'category': 'Property Law',
          'description':
              'Property dispute consultation and legal advice needed.',
          'status': 'completed',
          'price': 15000.0,
          'city': 'Islamabad',
          'scheduledAt': DateTime.now().subtract(const Duration(days: 1)),
          'completedAt': DateTime.now().subtract(const Duration(hours: 2)),
          'createdAt': DateTime.now().subtract(const Duration(days: 3)),
          'updatedAt': DateTime.now(),
        },
        {
          'userId': userId,
          'lawyerId': 'demo_lawyer_4',
          'type': 'paid',
          'category': 'Business Law',
          'description': 'Business contract review and legal documentation.',
          'status': 'rejected',
          'price': 8000.0,
          'city': 'Karachi',
          'scheduledAt': DateTime.now().add(const Duration(days: 7)),
          'createdAt': DateTime.now().subtract(const Duration(hours: 6)),
          'updatedAt': DateTime.now(),
        },
      ];

      for (var consultation in demoConsultations) {
        await _firestore
            .collection(AppConstants.consultationsCollection)
            .add(consultation);
      }

      print('✅ Demo consultations for user added successfully');
    } catch (e) {
      print('❌ Error adding demo consultations for user: $e');
    }
  }

  // Add demo consultations for lawyer
  static Future<void> addDemoConsultations(String lawyerId) async {
    try {
      final demoConsultations = [
        {
          'userId': 'demo_user_1',
          'lawyerId': lawyerId,
          'type': 'online',
          'category': 'Family Law',
          'description':
              'Need consultation for divorce proceedings and child custody arrangements.',
          'status': 'accepted',
          'price': 5000.0,
          'scheduledAt': DateTime.now().add(const Duration(days: 2)),
          'createdAt': DateTime.now().subtract(const Duration(days: 1)),
          'updatedAt': DateTime.now(),
        },
        {
          'userId': 'demo_user_2',
          'lawyerId': lawyerId,
          'type': 'in-person',
          'category': 'Criminal Law',
          'description':
              'Legal representation needed for traffic violation case.',
          'status': 'pending',
          'price': 8000.0,
          'scheduledAt': DateTime.now().add(const Duration(days: 5)),
          'createdAt': DateTime.now().subtract(const Duration(hours: 3)),
          'updatedAt': DateTime.now(),
        },
        {
          'userId': 'demo_user_3',
          'lawyerId': lawyerId,
          'type': 'online',
          'category': 'Property Law',
          'description':
              'Property dispute consultation and legal advice needed.',
          'status': 'completed',
          'price': 12000.0,
          'scheduledAt': DateTime.now().subtract(const Duration(days: 1)),
          'createdAt': DateTime.now().subtract(const Duration(days: 3)),
          'updatedAt': DateTime.now(),
        },
        {
          'userId': 'demo_user_4',
          'lawyerId': lawyerId,
          'type': 'in-person',
          'category': 'Corporate Law',
          'description': 'Business contract review and legal documentation.',
          'status': 'accepted',
          'price': 15000.0,
          'scheduledAt': DateTime.now().add(const Duration(days: 7)),
          'createdAt': DateTime.now().subtract(const Duration(hours: 6)),
          'updatedAt': DateTime.now(),
        },
      ];

      for (var consultation in demoConsultations) {
        await _firestore
            .collection(AppConstants.consultationsCollection)
            .add(consultation);
      }

      print('✅ Demo consultations added successfully');
    } catch (e) {
      print('❌ Error adding demo consultations: $e');
    }
  }

  // Add demo documents for lawyer
  static Future<void> addDemoDocuments(String lawyerId) async {
    try {
      final demoDocuments = [
        {
          'lawyerId': lawyerId,
          'fileName': 'Contract_Template.docx',
          'fileType': 'docx',
          'category': 'Contract',
          'url': 'https://example.com/demo-contract.docx',
          'uploadedAt': DateTime.now()
              .subtract(const Duration(days: 2))
              .millisecondsSinceEpoch,
          'size': 245760,
        },
        {
          'lawyerId': lawyerId,
          'fileName': 'Legal_Brief.pdf',
          'fileType': 'pdf',
          'category': 'Case File',
          'url': 'https://example.com/demo-brief.pdf',
          'uploadedAt': DateTime.now()
              .subtract(const Duration(days: 1))
              .millisecondsSinceEpoch,
          'size': 512000,
        },
        {
          'lawyerId': lawyerId,
          'fileName': 'Court_Order.pdf',
          'fileType': 'pdf',
          'category': 'Case File',
          'url': 'https://example.com/demo-court-order.pdf',
          'uploadedAt': DateTime.now()
              .subtract(const Duration(hours: 5))
              .millisecondsSinceEpoch,
          'size': 128000,
        },
        {
          'lawyerId': lawyerId,
          'fileName': 'Client_Agreement.pdf',
          'fileType': 'pdf',
          'category': 'Contract',
          'url': 'https://example.com/demo-agreement.pdf',
          'uploadedAt': DateTime.now()
              .subtract(const Duration(hours: 2))
              .millisecondsSinceEpoch,
          'size': 320000,
        },
        {
          'lawyerId': lawyerId,
          'fileName': 'PowerPoint_Presentation.pptx',
          'fileType': 'pptx',
          'category': 'Presentation',
          'url': 'https://example.com/demo-presentation.pptx',
          'uploadedAt': DateTime.now()
              .subtract(const Duration(hours: 1))
              .millisecondsSinceEpoch,
          'size': 1024000,
        },
        {
          'lawyerId': lawyerId,
          'fileName': 'Case_Notes.txt',
          'fileType': 'txt',
          'category': 'Notes',
          'url': 'https://example.com/demo-notes.txt',
          'uploadedAt': DateTime.now()
              .subtract(const Duration(minutes: 30))
              .millisecondsSinceEpoch,
          'size': 15360,
        },
      ];

      for (var document in demoDocuments) {
        await _firestore.collection('lawyer_documents').add(document);
      }

      print('✅ Demo documents added successfully');
    } catch (e) {
      print('❌ Error adding demo documents: $e');
    }
  }

  // Add demo users for consultations
  static Future<void> addDemoUsers() async {
    try {
      final demoUsers = [
        {
          'name': 'Ahmed Hassan',
          'email': 'ahmed.hassan@email.com',
          'phone': '+92-300-1234567',
          'role': 'user',
          'status': 'approved',
          'createdAt': DateTime.now().subtract(const Duration(days: 5)),
          'updatedAt': DateTime.now(),
        },
        {
          'name': 'Fatima Sheikh',
          'email': 'fatima.sheikh@email.com',
          'phone': '+92-301-2345678',
          'role': 'user',
          'status': 'approved',
          'createdAt': DateTime.now().subtract(const Duration(days: 3)),
          'updatedAt': DateTime.now(),
        },
        {
          'name': 'Muhammad Ali',
          'email': 'muhammad.ali@email.com',
          'phone': '+92-302-3456789',
          'role': 'user',
          'status': 'approved',
          'createdAt': DateTime.now().subtract(const Duration(days: 2)),
          'updatedAt': DateTime.now(),
        },
        {
          'name': 'Ayesha Khan',
          'email': 'ayesha.khan@email.com',
          'phone': '+92-303-4567890',
          'role': 'user',
          'status': 'approved',
          'createdAt': DateTime.now().subtract(const Duration(days: 1)),
          'updatedAt': DateTime.now(),
        },
      ];

      for (var user in demoUsers) {
        await _firestore.collection(AppConstants.usersCollection).add(user);
      }

      print('✅ Demo users added successfully');
    } catch (e) {
      print('❌ Error adding demo users: $e');
    }
  }

  // Add demo messages/chat data
  static Future<void> addDemoMessages(String lawyerId) async {
    try {
      final demoMessages = [
        {
          'lawyerId': lawyerId,
          'userId': 'demo_user_1',
          'message':
              'Hello, I need help with my divorce case. When can we schedule a consultation?',
          'sender': 'user',
          'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
          'read': false,
        },
        {
          'lawyerId': lawyerId,
          'userId': 'demo_user_1',
          'message':
              'I can help you with that. Let me check my schedule and get back to you.',
          'sender': 'lawyer',
          'timestamp': DateTime.now().subtract(const Duration(hours: 1)),
          'read': true,
        },
        {
          'lawyerId': lawyerId,
          'userId': 'demo_user_2',
          'message':
              'I have a traffic violation case. What documents do I need to prepare?',
          'sender': 'user',
          'timestamp': DateTime.now().subtract(const Duration(minutes: 30)),
          'read': false,
        },
        {
          'lawyerId': lawyerId,
          'userId': 'demo_user_3',
          'message':
              'Thank you for the consultation yesterday. The advice was very helpful.',
          'sender': 'user',
          'timestamp': DateTime.now().subtract(const Duration(minutes: 15)),
          'read': true,
        },
      ];

      for (var message in demoMessages) {
        await _firestore.collection('lawyer_messages').add(message);
      }

      print('✅ Demo messages added successfully');
    } catch (e) {
      print('❌ Error adding demo messages: $e');
    }
  }

  // Add all demo data for a lawyer
  static Future<void> addAllDemoData(String lawyerId) async {
    try {
      await addDemoUsers();
      await addDemoConsultations(lawyerId);
      await addDemoDocuments(lawyerId);
      await addDemoMessages(lawyerId);

      // Add demo chat messages for each user
      await addDemoChatMessages(lawyerId);

      print('🎉 All demo data added successfully for lawyer: $lawyerId');
    } catch (e) {
      print('❌ Error adding demo data: $e');
    }
  }

  // Clear all demo data
  static Future<void> clearDemoData(String lawyerId) async {
    try {
      // Clear consultations
      final consultations = await _firestore
          .collection(AppConstants.consultationsCollection)
          .where('lawyerId', isEqualTo: lawyerId)
          .get();

      for (var doc in consultations.docs) {
        await doc.reference.delete();
      }

      // Clear documents
      final documents = await _firestore
          .collection('lawyer_documents')
          .where('lawyerId', isEqualTo: lawyerId)
          .get();

      for (var doc in documents.docs) {
        await doc.reference.delete();
      }

      // Clear messages
      final messages = await _firestore
          .collection('lawyer_messages')
          .where('lawyerId', isEqualTo: lawyerId)
          .get();

      for (var doc in messages.docs) {
        await doc.reference.delete();
      }

      print('🗑️ Demo data cleared successfully');
    } catch (e) {
      print('❌ Error clearing demo data: $e');
    }
  }

  // Add real demo chat messages
  static Future<void> addDemoChatMessages(String userId) async {
    try {
      // Sample consultations to get lawyer-user pairs
      QuerySnapshot consultationsSnapshot = await _firestore
          .collection(AppConstants.consultationsCollection)
          .where('userId', isEqualTo: userId)
          .limit(3)
          .get();

      if (consultationsSnapshot.docs.isEmpty) return;

      List<String> chatMessages = [
        'Hello! I have a legal problem.',
        'Hello! I can help you. What is the problem?',
        'I have a property dispute matter.',
        'Okay, it\'s a property dispute. Please send details.',
        'I also have documents that I can show you.',
      ];

      // ChatService chatService = ChatService();

      for (var consultationDoc in consultationsSnapshot.docs) {
        String lawyerId = consultationDoc['lawyerId'] as String;

        // Add some chat messages
        for (int i = 0; i < chatMessages.length; i++) {
          bool isUserMessage = i % 2 == 0;

          try {
            // Use new real-time chat service
            await _firestore.collection('chat_messages').add({
              'chatId': '${userId}_$lawyerId',
              'senderId': isUserMessage ? userId : lawyerId,
              'senderName': isUserMessage ? 'Demo User' : 'Demo Lawyer',
              'senderRole': isUserMessage ? 'user' : 'lawyer',
              'message': chatMessages[i],
              'messageType': 'text',
              'sentAt': DateTime.now(),
              'isRead': false,
            });
          } catch (e) {
            print('Error sending demo message: $e');
          }

          // Add small delay between messages
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }

      print('✅ Demo chat messages added successfully');
    } catch (e) {
      print('❌ Error adding demo chat messages: $e');
    }
  }

  // Clear all demo chat messages
  static Future<void> clearDemoChatMessages() async {
    try {
      print('🗑️ Clearing demo chat messages...');

      // Get all chat messages
      QuerySnapshot chatMessagesSnapshot = await _firestore
          .collection('chat_messages')
          .get();

      // Delete all chat messages
      for (var doc in chatMessagesSnapshot.docs) {
        await doc.reference.delete();
      }

      print('✅ Demo chat messages cleared successfully');
    } catch (e) {
      print('❌ Error clearing demo chat messages: $e');
    }
  }

  // Clear all demo data
  static Future<void> clearAllDemoData() async {
    try {
      print('🗑️ Clearing all demo data...');

      // Clear chat messages
      await clearDemoChatMessages();

      // Clear consultations
      QuerySnapshot consultationsSnapshot = await _firestore
          .collection(AppConstants.consultationsCollection)
          .get();

      for (var doc in consultationsSnapshot.docs) {
        await doc.reference.delete();
      }

      print('✅ All demo data cleared successfully');
    } catch (e) {
      print('❌ Error clearing demo data: $e');
    }
  }
}
