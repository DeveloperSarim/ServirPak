import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/app_constants.dart';
import '../../models/user_model.dart';
import '../../models/consultation_model.dart';
import '../../services/auth_service.dart';

class LawyerClientSearchScreen extends StatefulWidget {
  const LawyerClientSearchScreen({super.key});

  @override
  State<LawyerClientSearchScreen> createState() =>
      _LawyerClientSearchScreenState();
}

class _LawyerClientSearchScreenState extends State<LawyerClientSearchScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  List<UserModel> _clients = [];
  List<UserModel> _filteredClients = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClients();
    _searchController.addListener(_filterClients);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadClients() async {
    try {
      final session = await AuthService.getSavedUserSession();
      if (session != null) {
        String lawyerId = session['userId'] as String;

        // Get consultations for this lawyer
        QuerySnapshot consultationsSnapshot = await _firestore
            .collection(AppConstants.consultationsCollection)
            .where('lawyerId', isEqualTo: lawyerId)
            .get();

        Set<String> clientIds = consultationsSnapshot.docs
            .map((doc) => doc['userId'] as String)
            .toSet();

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

        _filteredClients = List.from(_clients);
      }
    } catch (e) {
      print('Error loading clients: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterClients() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      _filteredClients = _clients.where((client) {
        return client.name.toLowerCase().contains(query) ||
            client.email.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Client Search',
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search bar
                Container(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search clients by name or email...',
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFF8B4513),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF8B4513)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF8B4513),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),

                // Clients list
                Expanded(
                  child: _filteredClients.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'No clients found',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                'Your clients will appear here',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredClients.length,
                          itemBuilder: (context, index) {
                            UserModel client = _filteredClients[index];
                            return _buildClientCard(client);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildClientCard(UserModel client) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showClientDetails(client),
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
                    const SizedBox(height: 4),
                    Text(
                      client.phone ?? 'No phone number',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showClientDetails(UserModel client) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(client.name),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: Column(
            children: [
              // Client info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B4513).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
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
                              size: 30,
                            )
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
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            client.email,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            client.phone ?? 'No phone number',
                            style: const TextStyle(
                              fontSize: 14,
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

              // Client consultations
              Expanded(
                child: FutureBuilder<List<ConsultationModel>>(
                  future: _getClientConsultations(client.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    List<ConsultationModel> consultations = snapshot.data ?? [];

                    if (consultations.isEmpty) {
                      return const Center(
                        child: Text(
                          'No consultations yet',
                          style: TextStyle(color: Colors.grey),
                        ),
                      );
                    }

                    return ListView.builder(
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
                    );
                  },
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

  Future<List<ConsultationModel>> _getClientConsultations(
    String clientId,
  ) async {
    try {
      final session = await AuthService.getSavedUserSession();
      if (session != null) {
        String lawyerId = session['userId'] as String;

        QuerySnapshot consultationsSnapshot = await _firestore
            .collection(AppConstants.consultationsCollection)
            .where('lawyerId', isEqualTo: lawyerId)
            .where('userId', isEqualTo: clientId)
            .orderBy('createdAt', descending: true)
            .get();

        return consultationsSnapshot.docs
            .map((doc) => ConsultationModel.fromFirestore(doc))
            .toList();
      }
    } catch (e) {
      print('Error loading client consultations: $e');
    }
    return [];
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
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
}
