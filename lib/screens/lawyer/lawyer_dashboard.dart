import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../constants/app_constants.dart';
import '../../models/user_model.dart';
import '../auth/login_screen.dart';
import '../settings/settings_screen.dart';

class LawyerDashboard extends StatefulWidget {
  const LawyerDashboard({super.key});

  @override
  State<LawyerDashboard> createState() => _LawyerDashboardState();
}

class _LawyerDashboardState extends State<LawyerDashboard> {
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
          BottomNavigationBarItem(icon: Icon(Icons.folder), label: 'My Cases'),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Messages'),
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
        return _buildMessages();
      case 3:
        return _buildDocuments();
      case 4:
        return _buildProfile();
      default:
        return _buildMainDashboard();
    }
  }

  Widget _buildMainDashboard() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lawyer Dashboard'),
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
          colors: [Colors.green, Colors.teal],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Welcome, Lawyer!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Manage your legal practice efficiently',
            style: TextStyle(fontSize: 16, color: Colors.white70),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildQuickActionButton(
                'New Case',
                Icons.add_circle,
                () => _showNewCaseDialog(),
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
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _buildStatCard('Active Cases', '12', Icons.folder, Colors.blue),
            _buildStatCard('Completed', '45', Icons.check_circle, Colors.green),
            _buildStatCard('Clients', '28', Icons.people, Colors.orange),
            _buildStatCard('Rating', '4.8', Icons.star, Colors.amber),
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
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
          children: [
            _buildActionCard(
              'Schedule Meeting',
              Icons.calendar_today,
              Colors.blue,
            ),
            _buildActionCard('Client Search', Icons.search, Colors.green),
            _buildActionCard('Case Notes', Icons.note, Colors.orange),
            _buildActionCard('Billing', Icons.payment, Colors.purple),
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
          // Handle action tap
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
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
        const Text(
          'Recent Cases',
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
          child: Column(
            children: [
              _buildCaseItem(
                'Criminal Defense',
                'State vs. John Doe',
                'Active',
                Colors.blue,
                '2 days ago',
              ),
              const Divider(),
              _buildCaseItem(
                'Family Law',
                'Divorce Settlement',
                'Pending',
                Colors.orange,
                '1 week ago',
              ),
              const Divider(),
              _buildCaseItem(
                'Property Dispute',
                'Land Ownership Case',
                'Completed',
                Colors.green,
                '2 weeks ago',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCaseItem(
    String type,
    String title,
    String status,
    Color statusColor,
    String time,
  ) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: statusColor.withOpacity(0.1),
        child: Icon(Icons.gavel, color: statusColor),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(type),
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
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                time,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        // Navigate to case details
      },
    );
  }

  Widget _buildMyCases() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Cases'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showNewCaseDialog,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCaseItem(
            'Criminal Defense',
            'State vs. John Doe',
            'Active',
            Colors.blue,
            '2 days ago',
          ),
          _buildCaseItem(
            'Family Law',
            'Divorce Settlement',
            'Pending',
            Colors.orange,
            '1 week ago',
          ),
          _buildCaseItem(
            'Property Dispute',
            'Land Ownership Case',
            'Completed',
            Colors.green,
            '2 weeks ago',
          ),
          _buildCaseItem(
            'Contract Law',
            'Business Agreement',
            'Active',
            Colors.blue,
            '3 weeks ago',
          ),
        ],
      ),
    );
  }

  Widget _buildMessages() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text(
          'Messages will be implemented here',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildDocuments() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Documents'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.upload),
            onPressed: _showUploadDialog,
          ),
        ],
      ),
      body: const Center(
        child: Text(
          'Document management will be implemented here',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
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
      if (session != null) {
        return await AuthService.getUserById(session['userId'] as String);
      }
      return null;
    } catch (e) {
      print('❌ Error getting current user: $e');
      return null;
    }
  }

  void _showNewCaseDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Case'),
        content: const Text('New case functionality will be implemented here'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showUploadDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upload Document'),
        content: const Text(
          'Document upload functionality will be implemented here',
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
