import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../services/realtime_chat_service.dart';
import '../../constants/app_constants.dart';
import '../../models/lawyer_model.dart';
import '../../models/consultation_model.dart';
import '../../models/user_model.dart';
import '../../models/chat_model.dart';
import 'lawyer_chat_list_screen.dart';
import 'lawyer_consultations_screen.dart';
import 'lawyer_chat_screen.dart';
import '../../utils/responsive_helper.dart';
import '../../services/demo_data_service.dart';
import 'lawyer_profile_management_screen.dart';
import 'lawyer_wallet_screen.dart';

class LawyerDashboard extends StatefulWidget {
  const LawyerDashboard({super.key});

  @override
  State<LawyerDashboard> createState() => _LawyerDashboardState();
}

class _LawyerDashboardState extends State<LawyerDashboard> {
  int _selectedIndex = 0;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  LawyerModel? _currentLawyer;
  // Removed static _consultations list - now using StreamBuilder for real-time updates
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLawyerData();
  }

  Future<void> _loadLawyerData() async {
    try {
      final session = await AuthService.getSavedUserSession();
      String userId = session['userId'] as String;

      // Get lawyer profile
      DocumentSnapshot lawyerDoc = await _firestore
          .collection(AppConstants.lawyersCollection)
          .doc(userId)
          .get();

      if (lawyerDoc.exists) {
        _currentLawyer = LawyerModel.fromFirestore(lawyerDoc);
      } else {
        // Create a default lawyer profile if not exists
        _currentLawyer = LawyerModel(
          id: userId,
          userId: userId,
          name: 'Demo Lawyer',
          email: session['email'] ?? 'lawyer@example.com',
          phone: '+92-300-0000000',
          specialization: 'General Practice',
          experience: '5',
          barCouncilNumber: 'BC-2024-001',
          status: 'verified',
          bio:
              'Experienced lawyer with 5+ years of practice in various legal fields including Family Law, Criminal Law, and Corporate Law.',
          rating: 4.8,
          totalCases: 150,
          languages: ['English', 'Urdu'],
          address: '123 Main Street, Lahore',
          city: 'Lahore',
          province: 'Punjab',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Save the default profile to Firestore
        await _firestore
            .collection(AppConstants.lawyersCollection)
            .doc(userId)
            .set(_currentLawyer!.toFirestore());
      }

      // Consultations are now loaded via StreamBuilder for real-time updates
    } catch (e) {
      print('Error loading lawyer data: $e');
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
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF8B4513),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder),
            label: 'Consultations',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Messages'),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Wallet',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildMainDashboard();
      case 1:
        return const LawyerConsultationsScreen();
      case 2:
        return Scaffold(
          body: const LawyerChatListScreen(),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showStartChatModal(),
            backgroundColor: const Color(0xFF8B4513),
            child: const Icon(Icons.add, color: Colors.white),
          ),
        );
      case 3:
        return LawyerWalletScreen(
          lawyerId: _currentLawyer?.id ?? '',
          lawyerName: _currentLawyer?.name ?? '',
          lawyerEmail: _currentLawyer?.email ?? '',
        );
      case 4:
        return _buildProfile();
      default:
        return _buildMainDashboard();
    }
  }

  Widget _buildMainDashboard() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'ServirPak',
          style: TextStyle(
            color: Color(0xFF8B4513),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          // Profile Image
          StreamBuilder<DocumentSnapshot>(
            stream: _firestore
                .collection(AppConstants.usersCollection)
                .doc(AuthService.currentUser?.uid ?? '')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data!.exists) {
                final userData = snapshot.data!.data() as Map<String, dynamic>?;
                final profileImageUrl = userData?['profileImage'] as String?;

                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF8B4513),
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFF8B4513),
                    child: profileImageUrl != null && profileImageUrl.isNotEmpty
                        ? ClipOval(
                            child: Image.network(
                              profileImageUrl,
                              width: 36,
                              height: 36,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.gavel,
                                  color: Colors.white,
                                  size: 18,
                                );
                              },
                            ),
                          )
                        : const Icon(
                            Icons.gavel,
                            color: Colors.white,
                            size: 18,
                          ),
                  ),
                );
              }
              return Container(
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF8B4513), width: 2),
                ),
                child: const CircleAvatar(
                  radius: 18,
                  backgroundColor: Color(0xFF8B4513),
                  child: Icon(Icons.gavel, color: Colors.white, size: 18),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            _buildWelcomeCard(),
            const SizedBox(height: 20),

            // Stats Cards
            _buildStatsCards(),
            const SizedBox(height: 20),

            // Quick Actions
            _buildQuickActions(),
            const SizedBox(height: 20),

            // Recent Cases
            _buildRecentCases(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B4513), Color(0xFFA0522D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B4513).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome, ${_currentLawyer?.name ?? 'Lawyer'}!',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_currentLawyer?.specialization ?? 'Legal Practice'} • ${_currentLawyer?.city ?? 'Location'}',
            style: const TextStyle(fontSize: 16, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getConsultationsStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        List<ConsultationModel> consultations = snapshot.data!.docs.map((doc) {
          return ConsultationModel.fromFirestore(doc);
        }).toList();

        int totalCases = consultations.length;
        int activeCases = consultations
            .where(
              (c) =>
                  c.status == AppConstants.pendingStatus ||
                  c.status == 'accepted',
            )
            .length;
        int completedCases = consultations
            .where((c) => c.status == AppConstants.completedStatus)
            .length;
        double totalRevenue = consultations
            .where((c) => c.status == AppConstants.completedStatus)
            .fold(0.0, (sum, c) => sum + c.price);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Practice Statistics',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: ResponsiveHelper.isMobile(context) ? 2 : 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
              children: [
                _buildStatCard(
                  'Total Cases',
                  totalCases.toString(),
                  Icons.folder,
                  const Color(0xFF8B4513),
                ),
                _buildStatCard(
                  'Active Cases',
                  activeCases.toString(),
                  Icons.work,
                  const Color(0xFFA0522D),
                ),
                _buildStatCard(
                  'Completed',
                  completedCases.toString(),
                  Icons.check_circle,
                  const Color(0xFF2E8B57),
                ),
                _buildStatCard(
                  'Revenue',
                  'PKR ${totalRevenue.toStringAsFixed(0)}',
                  Icons.attach_money,
                  const Color(0xFFD4AF37),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 24, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'My Consultations',
                Icons.folder,
                const Color(0xFF8B4513),
                () => setState(() => _selectedIndex = 1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'Messages',
                Icons.message,
                const Color(0xFF1E88E5),
                () => setState(() => _selectedIndex = 2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'Profile',
                Icons.person,
                const Color(0xFFA0522D),
                () => setState(() => _selectedIndex = 3),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 24, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentCases() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Consultations',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LawyerConsultationsScreen(),
                  ),
                );
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: StreamBuilder<QuerySnapshot>(
            stream: _getConsultationsStream(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              List<ConsultationModel> consultations = snapshot.data!.docs.map((
                doc,
              ) {
                return ConsultationModel.fromFirestore(doc);
              }).toList();

              if (consultations.isEmpty) {
                return const Center(
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
                          'Your consultations will appear here',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: consultations.take(5).map((consultation) {
                  return Column(
                    children: [
                      _buildConsultationItem(consultation),
                      if (consultation != consultations.take(5).last)
                        const Divider(),
                    ],
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildConsultationItem(ConsultationModel consultation) {
    Color statusColor = _getStatusColor(consultation.status);
    String timeAgo = _getTimeAgo(consultation.createdAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Info Section
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFF8B4513).withOpacity(0.1),
                  child: FutureBuilder<DocumentSnapshot>(
                    future: _firestore
                        .collection(AppConstants.usersCollection)
                        .doc(consultation.userId)
                        .get(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data!.exists) {
                        final userData =
                            snapshot.data!.data() as Map<String, dynamic>?;
                        final profileImage =
                            userData?['profileImage'] as String?;
                        final userName =
                            userData?['name'] as String? ?? 'Unknown User';

                        return profileImage != null && profileImage.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Image.network(
                                  profileImage,
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Text(
                                      userName.isNotEmpty
                                          ? userName[0].toUpperCase()
                                          : 'U',
                                      style: const TextStyle(
                                        color: Color(0xFF8B4513),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    );
                                  },
                                ),
                              )
                            : Text(
                                userName.isNotEmpty
                                    ? userName[0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                  color: Color(0xFF8B4513),
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                      }
                      return const Text(
                        'U',
                        style: TextStyle(
                          color: Color(0xFF8B4513),
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FutureBuilder<DocumentSnapshot>(
                        future: _firestore
                            .collection(AppConstants.usersCollection)
                            .doc(consultation.userId)
                            .get(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData && snapshot.data!.exists) {
                            final userData =
                                snapshot.data!.data() as Map<String, dynamic>?;
                            final userName =
                                userData?['name'] as String? ?? 'Unknown User';
                            final userEmail =
                                userData?['email'] as String? ?? 'No email';

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  userEmail,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            );
                          }
                          return const Text(
                            'Unknown User',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          );
                        },
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
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Consultation Details
            Text(
              consultation.category,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF8B4513),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              consultation.description,
              style: const TextStyle(fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),

            // Bottom Row
            Row(
              children: [
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
                    consultation.type.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  timeAgo,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ],
        ),
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

  String _getTimeAgo(DateTime dateTime) {
    Duration difference = DateTime.now().difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  Stream<QuerySnapshot> _getConsultationsStream() async* {
    try {
      final session = await AuthService.getSavedUserSession();
      String lawyerId = session['userId'] as String;

      print(
        '🔍 LawyerDashboard: Getting consultations for lawyer ID: $lawyerId',
      );
      print('🔍 LawyerDashboard: Session data: $session');

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

  Widget _buildProfile() {
    return const LawyerProfileManagementScreen();
  }

  Future<void> _clearDemoData() async {
    try {
      final session = await AuthService.getSavedUserSession();
      String lawyerId = session['userId'] as String;

      // Show confirmation dialog
      bool? confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Clear Demo Data'),
          content: const Text(
            'Are you sure you want to clear all demo data? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Clear', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirm == true) {
        // Show loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Clearing demo data...'),
              ],
            ),
          ),
        );

        await DemoDataService.clearDemoData(lawyerId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Demo data cleared successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }

        // Refresh data
        await _loadLawyerData();
      }
    } catch (e) {
      // Close loading dialog if open
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to clear demo data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Show modal to start chat with users
  Future<void> _showStartChatModal() async {
    try {
      // Get all users from Firebase
      QuerySnapshot usersSnapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .get();

      List<UserModel> users = usersSnapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();

      if (mounted) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => Container(
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Text(
                        'Start New Chat',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8B4513),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                // Users list
                Expanded(
                  child: users.isEmpty
                      ? const Center(
                          child: Text(
                            'No users available',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: users.length,
                          itemBuilder: (context, index) {
                            UserModel user = users[index];
                            return _buildUserChatCard(user);
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading users: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildUserChatCard(UserModel user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: const Color(0xFF8B4513).withOpacity(0.1),
          backgroundImage:
              user.profileImage != null && user.profileImage!.isNotEmpty
              ? NetworkImage(user.profileImage!)
              : null,
          child: user.profileImage == null || user.profileImage!.isEmpty
              ? const Icon(Icons.person, color: Color(0xFF8B4513))
              : null,
        ),
        title: Text(
          user.name,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Text(
          user.email,
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
        trailing: ElevatedButton(
          onPressed: () => _startChatWithUser(user),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8B4513),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          child: const Text('Chat'),
        ),
        onTap: () => _startChatWithUser(user),
      ),
    );
  }

  Future<void> _startChatWithUser(UserModel user) async {
    try {
      Navigator.pop(context); // Close modal

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Get current lawyer
      final session = await AuthService.getSavedUserSession();
      String lawyerId = session['userId'] as String;

      // Create chat
      await RealtimeChatService.createChatRealtime(
        lawyerId: lawyerId,
        userId: user.id,
      );

      // Get lawyer data
      DocumentSnapshot lawyerDoc = await _firestore
          .collection(AppConstants.lawyersCollection)
          .doc(lawyerId)
          .get();

      if (lawyerDoc.exists) {
        Map<String, dynamic> lawyerData =
            lawyerDoc.data() as Map<String, dynamic>;

        // Create ChatModel
        ChatModel chat = ChatModel(
          id: _generateChatId(lawyerId, user.id),
          lawyerId: lawyerId,
          lawyerName: lawyerData['name'] ?? 'Lawyer',
          lawyerEmail: lawyerData['email'] ?? '',
          lawyerProfileImage: lawyerData['profileImage'],
          userId: user.id,
          userName: user.name,
          userEmail: user.email,
          userProfileImage: user.profileImage,
          createdAt: DateTime.now(),
          consultationIds: [],
        );

        Navigator.pop(context); // Close loading

        // Navigate to chat
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => LawyerChatScreen(chat: chat)),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Close loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start chat: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _generateChatId(String lawyerId, String userId) {
    List<String> ids = [lawyerId, userId];
    ids.sort();
    return '${ids[0]}_${ids[1]}';
  }
}
