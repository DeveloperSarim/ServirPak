import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_model.dart';
import '../constants/app_constants.dart';

class RealtimeChatService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static StreamSubscription? _currentSubscription;

  // Real-time chat listener - whenever a message arrives, immediately notify
  static Stream<List<ChatMessageModel>> listenToChatMessages(String chatId) {
    return _firestore
        .collection(AppConstants.chatMessagesCollection)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .where((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    return data['chatId'] == chatId;
                  })
                  .map((doc) => ChatMessageModel.fromFirestore(doc))
                  .toList()
                ..sort((a, b) => a.sentAt.compareTo(b.sentAt)),
        );
  }

  // Real-time chat list updates for lawyer - Simple query without index
  static Stream<List<ChatModel>> listenToLawyerChatUpdates(String lawyerId) {
    return _firestore
        .collection(AppConstants.chatsCollection)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .where((doc) {
                var data = doc.data() as Map<String, dynamic>;
                return data['lawyerId'] == lawyerId;
              })
              .map((doc) => ChatModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Real-time chat list updates for user - Simple query without index
  static Stream<List<ChatModel>> listenToUserChatUpdates(String userId) {
    return _firestore
        .collection(AppConstants.chatsCollection)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .where((doc) {
                var data = doc.data() as Map<String, dynamic>;
                return data['userId'] == userId;
              })
              .map((doc) => ChatModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Create new chat real-time
  static Future<void> createChatRealtime({
    required String lawyerId,
    required String userId,
    List<String>? consultationIds,
  }) async {
    try {
      // First check if chat already exists
      QuerySnapshot existingChat = await _firestore
          .collection(AppConstants.chatsCollection)
          .where('lawyerId', isEqualTo: lawyerId)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (existingChat.docs.isNotEmpty) {
        print('Chat already exists');
        return; // Chat already exists
      }

      // Get user info
      DocumentSnapshot userDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        throw Exception('User not found');
      }

      // Get lawyer info
      DocumentSnapshot lawyerDoc = await _firestore
          .collection(AppConstants.lawyersCollection)
          .doc(lawyerId)
          .get();

      if (!lawyerDoc.exists) {
        throw Exception('Lawyer not found');
      }

      // Generate unique chat ID
      String chatId = _generateChatId(lawyerId, userId);

      // Create chat document
      Map<String, dynamic> lawyerData =
          lawyerDoc.data() as Map<String, dynamic>;
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

      // Debug: Print lawyer profile image from database
      String? lawyerProfileImage = lawyerData['profileImage'];
      print(
        '🔍 RealtimeChatService: Lawyer ${lawyerData['name']} - ProfileImage from DB: $lawyerProfileImage',
      );

      ChatModel chat = ChatModel(
        id: chatId,
        lawyerId: lawyerId,
        lawyerName: lawyerData['name'] ?? '',
        lawyerEmail: lawyerData['email'] ?? '',
        lawyerProfileImage: lawyerProfileImage,
        userId: userId,
        userName: userData['name'] ?? '',
        userEmail: userData['email'] ?? '',
        userProfileImage: userData['profileImage'],
        createdAt: DateTime.now(),
        consultationIds: consultationIds ?? [],
      );

      await _firestore
          .collection(AppConstants.chatsCollection)
          .doc(chatId)
          .set(chat.toFirestore());

      print('✅ Real-time chat created successfully');
    } catch (e) {
      print('❌ Error creating real-time chat: $e');
      throw e;
    }
  }

  // Send message with real-time updates
  static Future<bool> sendMessageRealtime({
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

      // Atomic write operation - message aur chat update dono ek saath
      WriteBatch batch = _firestore.batch();

      // Add message
      batch.set(messageRef, chatMessage.toFirestore());

      // Update chat's last message info
      DocumentReference chatRef = _firestore
          .collection(AppConstants.chatsCollection)
          .doc(chatId);

      batch.update(chatRef, {
        'lastMessage': message,
        'lastMessageSenderId': senderId,
        'lastMessageTime': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Commit transactions
      await batch.commit();

      print('✅ Real-Time Message sent successfully');
      return true;
    } catch (e) {
      print('❌ Error sending real-time message: $e');
      return false;
    }
  }

  // Mark messages as read immediately
  static Future<void> markMessagesAsReadRealtime({
    required String chatId,
    required String currentUserId,
  }) async {
    try {
      QuerySnapshot unreadMessages = await _firestore
          .collection(AppConstants.chatMessagesCollection)
          .where('chatId', isEqualTo: chatId)
          .where('senderId', isNotEqualTo: currentUserId)
          .get();

      if (unreadMessages.docs.isEmpty) return;

      WriteBatch batch = _firestore.batch();

      for (DocumentSnapshot doc in unreadMessages.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': Timestamp.fromDate(DateTime.now()),
          'readBy': FieldValue.arrayUnion([currentUserId]),
        });
      }

      await batch.commit();
      print('✅ Messages marked as read in real-time');
    } catch (e) {
      print('❌ Error marking messages as read: $e');
    }
  }

  // Listen for typing indicators (optional feature)
  static Future<void> updateTypingStatus({
    required String chatId,
    required String userId,
    required bool isTyping,
  }) async {
    try {
      await _firestore
          .collection(AppConstants.chatsCollection)
          .doc(chatId)
          .set({
            'isTyping': FieldValue.arrayUnion([userId]),
            'typingUsers': FieldValue.arrayUnion([userId]),
            'lastTypingTime': Timestamp.fromDate(DateTime.now()),
          })
          .catchError((error) {
            // Handle error if needed
            if (isTyping != true) {
              _removeTypingUser(chatId, userId);
            }
          });
    } catch (e) {
      print('❌ Error updating typing status: $e');
    }
  }

  static Future<void> _removeTypingUser(String chatId, String userId) async {
    try {
      await _firestore
          .collection(AppConstants.chatsCollection)
          .doc(chatId)
          .update({
            'typingUsers': FieldValue.arrayRemove([userId]),
          });
    } catch (e) {
      print('❌ Error removing typing user: $e');
    }
  }

  // Get typing indicators (optional feature)
  static Stream<List<String>> getTypingUsers(String chatId) {
    return _firestore
        .collection(AppConstants.chatsCollection)
        .doc(chatId)
        .snapshots()
        .map((snapshot) {
          if (snapshot.exists) {
            Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
            List<dynamic> typingUsers = data['typingUsers'] ?? [];
            return typingUsers.cast<String>();
          }
          return <String>[];
        });
  }

  // Cancel current subscription
  static void cancelSubscription() {
    _currentSubscription?.cancel();
    _currentSubscription = null;
  }

  // Generate unique chat ID
  static String _generateChatId(String lawyerId, String userId) {
    if (lawyerId.compareTo(userId) < 0) {
      return '${lawyerId}_$userId';
    } else {
      return '${userId}_$lawyerId';
    }
  }
}
