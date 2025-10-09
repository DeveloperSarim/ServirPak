import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/consultation_model.dart';
import '../../models/user_model.dart';
import '../../services/consultation_service.dart';
import '../../services/auth_service.dart';
import '../../services/google_meet_service.dart';
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
          print('🔍 LawyerConsultationsScreen: No data or empty docs');
          print('🔍 LawyerConsultationsScreen: Has data: ${snapshot.hasData}');
          print(
            '🔍 LawyerConsultationsScreen: Docs count: ${snapshot.data?.docs.length ?? 0}',
          );

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
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    print(
                      '🔍 Debug: Checking all consultations in database...',
                    );
                    _debugAllConsultations();
                  },
                  child: const Text('Debug: Check All Consultations'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    print('🔍 Debug: Creating test consultation...');
                    _createTestConsultation();
                  },
                  child: const Text('Debug: Create Test Consultation'),
                ),
              ],
            ),
          );
        }

        List<ConsultationModel> consultations = snapshot.data!.docs.map((doc) {
          return ConsultationModel.fromFirestore(doc);
        }).toList();

        print(
          '🔍 LawyerConsultationsScreen: Found ${consultations.length} consultations',
        );
        for (var consultation in consultations) {
          print(
            '🔍 LawyerConsultationsScreen: Consultation - ${consultation.category} (${consultation.status})',
          );
        }

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

      print(
        '🔍 LawyerConsultationsScreen: Getting consultations for lawyer ID: $lawyerId',
      );
      print('🔍 LawyerConsultationsScreen: Session data: $session');

      // First, let's check all consultations in the collection
      QuerySnapshot allSnapshot = await _firestore
          .collection(AppConstants.consultationsCollection)
          .get();

      print('🔍 Total consultations in collection: ${allSnapshot.docs.length}');

      for (var doc in allSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        print('🔍 Consultation ${doc.id}:');
        print('  - User ID: ${data['userId']}');
        print('  - Lawyer ID: ${data['lawyerId']}');
        print('  - Status: ${data['status']}');
        print('  - Category: ${data['category']}');
        print('  - Created: ${data['createdAt']}');
        print('  ---');
      }

      // Now get consultations for this specific lawyer
      yield* _firestore
          .collection(AppConstants.consultationsCollection)
          .where('lawyerId', isEqualTo: lawyerId)
          .orderBy('createdAt', descending: true)
          .snapshots();
    } catch (e) {
      print('❌ Error getting consultations stream: $e');
      yield* Stream.empty();
    }
  }

  Future<void> _debugAllConsultations() async {
    try {
      print('🔍 Debug: Checking all consultations in database...');

      // Get all consultations
      QuerySnapshot allSnapshot = await _firestore
          .collection(AppConstants.consultationsCollection)
          .get();

      print(
        '🔍 Debug: Total consultations in database: ${allSnapshot.docs.length}',
      );

      for (var doc in allSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        print('🔍 Debug: Consultation ID: ${doc.id}');
        print('🔍 Debug: Lawyer ID: ${data['lawyerId']}');
        print('🔍 Debug: User ID: ${data['userId']}');
        print('🔍 Debug: Category: ${data['category']}');
        print('🔍 Debug: Status: ${data['status']}');
        print('🔍 Debug: Created: ${data['createdAt']}');
        print('---');
      }

      // Get current lawyer ID
      final session = await AuthService.getSavedUserSession();
      String lawyerId = session['userId'] as String;
      print('🔍 Debug: Current lawyer ID: $lawyerId');

      // Check if any consultations match current lawyer
      QuerySnapshot lawyerSnapshot = await _firestore
          .collection(AppConstants.consultationsCollection)
          .where('lawyerId', isEqualTo: lawyerId)
          .get();

      print(
        '🔍 Debug: Consultations for current lawyer: ${lawyerSnapshot.docs.length}',
      );

      if (lawyerSnapshot.docs.isNotEmpty) {
        for (var doc in lawyerSnapshot.docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          print('🔍 Debug: Found consultation for lawyer: ${doc.id}');
          print('🔍 Debug: Data: $data');
        }
      }
    } catch (e) {
      print('❌ Debug error: $e');
    }
  }

  Future<void> _createTestConsultation() async {
    try {
      print('🔍 Debug: Creating test consultation...');

      final session = await AuthService.getSavedUserSession();
      String lawyerId = session['userId'] as String;

      print('🔍 Debug: Creating consultation for lawyer ID: $lawyerId');

      // Create a test consultation with proper structure
      Map<String, dynamic> consultationData = {
        'userId': 'test_user_${DateTime.now().millisecondsSinceEpoch}',
        'lawyerId': lawyerId,
        'type': 'free',
        'category': 'Test Law',
        'city': 'Karachi',
        'description':
            'Test consultation created from lawyer consultation screen',
        'price': 0.0,
        'platformFee': 0.0,
        'totalAmount': 0.0,
        'consultationDate': DateTime.now()
            .add(const Duration(days: 1))
            .toString()
            .split(' ')[0],
        'consultationTime': DateTime.now()
            .add(const Duration(days: 1))
            .toString()
            .split(' ')[1],
        'meetingLink': '',
        'status': 'pending',
        'scheduledAt': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 1)),
        ),
        'createdAt': Timestamp.fromDate(DateTime.now()),
      };

      print('🔍 Debug: Consultation data: $consultationData');

      await _firestore
          .collection(AppConstants.consultationsCollection)
          .add(consultationData);

      print('✅ Debug: Test consultation created successfully!');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Test consultation created! Check if it appears now.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('❌ Debug: Error creating test consultation: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create test consultation: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
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

            // Join Meeting Button (for accepted consultations)
            if (consultation.status == 'accepted') ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _joinMeeting(consultation),
                  icon: const Icon(Icons.video_call, size: 18),
                  label: const Text('Join Meeting'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
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

              // Meeting Link (if exists)
              if (consultation.meetingLink.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Meeting Link:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.video_call,
                        color: Colors.blue,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          consultation.meetingLink,
                          style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _joinMeeting(consultation),
                        icon: const Icon(Icons.launch, color: Colors.blue),
                        tooltip: 'Join Meeting',
                      ),
                    ],
                  ),
                ),
              ],

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

  Future<void> _joinMeeting(ConsultationModel consultation) async {
    try {
      // Check if consultation has a meeting link
      String meetingLink = consultation.meetingLink;

      if (meetingLink.isEmpty) {
        // Generate a new meeting link if none exists
        meetingLink = GoogleMeetService.generateScheduledMeetingLink(
          lawyerId: consultation.lawyerId,
          userId: consultation.userId,
          consultationId: consultation.id,
          date: DateFormat('yyyy-MM-dd').format(consultation.scheduledAt),
          time: DateFormat('HH:mm').format(consultation.scheduledAt),
          lawyerName: 'Lawyer', // You can fetch this from lawyer data
          userName: 'Client', // You can fetch this from user data
        );

        // Save the meeting link to the consultation
        await _firestore
            .collection(AppConstants.consultationsCollection)
            .doc(consultation.id)
            .update({'meetingLink': meetingLink});
      }

      // Convert old meeting links to new Google Meet format
      String convertedLink = GoogleMeetService.convertToGoogleMeetLink(
        meetingLink,
      );

      print('🔗 Original meeting link: $meetingLink');
      print('🔗 Converted meeting link: $convertedLink');

      // Validate the converted Google Meet link
      if (!GoogleMeetService.isValidGoogleMeetLink(convertedLink)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to create valid meeting link'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Try to launch the meeting with fallback
      bool launched = await GoogleMeetService.launchMeetingWithFallback(
        convertedLink,
        context,
      );

      if (launched) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Opening Google Meet...'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ Error joining meeting: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error joining meeting: $e'),
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
}
