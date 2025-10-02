import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../constants/app_constants.dart';
import '../../models/user_model.dart';
import '../settings/settings_screen.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = AuthService.currentUser;
      if (user != null) {
        final userDoc = await _firestore
            .collection(AppConstants.usersCollection)
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          setState(() {
            _currentUser = UserModel.fromFirestore(userDoc);
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Profile',
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
            icon: const Icon(Icons.settings, color: Color(0xFF8B4513)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(userRole: 'user'),
                ),
              );
            },
          ),
        ],
      ),
      body: _currentUser == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildProfileHeader(),
                  const SizedBox(height: 20),
                  _buildProfileStats(),
                  const SizedBox(height: 20),
                  _buildProfileOptions(),
                  const SizedBox(height: 20),
                  _buildSeedDataSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8B4513), Color(0xFFA0522D)],
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: Text(
              _currentUser?.name.isNotEmpty == true
                  ? _currentUser!.name[0].toUpperCase()
                  : 'U',
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _currentUser?.name ?? 'User',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _currentUser?.email ?? '',
            style: const TextStyle(fontSize: 16, color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _currentUser?.role.toUpperCase() ?? 'USER',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection(AppConstants.consultationsCollection)
            .where('userId', isEqualTo: AuthService.currentUser?.uid ?? '')
            .snapshots(),
        builder: (context, snapshot) {
          int totalConsultations = 0;
          int completedConsultations = 0;
          int pendingConsultations = 0;

          if (snapshot.hasData) {
            totalConsultations = snapshot.data!.docs.length;
            for (var doc in snapshot.data!.docs) {
              final data = doc.data() as Map<String, dynamic>;
              final status = data['status'] as String? ?? '';
              if (status == 'completed') {
                completedConsultations++;
              } else if (status == 'pending') {
                pendingConsultations++;
              }
            }
          }

          return Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total',
                  totalConsultations.toString(),
                  Icons.chat,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Completed',
                  completedConsultations.toString(),
                  Icons.check_circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Pending',
                  pendingConsultations.toString(),
                  Icons.schedule,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF8B4513), size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF8B4513),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOptions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildOptionTile('Edit Profile', Icons.edit, () {
            _showEditProfileDialog();
          }),
          _buildOptionTile('My Consultations', Icons.chat, () {
            _showMyConsultations();
          }),
          _buildOptionTile('My Cases', Icons.folder, () {
            _showMyCases();
          }),
          _buildOptionTile('Payment History', Icons.payment, () {
            _showPaymentHistory();
          }),
          _buildOptionTile('Help & Support', Icons.help, () {
            _showHelpSupport();
          }),
          _buildOptionTile('About ServirPak', Icons.info, () {
            _showAboutDialog();
          }),
        ],
      ),
    );
  }

  Widget _buildOptionTile(String title, IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF8B4513)),
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSeedDataSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Developer Options',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF8B4513),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _seedDemoData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B4513),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('Seed Demo Data'),
            ),
            const SizedBox(height: 8),
            Text(
              'This will add sample lawyers, consultations, and chat data to Firebase for testing purposes.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  // Profile Option Handlers
  void _showEditProfileDialog() {
    final nameController = TextEditingController(
      text: _currentUser?.name ?? '',
    );
    final phoneController = TextEditingController(
      text: _currentUser?.phone ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _updateProfile(nameController.text, phoneController.text);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _updateProfile(String name, String phone) async {
    try {
      final user = AuthService.currentUser;
      if (user != null) {
        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(user.uid)
            .update({
              'name': name,
              'phone': phone,
              'updatedAt': Timestamp.now(),
            });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        _loadUserData(); // Reload user data
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showMyConsultations() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('My Consultations'),
        content: StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection(AppConstants.consultationsCollection)
              .where('userId', isEqualTo: AuthService.currentUser?.uid ?? '')
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.data!.docs.isEmpty) {
              return const Text('No consultations found.');
            }

            return SizedBox(
              height: 300,
              child: ListView.builder(
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final doc = snapshot.data!.docs[index];
                  final data = doc.data() as Map<String, dynamic>;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(data['type'] ?? 'Consultation'),
                      subtitle: Text(data['description'] ?? ''),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(
                            data['status'] ?? '',
                          ).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          (data['status'] ?? '').toUpperCase(),
                          style: TextStyle(
                            color: _getStatusColor(data['status'] ?? ''),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
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

  void _showMyCases() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('My Cases'),
        content: const Text(
          'Your case history and ongoing cases will be displayed here.',
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

  void _showPaymentHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment History'),
        content: const Text(
          'Your payment history and transaction details will be displayed here.',
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

  void _showHelpSupport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.phone),
              title: const Text('Call Support'),
              subtitle: const Text('+92-300-911-911'),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Calling support...'),
                    backgroundColor: Colors.blue,
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('Email Support'),
              subtitle: const Text('support@servirpak.com'),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Opening email...'),
                    backgroundColor: Colors.blue,
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat),
              title: const Text('Live Chat'),
              subtitle: const Text('Chat with our support team'),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Opening live chat...'),
                    backgroundColor: Colors.blue,
                  ),
                );
              },
            ),
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
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About ServirPak'),
        content: const Text(
          'ServirPak is a comprehensive legal services platform that connects users with qualified lawyers and legal consultants across Pakistan.\n\nVersion: 1.0.0\nBuild: 2024',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _seedDemoData() async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Seeding demo data...'),
            ],
          ),
        ),
      );

      // Seed demo lawyers
      await _seedDemoLawyers();

      // Seed demo consultations
      await _seedDemoConsultations();

      // Seed demo chat messages
      await _seedDemoChats();

      // Close loading dialog
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Demo data seeded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error seeding data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _seedDemoLawyers() async {
    final lawyers = [
      {
        'name': 'Ahmed Ali Khan',
        'email': 'ahmed.khan@servirpak.com',
        'phone': '+92-300-1234567',
        'specialization': 'Criminal Law',
        'experience': '8 years',
        'rating': 4.8,
        'city': 'Lahore',
        'status': AppConstants.verifiedStatus,
        'bio': 'Experienced criminal defense lawyer with 8+ years of practice.',
        'createdAt': Timestamp.now(),
      },
      {
        'name': 'Fatima Sheikh',
        'email': 'fatima.sheikh@servirpak.com',
        'phone': '+92-300-2345678',
        'specialization': 'Family Law',
        'experience': '6 years',
        'rating': 4.9,
        'city': 'Karachi',
        'status': AppConstants.verifiedStatus,
        'bio': 'Specialized in family law and divorce cases.',
        'createdAt': Timestamp.now(),
      },
      {
        'name': 'Muhammad Hassan',
        'email': 'm.hassan@servirpak.com',
        'phone': '+92-300-3456789',
        'specialization': 'Property Law',
        'experience': '10 years',
        'rating': 4.7,
        'city': 'Islamabad',
        'status': AppConstants.verifiedStatus,
        'bio': 'Property law expert with extensive experience in real estate.',
        'createdAt': Timestamp.now(),
      },
    ];

    for (var lawyer in lawyers) {
      await _firestore.collection(AppConstants.lawyersCollection).add(lawyer);
    }
  }

  Future<void> _seedDemoConsultations() async {
    final consultations = [
      {
        'userId': AuthService.currentUser?.uid ?? '',
        'lawyerId': 'demo_lawyer_1',
        'type': 'Criminal Defense',
        'status': AppConstants.pendingStatus,
        'description': 'Need legal advice for a criminal case',
        'createdAt': Timestamp.now(),
      },
      {
        'userId': AuthService.currentUser?.uid ?? '',
        'lawyerId': 'demo_lawyer_2',
        'type': 'Family Law',
        'status': AppConstants.confirmedStatus,
        'description': 'Divorce consultation needed',
        'createdAt': Timestamp.now(),
      },
    ];

    for (var consultation in consultations) {
      await _firestore
          .collection(AppConstants.consultationsCollection)
          .add(consultation);
    }
  }

  Future<void> _seedDemoChats() async {
    final chats = [
      {
        'conversationId': 'demo_conversation_1',
        'senderId': AuthService.currentUser?.uid ?? '',
        'receiverId': 'demo_lawyer_1',
        'message': 'Hello, I need legal advice for my case.',
        'timestamp': Timestamp.now(),
        'participants': [AuthService.currentUser?.uid ?? '', 'demo_lawyer_1'],
      },
      {
        'conversationId': 'demo_conversation_1',
        'senderId': 'demo_lawyer_1',
        'receiverId': AuthService.currentUser?.uid ?? '',
        'message':
            'Hello! I would be happy to help you. Can you tell me more about your case?',
        'timestamp': Timestamp.now(),
        'participants': [AuthService.currentUser?.uid ?? '', 'demo_lawyer_1'],
      },
    ];

    for (var chat in chats) {
      await _firestore
          .collection(AppConstants.chatMessagesCollection)
          .add(chat);
    }
  }
}
