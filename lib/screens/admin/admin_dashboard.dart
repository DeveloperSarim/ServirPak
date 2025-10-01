import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../constants/app_constants.dart';
import '../../models/user_model.dart';
import '../../models/lawyer_model.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Users'),
          BottomNavigationBarItem(icon: Icon(Icons.gavel), label: 'Lawyers'),
          BottomNavigationBarItem(
            icon: Icon(Icons.verified_user),
            label: 'KYC',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
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
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
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
          colors: [Colors.deepPurple, Colors.purple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.3),
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
          child: const Column(
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green,
                  child: Icon(Icons.person_add, color: Colors.white),
                ),
                title: Text('New user registered'),
                subtitle: Text('Muhammad Hassan joined the platform'),
                trailing: Text(
                  '2 min ago',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
              Divider(),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Icon(Icons.gavel, color: Colors.white),
                ),
                title: Text('Lawyer verification pending'),
                subtitle: Text('Ahmed Ali Khan submitted KYC documents'),
                trailing: Text(
                  '1 hour ago',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
              Divider(),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.orange,
                  child: Icon(Icons.verified_user, color: Colors.white),
                ),
                title: Text('Lawyer verified'),
                subtitle: Text('Fatima Sheikh approved for practice'),
                trailing: Text(
                  '3 hours ago',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUsersManagement() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Users Management'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
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
      appBar: AppBar(
        title: const Text('Lawyers Management'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
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
      appBar: AppBar(
        title: const Text('KYC Management'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text(
          'KYC Management will be implemented here',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildSettings() {
    return FutureBuilder<UserModel?>(
      future: _getCurrentUser(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        return SettingsScreen(
          userRole: AppConstants.adminRole,
          user: snapshot.data,
        );
      },
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New User'),
        content: const Text('Add user functionality will be implemented here'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _handleUserAction(
    String userId,
    String action,
    Map<String, dynamic> data,
  ) {
    // Handle user actions (approve, reject, delete)
    print('User action: $action for user: $userId');
  }

  void _handleLawyerAction(
    String lawyerId,
    String action,
    Map<String, dynamic> data,
  ) {
    // Handle lawyer actions (approve, reject)
    print('Lawyer action: $action for lawyer: $lawyerId');
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
