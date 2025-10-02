import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../constants/app_constants.dart';
import '../../models/user_model.dart';
import '../../models/lawyer_model.dart';
import '../../models/consultation_model.dart';
import '../auth/login_screen.dart';
import '../settings/settings_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
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
                label: 'KYC',
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
        return _buildKycManagement();
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
        int lawyerCount = snapshot.data!.docs
            .where(
              (doc) =>
                  doc.data() is Map &&
                  (doc.data() as Map)['role'] == AppConstants.lawyerRole,
            )
            .length;
        int userCount = snapshot.data!.docs
            .where(
              (doc) =>
                  doc.data() is Map &&
                  (doc.data() as Map)['role'] == AppConstants.userRole,
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
                  Colors.purple,
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
        stream: _firestore.collection(AppConstants.usersCollection).snapshots(),
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
          backgroundColor: _getRoleColor(data['role']),
          child: Text(
            data['name']?.toString().substring(0, 1).toUpperCase() ?? 'U',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          data['name'] ?? 'Unknown',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
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
              value: 'approve',
              child: const Row(
                children: [
                  Icon(Icons.check, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Approve'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'reject',
              child: const Row(
                children: [
                  Icon(Icons.close, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Reject'),
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
                TextButton.icon(
                  onPressed: () =>
                      _handleLawyerAction(lawyerId, 'approve', data),
                  icon: const Icon(Icons.check, color: Colors.green),
                  label: const Text('Approve'),
                ),
                TextButton.icon(
                  onPressed: () =>
                      _handleLawyerAction(lawyerId, 'reject', data),
                  icon: const Icon(Icons.close, color: Colors.red),
                  label: const Text('Reject'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKycManagement() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'KYC Management',
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
                    'No pending KYC verifications',
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

  Future<UserModel?> _getCurrentUser() async {
    try {
      final session = await AuthService.getSavedUserSession();
      if (session != null) {
        return await AuthService.getUserById(session['userId'] as String);
      }
      return null;
    } catch (e) {
      print('❌ Error getting current user: $e');
      return null;
    }
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
          content: Text('User added successfully'),
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

            // KYC Documents
            const Text(
              'KYC Documents:',
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
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _handleLawyerAction(lawyerId, 'reject', data),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Reject'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
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
      String newStatus = '';
      switch (action) {
        case 'approve':
          newStatus = 'approved';
          break;
        case 'reject':
          newStatus = 'rejected';
          break;
        case 'delete':
          await _firestore
              .collection(AppConstants.usersCollection)
              .doc(userId)
              .delete();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          return;
      }

      if (newStatus.isNotEmpty) {
        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(userId)
            .update({'status': newStatus, 'updatedAt': DateTime.now()});

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User $action successfully'),
            backgroundColor: Colors.green,
          ),
        );
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
