import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_constants.dart';

class FirebaseSetupHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Setup basic chat demo data without complex queries
  static Future<void> setupDemoChatData() async {
    try {
      // Create demo chat
      await _createDemoChat('user_123', 'lawyer_123');

      // Send demo messages
      await _sendDemoMessages('user_123', 'lawyer_123');

      print('✅ Demo chat data created successfully');
    } catch (e) {
      print('❌ Error setting up demo chat data: $e');
    }
  }

  static Future<void> _createDemoChat(String userId, String lawyerId) async {
    final chatId = '${userId}_$lawyerId';

    await _firestore.collection(AppConstants.chatsCollection).doc(chatId).set({
      'id': chatId,
      'lawyerId': lawyerId,
      'userId': userId,
      'lawyerName': 'Demo Lawyer',
      'lawyerEmail': 'lawyer@demo.com',
      'lawyerProfileImage': null,
      'userName': 'Demo User',
      'userEmail': 'user@demo.com',
      'userProfileImage': null,
      'createdAt': DateTime.now(),
      'lastMessage': 'Hello! I need legal consultation.',
      'lastMessageSenderId': userId,
      'lastMessageTime': DateTime.now(),
      'lawyerHasBlocked': false,
      'userHasBlocked': false,
      'isArchived': false,
      'consultationIds': ['demo_123'],
      'updatedAt': DateTime.now(),
    });

    print('✅ Demo chat created: $chatId');
  }

  static Future<void> _sendDemoMessages(String userId, String lawyerId) async {
    final chatId = '${userId}_$lawyerId';
    final messages = [
      {
        'senderId': userId,
        'senderRole': 'user',
        'message': 'Hello! I need legal consultation regarding property law.',
      },
      {
        'senderId': lawyerId,
        'senderRole': 'lawyer',
        'message':
            'Hi! I\'m happy to help you. What specific property issues are you facing?',
      },
      {
        'senderId': userId,
        'senderRole': 'user',
        'message': 'I have a dispute about land ownership with my neighbor.',
      },
      {
        'senderId': lawyerId,
        'senderRole': 'lawyer',
        'message':
            'I understand. Property disputes can be complex. Let me schedule a consultation meeting.',
      },
    ];

    for (int i = 0; i < messages.length; i++) {
      final message = messages[i];
      await _firestore.collection(AppConstants.chatMessagesCollection).add({
        'id': '',
        'chatId': chatId,
        'senderId': message['senderId'],
        'senderName': message['senderRole'] == 'lawyer'
            ? 'Demo Lawyer'
            : 'Demo User',
        'senderRole': message['senderRole'],
        'senderEmail': message['senderRole'] == 'lawyer'
            ? 'lawyer@demo.com'
            : 'user@demo.com',
        'message': message['message'],
        'messageType': 'text',
        'imageUrl': null,
        'documentUrl': null,
        'documentName': null,
        'sentAt': DateTime.now().add(Duration(minutes: i)),
        'isRead': false,
        'isDeleted': false,
        'readAt': null,
        'readBy': [],
        'reactions': {},
        'replyTo': null,
        'editedAt': null,
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
      });

      // Add delay between messages
      await Future.delayed(const Duration(milliseconds: 500));
    }

    print('✅ Demo messages sent for chat: $chatId');
  }

  // Quick setup function to initialize everything
  static Future<void> quickSetup() async {
    try {
      await setupDemoChatData();
      print('🚀 Firebase demo setup complete!');
    } catch (e) {
      print('❌ Firebase setup error: $e');
    }
  }
}
