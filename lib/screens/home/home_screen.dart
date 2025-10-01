import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../constants/app_constants.dart';
import '../admin/admin_dashboard.dart';
import '../lawyer/lawyer_dashboard.dart';
import '../user/user_dashboard.dart';
import '../auth/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _getUserRole();
  }

  Future<void> _getUserRole() async {
    print('🏠 HomeScreen: Getting user role...');
    try {
      var session = await AuthService.getSavedUserSession();
      print('🏠 HomeScreen: Session data: $session');

      if (session != null && session['userRole'] != null) {
        setState(() {
          _userRole = session['userRole'];
        });
        print('🏠 HomeScreen: User role set to: $_userRole');
      } else {
        print('❌ HomeScreen: No user role found in session');
        // If no role found, default to user role
        setState(() {
          _userRole = AppConstants.userRole;
        });
        print('🏠 HomeScreen: Defaulting to user role: $_userRole');
      }
    } catch (e) {
      print('❌ HomeScreen: Error getting user role: $e');
      // On error, default to user role
      setState(() {
        _userRole = AppConstants.userRole;
      });
      print(
        '🏠 HomeScreen: Error occurred, defaulting to user role: $_userRole',
      );
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_userRole == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return _buildBody();
  }

  Widget _buildBody() {
    print('🏠 HomeScreen: Building body for role: $_userRole');
    // Route to appropriate dashboard based on user role
    if (_userRole == AppConstants.adminRole) {
      print('🏠 HomeScreen: Routing to AdminDashboard');
      return const AdminDashboard();
    } else if (_userRole == AppConstants.lawyerRole) {
      print('🏠 HomeScreen: Routing to LawyerDashboard');
      return const LawyerDashboard();
    } else {
      print('🏠 HomeScreen: Routing to UserDashboard (default)');
      return const UserDashboard();
    }
  }

  List<BottomNavigationBarItem> _buildBottomNavItems() {
    // Return empty list since each dashboard has its own navigation
    return [];
  }

  Widget _buildDashboard() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
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
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    colors: [Colors.deepPurple, Colors.purple],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome to Servipak!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Role: ${_userRole?.toUpperCase() ?? 'Loading...'}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Quick Actions
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
              children: _buildQuickActionCards(),
            ),

            const SizedBox(height: 20),

            // Recent Activity
            const Text(
              'Recent Activity',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'No recent activity to show.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildQuickActionCards() {
    List<Map<String, dynamic>> actions = [];

    if (_userRole == AppConstants.adminRole) {
      actions = [
        {'title': 'Manage Users', 'icon': Icons.people, 'color': Colors.blue},
        {
          'title': 'Verify Lawyers',
          'icon': Icons.verified_user,
          'color': Colors.green,
        },
        {
          'title': 'View Reports',
          'icon': Icons.analytics,
          'color': Colors.orange,
        },
        {'title': 'Settings', 'icon': Icons.settings, 'color': Colors.grey},
      ];
    } else if (_userRole == AppConstants.lawyerRole) {
      actions = [
        {'title': 'My Cases', 'icon': Icons.folder, 'color': Colors.blue},
        {
          'title': 'Upload Documents',
          'icon': Icons.upload,
          'color': Colors.green,
        },
        {
          'title': 'Client Messages',
          'icon': Icons.message,
          'color': Colors.orange,
        },
        {'title': 'Profile', 'icon': Icons.person, 'color': Colors.purple},
      ];
    } else {
      actions = [
        {'title': 'Find Lawyers', 'icon': Icons.search, 'color': Colors.blue},
        {'title': 'My Cases', 'icon': Icons.folder, 'color': Colors.green},
        {'title': 'Messages', 'icon': Icons.message, 'color': Colors.orange},
        {'title': 'Help', 'icon': Icons.help, 'color': Colors.purple},
      ];
    }

    return actions.map((action) => _buildActionCard(action)).toList();
  }

  Widget _buildActionCard(Map<String, dynamic> action) {
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
              Icon(action['icon'], size: 32, color: action['color']),
              const SizedBox(height: 8),
              Text(
                action['title'],
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

  Widget _buildLawyers() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lawyers'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text(
          'Lawyers list will be implemented here',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildProfile() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text(
          'Profile screen will be implemented here',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
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
