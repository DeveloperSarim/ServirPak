import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../constants/app_constants.dart';

class DebugConsultationsScreen extends StatefulWidget {
  const DebugConsultationsScreen({super.key});

  @override
  State<DebugConsultationsScreen> createState() =>
      _DebugConsultationsScreenState();
}

class _DebugConsultationsScreenState extends State<DebugConsultationsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _currentUserId;
  String? _currentUserRole;
  List<Map<String, dynamic>> _allConsultations = [];
  List<Map<String, dynamic>> _lawyerConsultations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Get current user session
      final session = await AuthService.getSavedUserSession();
      setState(() {
        _currentUserId = session['userId'];
        _currentUserRole = session['userRole'];
      });

      print('🔍 Debug: Current User ID: $_currentUserId');
      print('🔍 Debug: Current User Role: $_currentUserRole');

      // Load all consultations
      QuerySnapshot allSnapshot = await _firestore
          .collection(AppConstants.consultationsCollection)
          .orderBy('createdAt', descending: true)
          .get();

      setState(() {
        _allConsultations = allSnapshot.docs.map((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return data;
        }).toList();
      });

      print(
        '🔍 Debug: Total consultations in database: ${_allConsultations.length}',
      );

      // Load consultations for current lawyer
      if (_currentUserId != null) {
        QuerySnapshot lawyerSnapshot = await _firestore
            .collection(AppConstants.consultationsCollection)
            .where('lawyerId', isEqualTo: _currentUserId)
            .orderBy('createdAt', descending: true)
            .get();

        setState(() {
          _lawyerConsultations = lawyerSnapshot.docs.map((doc) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            return data;
          }).toList();
        });

        print(
          '🔍 Debug: Consultations for current lawyer: ${_lawyerConsultations.length}',
        );
      }

      setState(() => _isLoading = false);
    } catch (e) {
      print('❌ Debug: Error loading data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Debug Consultations',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF8B4513),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current User Info
                  _buildUserInfoCard(),
                  const SizedBox(height: 20),

                  // All Consultations
                  _buildAllConsultationsCard(),
                  const SizedBox(height: 20),

                  // Lawyer Consultations
                  _buildLawyerConsultationsCard(),
                  const SizedBox(height: 20),

                  // Test Actions
                  _buildTestActionsCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildUserInfoCard() {
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

            if (_allConsultations.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(Icons.folder_open, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text(
                        'No consultations in database',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
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

  Widget _buildLawyerConsultationsCard() {
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
                  'Consultations for Current Lawyer',
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
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_lawyerConsultations.length} found',
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_lawyerConsultations.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(Icons.search_off, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text(
                        'No consultations found for this lawyer',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                      Text(
                        'Check if lawyerId matches in consultations',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._lawyerConsultations.map(
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
                consultation['category'] ?? 'Unknown Category',
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
            consultation['description'] ?? 'No description',
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
                'User: ${consultation['userId'] ?? 'Unknown'}',
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              ),
              const SizedBox(width: 16),
              Icon(Icons.account_balance, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                'Lawyer: ${consultation['lawyerId'] ?? 'Unknown'}',
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Created: ${consultation['createdAt']?.toString() ?? 'Unknown'}',
            style: TextStyle(fontSize: 10, color: Colors.grey[500]),
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

            // Instructions
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Debug Instructions:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '1. Check if lawyerId in consultations matches your user ID',
                    style: TextStyle(fontSize: 12),
                  ),
                  Text(
                    '2. Verify consultation data is being created correctly',
                    style: TextStyle(fontSize: 12),
                  ),
                  Text(
                    '3. Check if lawyer role is set correctly',
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
      if (_currentUserId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login first'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Create a test consultation for the current lawyer
      await _firestore.collection(AppConstants.consultationsCollection).add({
        'userId': 'test_user_${DateTime.now().millisecondsSinceEpoch}',
        'lawyerId': _currentUserId,
        'type': 'free',
        'category': 'Test Law',
        'city': 'Karachi',
        'description': 'Test consultation created from debug screen',
        'price': 0.0,
        'status': 'pending',
        'scheduledAt': DateTime.now().add(const Duration(days: 1)),
        'createdAt': DateTime.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Test consultation created successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Refresh data
      await _loadData();
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
