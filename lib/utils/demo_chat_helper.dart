import '../services/realtime_chat_service.dart';

class DemoChatHelper {
  // Create demo chats between users and lawyers
  static Future<void> createDemoChats() async {
    try {
      // Demo user IDs
      final List<String> demoUsers = ['user_123', 'user_456', 'user_789'];

      // Demo lawyer IDs
      final List<String> demoLawyers = ['lawyer_123', 'lawyer_456'];

      // Create chats between users and lawyers
      for (int i = 0; i < demoUsers.length && i < demoLawyers.length; i++) {
        await RealtimeChatService.createChatRealtime(
          lawyerId: demoLawyers[i],
          userId: demoUsers[i],
          consultationIds: ['demo_consultation_${i + 1}'],
        );

        // Send welcome message
        await _sendWelcomeMessage(
          chatId: '${demoUsers[i]}_${demoLawyers[i]}',
          lawyerId: demoLawyers[i],
          userId: demoUsers[i],
        );
      }

      print('✅ Demo chats created successfully');
    } catch (e) {
      print('❌ Error creating demo chats: $e');
    }
  }

  static Future<void> _sendWelcomeMessage({
    required String chatId,
    required String lawyerId,
    required String userId,
  }) async {
    try {
      // Lawyer welcome message
      await RealtimeChatService.sendMessageRealtime(
        chatId: chatId,
        senderId: lawyerId,
        senderName: 'Demo Lawyer',
        senderRole: 'lawyer',
        senderEmail: 'lawyer@demo.com',
        message: 'Hello! I am your legal advisor. How can I help you today?',
      );

      // User response
      await Future.delayed(const Duration(seconds: 1));

      await RealtimeChatService.sendMessageRealtime(
        chatId: chatId,
        senderId: userId,
        senderName: 'Demo User',
        senderRole: 'user',
        senderEmail: 'user@demo.com',
        message: 'Hi! I need legal consultation regarding property matters.',
      );

      print('✅ Welcome messages sent for chat $chatId');
    } catch (e) {
      print('❌ Error sending welcome message: $e');
    }
  }

  // Quick test message for existing chat
  static Future<void> sendTestMessage(
    String chatId,
    String senderId,
    String senderRole,
  ) async {
    try {
      await RealtimeChatService.sendMessageRealtime(
        chatId: chatId,
        senderId: senderId,
        senderName: senderRole == 'lawyer' ? 'Demo Lawyer' : 'Demo User',
        senderRole: senderRole,
        senderEmail: senderRole == 'lawyer'
            ? 'lawyer@demo.com'
            : 'user@demo.com',
        message: 'Test message - ${DateTime.now().millisecondsSinceEpoch}',
      );

      print('✅ Test message sent');
    } catch (e) {
      print('❌ Error sending test message: $e');
    }
  }
}
