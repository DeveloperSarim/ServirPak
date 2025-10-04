import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../services/consultation_service.dart';
import '../../constants/app_constants.dart';

class SystemDemoScreen extends StatefulWidget {
  const SystemDemoScreen({super.key});

  @override
  State<SystemDemoScreen> createState() => _SystemDemoScreenState();
}

class _SystemDemoScreenState extends State<SystemDemoScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _currentUserRole;
  String? _currentUserId;
  List<Map<String, dynamic>> _allConsultations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadAllConsultations();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final session = await AuthService.getSavedUserSession();
      if (session != null && session.isNotEmpty) {
        setState(() {
          _currentUserRole = session['userRole'];
          _currentUserId = session['userId'];
        });
      }
    } catch (e) {
      print('Error loading current user: $e');
    }
  }

  Future<void> _loadAllConsultations() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.consultationsCollection)
          .orderBy('createdAt', descending: true)
          .get();

      setState(() {
        _allConsultations = snapshot.docs.map((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return data;
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading consultations: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'System Demo - Booking Flow',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF8B4513),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllConsultations,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current User Info
            _buildCurrentUserCard(),
            const SizedBox(height: 20),

            // System Flow Explanation
            _buildSystemFlowCard(),
            const SizedBox(height: 20),

            // All Consultations
            _buildAllConsultationsCard(),
            const SizedBox(height: 20),

            // Test Actions
            _buildTestActionsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentUserCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Current User Info',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  _getRoleIcon(_currentUserRole),
                  color: _getRoleColor(_currentUserRole),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Role: ${_currentUserRole ?? 'Not logged in'}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'User ID: ${_currentUserId ?? 'N/A'}',
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
          ],
        ),
      ),
    );
  }

  Widget _buildSystemFlowCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'How the System Works',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            // Step 1
            _buildFlowStep(
              '1',
              'User Login',
              'User logs in with email/password',
              Icons.person,
              Colors.blue,
            ),
            const SizedBox(height: 12),

            // Step 2
            _buildFlowStep(
              '2',
              'Browse Lawyers',
              'User finds and selects a lawyer',
              Icons.search,
              Colors.green,
            ),
            const SizedBox(height: 12),

            // Step 3
            _buildFlowStep(
              '3',
              'Book Consultation',
              'User fills booking form and submits',
              Icons.event_note,
              Colors.orange,
            ),
            const SizedBox(height: 12),

            // Step 4
            _buildFlowStep(
              '4',
              'Lawyer Login',
              'Lawyer logs in with their credentials',
              Icons.account_balance,
              Colors.purple,
            ),
            const SizedBox(height: 12),

            // Step 5
            _buildFlowStep(
              '5',
              'See Notification',
              'Lawyer sees red badge with pending count',
              Icons.notifications_active,
              Colors.red,
            ),
            const SizedBox(height: 12),

            // Step 6
            _buildFlowStep(
              '6',
              'Manage Consultation',
              'Lawyer accepts/rejects consultation',
              Icons.check_circle,
              Colors.teal,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlowStep(
    String number,
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                description,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAllConsultationsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'All Consultations in Database',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_allConsultations.length} total',
                    style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_allConsultations.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(Icons.folder_open, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text(
                        'No consultations yet',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                      Text(
                        'Create a test consultation below',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._allConsultations.map(
                (consultation) => _buildConsultationItem(consultation),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsultationItem(Map<String, dynamic> consultation) {
    Color statusColor = _getStatusColor(consultation['status']);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  consultation['status'].toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                consultation['category'],
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                consultation['price'] == 0
                    ? 'Free'
                    : 'PKR ${consultation['price']}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            consultation['description'],
            style: const TextStyle(fontSize: 12, color: Colors.black87),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.person, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                'User: ${consultation['userId']}',
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              ),
              const SizedBox(width: 16),
              Icon(Icons.account_balance, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                'Lawyer: ${consultation['lawyerId']}',
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTestActionsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Test Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            // Create Test Consultation Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _createTestConsultation,
                icon: const Icon(Icons.add),
                label: const Text('Create Test Consultation'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B4513),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Login Instructions
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Login Instructions:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• User: user1@servipak.com / password123',
                    style: TextStyle(fontSize: 12),
                  ),
                  const Text(
                    '• Lawyer: lawyer1@servipak.com / password123',
                    style: TextStyle(fontSize: 12),
                  ),
                  const Text(
                    '• Admin: admin@servipak.com / password123',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createTestConsultation() async {
    try {
      String testUserId = 'test_user_${DateTime.now().millisecondsSinceEpoch}';
      String testLawyerId =
          'test_lawyer_${DateTime.now().millisecondsSinceEpoch}';

      await ConsultationService.createConsultation(
        userId: testUserId,
        lawyerId: testLawyerId,
        type: 'free',
        category: 'Family Law',
        city: 'Karachi',
        description: 'Test consultation created from demo screen',
        price: 0.0,
        scheduledAt: DateTime.now().add(const Duration(days: 1)),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Test consultation created successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Refresh consultations
      await _loadAllConsultations();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create test consultation: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  IconData _getRoleIcon(String? role) {
    switch (role) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'lawyer':
        return Icons.account_balance;
      case 'user':
        return Icons.person;
      default:
        return Icons.help;
    }
  }

  Color _getRoleColor(String? role) {
    switch (role) {
      case 'admin':
        return Colors.red;
      case 'lawyer':
        return Colors.purple;
      case 'user':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'completed':
        return Colors.blue;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
