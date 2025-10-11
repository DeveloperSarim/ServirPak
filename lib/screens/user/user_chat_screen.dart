import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/realtime_chat_service.dart';
import '../../models/chat_model.dart';
import '../../widgets/chat_bubble.dart';

class UserChatScreen extends StatefulWidget {
  final ChatModel chat;

  const UserChatScreen({super.key, required this.chat});

  @override
  State<UserChatScreen> createState() => _UserChatScreenState();
}

class _UserChatScreenState extends State<UserChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late Stream<List<ChatMessageModel>> _messagesStream;
  String? _currentUserId;
  bool _isTyping = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
    _setupMessagesStream();
    _messageController.addListener(_onTextChanged);
    // Auto-scroll to bottom when chat opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        _scrollToBottomImmediate();
      });
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUserId() async {
    try {
      final session = await AuthService.getSavedUserSession();
      _currentUserId = session['userId'] as String;
    } catch (e) {
      print('❌ Error loading user ID: $e');
    }
  }

  void _onTextChanged() {
    setState(() {
      _hasText = _messageController.text.trim().isNotEmpty;
    });
  }

  void _setupMessagesStream() {
    _messagesStream = RealtimeChatService.listenToChatMessages(widget.chat.id);

    if (_currentUserId != null) {
      RealtimeChatService.markMessagesAsReadRealtime(
        chatId: widget.chat.id,
        currentUserId: _currentUserId!,
      );
    }
  }

  void _scrollToBottomImmediate() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  Future<void> _sendMessage() async {
    String message = _messageController.text.trim();
    if (message.isEmpty || _currentUserId == null) return;

    setState(() {
      _isTyping = true;
    });

    bool success = await RealtimeChatService.sendMessageRealtime(
      chatId: widget.chat.id,
      senderId: _currentUserId!,
      senderName: widget.chat.userName,
      senderRole: 'user',
      senderEmail: widget.chat.userEmail,
      message: message,
    );

    if (success) {
      _messageController.clear();
      _scrollToBottomImmediate();
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
          icon: const Icon(Icons.arrow_back, color: Colors.black),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFF8B4513).withOpacity(0.1),
              child:
                  widget.chat.lawyerProfileImage != null &&
                      widget.chat.lawyerProfileImage!.isNotEmpty
                  ? ClipOval(
                      child: Image.network(
                        widget.chat.lawyerProfileImage!,
                        width: 36,
                        height: 36,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Icon(
                            Icons.person,
                            color: Color(0xFF8B4513),
                            size: 20,
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          print(
                            '❌ Error loading lawyer profile image in app bar: $error',
                          );
                          print(
                            '❌ Image URL: ${widget.chat.lawyerProfileImage}',
                          );
                          return const Icon(
                            Icons.person,
                            color: Color(0xFF8B4513),
                            size: 20,
                          );
                        },
                      ),
                    )
                  : const Icon(
                      Icons.person,
                      color: Color(0xFF8B4513),
                      size: 20,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.chat.lawyerName,
                    style: const TextStyle(
                      color: Color(0xFF8B4513),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    widget.chat.lawyerEmail,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
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
                          ? 'This lawyer has blocked you'
                          : 'You have blocked this lawyer',
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
                          'Start the conversation with ${widget.chat.lawyerName}',
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

                // Auto-scroll to bottom when new messages arrive
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (messages.isNotEmpty) {
                    Future.delayed(const Duration(milliseconds: 200), () {
                      _scrollToBottomImmediate();
                    });
                  }
                });

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
    bool isFromCurrentUser = message.senderId == _currentUserId;
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
                child:
                    widget.chat.lawyerProfileImage != null &&
                        widget.chat.lawyerProfileImage!.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          widget.chat.lawyerProfileImage!,
                          width: 32,
                          height: 32,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Icon(
                              Icons.person,
                              color: Color(0xFF8B4513),
                              size: 16,
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            print(
                              '❌ Error loading lawyer profile image: $error',
                            );
                            print(
                              '❌ Image URL: ${widget.chat.lawyerProfileImage}',
                            );
                            return const Icon(
                              Icons.person,
                              color: Color(0xFF8B4513),
                              size: 16,
                            );
                          },
                        ),
                      )
                    : const Icon(
                        Icons.person,
                        color: Color(0xFF8B4513),
                        size: 16,
                      ),
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
                  documentName: message.documentName,
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
}
