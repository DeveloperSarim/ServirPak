import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/app_constants.dart';
import '../../models/user_model.dart';
import '../../models/consultation_model.dart';
import '../../services/auth_service.dart';

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
      if (session != null) {
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
                    client.profileImage == null ||
                        client.profileImage!.isEmpty
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

  void _openChat(UserModel client, List<ConsultationModel> consultations) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Chat with ${client.name}'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: Column(
            children: [
              // Client info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B4513).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFF8B4513),
                      backgroundImage:
                          client.profileImage != null &&
                              client.profileImage!.isNotEmpty
                          ? NetworkImage(client.profileImage!)
                          : null,
                      child:
                          client.profileImage == null ||
                              client.profileImage!.isEmpty
                          ? const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 20,
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            client.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            client.email,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Consultations list
              Expanded(
                child: consultations.isEmpty
                    ? const Center(
                        child: Text(
                          'No consultations yet',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: consultations.length,
                        itemBuilder: (context, index) {
                          ConsultationModel consultation = consultations[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(consultation.category),
                              subtitle: Text(consultation.description),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(
                                    consultation.status,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  consultation.status.toUpperCase(),
                                  style: TextStyle(
                                    color: _getStatusColor(consultation.status),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                _showConsultationDetails(consultation);
                              },
                            ),
                          );
                        },
                      ),
              ),

              // Message input
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send, color: Color(0xFF8B4513)),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Message functionality coming soon!'),
                            backgroundColor: Color(0xFF8B4513),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
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

  void _showConsultationDetails(ConsultationModel consultation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(consultation.category),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Description: ${consultation.description}'),
            const SizedBox(height: 8),
            Text('Type: ${consultation.type}'),
            const SizedBox(height: 8),
            Text('Status: ${consultation.status}'),
            const SizedBox(height: 8),
            Text('Price: PKR ${consultation.price.toStringAsFixed(0)}'),
            const SizedBox(height: 8),
            Text('Scheduled: ${consultation.scheduledAt.toString()}'),
          ],
        ),
        actions: [
          if (consultation.status == AppConstants.pendingStatus) ...[
            TextButton(
              onPressed: () {
                _updateConsultationStatus(consultation.id, 'accepted');
                Navigator.pop(context);
              },
              child: const Text('Accept'),
            ),
            TextButton(
              onPressed: () {
                _updateConsultationStatus(consultation.id, 'rejected');
                Navigator.pop(context);
              },
              child: const Text('Reject'),
            ),
          ],
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
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
