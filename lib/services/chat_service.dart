import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_model.dart';
import '../constants/app_constants.dart';

class ChatService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Send message (new method for direct chat)
  Future<void> sendDirectMessage({
    required String conversationId,
    required String senderId,
    required String receiverId,
    required String message,
  }) async {
    try {
      await _firestore.collection(AppConstants.chatMessagesCollection).add({
        'conversationId': conversationId,
        'senderId': senderId,
        'receiverId': receiverId,
        'message': message,
        'timestamp': Timestamp.now(),
        'participants': [senderId, receiverId],
      });
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }

  // Send message
  static Future<String> sendMessage({
    required String consultationId,
    required String senderId,
    required String senderName,
    required String senderRole,
    required String message,
    String messageType = 'text',
    String? fileUrl,
  }) async {
    try {
      ChatModel chatMessage = ChatModel(
        id: '', // Will be set by Firestore
        consultationId: consultationId,
        senderId: senderId,
        senderName: senderName,
        senderRole: senderRole,
        message: message,
        messageType: messageType,
        fileUrl: fileUrl,
        isRead: false,
        createdAt: DateTime.now(),
      );

      DocumentReference docRef = await _firestore
          .collection(AppConstants.chatCollection)
          .add(chatMessage.toFirestore());

      print('Message sent successfully: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }

  // Get messages for a consultation
  static Stream<List<ChatModel>> getMessagesStream(String consultationId) {
    return _firestore
        .collection(AppConstants.chatCollection)
        .where('consultationId', isEqualTo: consultationId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => ChatModel.fromFirestore(doc)).toList(),
        );
  }

  // Get messages for a consultation (one-time)
  static Future<List<ChatModel>> getMessages(String consultationId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.chatCollection)
          .where('consultationId', isEqualTo: consultationId)
          .orderBy('createdAt', descending: false)
          .get();

      return snapshot.docs.map((doc) => ChatModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting messages: $e');
      return [];
    }
  }

  // Mark message as read
  static Future<void> markMessageAsRead(String messageId) async {
    try {
      await _firestore
          .collection(AppConstants.chatCollection)
          .doc(messageId)
          .update({'isRead': true});

      print('Message marked as read: $messageId');
    } catch (e) {
      print('Error marking message as read: $e');
    }
  }

  // Mark all messages as read for a consultation
  static Future<void> markAllMessagesAsRead(
    String consultationId,
    String currentUserId,
  ) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.chatCollection)
          .where('consultationId', isEqualTo: consultationId)
          .where('senderId', isNotEqualTo: currentUserId)
          .where('isRead', isEqualTo: false)
          .get();

      WriteBatch batch = _firestore.batch();
      for (DocumentSnapshot doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
      print('All messages marked as read for consultation: $consultationId');
    } catch (e) {
      print('Error marking all messages as read: $e');
    }
  }

  // Get unread message count for a consultation
  static Future<int> getUnreadMessageCount(
    String consultationId,
    String currentUserId,
  ) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.chatCollection)
          .where('consultationId', isEqualTo: consultationId)
          .where('senderId', isNotEqualTo: currentUserId)
          .where('isRead', isEqualTo: false)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      print('Error getting unread message count: $e');
      return 0;
    }
  }

  // Get unread message count for all consultations
  static Future<Map<String, int>> getUnreadMessageCounts(
    String currentUserId,
  ) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.chatCollection)
          .where('senderId', isNotEqualTo: currentUserId)
          .where('isRead', isEqualTo: false)
          .get();

      Map<String, int> unreadCounts = {};
      for (DocumentSnapshot doc in snapshot.docs) {
        ChatModel message = ChatModel.fromFirestore(doc);
        unreadCounts[message.consultationId] =
            (unreadCounts[message.consultationId] ?? 0) + 1;
      }

      return unreadCounts;
    } catch (e) {
      print('Error getting unread message counts: $e');
      return {};
    }
  }

  // Delete message
  static Future<void> deleteMessage(String messageId) async {
    try {
      await _firestore
          .collection(AppConstants.chatCollection)
          .doc(messageId)
          .delete();

      print('Message deleted successfully: $messageId');
    } catch (e) {
      print('Error deleting message: $e');
      rethrow;
    }
  }

  // Get last message for a consultation
  static Future<ChatModel?> getLastMessage(String consultationId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.chatCollection)
          .where('consultationId', isEqualTo: consultationId)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return ChatModel.fromFirestore(snapshot.docs.first);
      }
      return null;
    } catch (e) {
      print('Error getting last message: $e');
      return null;
    }
  }

  // Get all consultations with unread messages
  static Future<List<String>> getConsultationsWithUnreadMessages(
    String currentUserId,
  ) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.chatCollection)
          .where('senderId', isNotEqualTo: currentUserId)
          .where('isRead', isEqualTo: false)
          .get();

      Set<String> consultationIds = {};
      for (DocumentSnapshot doc in snapshot.docs) {
        ChatModel message = ChatModel.fromFirestore(doc);
        consultationIds.add(message.consultationId);
      }

      return consultationIds.toList();
    } catch (e) {
      print('Error getting consultations with unread messages: $e');
      return [];
    }
  }
}
