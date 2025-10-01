import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String id;
  final String consultationId;
  final String senderId;
  final String senderName;
  final String senderRole; // 'user', 'lawyer', 'admin'
  final String message;
  final String messageType; // 'text', 'image', 'document', 'audio'
  final String? fileUrl;
  final bool isRead;
  final DateTime createdAt;

  ChatModel({
    required this.id,
    required this.consultationId,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.message,
    required this.messageType,
    this.fileUrl,
    required this.isRead,
    required this.createdAt,
  });

  factory ChatModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return ChatModel(
      id: doc.id,
      consultationId: data['consultationId'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      senderRole: data['senderRole'] ?? 'user',
      message: data['message'] ?? '',
      messageType: data['messageType'] ?? 'text',
      fileUrl: data['fileUrl'],
      isRead: data['isRead'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'consultationId': consultationId,
      'senderId': senderId,
      'senderName': senderName,
      'senderRole': senderRole,
      'message': message,
      'messageType': messageType,
      'fileUrl': fileUrl,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  ChatModel copyWith({
    String? id,
    String? consultationId,
    String? senderId,
    String? senderName,
    String? senderRole,
    String? message,
    String? messageType,
    String? fileUrl,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return ChatModel(
      id: id ?? this.id,
      consultationId: consultationId ?? this.consultationId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderRole: senderRole ?? this.senderRole,
      message: message ?? this.message,
      messageType: messageType ?? this.messageType,
      fileUrl: fileUrl ?? this.fileUrl,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isText => messageType == 'text';
  bool get isImage => messageType == 'image';
  bool get isDocument => messageType == 'document';
  bool get isAudio => messageType == 'audio';
  bool get isFromUser => senderRole == 'user';
  bool get isFromLawyer => senderRole == 'lawyer';
  bool get isFromAdmin => senderRole == 'admin';
}
