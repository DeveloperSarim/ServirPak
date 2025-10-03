import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../services/realtime_chat_service.dart';
import '../../models/chat_model.dart';
import '../../constants/app_constants.dart';
import '../../utils/responsive_helper.dart';
import 'user_chat_screen.dart';

class UserChatListScreen extends StatefulWidget {
  const UserChatListScreen({super.key});

  @override
  State<UserChatListScreen> createState() => _UserChatListScreenState();
}

class _UserChatListScreenState extends State<UserChatListScreen> {
  late Stream<List<ChatModel>> _chatsStream;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
  }

  Future<void> _loadCurrentUserId() async {
    try {
      final session = await AuthService.getSavedUserSession();
      _currentUserId = session['userId'] as String;
      setState(() {
        _chatsStream = RealtimeChatService.listenToUserChatUpdates(
          _currentUserId!,
        );
      });
    } catch (e) {
      print('❌ Error loading user ID: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Messages',
          style: TextStyle(
            color: Color(0xFF8B4513),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF8B4513),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'archived') {
                // TODO: Show archived chats
              } else if (value == 'blocked') {
                // TODO: Show blocked chats
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'archived',
                child: Row(
                  children: [
                    Icon(Icons.archive, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Archived Chats'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'blocked',
                child: Row(
                  children: [
                    Icon(Icons.block, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Blocked Lawyers'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<List<ChatModel>>(
        stream: _chatsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading chats',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: const TextStyle(fontSize: 12, color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          List<ChatModel> chats = snapshot.data ?? [];

          if (chats.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No messages yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Your conversations with lawyers will appear here',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: chats.length,
            itemBuilder: (context, index) {
              ChatModel chat = chats[index];
              return _buildChatCard(chat);
            },
          );
        },
      ),
    );
  }

  Widget _buildChatCard(ChatModel chat) {
    String lastMessageTime = _formatLastMessageTime(chat.lastMessageTime);
    bool hasUnreadMessages = chat.lastMessageSenderId != _currentUserId;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _navigateToChat(chat),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Profile Avatar
              Stack(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFF8B4513).withOpacity(0.1),
                    backgroundImage: chat.lawyerProfileImage != null
                        ? NetworkImage(chat.lawyerProfileImage!)
                        : null,
                    child: chat.lawyerProfileImage == null
                        ? const Icon(
                            Icons.person,
                            color: Color(0xFF8B4513),
                            size: 32,
                          )
                        : null,
                  ),
                  if (!chat.isArchived && hasUnreadMessages)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  if (chat.isArchived)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.archive,
                          size: 12,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),

              // Chat Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            chat.lawyerName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: hasUnreadMessages
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          lastMessageTime,
                          style: TextStyle(
                            fontSize: 12,
                            color: hasUnreadMessages
                                ? Colors.black87
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            chat.lastMessage ?? 'No messages yet',
                            style: TextStyle(
                              fontSize: 14,
                              color: hasUnreadMessages
                                  ? Colors.black87
                                  : Colors.grey.shade600,
                              fontWeight: hasUnreadMessages
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        if (chat.lastMessageSenderId == _currentUserId)
                          const Icon(
                            Icons.check,
                            size: 16,
                            color: Colors.green,
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Action Button
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'archive') {
                    _toggleArchive(chat);
                  } else if (value == 'block') {
                    _toggleBlock(chat);
                  } else if (value == 'view_profile') {
                    _showLawyerProfile(chat);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'archive',
                    child: Row(
                      children: [
                        Icon(
                          chat.isArchived ? Icons.unarchive : Icons.archive,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Text(chat.isArchived ? 'Unarchive' : 'Archive'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'block',
                    child: Row(
                      children: [
                        Icon(
                          chat.userHasBlocked
                              ? Icons.person_add
                              : Icons.person_remove,
                          color: Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          chat.userHasBlocked
                              ? 'Unblock Lawyer'
                              : 'Block Lawyer',
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'view_profile',
                    child: Row(
                      children: [
                        Icon(Icons.person, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('View Profile'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatLastMessageTime(DateTime? time) {
    if (time == null) return '';

    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inDays > 0) {
      return '${diff.inDays}d';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m';
    } else {
      return 'Now';
    }
  }

  void _navigateToChat(ChatModel chat) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => UserChatScreen(chat: chat)),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Messages'),
        content: const TextField(
          decoration: InputDecoration(
            hintText: 'Enter lawyer name or specialization...',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement search functionality
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Search functionality coming soon!'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B4513),
              foregroundColor: Colors.white,
            ),
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleArchive(ChatModel chat) async {
    try {
      await ChatService.toggleChatArchived(
        chatId: chat.id,
        archiveStatus: !chat.isArchived,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(chat.isArchived ? 'Chat unarchived' : 'Chat archived'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _toggleBlock(ChatModel chat) async {
    try {
      await ChatService.toggleUserBlock(
        chatId: chat.id,
        currentUserId: _currentUserId!,
        isLawyer: false,
        blockStatus: !chat.userHasBlocked,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            chat.userHasBlocked ? 'Lawyer unblocked' : 'Lawyer blocked',
          ),
          backgroundColor: chat.userHasBlocked ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showLawyerProfile(ChatModel chat) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(chat.lawyerName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: const Color(0xFF8B4513).withOpacity(0.1),
              backgroundImage: chat.lawyerProfileImage != null
                  ? NetworkImage(chat.lawyerProfileImage!)
                  : null,
              child: chat.lawyerProfileImage == null
                  ? const Icon(Icons.person, color: Color(0xFF8B4513), size: 40)
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              'Email: ${chat.lawyerEmail}',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              'Chat started: ${_formatDateTime(chat.createdAt)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToChat(chat);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B4513),
              foregroundColor: Colors.white,
            ),
            child: const Text('Start Chat'),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}
