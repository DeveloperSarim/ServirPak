import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../services/consultation_service.dart';
import '../../services/demo_data_service.dart';
// import '../../services/chat_service.dart';
import '../../constants/app_constants.dart';
import '../../models/consultation_model.dart';
import '../../models/lawyer_model.dart';
import '../../models/user_model.dart';
import '../auth/login_screen.dart';
// import '../consultation/consultation_booking_screen.dart';
import 'user_chat_list_screen.dart';
import '../profile/user_profile_screen.dart';
import '../settings/settings_screen.dart';
import '../consultation/consultation_booking_screen.dart';

class UserDashboard extends StatefulWidget {
  const UserDashboard({super.key});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  int _selectedIndex = 0;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(),
      drawer: _buildDrawer(),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.menu, color: Color(0xFF8B4513)),
        onPressed: () {
          _scaffoldKey.currentState?.openDrawer();
        },
      ),
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
                margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFF8B4513),
                  backgroundImage:
                      profileImageUrl != null && profileImageUrl.isNotEmpty
                      ? NetworkImage(profileImageUrl)
                      : null,
                  child: profileImageUrl == null || profileImageUrl.isEmpty
                      ? const Icon(Icons.person, color: Colors.white, size: 24)
                      : null,
                ),
              );
            }
            return Container(
              margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
              child: const CircleAvatar(
                radius: 20,
                backgroundColor: Color(0xFF8B4513),
                child: Icon(Icons.person, color: Colors.white, size: 24),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: _getCurrentBottomNavIndex(),
      onTap: (index) {
        if (index == 0) {
          // Navigate to chats
          setState(() => _selectedIndex = 3);
        } else if (index == 1) {
          // Navigate to home
          setState(() => _selectedIndex = 0);
        } else if (index == 2) {
          // Navigate to profile
          setState(() => _selectedIndex = 4);
        }
      },
      selectedItemColor: const Color(0xFF8B4513),
      unselectedItemColor: Colors.grey,
      backgroundColor: Colors.white,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chats'),
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }

  int _getCurrentBottomNavIndex() {
    switch (_selectedIndex) {
      case 0:
        return 1; // Home
      case 3:
        return 0; // Chats
      case 4:
        return 2; // Profile
      default:
        return 1; // Default to Home
    }
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF8B4513), Color(0xFFA0522D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'ServirPak',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Legal Services Platform',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home, color: Color(0xFF8B4513)),
            title: const Text('Home'),
            onTap: () {
              Navigator.pop(context);
              setState(() => _selectedIndex = 0);
            },
          ),
          ListTile(
            leading: const Icon(Icons.search, color: Color(0xFF8B4513)),
            title: const Text('Find Lawyers'),
            onTap: () {
              Navigator.pop(context);
              setState(() => _selectedIndex = 1);
            },
          ),
          ListTile(
            leading: const Icon(Icons.folder, color: Color(0xFF8B4513)),
            title: const Text('My Cases'),
            onTap: () {
              Navigator.pop(context);
              setState(() => _selectedIndex = 2);
            },
          ),
          ListTile(
            leading: const Icon(Icons.message, color: Color(0xFF8B4513)),
            title: const Text('Messages'),
            onTap: () {
              Navigator.pop(context);
              setState(() => _selectedIndex = 3);
            },
          ),
          ListTile(
            leading: const Icon(Icons.person, color: Color(0xFF8B4513)),
            title: const Text('Profile'),
            onTap: () {
              Navigator.pop(context);
              setState(() => _selectedIndex = 4);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings, color: Color(0xFF8B4513)),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(userRole: 'user'),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout'),
            onTap: () {
              Navigator.pop(context);
              _logout();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildHome();
      case 1:
        return _buildFindLawyers();
      case 2:
        return _buildMyCases();
      case 3:
        return const UserChatListScreen();
      case 4:
        return const UserProfileScreen();
      default:
        return _buildHome();
    }
  }

  Widget _buildHome() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero Slider
          _buildHeroSlider(),
          const SizedBox(height: 20),

          // Greeting Section
          _buildGreetingSection(),
          const SizedBox(height: 20),

          // Search Bar
          _buildSearchSection(),
          const SizedBox(height: 20),

          // Categories Section
          _buildCategoriesSection(),
          const SizedBox(height: 20),

          // Qualified Lawyers Section
          _buildQualifiedLawyersSection(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHeroSlider() {
    return Container(
      height: 180,
      margin: const EdgeInsets.all(16),
      child: PageView.builder(
        itemCount: 3,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF8B4513), // Saddle Brown
                  Color(0xFFA0522D), // Sienna
                  Color(0xFF6B4423), // Dark Brown
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              children: [
                // Background Image Placeholder
                Positioned(
                  right: 12,
                  top: 16,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Need Consultation Now?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Consult our professional Lawyers',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: () {
                          setState(() => _selectedIndex = 1);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD4AF37), // Gold
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: const Text(
                          'Book Now',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGreetingSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: StreamBuilder<DocumentSnapshot>(
        stream: _firestore
            .collection(AppConstants.usersCollection)
            .doc(AuthService.currentUser?.uid ?? '')
            .snapshots(),
        builder: (context, snapshot) {
          String userName = 'User';
          if (snapshot.hasData && snapshot.data!.exists) {
            final userData = snapshot.data!.data() as Map<String, dynamic>?;
            userName = userData?['name'] as String? ?? 'User';
          }

          return Row(
            children: [
              Text(
                'Hello $userName | ',
                style: const TextStyle(
                  color: Color(0xFF8B4513),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Text(
                'Find your Consultant',
                style: TextStyle(
                  color: Color(0xFF8B4513),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onSubmitted: (value) {
                  _performSearch(value);
                },
                decoration: InputDecoration(
                  hintText: 'Search your expert',
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF8B4513),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () {
              _performSearch(_searchController.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B4513),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
            child: const Text(
              'Search',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Categories',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              TextButton(
                onPressed: () {
                  _showAllCategories();
                },
                child: const Text(
                  'All',
                  style: TextStyle(
                    color: Color(0xFF8B4513),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 6,
              itemBuilder: (context, index) {
                final categories = [
                  {
                    'name': 'Administrative Law',
                    'icon': Icons.gavel,
                    'color': Colors.red,
                  },
                  {
                    'name': 'Cannabis Law',
                    'icon': Icons.eco,
                    'color': Colors.green,
                  },
                  {
                    'name': 'Commercial Law',
                    'icon': Icons.attach_money,
                    'color': Colors.blue,
                  },
                  {
                    'name': 'Criminal Law',
                    'icon': Icons.security,
                    'color': Colors.orange,
                  },
                  {
                    'name': 'Family Law',
                    'icon': Icons.family_restroom,
                    'color': const Color(0xFF8B4513),
                  },
                  {
                    'name': 'Property Law',
                    'icon': Icons.home,
                    'color': Colors.teal,
                  },
                ];

                final category = categories[index];
                return Container(
                  width: 100,
                  margin: const EdgeInsets.only(right: 12),
                  child: Column(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          category['icon'] as IconData,
                          color: category['color'] as Color,
                          size: 30,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        category['name'] as String,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernActionCard(String title, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _handleActionCardTap(title);
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, size: 32, color: color),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C1810),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQualifiedLawyersSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Qualified Lawyers',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Row(
                children: [
                  _buildFilterChip('All', true),
                  const SizedBox(width: 8),
                  _buildFilterChip('Top Rated', false),
                  const SizedBox(width: 8),
                  _buildFilterChip('Featured', false),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection(AppConstants.lawyersCollection)
                  .where('status', isEqualTo: AppConstants.verifiedStatus)
                  .limit(5)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('No verified lawyers available'),
                  );
                }

                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    return _buildLawyerCard(data, index);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        _handleFilterChipTap(label);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF8B4513) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF8B4513) : Colors.grey,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildLawyerCard(Map<String, dynamic> data, int index) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Lawyer Image
              Container(
                height: 80,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF8B4513).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.person,
                  size: 40,
                  color: Color(0xFF8B4513),
                ),
              ),
              const SizedBox(height: 12),
              // Lawyer Name
              Text(
                data['name'] as String? ?? 'Laura Parker',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              // Specialization
              Text(
                data['specialization'] as String? ?? 'Advertising Law | Medica',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              // Book Now Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    // Create lawyer model from Firestore data
                    LawyerModel lawyerModel = LawyerModel(
                      id: data['id'] as String? ?? 'lawyer_$index',
                      userId: data['userId'] as String? ?? 'lawyer_$index',
                      email: data['email'] as String? ?? 'lawyer@servipak.com',
                      name: data['name'] as String? ?? 'Unknown Lawyer',
                      phone: data['phone'] as String? ?? '+92-300-0000000',
                      status:
                          data['status'] as String? ??
                          AppConstants.verifiedStatus,
                      specialization:
                          data['specialization'] as String? ??
                          'General Practice',
                      experience: data['experience'] as String? ?? '0 years',
                      barCouncilNumber:
                          data['barCouncilNumber'] as String? ?? 'BC-2023-000',
                      bio: data['bio'] as String? ?? 'Experienced lawyer',
                      rating: data['rating'] as double? ?? 0.0,
                      totalCases: data['totalCases'] as int? ?? 0,
                      languages: List<String>.from(
                        data['languages'] as List? ?? ['Urdu', 'English'],
                      ),
                      address:
                          data['address'] as String? ?? 'Address not provided',
                      city: data['city'] as String? ?? 'Unknown',
                      province: data['province'] as String? ?? 'Unknown',
                      createdAt: DateTime.now(),
                    );

                    // Get current user
                    UserModel? currentUser = await _getCurrentUser();

                    if (currentUser != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ConsultationBookingScreen(
                            lawyer: lawyerModel,
                            user: currentUser,
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please login to book consultation'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B4513),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: const Text(
                    'Book Now',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernCategoryCard(String title, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _handleCategoryCardTap(title);
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, size: 32, color: color),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C1810),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFindLawyers() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Lawyers'),
        backgroundColor: const Color(0xFF8B4513), // Saddle Brown
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search lawyers by name, specialization, or location',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF8B4513),
                  ), // Saddle Brown
                ),
              ),
            ),
          ),

          // Filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Specialization',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All')),
                      DropdownMenuItem(
                        value: 'criminal',
                        child: Text('Criminal Law'),
                      ),
                      DropdownMenuItem(
                        value: 'family',
                        child: Text('Family Law'),
                      ),
                      DropdownMenuItem(
                        value: 'property',
                        child: Text('Property Law'),
                      ),
                    ],
                    onChanged: (value) {
                      _handleSpecializationFilter(value);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'City',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All Cities')),
                      DropdownMenuItem(value: 'lahore', child: Text('Lahore')),
                      DropdownMenuItem(
                        value: 'karachi',
                        child: Text('Karachi'),
                      ),
                      DropdownMenuItem(
                        value: 'islamabad',
                        child: Text('Islamabad'),
                      ),
                    ],
                    onChanged: (value) {
                      _handleCityFilter(value);
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Lawyers List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection(AppConstants.lawyersCollection)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final data = doc.data() as Map<String, dynamic>;

                    return _buildLawyerListItem(data, index);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLawyerListItem(Map<String, dynamic> data, int index) {
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
                  radius: 25,
                  backgroundColor: Colors.green.withOpacity(0.1),
                  child: Text(
                    data['name']?.toString().substring(0, 1).toUpperCase() ??
                        'L',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
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
                Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text('${data['rating'] ?? 0.0}'),
                      ],
                    ),
                    Text(
                      '${data['totalCases'] ?? 0} cases',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.grey, size: 16),
                const SizedBox(width: 4),
                Text(data['city'] ?? 'Unknown'),
                const Spacer(),
                ElevatedButton(
                  onPressed: () async {
                    // Create lawyer model from Firestore data
                    LawyerModel lawyerModel = LawyerModel(
                      id: data['id'] as String? ?? 'lawyer_$index',
                      userId: data['userId'] as String? ?? 'lawyer_$index',
                      email: data['email'] as String? ?? 'lawyer@servipak.com',
                      name: data['name'] as String? ?? 'Unknown Lawyer',
                      phone: data['phone'] as String? ?? '+92-300-0000000',
                      status:
                          data['status'] as String? ??
                          AppConstants.verifiedStatus,
                      specialization:
                          data['specialization'] as String? ??
                          'General Practice',
                      experience: data['experience'] as String? ?? '0 years',
                      barCouncilNumber:
                          data['barCouncilNumber'] as String? ?? 'BC-2023-000',
                      bio: data['bio'] as String? ?? 'Experienced lawyer',
                      rating: data['rating'] as double? ?? 0.0,
                      totalCases: data['totalCases'] as int? ?? 0,
                      languages: List<String>.from(
                        data['languages'] as List? ?? ['Urdu', 'English'],
                      ),
                      address:
                          data['address'] as String? ?? 'Address not provided',
                      city: data['city'] as String? ?? 'Unknown',
                      province: data['province'] as String? ?? 'Unknown',
                      createdAt: DateTime.now(),
                    );

                    // Get current user
                    UserModel? currentUser = await _getCurrentUser();

                    if (currentUser != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ConsultationBookingScreen(
                            lawyer: lawyerModel,
                            user: currentUser,
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please login to book consultation'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B4513), // Saddle Brown
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Book Consultation'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyCases() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Consultations'),
        backgroundColor: const Color(0xFF8B4513), // Saddle Brown
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<ConsultationModel>>(
        future: _getUserConsultations(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          List<ConsultationModel> consultations = snapshot.data ?? [];

          if (consultations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.folder_open, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No consultations yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const Text(
                    'Book your first consultation!',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _addDemoConsultations(),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Demo Consultations'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B4513),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: consultations.length,
            itemBuilder: (context, index) {
              ConsultationModel consultation = consultations[index];
              return _buildConsultationCard(consultation);
            },
          );
        },
      ),
    );
  }

  Future<List<ConsultationModel>> _getUserConsultations() async {
    try {
      print('🔍 Getting user consultations...');
      var session = await AuthService.getSavedUserSession();
      print('🔍 Session data: $session');

      if (session == null || session.isEmpty) {
        print('❌ No session found');
        return [];
      }

      String userId = session['userId'] ?? '';
      print('🔍 User ID: $userId');

      if (userId.isEmpty) {
        print('❌ User ID is empty');
        return [];
      }

      List<ConsultationModel> consultations =
          await ConsultationService.getConsultationsByUserId(userId);
      print('✅ Found ${consultations.length} consultations');

      return consultations;
    } catch (e) {
      print('❌ Error getting user consultations: $e');
      return [];
    }
  }

  Future<void> _addDemoConsultations() async {
    try {
      var session = await AuthService.getSavedUserSession();
      if (session != null && session.isNotEmpty) {
        String userId = session['userId'] ?? '';
        if (userId.isNotEmpty) {
          await DemoDataService.addDemoConsultationsForUser(userId);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Demo consultations added successfully!'),
              backgroundColor: Color(0xFF8B4513),
            ),
          );
          // Refresh the consultations list
          setState(() {});
        }
      }
    } catch (e) {
      print('❌ Error adding demo consultations: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding demo consultations: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildConsultationCard(ConsultationModel consultation) {
    Color statusColor = _getStatusColor(consultation.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor,
          child: Icon(_getStatusIcon(consultation.status), color: Colors.white),
        ),
        title: Text(
          consultation.category,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(consultation.description),
            const SizedBox(height: 4),
            Row(
              children: [
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
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
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'PKR ${consultation.price.toStringAsFixed(0)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            Text(
              _formatDate(consultation.scheduledAt),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        onTap: () {
          // Navigate to chat if consultation is accepted
          if (consultation.isAccepted) {
            _openChatWithLawyer(consultation);
          } else {
            _showConsultationDetails(consultation);
          }
        },
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

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
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

  // Action Card Handlers
  void _handleActionCardTap(String title) {
    switch (title) {
      case 'Emergency':
        _showEmergencyDialog();
        break;
      case 'Document Review':
        _showDocumentReviewDialog();
        break;
      case 'Legal Advice':
        _showLegalAdviceDialog();
        break;
      case 'Court Representation':
        _showCourtRepresentationDialog();
        break;
      case 'Contract Review':
        _showContractReviewDialog();
        break;
      case 'Property Law':
        _showPropertyLawDialog();
        break;
      default:
        _showGenericActionDialog(title);
    }
  }

  void _handleCategoryCardTap(String title) {
    switch (title) {
      case 'Administrative Law':
        _showCategoryLawyersDialog(title, 'Administrative Law');
        break;
      case 'Cannabis Law':
        _showCategoryLawyersDialog(title, 'Cannabis Law');
        break;
      case 'Commercial Law':
        _showCategoryLawyersDialog(title, 'Commercial Law');
        break;
      case 'Criminal Law':
        _showCategoryLawyersDialog(title, 'Criminal Law');
        break;
      case 'Family Law':
        _showCategoryLawyersDialog(title, 'Family Law');
        break;
      case 'Property Law':
        _showCategoryLawyersDialog(title, 'Property Law');
        break;
      default:
        _showCategoryLawyersDialog(title, title);
    }
  }

  // Emergency Dialog
  void _showEmergencyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Emergency Legal Help'),
        content: const Text(
          'Get immediate legal assistance for urgent matters.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _callEmergencyNumber();
            },
            child: const Text('Call Now'),
          ),
        ],
      ),
    );
  }

  void _callEmergencyNumber() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Calling emergency legal helpline: +92-300-911-911'),
        backgroundColor: Colors.red,
      ),
    );
  }

  // Document Review Dialog
  void _showDocumentReviewDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Document Review'),
        content: const Text(
          'Upload your legal documents for professional review and feedback.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _uploadDocumentForReview();
            },
            child: const Text('Upload Document'),
          ),
        ],
      ),
    );
  }

  void _uploadDocumentForReview() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Document upload feature opened'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  // Legal Advice Dialog
  void _showLegalAdviceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Legal Advice'),
        content: const Text(
          'Get professional legal advice from qualified lawyers.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _selectedIndex = 1); // Navigate to Find Lawyers
            },
            child: const Text('Find Lawyers'),
          ),
        ],
      ),
    );
  }

  // Court Representation Dialog
  void _showCourtRepresentationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Court Representation'),
        content: const Text(
          'Find experienced lawyers for court representation and litigation.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _searchCourtLawyers();
            },
            child: const Text('Find Court Lawyers'),
          ),
        ],
      ),
    );
  }

  void _searchCourtLawyers() {
    setState(() => _selectedIndex = 1); // Navigate to Find Lawyers
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Searching for court representation lawyers...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  // Contract Review Dialog
  void _showContractReviewDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contract Review'),
        content: const Text(
          'Get your contracts reviewed by legal experts for potential issues and improvements.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _startContractReview();
            },
            child: const Text('Start Review'),
          ),
        ],
      ),
    );
  }

  void _startContractReview() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Contract review process started'),
        backgroundColor: Colors.green,
      ),
    );
  }

  // Property Law Dialog
  void _showPropertyLawDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Property Law'),
        content: const Text(
          'Get assistance with property transactions, disputes, and legal matters.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _findPropertyLawyers();
            },
            child: const Text('Find Property Lawyers'),
          ),
        ],
      ),
    );
  }

  void _findPropertyLawyers() {
    setState(() => _selectedIndex = 1); // Navigate to Find Lawyers
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Searching for property law specialists...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  // Generic Action Dialog
  void _showGenericActionDialog(String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text('Get professional assistance with $title matters.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _selectedIndex = 1); // Navigate to Find Lawyers
            },
            child: const Text('Find Lawyers'),
          ),
        ],
      ),
    );
  }

  // Category Lawyers Dialog
  void _showCategoryLawyersDialog(String category, String specialization) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$category Lawyers'),
        content: Text('Find qualified lawyers specializing in $category.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _searchCategoryLawyers(specialization);
            },
            child: const Text('Search Lawyers'),
          ),
        ],
      ),
    );
  }

  void _searchCategoryLawyers(String specialization) {
    setState(() => _selectedIndex = 1); // Navigate to Find Lawyers
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Searching for $specialization lawyers...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  // Filter Chip Handler
  void _handleFilterChipTap(String label) {
    switch (label) {
      case 'All':
        _showAllLawyers();
        break;
      case 'Top Rated':
        _showTopRatedLawyers();
        break;
      case 'Featured':
        _showFeaturedLawyers();
        break;
      default:
        _showAllLawyers();
    }
  }

  void _showAllLawyers() {
    setState(() => _selectedIndex = 1); // Navigate to Find Lawyers
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Showing all verified lawyers'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showTopRatedLawyers() {
    setState(() => _selectedIndex = 1); // Navigate to Find Lawyers
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Showing top rated lawyers'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showFeaturedLawyers() {
    setState(() => _selectedIndex = 1); // Navigate to Find Lawyers
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Showing featured lawyers'),
        backgroundColor: const Color(0xFF8B4513),
      ),
    );
  }

  // Filter Handlers
  void _handleSpecializationFilter(String? value) {
    if (value != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Filtering by specialization: $value'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  void _handleCityFilter(String? value) {
    if (value != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Filtering by city: $value'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // Chat and Consultation Handlers
  void _openChatWithLawyer(ConsultationModel consultation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chat with Lawyer'),
        content: Text(
          'Start chatting with your lawyer for consultation: ${consultation.category}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _startChatSession(consultation);
            },
            child: const Text('Start Chat'),
          ),
        ],
      ),
    );
  }

  void _startChatSession(ConsultationModel consultation) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Chat session started with lawyer'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showConsultationDetails(ConsultationModel consultation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Consultation Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Category: ${consultation.category}'),
            Text('Type: ${consultation.type}'),
            Text('Status: ${consultation.status}'),
            Text('Price: PKR ${consultation.price.toStringAsFixed(0)}'),
            Text('Scheduled: ${_formatDate(consultation.scheduledAt)}'),
            if (consultation.description.isNotEmpty)
              Text('Description: ${consultation.description}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (consultation.status == 'pending')
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _cancelConsultation(consultation);
              },
              child: const Text('Cancel'),
            ),
        ],
      ),
    );
  }

  void _cancelConsultation(ConsultationModel consultation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Consultation'),
        content: const Text(
          'Are you sure you want to cancel this consultation?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _confirmCancelConsultation(consultation);
            },
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  void _confirmCancelConsultation(ConsultationModel consultation) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Consultation cancelled successfully'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  // Search Functionality
  void _performSearch(String query) {
    if (query.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a search term'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Navigate to Find Lawyers tab with search query
    setState(() => _selectedIndex = 1);

    // Store search query for use in Find Lawyers section
    _searchController.text = query;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Searching for: $query'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  // All Categories Dialog
  void _showAllCategories() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('All Legal Categories'),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: 12,
            itemBuilder: (context, index) {
              final categories = [
                {
                  'name': 'Administrative Law',
                  'icon': Icons.gavel,
                  'color': Colors.red,
                },
                {
                  'name': 'Cannabis Law',
                  'icon': Icons.eco,
                  'color': Colors.green,
                },
                {
                  'name': 'Commercial Law',
                  'icon': Icons.attach_money,
                  'color': Colors.blue,
                },
                {
                  'name': 'Criminal Law',
                  'icon': Icons.security,
                  'color': Colors.orange,
                },
                {
                  'name': 'Family Law',
                  'icon': Icons.family_restroom,
                  'color': Colors.purple,
                },
                {
                  'name': 'Property Law',
                  'icon': Icons.home,
                  'color': Colors.teal,
                },
                {
                  'name': 'Corporate Law',
                  'icon': Icons.business,
                  'color': Colors.indigo,
                },
                {
                  'name': 'Tax Law',
                  'icon': Icons.account_balance,
                  'color': Colors.brown,
                },
                {
                  'name': 'Immigration Law',
                  'icon': Icons.people,
                  'color': Colors.cyan,
                },
                {
                  'name': 'Employment Law',
                  'icon': Icons.work,
                  'color': Colors.amber,
                },
                {
                  'name': 'Intellectual Property',
                  'icon': Icons.lightbulb,
                  'color': Colors.pink,
                },
                {
                  'name': 'Environmental Law',
                  'icon': Icons.nature,
                  'color': Colors.lightGreen,
                },
              ];

              final category = categories[index];
              return InkWell(
                onTap: () {
                  Navigator.pop(context);
                  _searchCategoryLawyers(category['name'] as String);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: (category['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: (category['color'] as Color).withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        category['icon'] as IconData,
                        color: category['color'] as Color,
                        size: 20,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        category['name'] as String,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: category['color'] as Color,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
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
