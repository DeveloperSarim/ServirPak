import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/consultation_model.dart';
import '../../models/user_model.dart';
import '../../services/consultation_service.dart';
import '../../services/auth_service.dart';
import '../../constants/app_constants.dart';

class LawyerConsultationsScreen extends StatefulWidget {
  const LawyerConsultationsScreen({super.key});

  @override
  State<LawyerConsultationsScreen> createState() =>
      _LawyerConsultationsScreenState();
}

class _LawyerConsultationsScreenState extends State<LawyerConsultationsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _selectedFilter = 'All';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'My Consultations',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF8B4513),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              Future.delayed(const Duration(milliseconds: 500), () {
                setState(() {
                  _isLoading = false;
                });
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: _debugConsultations,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createTestConsultation,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Section
          _buildFilterSection(),

          // Consultations List
          Expanded(child: _buildConsultationsList()),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          const Text('Filter:', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedFilter,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              items: ['All', 'Pending', 'Accepted', 'Completed', 'Rejected']
                  .map((status) {
                    return DropdownMenuItem(value: status, child: Text(status));
                  })
                  .toList(),
              onChanged: (value) => setState(() => _selectedFilter = value!),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsultationsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getConsultationsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && _isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error loading consultations: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                    });
                    Future.delayed(const Duration(milliseconds: 500), () {
                      setState(() {
                        _isLoading = false;
                      });
                    });
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.folder_open, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  _selectedFilter == 'All'
                      ? 'No consultations yet'
                      : 'No $_selectedFilter consultations',
                  style: const TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const Text(
                  'Your consultations will appear here',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        List<ConsultationModel> consultations = snapshot.data!.docs.map((doc) {
          return ConsultationModel.fromFirestore(doc);
        }).toList();

        List<ConsultationModel> filteredConsultations = consultations;
        if (_selectedFilter != 'All') {
          filteredConsultations = consultations.where((consultation) {
            return consultation.status.toLowerCase() ==
                _selectedFilter.toLowerCase();
          }).toList();
        }

        if (filteredConsultations.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.folder_open, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'No $_selectedFilter consultations',
                  style: const TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const Text(
                  'Try changing the filter',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredConsultations.length,
          itemBuilder: (context, index) {
            final consultation = filteredConsultations[index];
            return _buildConsultationCard(consultation);
          },
        );
      },
    );
  }

  Stream<QuerySnapshot> _getConsultationsStream() async* {
    try {
      final session = await AuthService.getSavedUserSession();
      String lawyerId = session['userId'] as String;

      yield* _firestore
          .collection(AppConstants.consultationsCollection)
          .where('lawyerId', isEqualTo: lawyerId)
          .orderBy('createdAt', descending: true)
          .snapshots();
    } catch (e) {
      print('Error getting consultations stream: $e');
      yield* Stream.empty();
    }
  }

  Widget _buildConsultationCard(ConsultationModel consultation) {
    Color statusColor = _getStatusColor(consultation.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getStatusIcon(consultation.status),
                    color: statusColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        consultation.category,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        consultation.type,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    consultation.status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Description
            Text(
              consultation.description,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 12),

            // Details Row
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  DateFormat('MMM dd, yyyy').format(consultation.scheduledAt),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(width: 16),
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  DateFormat('hh:mm a').format(consultation.scheduledAt),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const Spacer(),
                Text(
                  consultation.price == 0
                      ? 'Free'
                      : 'PKR ${consultation.price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showConsultationDetails(consultation),
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('View Details'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF8B4513),
                      side: const BorderSide(color: Color(0xFF8B4513)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (consultation.status == AppConstants.pendingStatus) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateConsultationStatus(
                        consultation.id,
                        'accepted',
                      ),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Accept'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateConsultationStatus(
                        consultation.id,
                        'rejected',
                      ),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Reject'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ] else if (consultation.status == 'accepted') ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateConsultationStatus(
                        consultation.id,
                        AppConstants.completedStatus,
                      ),
                      icon: const Icon(Icons.done_all, size: 16),
                      label: const Text('Complete'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B4513),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
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

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return Icons.check_circle;
      case 'pending':
        return Icons.schedule;
      case 'completed':
        return Icons.done_all;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  void _showConsultationDetails(ConsultationModel consultation) async {
    // Get user details
    UserModel? user;
    try {
      DocumentSnapshot userDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(consultation.userId)
          .get();

      if (userDoc.exists) {
        user = UserModel.fromFirestore(userDoc);
      }
    } catch (e) {
      print('Error loading user details: $e');
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(consultation.category),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Info
              if (user != null) ...[
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFF8B4513),
                      backgroundImage:
                          user.profileImage != null &&
                              user.profileImage!.isNotEmpty
                          ? NetworkImage(user.profileImage!)
                          : null,
                      child:
                          user.profileImage == null ||
                              user.profileImage!.isEmpty
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
                            user.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            user.email,
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
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
              ],

              // Consultation Details
              _buildDetailRow('Type', consultation.type),
              _buildDetailRow('Category', consultation.category),
              _buildDetailRow('Status', consultation.status),
              _buildDetailRow(
                'Price',
                consultation.price == 0
                    ? 'Free'
                    : 'PKR ${consultation.price.toStringAsFixed(0)}',
              ),
              _buildDetailRow(
                'Scheduled Date',
                DateFormat('MMM dd, yyyy').format(consultation.scheduledAt),
              ),
              _buildDetailRow(
                'Scheduled Time',
                DateFormat('hh:mm a').format(consultation.scheduledAt),
              ),
              _buildDetailRow(
                'Created',
                DateFormat(
                  'MMM dd, yyyy hh:mm a',
                ).format(consultation.createdAt),
              ),

              const SizedBox(height: 12),
              const Text(
                'Description:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(consultation.description),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
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
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Future<void> _updateConsultationStatus(
    String consultationId,
    String status,
  ) async {
    try {
      await ConsultationService.updateConsultationStatus(
        consultationId: consultationId,
        status: status,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Consultation $status successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update consultation: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _debugConsultations() async {
    try {
      final session = await AuthService.getSavedUserSession();
      String lawyerId = session['userId'] as String;

      print('🔍 DEBUG: Lawyer ID: $lawyerId');

      // Get all consultations in the collection
      QuerySnapshot allConsultations = await _firestore
          .collection(AppConstants.consultationsCollection)
          .get();

      print(
        '🔍 DEBUG: Total consultations in collection: ${allConsultations.docs.length}',
      );

      for (var doc in allConsultations.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        print('🔍 DEBUG: Consultation ${doc.id}:');
        print('  - User ID: ${data['userId']}');
        print('  - Lawyer ID: ${data['lawyerId']}');
        print('  - Status: ${data['status']}');
        print('  - Category: ${data['category']}');
        print('  - Type: ${data['type']}');
        print('  - Description: ${data['description']}');
        print('  - Created: ${data['createdAt']}');
        print('  ---');
      }

      // Get consultations for this specific lawyer
      QuerySnapshot lawyerConsultations = await _firestore
          .collection(AppConstants.consultationsCollection)
          .where('lawyerId', isEqualTo: lawyerId)
          .get();

      print(
        '🔍 DEBUG: Consultations for this lawyer: ${lawyerConsultations.docs.length}',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Debug info printed to console. Total: ${allConsultations.docs.length}, For lawyer: ${lawyerConsultations.docs.length}',
          ),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      print('❌ DEBUG Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Debug error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _createTestConsultation() async {
    try {
      final session = await AuthService.getSavedUserSession();
      String lawyerId = session['userId'] as String;

      // Create a test consultation
      await ConsultationService.createConsultation(
        userId: 'test_user_123',
        lawyerId: lawyerId,
        type: 'free',
        category: 'Family Law',
        city: 'Karachi',
        description: 'Test consultation for debugging purposes',
        price: 0.0,
        scheduledAt: DateTime.now().add(const Duration(days: 1)),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Test consultation created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('❌ Test consultation error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create test consultation: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
