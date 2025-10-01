import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../constants/app_constants.dart';
import '../../models/chat_model.dart';
import '../../models/lawyer_model.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ChatService _chatService = ChatService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Chats',
          style: TextStyle(
            color: Color(0xFF8B4513),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Color(0xFF8B4513)),
            onPressed: () {
              // TODO: Implement search functionality
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection(AppConstants.chatMessagesCollection)
            .where(
              'participants',
              arrayContains: AuthService.currentUser?.uid ?? '',
            )
            .orderBy('lastMessageTime', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          // Group chats by conversation
          Map<String, List<QueryDocumentSnapshot>> conversations = {};
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final participants = List<String>.from(data['participants'] ?? []);
            final conversationId = _getConversationId(participants);

            if (!conversations.containsKey(conversationId)) {
              conversations[conversationId] = [];
            }
            conversations[conversationId]!.add(doc);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              final conversationId = conversations.keys.elementAt(index);
              final messages = conversations[conversationId]!;
              final lastMessage = messages.first;
              final data = lastMessage.data() as Map<String, dynamic>;

              return _buildChatItem(data, conversationId);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showNewChatDialog();
        },
        backgroundColor: const Color(0xFF8B4513),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No chats yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a conversation with a lawyer',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              _showNewChatDialog();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B4513),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Start New Chat'),
          ),
        ],
      ),
    );
  }

  Widget _buildChatItem(Map<String, dynamic> data, String conversationId) {
    final participants = List<String>.from(data['participants'] ?? []);
    final otherParticipantId = participants.firstWhere(
      (id) => id != AuthService.currentUser?.uid,
      orElse: () => '',
    );

    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore
          .collection(AppConstants.lawyersCollection)
          .doc(otherParticipantId)
          .snapshots(),
      builder: (context, lawyerSnapshot) {
        if (!lawyerSnapshot.hasData) {
          return const SizedBox.shrink();
        }

        final lawyerData = lawyerSnapshot.data!.data() as Map<String, dynamic>?;
        final lawyerName = lawyerData?['name'] ?? 'Unknown Lawyer';
        final lawyerSpecialization =
            lawyerData?['specialization'] ?? 'General Practice';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              radius: 25,
              backgroundColor: const Color(0xFF8B4513).withOpacity(0.1),
              child: Text(
                lawyerName.isNotEmpty ? lawyerName[0].toUpperCase() : 'L',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8B4513),
                ),
              ),
            ),
            title: Text(
              lawyerName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  lawyerSpecialization,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Text(
                  data['message'] ?? 'No messages yet',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatTime(data['timestamp']),
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                const SizedBox(height: 4),
                if (data['unreadCount'] != null && data['unreadCount'] > 0)
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color(0xFF8B4513),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${data['unreadCount']}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    lawyerId: otherParticipantId,
                    lawyerName: lawyerName,
                    conversationId: conversationId,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  String _getConversationId(List<String> participants) {
    participants.sort();
    return participants.join('_');
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return '';

    DateTime dateTime;
    if (timestamp is Timestamp) {
      dateTime = timestamp.toDate();
    } else {
      return '';
    }

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _showNewChatDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start New Chat'),
        content: const Text('Select a lawyer to start a conversation'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Navigate to lawyer selection
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B4513),
              foregroundColor: Colors.white,
            ),
            child: const Text('Select Lawyer'),
          ),
        ],
      ),
    );
  }
}
