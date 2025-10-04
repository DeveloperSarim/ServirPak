import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../services/consultation_service.dart';
import '../../constants/app_constants.dart';
import '../../models/user_model.dart';
import '../../models/lawyer_model.dart';
import '../../models/consultation_model.dart';
import '../auth/login_screen.dart';
import '../settings/settings_screen.dart';
import 'lawyer_analytics_screen.dart';
import 'lawyer_documents_screen.dart';
import 'lawyer_schedule_screen.dart';
import 'lawyer_client_search_screen.dart';
import 'lawyer_chat_list_screen.dart';
import 'lawyer_consultations_screen.dart';
import '../../utils/firebase_setup_helper.dart';
import '../../utils/responsive_helper.dart';
import '../../services/demo_data_service.dart';

class LawyerDashboard extends StatefulWidget {
  const LawyerDashboard({super.key});

  @override
  State<LawyerDashboard> createState() => _LawyerDashboardState();
}

class _LawyerDashboardState extends State<LawyerDashboard> {
  int _selectedIndex = 0;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  LawyerModel? _currentLawyer;
  List<ConsultationModel> _consultations = [];
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

      // Get consultations
      _consultations = await ConsultationService.getConsultationsByLawyerId(
        userId,
      );

      // If no consultations exist, add demo data automatically
      if (_consultations.isEmpty) {
        await DemoDataService.addAllDemoData(userId);
        // Reload consultations after adding demo data
        _consultations = await ConsultationService.getConsultationsByLawyerId(
          userId,
        );
      }
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
          BottomNavigationBarItem(icon: Icon(Icons.folder), label: 'My Cases'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Messages'),
          BottomNavigationBarItem(icon: Icon(Icons.upload), label: 'Documents'),
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
        return _buildMyCases();
      case 2:
        return Scaffold(
          body: const LawyerChatListScreen(),
          floatingActionButton: FloatingActionButton(
            onPressed: () async {
              await FirebaseSetupHelper.setupDemoChatData();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Demo chat created!')),
              );
            },
            backgroundColor: const Color(0xFF8B4513),
            child: const Icon(Icons.add, color: Colors.white),
          ),
        );
      case 3:
        return const LawyerDocumentsScreen();
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
                    backgroundImage:
                        profileImageUrl != null && profileImageUrl.isNotEmpty
                        ? NetworkImage(profileImageUrl)
                        : null,
                    onBackgroundImageError: (exception, stackTrace) {
                      print('❌ Error loading lawyer profile image: $exception');
                    },
                    child: profileImageUrl == null || profileImageUrl.isEmpty
                        ? const Icon(Icons.gavel, color: Colors.white, size: 18)
                        : null,
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
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Color(0xFF8B4513)),
            onSelected: (value) {
              if (value == 'add_demo_data') {
                _addDemoData();
              } else if (value == 'clear_demo_data') {
                _clearDemoData();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'add_demo_data',
                child: Row(
                  children: [
                    Icon(Icons.add_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Add Demo Data'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_demo_data',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Clear Demo Data'),
                  ],
                ),
              ),
            ],
          ),
          Container(
            margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFF8B4513),
              backgroundImage:
                  _currentLawyer?.profileImage != null &&
                      _currentLawyer!.profileImage!.isNotEmpty
                  ? NetworkImage(_currentLawyer!.profileImage!)
                  : null,
              child:
                  _currentLawyer?.profileImage == null ||
                      _currentLawyer!.profileImage!.isEmpty
                  ? const Icon(Icons.person, color: Colors.white, size: 24)
                  : null,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFF8B4513)),
            onPressed: _logout,
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
          const SizedBox(height: 16),
          Row(
            children: [
              _buildQuickActionButton(
                'Analytics',
                Icons.analytics,
                () => _navigateToAnalytics(),
              ),
              const SizedBox(width: 12),
              _buildQuickActionButton(
                'Upload Docs',
                Icons.upload,
                () => setState(() => _selectedIndex = 3),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    int totalCases = _consultations.length;
    int activeCases = _consultations
        .where(
          (c) =>
              c.status == AppConstants.pendingStatus || c.status == 'accepted',
        )
        .length;
    int completedCases = _consultations
        .where((c) => c.status == AppConstants.completedStatus)
        .length;
    double totalRevenue = _consultations
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
        GridView.count(
          crossAxisCount: ResponsiveHelper.isMobile(context) ? 2 : 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.1,
          children: [
            _buildActionCard(
              'Schedule Meeting',
              Icons.calendar_today,
              const Color(0xFF8B4513),
            ),
            _buildActionCard(
              'Client Search',
              Icons.search,
              const Color(0xFFA0522D),
            ),
            _buildActionCard('Case Notes', Icons.note, const Color(0xFF2E8B57)),
            _buildActionCard('Billing', Icons.payment, const Color(0xFFD4AF37)),
            _buildActionCard(
              'Analytics',
              Icons.analytics,
              const Color(0xFF8B4513),
            ),
            _buildActionCard(
              'Documents',
              Icons.folder,
              const Color(0xFFA0522D),
            ),
            _buildActionCard(
              'Messages',
              Icons.message,
              const Color(0xFF1E88E5),
            ),
            _buildActionCard(
              'Consultations',
              Icons.assignment,
              const Color(0xFF8B4513),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          if (title == 'Analytics') {
            _navigateToAnalytics();
          } else if (title == 'Documents') {
            setState(() => _selectedIndex = 3);
          } else if (title == 'Messages') {
            setState(() => _selectedIndex = 2);
          } else if (title == 'Schedule Meeting') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const LawyerScheduleScreen(),
              ),
            );
          } else if (title == 'Client Search') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const LawyerClientSearchScreen(),
              ),
            );
          } else if (title == 'Case Notes') {
            _showCaseNotesDialog();
          } else if (title == 'Billing') {
            _showBillingDialog();
          } else if (title == 'Consultations') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const LawyerConsultationsScreen(),
              ),
            );
          } else {
            // Handle other actions
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$title functionality coming soon!')),
            );
          }
        },
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
          child: _consultations.isEmpty
              ? const Center(
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
                )
              : Column(
                  children: _consultations.take(5).map((consultation) {
                    return Column(
                      children: [
                        _buildConsultationItem(consultation),
                        if (consultation != _consultations.take(5).last)
                          const Divider(),
                      ],
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildConsultationItem(ConsultationModel consultation) {
    Color statusColor = _getStatusColor(consultation.status);
    String timeAgo = _getTimeAgo(consultation.createdAt);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: statusColor.withOpacity(0.1),
        child: Icon(_getStatusIcon(consultation.status), color: statusColor),
      ),
      title: Text(
        consultation.category,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            consultation.description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
      trailing: Text(
        'PKR ${consultation.price.toStringAsFixed(0)}',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.green,
        ),
      ),
      onTap: () {
        _showConsultationDetails(consultation);
      },
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

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'accepted':
        return Icons.check_circle;
      case 'pending':
        return Icons.schedule;
      case 'completed':
        return Icons.done_all;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help;
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
      await ConsultationService.updateConsultationStatus(
        consultationId: consultationId,
        status: status,
      );

      // Refresh data
      await _loadLawyerData();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Consultation $status successfully'),
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

  Widget _buildMyCases() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'My Consultations',
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
      body: _consultations.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_open, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No consultations yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  Text(
                    'Your consultations will appear here',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _consultations.length,
              itemBuilder: (context, index) {
                ConsultationModel consultation = _consultations[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: _buildConsultationItem(consultation),
                );
              },
            ),
    );
  }

  Widget _buildProfile() {
    return FutureBuilder<UserModel?>(
      future: _getCurrentUser(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        return SettingsScreen(
          userRole: AppConstants.lawyerRole,
          user: snapshot.data,
        );
      },
    );
  }

  Future<UserModel?> _getCurrentUser() async {
    try {
      final session = await AuthService.getSavedUserSession();
      return await AuthService.getUserById(session['userId'] as String);
    } catch (e) {
      print('❌ Error getting current user: $e');
      return null;
    }
  }

  void _navigateToAnalytics() {
    if (_currentLawyer != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LawyerAnalyticsScreen(lawyer: _currentLawyer!),
        ),
      );
    }
  }

  void _showCaseNotesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Case Notes'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: Column(
            children: [
              const Text(
                'Create and manage case notes for your consultations:',
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: _consultations.length,
                  itemBuilder: (context, index) {
                    ConsultationModel consultation = _consultations[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(consultation.category),
                        subtitle: Text(consultation.description),
                        trailing: IconButton(
                          icon: const Icon(Icons.note_add),
                          onPressed: () => _addCaseNote(consultation),
                        ),
                      ),
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

  void _showBillingDialog() {
    double totalRevenue = _consultations
        .where((c) => c.status == AppConstants.completedStatus)
        .fold(0.0, (sum, c) => sum + c.price);

    int completedCases = _consultations
        .where((c) => c.status == AppConstants.completedStatus)
        .length;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Billing Summary'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B4513).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      'Total Revenue',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'PKR ${totalRevenue.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8B4513),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        completedCases.toString(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const Text('Completed Cases'),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        _consultations.length.toString(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const Text('Total Cases'),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToAnalytics();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B4513),
              foregroundColor: Colors.white,
            ),
            child: const Text('View Analytics'),
          ),
        ],
      ),
    );
  }

  void _addCaseNote(ConsultationModel consultation) {
    final TextEditingController noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Note for ${consultation.category}'),
        content: TextField(
          controller: noteController,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Enter your case notes here...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (noteController.text.isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Case note saved successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B4513),
              foregroundColor: Colors.white,
            ),
            child: const Text('Save Note'),
          ),
        ],
      ),
    );
  }

  Future<void> _addDemoData() async {
    try {
      final session = await AuthService.getSavedUserSession();
      String lawyerId = session['userId'] as String;

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Adding demo data...'),
            ],
          ),
        ),
      );

      await DemoDataService.addAllDemoData(lawyerId);

      // Close loading dialog
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Demo data added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Refresh data
      await _loadLawyerData();
    } catch (e) {
      // Close loading dialog if open
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add demo data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

  Future<void> _logout() async {
    try {
      await AuthService.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
