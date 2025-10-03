import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/app_constants.dart';
import '../../models/user_model.dart';
import '../../models/consultation_model.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../chat/lawyer_chat_screen.dart';

class LawyerMessagesScreen extends StatefulWidget {
  const LawyerMessagesScreen({super.key});

  @override
  State<LawyerMessagesScreen> createState() => _LawyerMessagesScreenState();
}

class _LawyerMessagesScreenState extends State<LawyerMessagesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<ConsultationModel> _consultations = [];
  List<UserModel> _clients = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMessagesData();
  }

  Future<void> _loadMessagesData() async {
    try {
      final session = await AuthService.getSavedUserSession();
      String lawyerId = session['userId'] as String;

      // Get consultations for this lawyer
      QuerySnapshot consultationsSnapshot = await _firestore
          .collection(AppConstants.consultationsCollection)
          .where('lawyerId', isEqualTo: lawyerId)
          .orderBy('createdAt', descending: true)
          .get();

      _consultations = consultationsSnapshot.docs
          .map((doc) => ConsultationModel.fromFirestore(doc))
          .toList();

      // Get unique client IDs
      Set<String> clientIds = _consultations.map((c) => c.userId).toSet();

      // Get client details
      for (String clientId in clientIds) {
        DocumentSnapshot userDoc = await _firestore
            .collection(AppConstants.usersCollection)
            .doc(clientId)
            .get();

        if (userDoc.exists) {
          _clients.add(UserModel.fromFirestore(userDoc));
        }
      }
    } catch (e) {
      print('Error loading messages data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
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
      ),
      body: _clients.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.message, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No messages yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  Text(
                    'Your client conversations will appear here',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _clients.length,
              itemBuilder: (context, index) {
                UserModel client = _clients[index];
                List<ConsultationModel> clientConsultations = _consultations
                    .where((c) => c.userId == client.id)
                    .toList();

                return _buildMessageCard(client, clientConsultations);
              },
            ),
    );
  }

  Widget _buildMessageCard(
    UserModel client,
    List<ConsultationModel> consultations,
  ) {
    ConsultationModel? latestConsultation = consultations.isNotEmpty
        ? consultations.first
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _openChat(client, consultations),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: const Color(0xFF8B4513),
                backgroundImage:
                    client.profileImage != null &&
                        client.profileImage!.isNotEmpty
                    ? NetworkImage(client.profileImage!)
                    : null,
                child:
                    client.profileImage == null || client.profileImage!.isEmpty
                    ? const Icon(Icons.person, color: Colors.white, size: 24)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      client.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      client.email,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    if (latestConsultation != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(
                                latestConsultation.status,
                              ).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              latestConsultation.status.toUpperCase(),
                              style: TextStyle(
                                color: _getStatusColor(
                                  latestConsultation.status,
                                ),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            latestConsultation.category,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (latestConsultation != null)
                    Text(
                      _getTimeAgo(latestConsultation.createdAt),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B4513).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.chat,
                      color: Color(0xFF8B4513),
                      size: 16,
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

  void _openChat(
    UserModel client,
    List<ConsultationModel> consultations,
  ) async {
    final session = await AuthService.getSavedUserSession();

    final lawyerId = session['userId'] as String;
    final conversationId = ChatService.generateConversationId(
      client.id,
      lawyerId,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LawyerChatScreen(
          userId: client.id,
          userName: client.name,
          conversationId: conversationId,
        ),
      ),
    );
  }

  Future<void> _updateConsultationStatus(
    String consultationId,
    String status,
  ) async {
    try {
      await _firestore
          .collection(AppConstants.consultationsCollection)
          .doc(consultationId)
          .update({'status': status});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Consultation $status successfully'),
          backgroundColor: Colors.green,
        ),
      );

      // Refresh data
      await _loadMessagesData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update consultation: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'accepted':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    Duration difference = DateTime.now().difference(dateTime);

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
}
