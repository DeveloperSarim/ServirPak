import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_constants.dart';
import '../models/chat_model.dart';
import '../models/user_model.dart';
import '../models/lawyer_model.dart';

class ChatService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new chat between lawyer and user
  static Future<String?> createChat({
    required String lawyerId,
    required String userId,
    List<String>? consultationIds,
  }) async {
    try {
      // Check if chat already exists
      String chatId = await _getExistingChatId(lawyerId, userId);
      if (chatId.isNotEmpty) {
        return chatId;
      }

      // Get user info
      DocumentSnapshot userDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        throw Exception('User not found');
      }

      UserModel user = UserModel.fromFirestore(userDoc);

      // Get lawyer info
      DocumentSnapshot lawyerDoc = await _firestore
          .collection(AppConstants.lawyersCollection)
          .doc(lawyerId)
          .get();

      if (!lawyerDoc.exists) {
        throw Exception('Lawyer not found');
      }

      LawyerModel lawyer = LawyerModel.fromFirestore(lawyerDoc);

      // Create chat document
      ChatModel chat = ChatModel(
        id: _generateChatId(lawyerId, userId),
        lawyerId: lawyerId,
        lawyerName: lawyer.name,
        lawyerEmail: lawyer.email,
        lawyerProfileImage: lawyer.profileImage,
        userId: userId,
        userName: user.name,
        userEmail: user.email,
        userProfileImage: user.profileImage,
        createdAt: DateTime.now(),
        consultationIds: consultationIds ?? [],
      );

      await _firestore
          .collection(AppConstants.chatsCollection)
          .doc(chat.id)
          .set(chat.toFirestore());

      print('✅ ChatService: Created chat ${chat.id}');
      return chat.id;
    } catch (e) {
      print('❌ ChatService: Error creating chat: $e');
      return null;
    }
  }

  // Send a message
  static Future<bool> sendMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String senderRole,
    required String senderEmail,
    required String message,
    String messageType = 'text',
    String? imageUrl,
    String? documentUrl,
    String? documentName,
  }) async {
    try {
      DocumentReference messageRef = _firestore
          .collection(AppConstants.chatMessagesCollection)
          .doc();

      ChatMessageModel chatMessage = ChatMessageModel(
        id: messageRef.id,
        chatId: chatId,
        senderId: senderId,
        senderName: senderName,
        senderRole: senderRole,
        senderEmail: senderEmail,
        message: message,
        messageType: messageType,
        imageUrl: imageUrl,
        documentUrl: documentUrl,
        documentName: documentName,
        sentAt: DateTime.now(),
      );

      await messageRef.set(chatMessage.toFirestore());

      // Update chat with last message info
      await _updateChatLastMessage(chatId, message, senderId, DateTime.now());

      print('✅ ChatService: Message sent successfully');
      return true;
    } catch (e) {
      print('❌ ChatService: Error sending message: $e');
      return false;
    }
  }

  // Get chat messages
  static Stream<List<ChatMessageModel>> getChatMessages(String chatId) {
    return _firestore
        .collection(AppConstants.chatMessagesCollection)
        .where('chatId', isEqualTo: chatId)
        .orderBy('sentAt', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ChatMessageModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Get chats for lawyer
  static Stream<List<ChatModel>> getLawyerChats(String lawyerId) {
    return _firestore
        .collection(AppConstants.chatsCollection)
        .where('lawyerId', isEqualTo: lawyerId)
        .where('lawyerHasBlocked', isEqualTo: false)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => ChatModel.fromFirestore(doc)).toList(),
        );
  }

  // Get chats for user
  static Stream<List<ChatModel>> getUserChats(String userId) {
    return _firestore
        .collection(AppConstants.chatsCollection)
        .where('userId', isEqualTo: userId)
        .where('userHasBlocked', isEqualTo: false)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => ChatModel.fromFirestore(doc)).toList(),
        );
  }

  // Get specific chat
  static Future<ChatModel?> getChat(String chatId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(AppConstants.chatsCollection)
          .doc(chatId)
          .get();

      if (doc.exists) {
        return ChatModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('❌ ChatService: Error getting chat: $e');
      return null;
    }
  }

  // Mark messages as read
  static Future<void> markMessagesAsRead({
    required String chatId,
    required String currentUserId,
  }) async {
    try {
      QuerySnapshot unreadMessages = await _firestore
          .collection(AppConstants.chatMessagesCollection)
          .where('chatId', isEqualTo: chatId)
          .where('senderId', isNotEqualTo: currentUserId)
          .get();

      WriteBatch batch = _firestore.batch();

      for (DocumentSnapshot doc in unreadMessages.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': Timestamp.fromDate(DateTime.now()),
          'readBy': FieldValue.arrayUnion([currentUserId]),
        });
      }

      await batch.commit();
      print('✅ ChatService: Messages marked as read');
    } catch (e) {
      print('❌ ChatService: Error marking messages as read: $e');
    }
  }

  // Block/unblock user in chat
  static Future<void> toggleUserBlock({
    required String chatId,
    required String currentUserId,
    required bool isLawyer,
    required bool blockStatus,
  }) async {
    try {
      Map<String, dynamic> updateData = {};

      if (isLawyer) {
        updateData['lawyerHasBlocked'] = blockStatus;
      } else {
        updateData['userHasBlocked'] = blockStatus;
      }

      updateData['updatedAt'] = Timestamp.fromDate(DateTime.now());

      await _firestore
          .collection(AppConstants.chatsCollection)
          .doc(chatId)
          .update(updateData);

      print('✅ ChatService: User blocked/unblocked');
    } catch (e) {
      print('❌ ChatService: Error blocking user: $e');
    }
  }

  // Archive/unarchive chat
  static Future<void> toggleChatArchived({
    required String chatId,
    required bool archiveStatus,
  }) async {
    try {
      await _firestore
          .collection(AppConstants.chatsCollection)
          .doc(chatId)
          .update({
            'isArchived': archiveStatus,
            'updatedAt': Timestamp.fromDate(DateTime.now()),
          });

      print('✅ ChatService: Chat archived/unarchived');
    } catch (e) {
      print('❌ ChatService: Error archiving chat: $e');
    }
  }

  // Delete message
  static Future<void> deleteMessage(String messageId) async {
    try {
      await _firestore
          .collection(AppConstants.chatMessagesCollection)
          .doc(messageId)
          .update({
            'isDeleted': true,
            'updatedAt': Timestamp.fromDate(DateTime.now()),
          });

      print('✅ ChatService: Message deleted');
    } catch (e) {
      print('❌ ChatService: Error deleting message: $e');
    }
  }

  // Update chat with last message info
  static Future<void> _updateChatLastMessage(
    String chatId,
    String message,
    String senderId,
    DateTime time,
  ) async {
    try {
      await _firestore
          .collection(AppConstants.chatsCollection)
          .doc(chatId)
          .update({
            'lastMessage': message,
            'lastMessageSenderId': senderId,
            'lastMessageTime': Timestamp.fromDate(time),
            'updatedAt': Timestamp.fromDate(DateTime.now()),
          });
    } catch (e) {
      print('❌ ChatService: Error updating chat last message: $e');
    }
  }

  // Get existing chat ID
  static Future<String> _getExistingChatId(
    String lawyerId,
    String userId,
  ) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.chatsCollection)
          .where('lawyerId', isEqualTo: lawyerId)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.id;
      }
      return '';
    } catch (e) {
      print('❌ ChatService: Error getting existing chat ID: $e');
      return '';
    }
  }

  // Generate chat ID
  static String _generateChatId(String lawyerId, String userId) {
    // Create a consistent chat ID regardless of who initiates
    if (lawyerId.compareTo(userId) < 0) {
      return '${lawyerId}_$userId';
    } else {
      return '${userId}_$lawyerId';
    }
  }

  // Get unread message count for user/lawyer
  static Stream<int> getUnreadMessageCount(String userId, bool isLawyer) {
    return _firestore
        .collection(AppConstants.chatMessagesCollection)
        .where('senderRole', isEqualTo: isLawyer ? 'user' : 'lawyer')
        .snapshots()
        .map((snapshot) {
          int unreadCount = 0;
          for (var doc in snapshot.docs) {
            var data = doc.data() as Map<String, dynamic>;
            if (!data['isRead'] ?? false) {
              unreadCount++;
            }
          }
          return unreadCount;
        });
  }

  // Send message and get real-time updates
  static Stream<bool> sendMessageWithStatus({
    required String chatId,
    required String senderId,
    required String senderName,
    required String senderRole,
    required String senderEmail,
    required String message,
    String messageType = 'text',
    String? imageUrl,
    String? documentUrl,
    String? documentName,
  }) async* {
    try {
      DocumentReference messageRef = _firestore
          .collection(AppConstants.chatMessagesCollection)
          .doc();

      ChatMessageModel chatMessage = ChatMessageModel(
        id: messageRef.id,
        chatId: chatId,
        senderId: senderId,
        senderName: senderName,
        senderRole: senderRole,
        senderEmail: senderEmail,
        message: message,
        messageType: messageType,
        imageUrl: imageUrl,
        documentUrl: documentUrl,
        documentName: documentName,
        sentAt: DateTime.now(),
      );

      await messageRef.set(chatMessage.toFirestore());

      // Update chat with last message info
      await _updateChatLastMessage(chatId, message, senderId, DateTime.now());

      print('✅ ChatService: Message sent successfully');
      yield true;
    } catch (e) {
      print('❌ ChatService: Error sending message: $e');
      yield false;
    }
  }

  // Listen for new messages in a chat (real-time)
  static Stream<ChatMessageModel> listenForNewMessages(
    String chatId,
    String currentUserId,
  ) {
    return _firestore
        .collection(AppConstants.chatMessagesCollection)
        .where('chatId', isEqualTo: chatId)
        .orderBy('sentAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isNotEmpty) {
            return ChatMessageModel.fromFirestore(snapshot.docs.first);
          }
          throw Exception('No messages found');
        });
  }

  // Legacy methods for backward compatibility
  static Future<List<Map<String, dynamic>>> getUserConversations(
    String userId,
  ) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.chatsCollection)
          .where('userId', isEqualTo: userId)
          .get();

      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print('❌ Error getting user conversations: $e');
      return [];
    }
  }

  static String generateConversationId(String userId1, String userId2) {
    if (userId1.compareTo(userId2) < 0) {
      return '${userId1}_$userId2';
    } else {
      return '${userId2}_$userId1';
    }
  }

  static Future<List<Map<String, dynamic>>> getConversationMessages(
    String conversationId,
  ) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.chatMessagesCollection)
          .where('conversationId', isEqualTo: conversationId)
          .orderBy('timestamp', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print('❌ Error getting conversation messages: $e');
      return [];
    }
  }

  static Future<bool> sendDirectMessage({
    required String conversationId,
    required String senderId,
    required String content,
    String messageType = 'text',
  }) async {
    try {
      await _firestore.collection(AppConstants.chatMessagesCollection).add({
        'conversationId': conversationId,
        'senderId': senderId,
        'content': content,
        'messageType': messageType,
        'timestamp': DateTime.now(),
        'isRead': false,
      });

      print('✅ Direct message sent successfully');
      return true;
    } catch (e) {
      print('❌ Error sending direct message: $e');
      return false;
    }
  }
}
