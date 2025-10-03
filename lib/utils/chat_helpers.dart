import '../../services/realtime_chat_service.dart';
import '../../models/consultation_model.dart';
import '../../models/chat_model.dart';
import '../../constants/app_constants.dart';

class ChatHelpers {
  // Jab lawyer accept karta hai consultation ko, automatically chat ban jaye
  static Future<void> createChatFromConsultation({
    required ConsultationModel consultation,
  }) async {
    try {
      await RealtimeChatService.createChatRealtime(
        lawyerId: consultation.lawyerId,
        userId: consultation.userId,
        consultationIds: [consultation.id],
      );

      print(
        '✅ Chat created automatically from consultation ${consultation.id}',
      );
    } catch (e) {
      print('❌ Error creating chat from consultation: $e');
    }
  }

  // Jab user consultation book karta hai, uska lawyer select karne ke baad chat ban jaye
  static Future<void> createChatForNewConsultation({
    required String lawyerId,
    required String userId,
    required String consultationId,
  }) async {
    try {
      await RealtimeChatService.createChatRealtime(
        lawyerId: lawyerId,
        userId: userId,
        consultationIds: [consultationId],
      );

      print('✅ Chat created automatically for consultation $consultationId');
    } catch (e) {
      print('❌ Error creating chat for consultation: $e');
    }
  }

  // Generate welcome message automatically
  static String generateWelcomeMessage({
    required String senderName,
    required String recipientName,
    required bool isFromLawyer,
  }) {
    if (isFromLawyer) {
      return "Hello ${recipientName}! I'm ${senderName}, your legal advisor. How can I help you today?";
    } else {
      return "Hello ${recipientName}! Thank you for accepting my consultation request. I have some legal questions for you.";
    }
  }

  // Format chat display name
  static String getChatDisplayName({
    required bool isLawyer,
    required String lawyerName,
    required String userName,
  }) {
    return isLawyer ? userName : lawyerName;
  }

  // Get chat status for display
  static String getChatStatus(ChatModel chat) {
    if (chat.lawyerHasBlocked) {
      return 'Blocked by lawyer';
    } else if (chat.userHasBlocked) {
      return 'Blocked by user';
    } else if (chat.isArchived) {
      return 'Archived';
    } else {
      return 'Active';
    }
  }

  // Get appropriate icon for chat status
  static String getChatStatusIcon(ChatModel chat) {
    if (chat.lawyerHasBlocked || chat.userHasBlocked) {
      return 'block';
    } else if (chat.isArchived) {
      return 'archive';
    } else if (chat.lastMessageSenderId != null) {
      // Check if last message was not from current user (unread)
      return 'unread';
    } else {
      return 'active';
    }
  }

  // Send welcome message when chat is created
  static Future<void> sendWelcomeMessage({
    required String chatId,
    required String lawyerId,
    required String lawyerName,
    required String lawyerEmail,
    required String userId,
    required String userName,
    required String userEmail,
  }) async {
    try {
      // Lawyer se welcome message
      await RealtimeChatService.sendMessageRealtime(
        chatId: chatId,
        senderId: lawyerId,
        senderName: lawyerName,
        senderRole: 'lawyer',
        senderEmail: lawyerEmail,
        message: ChatHelpers.generateWelcomeMessage(
          senderName: lawyerName,
          recipientName: userName,
          isFromLawyer: true,
        ),
      );

      // User se welcome message (optional)
      await Future.delayed(const Duration(seconds: 2));

      await RealtimeChatService.sendMessageRealtime(
        chatId: chatId,
        senderId: userId,
        senderName: userName,
        senderRole: 'user',
        senderEmail: userEmail,
        message: ChatHelpers.generateWelcomeMessage(
          senderName: userName,
          recipientName: lawyerName,
          isFromLawyer: false,
        ),
      );

      print('✅ Welcome messages sent automatically');
    } catch (e) {
      print('❌ Error sending welcome message: $e');
    }
  }

  // Get lawyer info for chat
  static Future<Map<String, dynamic>?> getLawyerInfoForChat(
    String lawyerId,
  ) async {
    try {
      // This would normally fetch from Firestore
      // For demo purposes, return sample data
      return {
        'name': 'Demo Lawyer',
        'email': 'lawyer@demo.com',
        'specialization': 'General Practice',
        'rating': 4.8,
      };
    } catch (e) {
      print('❌ Error getting lawyer info: $e');
      return null;
    }
  }

  // Get user info for chat
  static Future<Map<String, dynamic>?> getUserInfoForChat(String userId) async {
    try {
      // This would normally fetch from Firestore
      // For demo purposes, return sample data
      return {
        'name': 'Demo User',
        'email': 'user@demo.com',
        'phone': '+92-300-0000000',
      };
    } catch (e) {
      print('❌ Error getting user info: $e');
      return null;
    }
  }
}
