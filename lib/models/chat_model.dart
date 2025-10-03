import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String id;
  final String lawyerId;
  final String lawyerName;
  final String lawyerEmail;
  final String? lawyerProfileImage;
  final String userId;
  final String userName;
  final String userEmail;
  final String? userProfileImage;
  final String? lastMessage;
  final String? lastMessageSenderId;
  final DateTime? lastMessageTime;
  final bool isArchived;
  final bool lawyerHasBlocked;
  final bool userHasBlocked;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<String> consultationIds; // Related consultations

  ChatModel({
    required this.id,
    required this.lawyerId,
    required this.lawyerName,
    required this.lawyerEmail,
    this.lawyerProfileImage,
    required this.userId,
    required this.userName,
    required this.userEmail,
    this.userProfileImage,
    this.lastMessage,
    this.lastMessageSenderId,
    this.lastMessageTime,
    this.isArchived = false,
    this.lawyerHasBlocked = false,
    this.userHasBlocked = false,
    required this.createdAt,
    this.updatedAt,
    this.consultationIds = const [],
  });

  factory ChatModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return ChatModel(
      id: doc.id,
      lawyerId: data['lawyerId'] ?? '',
      lawyerName: data['lawyerName'] ?? '',
      lawyerEmail: data['lawyerEmail'] ?? '',
      lawyerProfileImage: data['lawyerProfileImage'],
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userEmail: data['userEmail'] ?? '',
      userProfileImage: data['userProfileImage'],
      lastMessage: data['lastMessage'],
      lastMessageSenderId: data['lastMessageSenderId'],
      lastMessageTime: data['lastMessageTime'] != null
          ? (data['lastMessageTime'] as Timestamp).toDate()
          : null,
      isArchived: data['isArchived'] ?? false,
      lawyerHasBlocked: data['lawyerHasBlocked'] ?? false,
      userHasBlocked: data['userHasBlocked'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      consultationIds: List<String>.from(data['consultationIds'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'lawyerId': lawyerId,
      'lawyerName': lawyerName,
      'lawyerEmail': lawyerEmail,
      'lawyerProfileImage': lawyerProfileImage,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'userProfileImage': userProfileImage,
      'lastMessage': lastMessage,
      'lastMessageSenderId': lastMessageSenderId,
      'lastMessageTime': lastMessageTime != null
          ? Timestamp.fromDate(lastMessageTime!)
          : null,
      'isArchived': isArchived,
      'lawyerHasBlocked': lawyerHasBlocked,
      'userHasBlocked': userHasBlocked,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'consultationIds': consultationIds,
    };
  }

  ChatModel copyWith({
    String? id,
    String? lawyerId,
    String? lawyerName,
    String? lawyerEmail,
    String? lawyerProfileImage,
    String? userId,
    String? userName,
    String? userEmail,
    String? userProfileImage,
    String? lastMessage,
    String? lastMessageSenderId,
    DateTime? lastMessageTime,
    bool? isArchived,
    bool? lawyerHasBlocked,
    bool? userHasBlocked,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? consultationIds,
  }) {
    return ChatModel(
      id: id ?? this.id,
      lawyerId: lawyerId ?? this.lawyerId,
      lawyerName: lawyerName ?? this.lawyerName,
      lawyerEmail: lawyerEmail ?? this.lawyerEmail,
      lawyerProfileImage: lawyerProfileImage ?? this.lawyerProfileImage,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      userProfileImage: userProfileImage ?? this.userProfileImage,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      isArchived: isArchived ?? this.isArchived,
      lawyerHasBlocked: lawyerHasBlocked ?? this.lawyerHasBlocked,
      userHasBlocked: userHasBlocked ?? this.userHasBlocked,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      consultationIds: consultationIds ?? this.consultationIds,
    );
  }

  String get otherPersonName =>
      lawyerHasBlocked || userHasBlocked ? 'User' : userName;
  String? get otherPersonImage =>
      lawyerHasBlocked || userHasBlocked ? null : userProfileImage;
  bool get canSendMessage => !lawyerHasBlocked && !userHasBlocked;
}

class ChatMessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String senderName;
  final String senderRole; // 'lawyer' or 'user'
  final String senderEmail;
  final String message;
  final String messageType; // 'text', 'image', 'document'
  final String? imageUrl;
  final String? documentUrl;
  final String? documentName;
  final bool isRead;
  final DateTime sentAt;
  final DateTime? readAt;
  final bool isDeleted;
  final List<String> readBy; // List of userIds who have read this message

  ChatMessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.senderEmail,
    required this.message,
    this.messageType = 'text',
    this.imageUrl,
    this.documentUrl,
    this.documentName,
    this.isRead = false,
    required this.sentAt,
    this.readAt,
    this.isDeleted = false,
    this.readBy = const [],
  });

  factory ChatMessageModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return ChatMessageModel(
      id: doc.id,
      chatId: data['chatId'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      senderRole: data['senderRole'] ?? '',
      senderEmail: data['senderEmail'] ?? '',
      message: data['message'] ?? '',
      messageType: data['messageType'] ?? 'text',
      imageUrl: data['imageUrl'],
      documentUrl: data['documentUrl'],
      documentName: data['documentName'],
      isRead: data['isRead'] ?? false,
      sentAt: (data['sentAt'] as Timestamp).toDate(),
      readAt: data['readAt'] != null
          ? (data['readAt'] as Timestamp).toDate()
          : null,
      isDeleted: data['isDeleted'] ?? false,
      readBy: List<String>.from(data['readBy'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'senderRole': senderRole,
      'senderEmail': senderEmail,
      'message': message,
      'messageType': messageType,
      'imageUrl': imageUrl,
      'documentUrl': documentUrl,
      'documentName': documentName,
      'isRead': isRead,
      'sentAt': Timestamp.fromDate(sentAt),
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
      'isDeleted': isDeleted,
      'readBy': readBy,
    };
  }

  ChatMessageModel copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? senderName,
    String? senderRole,
    String? senderEmail,
    String? message,
    String? messageType,
    String? imageUrl,
    String? documentUrl,
    String? documentName,
    bool? isRead,
    DateTime? sentAt,
    DateTime? readAt,
    bool? isDeleted,
    List<String>? readBy,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderRole: senderRole ?? this.senderRole,
      senderEmail: senderEmail ?? this.senderEmail,
      message: message ?? this.message,
      messageType: messageType ?? this.messageType,
      imageUrl: imageUrl ?? this.imageUrl,
      documentUrl: documentUrl ?? this.documentUrl,
      documentName: documentName ?? this.documentName,
      isRead: isRead ?? this.isRead,
      sentAt: sentAt ?? this.sentAt,
      readAt: readAt ?? this.readAt,
      isDeleted: isDeleted ?? this.isDeleted,
      readBy: readBy ?? this.readBy,
    );
  }

  bool get isFromCurrentUser => false; // This will be set dynamically
  String get displayTime => _formatTime(sentAt);

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
