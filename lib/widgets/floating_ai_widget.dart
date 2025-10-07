import 'package:flutter/material.dart';
import '../services/ai_service.dart';

class FloatingAIWidget extends StatefulWidget {
  const FloatingAIWidget({super.key});

  @override
  State<FloatingAIWidget> createState() => _FloatingAIWidgetState();
}

class _FloatingAIWidgetState extends State<FloatingAIWidget>
    with TickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _initializeAI();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeAI() async {
    try {
      await AIService.initialize();
    } catch (e) {
      // Handle initialization error silently
    }
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
    });

    if (_isExpanded) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Floating Action Button
        Positioned(
          bottom: 20,
          right: 20,
          child: GestureDetector(
            onTap: _toggleExpansion,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFF8B4513),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: AnimatedBuilder(
                animation: _rotationAnimation,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _rotationAnimation.value * 3.14159,
                    child: Icon(
                      _isExpanded ? Icons.close : Icons.psychology,
                      color: Colors.white,
                      size: 24,
                    ),
                  );
                },
              ),
            ),
          ),
        ),

        // Expanded AI Chat Widget
        if (_isExpanded)
          Positioned(
            bottom: 90,
            right: 20,
            child: AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.85,
                    height: MediaQuery.of(context).size.height * 0.6,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: const AIChatWidget(),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class AIChatWidget extends StatefulWidget {
  const AIChatWidget({super.key});

  @override
  State<AIChatWidget> createState() => _AIChatWidgetState();
}

class _AIChatWidgetState extends State<AIChatWidget> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isInitialized = false;
  static List<ChatMessage> _persistentMessages =
      []; // Static to persist across widget rebuilds

  @override
  void initState() {
    super.initState();
    _initializeAI();
    _loadPersistentMessages();
  }

  void _loadPersistentMessages() {
    setState(() {
      _messages.clear();
      _messages.addAll(_persistentMessages);
    });
  }

  Future<void> _initializeAI() async {
    try {
      await AIService.initialize();
      setState(() {
        _isInitialized = true;
      });

      // Add welcome message only if no messages exist
      if (_persistentMessages.isEmpty) {
        _addMessage(
          'Welcome! I\'m your AI legal assistant. I can help you with questions about Pakistani law and the Constitution. How can I assist you today?',
          isUser: false,
        );
      }
    } catch (e) {
      setState(() {
        _isInitialized = false;
      });
      _addMessage(
        'Sorry, I\'m having trouble connecting to the AI service. Please try again.',
        isUser: false,
      );
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addMessage(String text, {required bool isUser}) {
    final message = ChatMessage(
      text: text,
      isUser: isUser,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(message);
      _persistentMessages.add(message); // Add to persistent list

      // Limit persistent messages to last 50 to avoid memory issues
      if (_persistentMessages.length > 50) {
        _persistentMessages.removeAt(0);
      }
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isLoading || !_isInitialized) return;

    _messageController.clear();
    _addMessage(text, isUser: true);

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await AIService.getLegalAdvice(text);
      _addMessage(response, isUser: false);
    } catch (e) {
      _addMessage(
        'Sorry, I encountered an error while processing your request. Please try again.',
        isUser: false,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _clearChat() {
    setState(() {
      _messages.clear();
      _persistentMessages.clear(); // Clear persistent list too
    });
    _addMessage(
      'Chat cleared. How can I help you with Pakistani law today?',
      isUser: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Color(0xFF8B4513),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.psychology,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'AI Legal Assistant',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (_isInitialized)
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Online',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (_persistentMessages.length > 1) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_persistentMessages.length - 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Offline',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _clearChat,
                icon: const Icon(
                  Icons.clear_all,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
        ),

        // Messages
        Expanded(
          child: _messages.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 48,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Start a conversation with AI',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    return _buildMessageBubble(message);
                  },
                ),
        ),

        // Input area
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  enabled: _isInitialized && !_isLoading,
                  decoration: InputDecoration(
                    hintText: _isInitialized
                        ? 'Ask about Pakistani law...'
                        : 'Initializing AI...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  maxLines: null,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: _isInitialized && !_isLoading
                      ? const Color(0xFF8B4513)
                      : Colors.grey,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: IconButton(
                  onPressed: _isInitialized && !_isLoading
                      ? _sendMessage
                      : null,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Icon(Icons.send, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF8B4513).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.psychology,
                color: Color(0xFF8B4513),
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isUser
                    ? const Color(0xFF8B4513)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20).copyWith(
                  bottomLeft: message.isUser
                      ? const Radius.circular(20)
                      : const Radius.circular(4),
                  bottomRight: message.isUser
                      ? const Radius.circular(4)
                      : const Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.isUser)
                    Text(
                      message.text,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    )
                  else
                    _buildFormattedText(message.text),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      color: message.isUser
                          ? Colors.white.withOpacity(0.7)
                          : Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF8B4513).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.person,
                color: Color(0xFF8B4513),
                size: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  Widget _buildFormattedText(String text) {
    return RichText(text: _parseMarkdown(text));
  }

  TextSpan _parseMarkdown(String text) {
    final List<TextSpan> spans = [];
    final RegExp boldRegex = RegExp(r'\*\*(.*?)\*\*');
    final RegExp italicRegex = RegExp(r'\*(.*?)\*');
    final RegExp bulletRegex = RegExp(r'^•\s*(.*)$', multiLine: true);

    int currentIndex = 0;

    // Split by lines to handle bullet points
    final lines = text.split('\n');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      if (line.trim().isEmpty) {
        spans.add(const TextSpan(text: '\n'));
        continue;
      }

      // Check if it's a bullet point
      if (bulletRegex.hasMatch(line)) {
        final match = bulletRegex.firstMatch(line);
        if (match != null) {
          spans.add(
            TextSpan(
              text: '• ',
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
          spans.add(_parseInlineMarkdown(match.group(1) ?? ''));
          if (i < lines.length - 1) {
            spans.add(const TextSpan(text: '\n'));
          }
          continue;
        }
      }

      // Regular line with inline formatting
      spans.add(_parseInlineMarkdown(line));
      if (i < lines.length - 1) {
        spans.add(const TextSpan(text: '\n'));
      }
    }

    return TextSpan(children: spans);
  }

  TextSpan _parseInlineMarkdown(String text) {
    final List<TextSpan> spans = [];
    int currentIndex = 0;

    // Process text character by character to handle bold and italic
    while (currentIndex < text.length) {
      // Check for bold pattern **text**
      if (currentIndex + 1 < text.length &&
          text[currentIndex] == '*' &&
          text[currentIndex + 1] == '*') {
        // Find the closing **
        int endIndex = currentIndex + 2;
        while (endIndex + 1 < text.length) {
          if (text[endIndex] == '*' && text[endIndex + 1] == '*') {
            // Found bold text
            final boldText = text.substring(currentIndex + 2, endIndex);
            spans.add(
              TextSpan(
                text: boldText,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
            currentIndex = endIndex + 2;
            break;
          }
          endIndex++;
        }
        if (endIndex + 1 >= text.length) {
          // No closing ** found, treat as regular text
          spans.add(
            TextSpan(
              text: text.substring(currentIndex, currentIndex + 2),
              style: const TextStyle(color: Colors.black87, fontSize: 14),
            ),
          );
          currentIndex += 2;
        }
      }
      // Check for italic pattern *text*
      else if (text[currentIndex] == '*' &&
          (currentIndex == 0 || text[currentIndex - 1] != '*') &&
          (currentIndex + 1 >= text.length || text[currentIndex + 1] != '*')) {
        // Find the closing *
        int endIndex = currentIndex + 1;
        while (endIndex < text.length) {
          if (text[endIndex] == '*' &&
              (endIndex + 1 >= text.length || text[endIndex + 1] != '*')) {
            // Found italic text
            final italicText = text.substring(currentIndex + 1, endIndex);
            spans.add(
              TextSpan(
                text: italicText,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
            );
            currentIndex = endIndex + 1;
            break;
          }
          endIndex++;
        }
        if (endIndex >= text.length) {
          // No closing * found, treat as regular text
          spans.add(
            TextSpan(
              text: text[currentIndex],
              style: const TextStyle(color: Colors.black87, fontSize: 14),
            ),
          );
          currentIndex++;
        }
      }
      // Regular character
      else {
        spans.add(
          TextSpan(
            text: text[currentIndex],
            style: const TextStyle(color: Colors.black87, fontSize: 14),
          ),
        );
        currentIndex++;
      }
    }

    return TextSpan(children: spans);
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}
