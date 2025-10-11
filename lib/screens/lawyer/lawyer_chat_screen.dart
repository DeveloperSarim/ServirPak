import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../services/realtime_chat_service.dart';
import '../../models/chat_model.dart';
import '../../widgets/chat_bubble.dart';

class LawyerChatScreen extends StatefulWidget {
  final ChatModel chat;

  const LawyerChatScreen({super.key, required this.chat});

  @override
  State<LawyerChatScreen> createState() => _LawyerChatScreenState();
}

class _LawyerChatScreenState extends State<LawyerChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late Stream<List<ChatMessageModel>> _messagesStream;
  String? _currentLawyerId;
  bool _isTyping = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentLawyerId();
    _setupMessagesStream();
    _messageController.addListener(_onTextChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentLawyerId() async {
    try {
      final session = await AuthService.getSavedUserSession();
      _currentLawyerId = session['userId'] as String;
    } catch (e) {
      print('❌ Error loading lawyer ID: $e');
    }
  }

  void _onTextChanged() {
    setState(() {
      _hasText = _messageController.text.trim().isNotEmpty;
    });
  }

  void _setupMessagesStream() {
    _messagesStream = RealtimeChatService.listenToChatMessages(widget.chat.id);

    // Mark messages as read when screen opens - Real-time
    if (_currentLawyerId != null) {
      RealtimeChatService.markMessagesAsReadRealtime(
        chatId: widget.chat.id,
        currentUserId: _currentLawyerId!,
      );
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<void> _sendMessage() async {
    String message = _messageController.text.trim();
    if (message.isEmpty || _currentLawyerId == null) return;

    setState(() {
      _isTyping = true;
    });

    bool success = await RealtimeChatService.sendMessageRealtime(
      chatId: widget.chat.id,
      senderId: _currentLawyerId!,
      senderName: widget.chat.lawyerName,
      senderRole: 'lawyer',
      senderEmail: widget.chat.lawyerEmail,
      message: message,
    );

    if (success) {
      _messageController.clear();
      _scrollToBottom();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to send message'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() {
      _isTyping = false;
      _hasText = false;
    });
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type your message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: const BorderSide(color: Color(0xFF8B4513)),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              onChanged: (text) {
                // TODO: Implement typing indicator
              },
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: _isTyping || !_hasText
                ? Colors.grey.shade400
                : const Color(0xFF8B4513),
            child: _isTyping
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : IconButton(
                    onPressed: _hasText && !_isTyping ? _sendMessage : null,
                    icon: const Icon(Icons.send, color: Colors.white),
                  ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Color(0xFF8B4513)),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFF8B4513).withOpacity(0.1),
              backgroundImage: widget.chat.userProfileImage != null
                  ? NetworkImage(widget.chat.userProfileImage!)
                  : null,
              child: widget.chat.userProfileImage == null
                  ? const Icon(Icons.person, color: Color(0xFF8B4513), size: 20)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.chat.userName,
                    style: const TextStyle(
                      color: Color(0xFF8B4513),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    widget.chat.userEmail,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'mute') {
                // TODO: Implement mute functionality
              } else if (value == 'block') {
                _toggleBlock();
              } else if (value == 'archive') {
                _toggleArchive();
              } else if (value == 'info') {
                _showChatInfo();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'mute',
                child: Row(
                  children: [
                    Icon(Icons.notifications_off, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Mute Notifications'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'block',
                child: Row(
                  children: [
                    Icon(
                      widget.chat.lawyerHasBlocked
                          ? Icons.person_add
                          : Icons.person_remove,
                      color: Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.chat.lawyerHasBlocked
                          ? 'Unblock User'
                          : 'Block User',
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'archive',
                child: Row(
                  children: [
                    Icon(
                      widget.chat.isArchived ? Icons.unarchive : Icons.archive,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Text(widget.chat.isArchived ? 'Unarchive' : 'Archive'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'info',
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Chat Info'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (widget.chat.lawyerHasBlocked || widget.chat.userHasBlocked)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.red.shade50,
              child: Row(
                children: [
                  Icon(Icons.block, color: Colors.red.shade700, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.chat.lawyerHasBlocked
                          ? 'You have blocked this user'
                          : 'This user has blocked you',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: StreamBuilder<List<ChatMessageModel>>(
              stream: _messagesStream,
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
                          'Error loading messages',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          snapshot.error.toString(),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.red,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                List<ChatMessageModel> messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start the conversation with ${widget.chat.userName}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    ChatMessageModel message = messages[index];
                    return _buildMessageBubble(message, index, messages);
                  },
                );
              },
            ),
          ),
          if (widget.chat.canSendMessage) _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
    ChatMessageModel message,
    int index,
    List<ChatMessageModel> messages,
  ) {
    bool isFromCurrentUser = message.senderId == _currentLawyerId;
    bool showTimeStamp =
        index == 0 ||
        messages[index].sentAt
                .difference(messages[index - 1].sentAt)
                .inMinutes >=
            5;

    if (isFromCurrentUser) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (showTimeStamp) _buildTimeStamp(message.sentAt),
          ChatBubble(
            message: message.message,
            isFromCurrentUser: true,
            timestamp: message.displayTime,
            messageType: message.messageType,
            imageUrl: message.imageUrl,
            documentUrl: message.documentUrl,
            documentName: message.documentName,
            isRead: message.isRead,
          ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showTimeStamp) _buildTimeStamp(message.sentAt),
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFF8B4513).withOpacity(0.1),
                backgroundImage: widget.chat.userProfileImage != null
                    ? NetworkImage(widget.chat.userProfileImage!)
                    : null,
                child: widget.chat.userProfileImage == null
                    ? const Icon(
                        Icons.person,
                        color: Color(0xFF8B4513),
                        size: 16,
                      )
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChatBubble(
                  message: message.message,
                  isFromCurrentUser: false,
                  timestamp: message.displayTime,
                  messageType: message.messageType,
                  imageUrl: message.imageUrl,
                  documentUrl: message.documentUrl,
                  isRead: message.isRead,
                ),
              ),
            ],
          ),
        ],
      );
    }
  }

  Widget _buildTimeStamp(DateTime time) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        _formatDateTime(time),
        style: const TextStyle(fontSize: 12, color: Colors.grey),
        textAlign: TextAlign.center,
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inDays > 0) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (diff.inHours > 0) {
      return 'Today ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _toggleBlock() async {
    try {
      await ChatService.toggleUserBlock(
        chatId: widget.chat.id,
        currentUserId: _currentLawyerId!,
        isLawyer: true,
        blockStatus: !widget.chat.lawyerHasBlocked,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.chat.lawyerHasBlocked ? 'User unblocked' : 'User blocked',
          ),
          backgroundColor: widget.chat.lawyerHasBlocked
              ? Colors.green
              : Colors.red,
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

  Future<void> _toggleArchive() async {
    try {
      await ChatService.toggleChatArchived(
        chatId: widget.chat.id,
        archiveStatus: !widget.chat.isArchived,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.chat.isArchived ? 'Chat unarchived' : 'Chat archived',
          ),
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

  void _showChatInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Chat Info'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: const Color(0xFF8B4513).withOpacity(0.1),
              backgroundImage: widget.chat.userProfileImage != null
                  ? NetworkImage(widget.chat.userProfileImage!)
                  : null,
              child: widget.chat.userProfileImage == null
                  ? const Icon(Icons.person, color: Color(0xFF8B4513), size: 40)
                  : null,
            ),
            const SizedBox(height: 16),
            Text('Client: ${widget.chat.userName}'),
            Text('Email: ${widget.chat.userEmail}'),
            const SizedBox(height: 8),
            Text(
              'Chat started: ${_formatDateTime(widget.chat.createdAt)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            if (widget.chat.consultationIds.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Related consultations: ${widget.chat.consultationIds.length}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
