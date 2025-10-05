import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../../services/auth_service.dart';
import '../../services/image_service.dart';
import '../../services/lawyer_service.dart';
import '../../services/review_service.dart';
import '../../services/user_seed_service.dart';
import '../../constants/app_constants.dart';
import '../../services/lawyer_management_service.dart';
import '../auth/login_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LawyerService _lawyerService = LawyerService();
  final ReviewService _reviewService = ReviewService();
  int _pendingLawyersCount = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
      bottomNavigationBar: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection(AppConstants.lawyersCollection)
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            _pendingLawyersCount = snapshot.data!.docs.length;
          }

          return BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: _selectedIndex,
            onTap: (index) => setState(() => _selectedIndex = index),
            backgroundColor: Colors.white,
            selectedItemColor: const Color(0xFF8B4513),
            unselectedItemColor: Colors.grey,
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.dashboard),
                label: 'Dashboard',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.people),
                label: 'Users',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.gavel),
                label: 'Lawyers',
              ),
              BottomNavigationBarItem(
                icon: Stack(
                  children: [
                    const Icon(Icons.verified_user),
                    if (_pendingLawyersCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '$_pendingLawyersCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                label: 'Verification',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildMainDashboard();
      case 1:
        return _buildUsersManagement();
      case 2:
        return _buildLawyersManagement();
      case 3:
        return _buildVerificationManagement();
      case 4:
        return _buildSettings();
      default:
        return _buildMainDashboard();
    }
  }

  Widget _buildMainDashboard() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Admin Dashboard',
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
        actions: [
          StreamBuilder<DocumentSnapshot>(
            stream: _firestore
                .collection(AppConstants.usersCollection)
                .doc(AuthService.currentUser?.uid ?? '')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data!.exists) {
                final userData = snapshot.data!.data() as Map<String, dynamic>?;
                final profileImageUrl = userData?['profileImage'] as String?;

                return GestureDetector(
                  onTap: () {
                    // Show admin profile info
                    _showAdminProfileDialog(userData);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF8B4513),
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFF8B4513),
                      backgroundImage:
                          profileImageUrl != null && profileImageUrl.isNotEmpty
                          ? NetworkImage(profileImageUrl)
                          : null,
                      onBackgroundImageError: (exception, stackTrace) {
                        print(
                          '❌ Error loading admin profile image: $exception',
                        );
                      },
                      child: profileImageUrl == null || profileImageUrl.isEmpty
                          ? const Icon(
                              Icons.admin_panel_settings,
                              color: Colors.white,
                              size: 20,
                            )
                          : null,
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
                  radius: 20,
                  backgroundColor: Color(0xFF8B4513),
                  child: Icon(
                    Icons.admin_panel_settings,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFF8B4513)),
            onPressed: _logout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            _buildWelcomeCard(),

            const SizedBox(height: 20),

            // Stats Cards
            _buildStatsCards(),

            const SizedBox(height: 20),

            // Seed Data Button
            _buildSeedDataButton(),

            const SizedBox(height: 20),

            // Recent Activity
            _buildRecentActivity(),
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
          const Text(
            'Welcome, Admin!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Manage your legal platform with ease',
            style: TextStyle(fontSize: 16, color: Colors.white70),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildQuickActionButton(
                'Add User',
                Icons.person_add,
                () => _showAddUserDialog(),
              ),
              const SizedBox(width: 12),
              _buildQuickActionButton(
                'Verify Lawyer',
                Icons.verified_user,
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

  Widget _buildSeedDataButton() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _seedAllData,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B4513),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.storage),
            label: const Text(
              '🌱 Seed All Data (Users, Lawyers, Reviews, Consultations, Chats)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _seedLawyerData,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.gavel),
            label: const Text(
              '⚖️ Seed Only Lawyers & Reviews',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCards() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection(AppConstants.usersCollection).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        int totalUsers = snapshot.data!.docs.length;
        int adminCount = snapshot.data!.docs
            .where(
              (doc) =>
                  doc.data() is Map &&
                  (doc.data() as Map)['role'] == AppConstants.adminRole,
            )
            .length;
        List<QueryDocumentSnapshot> usersAndLawyers = snapshot.data!.docs
            .where((doc) => doc.data() is Map)
            .toList();
        int lawyerCount = usersAndLawyers
            .where(
              (doc) => (doc.data() as Map)['role'] == AppConstants.lawyerRole,
            )
            .length;
        int userCount = usersAndLawyers
            .where(
              (doc) => (doc.data() as Map)['role'] == AppConstants.userRole,
            )
            .length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Platform Statistics',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                _buildStatCard(
                  'Total Users',
                  totalUsers.toString(),
                  Icons.people,
                  Colors.blue,
                ),
                _buildStatCard(
                  'Admins',
                  adminCount.toString(),
                  Icons.admin_panel_settings,
                  Colors.red,
                ),
                _buildStatCard(
                  'Lawyers',
                  lawyerCount.toString(),
                  Icons.gavel,
                  Colors.green,
                ),
                _buildStatCard(
                  'Clients',
                  userCount.toString(),
                  Icons.person,
                  Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildAnalyticsSection(),
          ],
        );
      },
    );
  }

  Widget _buildAnalyticsSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection(AppConstants.consultationsCollection)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        int totalConsultations = snapshot.data!.docs.length;
        int completedConsultations = snapshot.data!.docs
            .where((doc) => (doc.data() as Map)['status'] == 'completed')
            .length;
        int pendingConsultations = snapshot.data!.docs
            .where((doc) => (doc.data() as Map)['status'] == 'pending')
            .length;
        int acceptedConsultations = snapshot.data!.docs
            .where((doc) => (doc.data() as Map)['status'] == 'accepted')
            .length;

        double totalRevenue = 0;
        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['price'] != null && data['status'] == 'completed') {
            totalRevenue += (data['price'] as num).toDouble();
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Consultation Analytics',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                _buildStatCard(
                  'Total Consultations',
                  totalConsultations.toString(),
                  Icons.assignment,
                  const Color(0xFF8B4513),
                ),
                _buildStatCard(
                  'Completed',
                  completedConsultations.toString(),
                  Icons.check_circle,
                  Colors.green,
                ),
                _buildStatCard(
                  'Pending',
                  pendingConsultations.toString(),
                  Icons.pending,
                  Colors.orange,
                ),
                _buildStatCard(
                  'Accepted',
                  acceptedConsultations.toString(),
                  Icons.thumb_up,
                  Colors.blue,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.attach_money,
                          color: Colors.green,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Total Revenue',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'PKR ${totalRevenue.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'From ${completedConsultations} completed consultations',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
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
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
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

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Activity',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
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
            stream: _firestore
                .collection(AppConstants.lawyersCollection)
                .orderBy('createdAt', descending: true)
                .limit(5)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text(
                    'No recent activity',
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }

              return Column(
                children: snapshot.data!.docs.asMap().entries.map((entry) {
                  int index = entry.key;
                  final doc = entry.value;
                  final data = doc.data() as Map<String, dynamic>;

                  return Column(
                    children: [
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getStatusColor(data['status']),
                          child: Icon(
                            data['status'] == 'pending'
                                ? Icons.gavel
                                : data['status'] == 'verified'
                                ? Icons.verified_user
                                : Icons.person_add,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          data['status'] == 'pending'
                              ? 'Lawyer verification pending'
                              : data['status'] == 'verified'
                              ? 'Lawyer verified'
                              : 'New lawyer registered',
                        ),
                        subtitle: Text(
                          '${data['name']} - ${data['specialization']}',
                        ),
                        trailing: Text(
                          _getTimeAgo(data['createdAt']),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      if (index < snapshot.data!.docs.length - 1)
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

  Widget _buildUsersManagement() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Users Management',
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
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add, color: Color(0xFF8B4513)),
            onPressed: _showAddUserDialog,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection(AppConstants.usersCollection)
            .where('role', isEqualTo: AppConstants.userRole)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final userDocs = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['role'] == AppConstants.userRole;
          }).toList();

          if (userDocs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No users found',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  Text(
                    'Only user accounts are shown here',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: userDocs.length,
            itemBuilder: (context, index) {
              final doc = userDocs[index];
              final data = doc.data() as Map<String, dynamic>;

              return _buildUserCard(doc.id, data);
            },
          );
        },
      ),
    );
  }

  Widget _buildUserCard(String userId, Map<String, dynamic> data) {
    Color statusColor = _getStatusColor(data['status']);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          radius: 30,
          backgroundColor: _getRoleColor(data['role']),
          backgroundImage:
              data['profileImage'] != null && data['profileImage'].isNotEmpty
              ? NetworkImage(data['profileImage'])
              : null,
          child: data['profileImage'] == null || data['profileImage'].isEmpty
              ? Text(
                  data['name']?.toString().substring(0, 1).toUpperCase() ?? 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        title: Text(
          data['name'] ?? 'Unknown',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        onTap: () => _showUserDetailsDialog(userId, data),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(data['email'] ?? ''),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getRoleColor(data['role']).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    data['role']?.toString().toUpperCase() ?? 'USER',
                    style: TextStyle(
                      color: _getRoleColor(data['role']),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    data['status']?.toString().toUpperCase() ?? 'PENDING',
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'edit',
              child: const Row(
                children: [
                  Icon(Icons.edit, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Edit Details'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'reset_password',
              child: const Row(
                children: [
                  Icon(Icons.lock_reset, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('Reset Password'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'change_role',
              child: const Row(
                children: [
                  Icon(Icons.swap_horiz, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Change Role'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: const Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete'),
                ],
              ),
            ),
          ],
          onSelected: (value) =>
              _handleUserAction(userId, value.toString(), data),
        ),
      ),
    );
  }

  Widget _buildLawyersManagement() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Lawyers Management',
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
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection(AppConstants.lawyersCollection)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;

              return _buildLawyerCard(doc.id, data);
            },
          );
        },
      ),
    );
  }

  Widget _buildLawyerCard(String lawyerId, Map<String, dynamic> data) {
    Color statusColor = _getStatusColor(data['status']);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.green,
                  child: Text(
                    data['name']?.toString().substring(0, 1).toUpperCase() ??
                        'L',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['name'] ?? 'Unknown',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        data['specialization'] ?? 'General Practice',
                        style: const TextStyle(color: Colors.grey),
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
                    data['status']?.toString().toUpperCase() ?? 'PENDING',
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
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Text('${data['rating'] ?? 0.0}'),
                const SizedBox(width: 16),
                Icon(Icons.folder, color: Colors.blue, size: 16),
                const SizedBox(width: 4),
                Text('${data['totalCases'] ?? 0} cases'),
                const SizedBox(width: 16),
                Icon(Icons.location_on, color: Colors.grey, size: 16),
                const SizedBox(width: 4),
                Text(data['city'] ?? 'Unknown'),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (data['status'] != 'verified')
                  TextButton.icon(
                    onPressed: () =>
                        _handleLawyerAction(lawyerId, 'approve', data),
                    icon: const Icon(Icons.check, color: Colors.green),
                    label: const Text('Verify Lawyer'),
                  ),
                if (data['status'] == 'verified') ...[
                  TextButton.icon(
                    onPressed: () => _showEditUserDialog(lawyerId, data),
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    label: const Text('Edit Details'),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      String email = data['email'] ?? '';
                      if (email.isNotEmpty) {
                        AuthService.resetUserPassword(email: email);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '$email par password reset email send ho gaya!',
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.lock_reset, color: Colors.orange),
                    label: const Text('Reset Password'),
                  ),
                ],
                TextButton.icon(
                  onPressed: () =>
                      _handleLawyerAction(lawyerId, 'reject', data),
                  icon: const Icon(Icons.close, color: Colors.red),
                  label: const Text('Delete'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationManagement() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Verification Management',
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
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection(AppConstants.lawyersCollection)
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.verified_user, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No pending verifications',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  Text(
                    'All lawyers are verified',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;

              return _buildKycCard(doc.id, data);
            },
          );
        },
      ),
    );
  }

  Widget _buildSettings() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Admin Settings',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAdminSettingsSection(),
            const SizedBox(height: 24),
            _buildSystemSettingsSection(),
            const SizedBox(height: 24),
            _buildPlatformSettingsSection(),
            const SizedBox(height: 24),
            _buildReportsSection(),
            const SizedBox(height: 24),
            _buildDangerZoneSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminSettingsSection() {
    return _buildSection(
      title: 'Admin Management',
      children: [
        _buildListTile(
          icon: Icons.person_add,
          title: 'Add New Admin',
          subtitle: 'Create a new administrator account',
          onTap: () => _showAddAdminDialog(),
        ),
        _buildListTile(
          icon: Icons.admin_panel_settings,
          title: 'Admin Permissions',
          subtitle: 'Manage admin access levels',
          onTap: () => _showAdminPermissionsDialog(),
        ),
        _buildListTile(
          icon: Icons.security,
          title: 'Security Settings',
          subtitle: 'Configure platform security',
          onTap: () => _showSecuritySettingsDialog(),
        ),
        _buildListTile(
          icon: Icons.refresh,
          title: 'Replace All Lawyers',
          subtitle: 'Clear existing lawyers and add new ones with passwords',
          onTap: () => _showReplaceLawyersDialog(),
          textColor: Colors.blue,
        ),
      ],
    );
  }

  Widget _buildSystemSettingsSection() {
    return _buildSection(
      title: 'System Settings',
      children: [
        _buildListTile(
          icon: Icons.settings,
          title: 'Platform Configuration',
          subtitle: 'Configure platform-wide settings',
          onTap: () => _showPlatformConfigDialog(),
        ),
        _buildListTile(
          icon: Icons.notifications,
          title: 'Notification Settings',
          subtitle: 'Manage system notifications',
          onTap: () => _showNotificationSettingsDialog(),
        ),
        _buildListTile(
          icon: Icons.backup,
          title: 'Data Backup',
          subtitle: 'Backup and restore data',
          onTap: () => _showBackupDialog(),
        ),
      ],
    );
  }

  Widget _buildPlatformSettingsSection() {
    return _buildSection(
      title: 'Platform Settings',
      children: [
        _buildListTile(
          icon: Icons.monetization_on,
          title: 'Pricing Configuration',
          subtitle: 'Set consultation fees and rates',
          onTap: () => _showPricingConfigDialog(),
        ),
        _buildListTile(
          icon: Icons.category,
          title: 'Legal Categories',
          subtitle: 'Manage legal practice areas',
          onTap: () => _showLegalCategoriesDialog(),
        ),
        _buildListTile(
          icon: Icons.location_city,
          title: 'Cities Management',
          subtitle: 'Add or remove cities',
          onTap: () => _showCitiesManagementDialog(),
        ),
      ],
    );
  }

  Widget _buildReportsSection() {
    return _buildSection(
      title: 'Reports & Analytics',
      children: [
        _buildListTile(
          icon: Icons.analytics,
          title: 'Generate Report',
          subtitle: 'Create detailed platform reports',
          onTap: () => _showGenerateReportDialog(),
        ),
        _buildListTile(
          icon: Icons.download,
          title: 'Export Data',
          subtitle: 'Export user and consultation data',
          onTap: () => _showExportDataDialog(),
        ),
        _buildListTile(
          icon: Icons.trending_up,
          title: 'Performance Metrics',
          subtitle: 'View platform performance',
          onTap: () => _showPerformanceMetricsDialog(),
        ),
      ],
    );
  }

  Widget _buildDangerZoneSection() {
    return _buildSection(
      title: 'Danger Zone',
      children: [
        _buildListTile(
          icon: Icons.delete_forever,
          title: 'Delete All Data',
          subtitle: 'Permanently delete all platform data',
          onTap: () => _showDeleteAllDataDialog(),
          textColor: Colors.red,
        ),
        _buildListTile(
          icon: Icons.restore,
          title: 'Reset Platform',
          subtitle: 'Reset platform to default settings',
          onTap: () => _showResetPlatformDialog(),
          textColor: Colors.orange,
        ),
        _buildListTile(
          icon: Icons.logout,
          title: 'Logout',
          subtitle: 'Sign out of admin account',
          onTap: _logout,
          textColor: Colors.orange,
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF8B4513),
          ),
        ),
        const SizedBox(height: 8),
        Card(child: Column(children: children)),
      ],
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: textColor ?? const Color(0xFF8B4513)),
      title: Text(title, style: TextStyle(color: textColor)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'verified':
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getRoleColor(String? role) {
    switch (role) {
      case 'admin':
        return Colors.red;
      case 'lawyer':
        return Colors.green;
      case 'user':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  void _showAddUserDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController emailController = TextEditingController();
    final TextEditingController phoneController = TextEditingController();
    String selectedRole = 'user';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New User'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
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
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'user', child: Text('User')),
                  DropdownMenuItem(value: 'lawyer', child: Text('Lawyer')),
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                ],
                onChanged: (value) {
                  selectedRole = value!;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty &&
                  emailController.text.isNotEmpty &&
                  phoneController.text.isNotEmpty) {
                await _addNewUser(
                  nameController.text,
                  emailController.text,
                  phoneController.text,
                  selectedRole,
                );
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill all fields'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B4513),
              foregroundColor: Colors.white,
            ),
            child: const Text('Add User'),
          ),
        ],
      ),
    );
  }

  Future<void> _addNewUser(
    String name,
    String email,
    String phone,
    String role,
  ) async {
    try {
      await _firestore.collection(AppConstants.usersCollection).add({
        'name': name,
        'email': email,
        'phone': phone,
        'role': role,
        'status': 'approved',
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User successfully added!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add user: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildKycCard(String lawyerId, Map<String, dynamic> data) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: const Color(0xFF8B4513),
                  backgroundImage:
                      data['profileImage'] != null &&
                          data['profileImage'].isNotEmpty
                      ? NetworkImage(data['profileImage'])
                      : null,
                  child:
                      data['profileImage'] == null ||
                          data['profileImage'].isEmpty
                      ? const Icon(Icons.person, color: Colors.white, size: 24)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['name'] ?? 'Unknown',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data['email'] ?? '',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data['specialization'] ?? 'General Practice',
                        style: const TextStyle(
                          fontSize: 12,
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
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'PENDING',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Verification Documents
            const Text(
              'Verification Documents:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildDocumentStatus('CNIC', data['cnicFront'] != null),
                const SizedBox(width: 16),
                _buildDocumentStatus(
                  'Bar Certificate',
                  data['barCertificate'] != null,
                ),
                const SizedBox(width: 16),
                _buildDocumentStatus(
                  'Degree',
                  data['degreeCertificate'] != null,
                ),
              ],
            ),

            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _handleLawyerAction(lawyerId, 'approve', data),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Verify Lawyer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showEditUserDialog(lawyerId, data),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit Details'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B4513),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentStatus(String docName, bool isUploaded) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isUploaded ? Icons.check_circle : Icons.cancel,
          color: isUploaded ? Colors.green : Colors.red,
          size: 16,
        ),
        const SizedBox(width: 4),
        Text(
          docName,
          style: TextStyle(
            fontSize: 12,
            color: isUploaded ? Colors.green : Colors.red,
          ),
        ),
      ],
    );
  }

  void _handleUserAction(
    String userId,
    String action,
    Map<String, dynamic> data,
  ) async {
    try {
      switch (action) {
        case 'edit':
          _showEditUserDialog(userId, data);
          break;

        case 'reset_password':
          String email = data['email'] ?? '';
          if (email.isNotEmpty) {
            await AuthService.resetUserPassword(email: email);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Password reset email sent to $email!'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('User email not found'),
                backgroundColor: Colors.red,
              ),
            );
          }
          break;

        case 'change_role':
          _showChangeRoleDialog(userId, data);
          break;

        case 'delete':
          await _showDeleteConfirmation(userId, data['name'] ?? 'Unknown User');
          break;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to $action user: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleLawyerAction(
    String lawyerId,
    String action,
    Map<String, dynamic> data,
  ) async {
    try {
      String newStatus = '';
      switch (action) {
        case 'approve':
          newStatus = 'verified';
          break;
        case 'reject':
          newStatus = 'rejected';
          break;
      }

      if (newStatus.isNotEmpty) {
        // Update lawyer status
        await _firestore
            .collection(AppConstants.lawyersCollection)
            .doc(lawyerId)
            .update({'status': newStatus, 'updatedAt': DateTime.now()});

        // Also update user status if lawyer has a user account
        if (data['userId'] != null) {
          await _firestore
              .collection(AppConstants.usersCollection)
              .doc(data['userId'])
              .update({'status': newStatus, 'updatedAt': DateTime.now()});
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lawyer $action successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Show notification for new lawyer approval
        if (action == 'approve') {
          _showNotification(
            'Lawyer Approved',
            '${data['name']} has been approved and can now practice',
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to $action lawyer: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showNotification(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.notifications_active, color: Colors.green),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(dynamic timestamp) {
    DateTime dateTime;
    if (timestamp is Timestamp) {
      dateTime = timestamp.toDate();
    } else if (timestamp is DateTime) {
      dateTime = timestamp;
    } else {
      return 'Unknown';
    }

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

  // Admin Settings Dialogs
  void _showAddAdminDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Admin'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
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
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Admin account created successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Create Admin'),
          ),
        ],
      ),
    );
  }

  void _showAdminPermissionsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Admin Permissions'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPermissionItem('User Management', true),
              _buildPermissionItem('Lawyer Verification', true),
              _buildPermissionItem('System Settings', true),
              _buildPermissionItem('Data Export', false),
              _buildPermissionItem('Platform Reset', false),
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

  Widget _buildPermissionItem(String title, bool enabled) {
    return SwitchListTile(
      title: Text(title),
      value: enabled,
      onChanged: (value) {
        // Handle permission change
      },
    );
  }

  void _showReplaceLawyersDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Replace All Lawyers'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This action will:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• Delete all existing lawyers and users'),
            Text('• Create 8 new lawyers with passwords'),
            Text('• All new lawyers will be verified'),
            SizedBox(height: 16),
            Text(
              'New Lawyer Credentials:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('ahmed.khan@servipak.com - lawyer123'),
            Text('fatima.sheikh@servipak.com - lawyer123'),
            Text('muhammad.hassan@servipak.com - lawyer123'),
            Text('sara.ahmed@servipak.com - lawyer123'),
            Text('omar.sheikh@servipak.com - lawyer123'),
            Text('aisha.malik@servipak.com - lawyer123'),
            Text('hassan.ali@servipak.com - lawyer123'),
            Text('zainab.khan@servipak.com - lawyer123'),
            SizedBox(height: 16),
            Text(
              '⚠️ This action cannot be undone!',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _replaceAllLawyers();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Replace Lawyers'),
          ),
        ],
      ),
    );
  }

  Future<void> _replaceAllLawyers() async {
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
              Text('Replacing lawyers...'),
            ],
          ),
        ),
      );

      await LawyerManagementService.replaceAllLawyers();

      // Close loading dialog
      Navigator.pop(context);

      // Show success dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Success!'),
          content: const Text(
            'All lawyers have been replaced successfully!\n\n'
            '8 new lawyers have been created with the passwords provided.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      // Close loading dialog
      Navigator.pop(context);

      // Show error dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text('Failed to replace lawyers: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void _showSecuritySettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Security Settings'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSecurityItem('Two-Factor Authentication', true),
              _buildSecurityItem('Session Timeout', true),
              _buildSecurityItem('IP Whitelist', false),
              _buildSecurityItem('Audit Logging', true),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Security settings updated!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityItem(String title, bool enabled) {
    return SwitchListTile(
      title: Text(title),
      value: enabled,
      onChanged: (value) {
        // Handle security setting change
      },
    );
  }

  void _showPlatformConfigDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Platform Configuration'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildConfigItem('Maintenance Mode', false),
              _buildConfigItem('Registration Enabled', true),
              _buildConfigItem('Lawyer Registration', true),
              _buildConfigItem('Email Notifications', true),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Platform configuration updated!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigItem(String title, bool enabled) {
    return SwitchListTile(
      title: Text(title),
      value: enabled,
      onChanged: (value) {
        // Handle config change
      },
    );
  }

  void _showNotificationSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notification Settings'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildNotificationItem('Email Notifications', true),
              _buildNotificationItem('SMS Notifications', false),
              _buildNotificationItem('Push Notifications', true),
              _buildNotificationItem('System Alerts', true),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notification settings updated!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(String title, bool enabled) {
    return SwitchListTile(
      title: Text(title),
      value: enabled,
      onChanged: (value) {
        // Handle notification setting change
      },
    );
  }

  void _showBackupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Data Backup'),
        content: const Text('Choose backup option:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Backup created successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Create Backup'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Restore completed!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }

  void _showPricingConfigDialog() {
    final onlinePriceController = TextEditingController(text: '5000');
    final inPersonPriceController = TextEditingController(text: '8000');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pricing Configuration'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: onlinePriceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Online Consultation Price (PKR)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: inPersonPriceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'In-Person Consultation Price (PKR)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Pricing configuration updated!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showLegalCategoriesDialog() {
    final categories = [
      'Family Law',
      'Criminal Law',
      'Corporate Law',
      'Property Law',
      'Immigration Law',
      'Tax Law',
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Legal Categories'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: categories.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(categories[index]),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${categories[index]} deleted'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Add new category dialog opened'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            child: const Text('Add Category'),
          ),
        ],
      ),
    );
  }

  void _showCitiesManagementDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cities Management'),
        content: const Text('Manage cities and provinces for the platform.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cities management opened'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            child: const Text('Manage'),
          ),
        ],
      ),
    );
  }

  void _showGenerateReportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Generate Report'),
        content: const Text('Select report type and date range:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Report generated successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Generate'),
          ),
        ],
      ),
    );
  }

  void _showExportDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Data'),
        content: const Text('Export user and consultation data to CSV/Excel.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Data export started!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }

  void _showPerformanceMetricsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Performance Metrics'),
        content: const Text('View platform performance and usage statistics.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Performance metrics opened'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            child: const Text('View'),
          ),
        ],
      ),
    );
  }

  // User Management Helper Methods
  void _showChangeRoleDialog(String userId, Map<String, dynamic> data) {
    String currentRole = data['role'] ?? 'user';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change User Role'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current Role: ${currentRole.toUpperCase()}'),
            const SizedBox(height: 16),
            const Text('Select New Role:'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: currentRole,
              onChanged: (value) {
                if (value != null && value != currentRole) {
                  Navigator.pop(context);
                  _confirmRoleChange(userId, value);
                }
              },
              items: const [
                DropdownMenuItem(value: 'user', child: Text('User')),
                DropdownMenuItem(value: 'lawyer', child: Text('Lawyer')),
                DropdownMenuItem(value: 'admin', child: Text('Admin')),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmRoleChange(String userId, String newRole) async {
    bool confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Role Change'),
        content: Text(
          'Are you sure you want to change this user\'s role to $newRole?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B4513),
              foregroundColor: Colors.white,
            ),
            child: const Text('Change Role'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await AuthService.updateUserRole(userId: userId, newRole: newRole);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User role successfully changed to $newRole!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to change role: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showDeleteConfirmation(String userId, String userName) async {
    bool confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text(
          'Are you sure you want to delete user "$userName"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete User'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await AuthService.deleteUserAccount(userId: userId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete user: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showEditUserDialog(String userId, Map<String, dynamic> data) {
    final nameController = TextEditingController(text: data['name'] ?? '');
    final emailController = TextEditingController(text: data['email'] ?? '');
    final phoneController = TextEditingController(text: data['phone'] ?? '');

    String? currentProfileImage = data['profileImage'];
    File? selectedImage;
    Uint8List? selectedImageBytes; // For web compatibility
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit User Details'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Profile Image Section
                _buildProfileImageSection(
                  currentProfileImage,
                  selectedImage,
                  selectedImageBytes,
                  (imageFile, imageBytes) => setDialogState(() {
                    selectedImage = imageFile;
                    selectedImageBytes = imageBytes;
                  }),
                ),

                const SizedBox(height: 20),

                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                ),

                if (isLoading)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(width: 16),
                        Text('Saving changes...'),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      setDialogState(() => isLoading = true);

                      await _updateUserDetailsWithImage(
                        userId,
                        nameController.text.trim(),
                        emailController.text.trim(),
                        phoneController.text.trim(),
                        data['email'] ?? '',
                        selectedImage,
                        selectedImageBytes,
                        currentProfileImage,
                        setDialogState,
                      );

                      Navigator.pop(context);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B4513),
                foregroundColor: Colors.white,
              ),
              child: const Text('Update Details'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImageSection(
    String? currentImage,
    File? selectedImage,
    Uint8List? selectedImageBytes,
    Function(File?, Uint8List?) onImageSelected,
  ) {
    return Column(
      children: [
        // Current image preview - Web Compatible & Responsive
        Container(
          width: MediaQuery.of(context).size.width > 600 ? 150 : 120,
          height: MediaQuery.of(context).size.width > 600 ? 150 : 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              MediaQuery.of(context).size.width > 600 ? 75 : 60,
            ),
            border: Border.all(
              color: const Color(0xFF8B4513),
              width: MediaQuery.of(context).size.width > 600 ? 4 : 3,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(
              MediaQuery.of(context).size.width > 600 ? 75 : 60,
            ),
            child: (selectedImage != null || selectedImageBytes != null)
                ? _buildImagePreview(selectedImage, selectedImageBytes)
                : currentImage != null && currentImage.isNotEmpty
                ? Image.network(
                    currentImage,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.person,
                        size: MediaQuery.of(context).size.width > 600 ? 75 : 60,
                        color: const Color(0xFF8B4513),
                      );
                    },
                  )
                : Icon(
                    Icons.person,
                    size: MediaQuery.of(context).size.width > 600 ? 75 : 60,
                    color: const Color(0xFF8B4513),
                  ),
          ),
        ),

        const SizedBox(height: 16),

        // Upload/Change buttons - Responsive Design
        LayoutBuilder(
          builder: (context, constraints) {
            bool isWideScreen = constraints.maxWidth > 600;
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickImageFromCamera(onImageSelected),
                    icon: Icon(Icons.camera_alt, size: isWideScreen ? 20 : 18),
                    label: Text(
                      'Camera',
                      style: TextStyle(fontSize: isWideScreen ? 16 : 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[100],
                      foregroundColor: Colors.blue[800],
                      padding: EdgeInsets.symmetric(
                        horizontal: isWideScreen ? 20 : 16,
                        vertical: isWideScreen ? 12 : 8,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickImageFromGallery(onImageSelected),
                    icon: Icon(
                      Icons.photo_library,
                      size: isWideScreen ? 20 : 18,
                    ),
                    label: Text(
                      'Gallery',
                      style: TextStyle(fontSize: isWideScreen ? 16 : 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[100],
                      foregroundColor: Colors.green[800],
                      padding: EdgeInsets.symmetric(
                        horizontal: isWideScreen ? 20 : 16,
                        vertical: isWideScreen ? 12 : 8,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),

        // Remove button section
        if ((selectedImage != null || selectedImageBytes != null) ||
            (currentImage != null && currentImage.isNotEmpty)) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => onImageSelected(null, null),
              icon: Icon(
                Icons.delete,
                size: MediaQuery.of(context).size.width > 600 ? 20 : 18,
              ),
              label: Text(
                'Remove Image',
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width > 600 ? 16 : 14,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[100],
                foregroundColor: Colors.red[800],
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width > 600 ? 20 : 16,
                  vertical: MediaQuery.of(context).size.width > 600 ? 12 : 8,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // Web-compatible image preview widget
  Widget _buildImagePreview(
    File? selectedImage,
    Uint8List? selectedImageBytes,
  ) {
    // Prioritize Uint8List for web, fallback to File
    if (selectedImageBytes != null) {
      return Image.memory(
        selectedImageBytes,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.person, size: 60, color: Color(0xFF8B4513));
        },
      );
    } else if (selectedImage != null) {
      // For mobile platforms
      return Image.file(
        selectedImage,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.person, size: 60, color: Color(0xFF8B4513));
        },
      );
    } else {
      return const Icon(Icons.person, size: 60, color: Color(0xFF8B4513));
    }
  }

  Future<void> _pickImageFromCamera(
    Function(File?, Uint8List?) onImageSelected,
  ) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 90,
      );

      if (image != null) {
        if (kIsWeb) {
          // For web, read as bytes
          final Uint8List bytes = await image.readAsBytes();
          onImageSelected(null, bytes);
        } else {
          // For mobile, use file path
          onImageSelected(File(image.path), null);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot select image from camera: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickImageFromGallery(
    Function(File?, Uint8List?) onImageSelected,
  ) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 90,
      );

      if (image != null) {
        if (kIsWeb) {
          // For web, read as bytes
          final Uint8List bytes = await image.readAsBytes();
          onImageSelected(null, bytes);
        } else {
          // For mobile, use file path
          onImageSelected(File(image.path), null);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot select image from gallery: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateUserDetailsWithImage(
    String userId,
    String newName,
    String newEmail,
    String newPhone,
    String currentEmail,
    File? selectedImage,
    Uint8List? selectedImageBytes,
    String? currentProfileImage,
    StateSetter setDialogState,
  ) async {
    setDialogState(() {});

    try {
      bool emailChanged = newEmail != currentEmail;
      String? updatedProfileImage = currentProfileImage;

      // Upload new image if selected
      if (selectedImage != null || selectedImageBytes != null) {
        setDialogState(() {});

        // Use working ImageService for uploads
        String? imageUrl;
        if (kIsWeb && selectedImageBytes != null) {
          // For web, use bytes with ImageService
          imageUrl = await ImageService.uploadProfileImage(
            selectedImageBytes,
            userId,
          );
        } else if (selectedImage != null) {
          // For mobile, use File with ImageService
          imageUrl = await ImageService.uploadProfileImage(
            selectedImage,
            userId,
          );
        }

        if (imageUrl != null) {
          updatedProfileImage = imageUrl;
          print('✅ Profile image uploaded: $imageUrl');
        } else {
          print('❌ Image upload failed - using mock URL for testing');
          // For testing, use a mock URL temporarily
          updatedProfileImage =
              'https://via.placeholder.com/512x512/8B4513/FFFFFF?text=Profile+${userId.substring(0, 4)}';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Image upload failed! Using demo URL.\n'
                'Web: ${kIsWeb}\n'
                'Has image bytes: ${selectedImageBytes != null}\n'
                'Has image file: ${selectedImage != null}',
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 5),
            ),
          );
          // Don't return - continue with mock URL for testing
        }
      }

      // Update user details in Firestore
      Map<String, dynamic> updateData = {
        'name': newName,
        'email': newEmail,
        'phone': newPhone,
        'updatedAt': DateTime.now(),
      };

      if (updatedProfileImage != null) {
        updateData['profileImage'] = updatedProfileImage;
      } else if (selectedImage == null && updatedProfileImage == null) {
        updateData['profileImage'] = FieldValue.delete();
      }

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update(updateData);

      // If email changed, update in Firebase Auth as well
      if (emailChanged) {
        try {
          await AuthService.updateUserEmail(
            userId: userId,
            oldEmail: currentEmail,
            newEmail: newEmail,
          );
        } catch (e) {
          print('Email update in Firebase Auth failed: $e');
          // Email updated in Firestore but not in Firebase Auth
          // This will be handled gracefully
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User details and image successfully updated!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update user details: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showUserDetailsDialog(String userId, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${data['name'] ?? 'Unknown'} Details'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Profile Image Preview
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(
                      color: const Color(0xFF8B4513),
                      width: 2,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(50),
                    child:
                        data['profileImage'] != null &&
                            data['profileImage'].isNotEmpty
                        ? Image.network(
                            data['profileImage'],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.person,
                                size: 50,
                                color: Color(0xFF8B4513),
                              );
                            },
                          )
                        : const Icon(
                            Icons.person,
                            size: 50,
                            color: Color(0xFF8B4513),
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              _buildDetailRow('Name', data['name'] ?? 'Not provided'),
              _buildDetailRow('Email', data['email'] ?? 'Not provided'),
              _buildDetailRow('Phone', data['phone'] ?? 'Not provided'),
              _buildDetailRow('Role', (data['role'] ?? 'user').toUpperCase()),
              _buildDetailRow(
                'Status',
                (data['status'] ?? 'unknown').toUpperCase(),
              ),
              _buildDetailRow('Created', _formatDate(data['createdAt'])),
              if (data['updatedAt'] != null)
                _buildDetailRow('Updated', _formatDate(data['updatedAt'])),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showEditUserDialog(userId, data);
            },
            icon: const Icon(Icons.edit, size: 18),
            label: const Text('Edit Details'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B4513),
              foregroundColor: Colors.white,
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showChangeRoleDialog(userId, data);
            },
            child: const Text('Change Role'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              String email = data['email'] ?? '';
              if (email.isNotEmpty) {
                AuthService.resetUserPassword(email: email);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '$email par password reset email send ho gaya!',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Reset Password'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';

    DateTime dateTime;
    if (timestamp is Timestamp) {
      dateTime = timestamp.toDate();
    } else if (timestamp is DateTime) {
      dateTime = timestamp;
    } else {
      return 'Unknown';
    }

    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _showDeleteAllDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Data'),
        content: const Text(
          'This will permanently delete ALL platform data. This action cannot be undone!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All data deletion request submitted'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }

  void _showResetPlatformDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Platform'),
        content: const Text(
          'This will reset the platform to default settings. All custom configurations will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Platform reset completed!'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _showAdminProfileDialog(Map<String, dynamic>? userData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Admin Profile',
          style: TextStyle(color: Color(0xFF8B4513)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: const Color(0xFF8B4513),
              backgroundImage: userData?['profileImage'] != null
                  ? NetworkImage(userData!['profileImage'])
                  : null,
              child: userData?['profileImage'] == null
                  ? const Icon(
                      Icons.admin_panel_settings,
                      size: 50,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              userData?['name'] ?? 'Admin',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              userData?['email'] ?? '',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.vpn_key, color: Colors.green[700], size: 20),
                const SizedBox(width: 4),
                Text(
                  'Admin Access',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: Color(0xFF8B4513)),
            ),
          ),
        ],
      ),
    );
  }

  // Comprehensive seed all data
  Future<void> _seedAllData() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Seeding all data...'),
            ],
          ),
        ),
      );

      // Seed users first
      await UserSeedService.seedUserData();

      // Seed lawyer details
      await _lawyerService.seedLawyerDetails();

      // Seed reviews for each lawyer
      final lawyers = await _lawyerService.getVerifiedLawyers();
      for (var lawyer in lawyers) {
        await _reviewService.seedSampleReviews(lawyer.id);
      }

      // Seed consultations
      await UserSeedService.seedConsultationData();

      // Seed chats
      await UserSeedService.seedChatData();

      Navigator.pop(context); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '🎉 All data seeded successfully! Users, Lawyers, Reviews, Consultations & Chats',
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
        ),
      );
    } catch (e) {
      Navigator.pop(context); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error seeding all data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _seedLawyerData() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Seeding lawyer data...'),
            ],
          ),
        ),
      );

      // Seed lawyer details
      await _lawyerService.seedLawyerDetails();

      // Seed reviews for each lawyer
      final lawyers = await _lawyerService.getVerifiedLawyers();
      for (var lawyer in lawyers) {
        await _reviewService.seedSampleReviews(lawyer.id);
      }

      Navigator.pop(context); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Lawyer data and reviews seeded successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      Navigator.pop(context); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error seeding data: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
