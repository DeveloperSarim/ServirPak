import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../constants/app_constants.dart';
import '../../services/realtime_chat_service.dart';
import '../../models/chat_model.dart';
import '../auth/login_screen.dart';
// import '../consultation/consultation_booking_screen.dart';
import 'user_chat_list_screen.dart';
import 'user_chat_screen.dart';
import '../profile/user_profile_screen.dart';
import '../profile/my_consultations_screen.dart';
import 'lawyer_booking_screen.dart';
import '../lawyer/lawyer_details_screen.dart';
import 'working_booking_demo.dart';
import '../../widgets/floating_ai_widget.dart';

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
  String? _currentUserId;
  String? _selectedCategory;
  String? _searchQuery;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    try {
      final session = await AuthService.getSavedUserSession();
      final userId = session['userId'] as String;

      if (mounted) {
        setState(() {
          _currentUserId = userId;
        });
      }

      print('🔍 UserDashboard: Loaded User ID from session: $_currentUserId');
    } catch (e) {
      print('❌ UserDashboard: Error loading user ID: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(),
      drawer: _buildDrawer(),
      body: Stack(children: [_buildBody(), const FloatingAIWidget()]),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.menu, color: Colors.black),
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
        _currentUserId != null
            ? StreamBuilder<DocumentSnapshot>(
                stream: _firestore
                    .collection(AppConstants.usersCollection)
                    .doc(_currentUserId!)
                    .snapshots(),
                builder: (context, snapshot) {
                  print(
                    '🔍 UserDashboard: StreamBuilder running for user: $_currentUserId',
                  );

                  if (snapshot.hasData && snapshot.data!.exists) {
                    final userData =
                        snapshot.data!.data() as Map<String, dynamic>?;
                    final profileImageUrl =
                        userData?['profileImage'] as String?;
                    print(
                      '🔍 UserDashboard: Profile Image URL: $profileImageUrl',
                    );
                    print(
                      '🔍 UserDashboard: Profile Image exists: ${profileImageUrl != null && profileImageUrl.isNotEmpty}',
                    );

                    print(
                      '🔍 UserDashboard: Using real profile image: $profileImageUrl',
                    );

                    return GestureDetector(
                      onTap: () {
                        // Navigate to profile when profile image is tapped
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const UserProfileScreen(),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(
                          right: 16,
                          top: 8,
                          bottom: 8,
                        ),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 22, // Slightly larger for better visibility
                          backgroundColor: const Color(0xFF8B4513),
                          backgroundImage:
                              profileImageUrl != null &&
                                  profileImageUrl.isNotEmpty
                              ? NetworkImage(profileImageUrl)
                              : null, // No image if no profile image
                          onBackgroundImageError: (exception, stackTrace) {
                            print('❌ Error loading profile image: $exception');
                          },
                          child:
                              profileImageUrl == null || profileImageUrl.isEmpty
                              ? const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 24,
                                )
                              : null,
                        ),
                      ),
                    );
                  }
                  return GestureDetector(
                    onTap: () {
                      // Navigate to profile when profile image is tapped
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const UserProfileScreen(),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(
                        right: 16,
                        top: 8,
                        bottom: 8,
                      ),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: const CircleAvatar(
                        radius: 22,
                        backgroundColor: Color(0xFF8B4513),
                        child: Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  );
                },
              )
            : // Fallback when userId is not loaded yet
              Container(
                margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
                child: const CircleAvatar(
                  radius: 22,
                  backgroundColor: Color(0xFF8B4513),
                  child: Icon(Icons.person, color: Colors.white, size: 24),
                ),
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
            title: const Text('My Consultations'),
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
        return MyConsultationsScreen(
          onBackToHome: () {
            setState(() {
              _selectedIndex = 0; // Navigate to home tab
            });
          },
        );
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
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dynamic profile greeting with real user data
                  Row(
                    children: [
                      // Real user profile image from Cloudinary
                      StreamBuilder<DocumentSnapshot>(
                        stream: _firestore
                            .collection(AppConstants.usersCollection)
                            .doc(_currentUserId ?? '')
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData && snapshot.data!.exists) {
                            final userData =
                                snapshot.data!.data() as Map<String, dynamic>?;
                            final profileImageUrl =
                                userData?['profileImage'] as String?;

                            return Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 15,
                                backgroundColor: Colors.white.withOpacity(0.2),
                                backgroundImage:
                                    profileImageUrl != null &&
                                        profileImageUrl.isNotEmpty
                                    ? NetworkImage(profileImageUrl)
                                    : null,
                                child:
                                    profileImageUrl == null ||
                                        profileImageUrl.isEmpty
                                    ? Icon(
                                        Icons.person,
                                        color: Colors.white,
                                        size: 16,
                                      )
                                    : null,
                              ),
                            );
                          }
                          return Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: CircleAvatar(
                              radius: 15,
                              backgroundColor: Colors.white.withOpacity(0.2),
                              child: Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Welcome Back!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
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
          );
        },
      ),
    );
  }

  Widget _buildGreetingSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: _currentUserId != null
          ? StreamBuilder<DocumentSnapshot>(
              stream: _firestore
                  .collection(AppConstants.usersCollection)
                  .doc(_currentUserId!)
                  .snapshots(),
              builder: (context, snapshot) {
                String userName = 'User';
                if (snapshot.hasData && snapshot.data!.exists) {
                  final userData =
                      snapshot.data!.data() as Map<String, dynamic>?;
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
            )
          : Row(
              children: [
                Text(
                  'Hello User | ',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
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
                    'specialization': 'Administrative Law',
                  },
                  {
                    'name': 'Cannabis Law',
                    'icon': Icons.eco,
                    'color': Colors.green,
                    'specialization': 'Cannabis Law',
                  },
                  {
                    'name': 'Commercial Law',
                    'icon': Icons.attach_money,
                    'color': Colors.blue,
                    'specialization': 'Commercial Law',
                  },
                  {
                    'name': 'Criminal Law',
                    'icon': Icons.security,
                    'color': Colors.orange,
                    'specialization': 'Criminal Law',
                  },
                  {
                    'name': 'Family Law',
                    'icon': Icons.family_restroom,
                    'color': const Color(0xFF8B4513),
                    'specialization': 'Family Law',
                  },
                  {
                    'name': 'Property Law',
                    'icon': Icons.home,
                    'color': Colors.teal,
                    'specialization': 'Property Law',
                  },
                ];

                final category = categories[index];
                return GestureDetector(
                  onTap: () {
                    _onCategoryTap(
                      category['name'] as String,
                      category['specialization'] as String,
                    );
                  },
                  child: Container(
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
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQualifiedLawyersSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and filters in a responsive layout
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Qualified Lawyers',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              // Responsive filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All', true),
                    const SizedBox(width: 8),
                    _buildFilterChip('Top Rated', false),
                    const SizedBox(width: 8),
                    _buildFilterChip('Featured', false),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Responsive lawyer cards
          StreamBuilder<QuerySnapshot>(
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

              // Use responsive grid layout instead of horizontal scroll
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: MediaQuery.of(context).size.width > 600
                      ? 2
                      : 1,
                  childAspectRatio: MediaQuery.of(context).size.width > 600
                      ? 1.2
                      : 2.5,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final doc = snapshot.data!.docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  return _buildResponsiveLawyerCard(data, index);
                },
              );
            },
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF8B4513) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF8B4513) : Colors.grey.shade300,
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF8B4513).withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildResponsiveLawyerCard(Map<String, dynamic> data, int index) {
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
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Lawyer Image and Info Row
            Row(
              children: [
                // Lawyer Image with better handling
                Container(
                  height: 60,
                  width: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B4513).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: const Color(0xFF8B4513).withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: FutureBuilder<String?>(
                      future: _getLawyerProfileImage(data),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF8B4513),
                              strokeWidth: 2,
                            ),
                          );
                        }

                        final profileImage = snapshot.data;
                        print(
                          '🔍 UserDashboard: Lawyer ${data['name']} - ProfileImage: $profileImage',
                        );

                        if (profileImage != null && profileImage.isNotEmpty) {
                          return Image.network(
                            profileImage,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF8B4513),
                                  strokeWidth: 2,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              print(
                                '❌ UserDashboard: Error loading image for ${data['name']}: $error',
                              );
                              return const Icon(
                                Icons.person,
                                size: 30,
                                color: Color(0xFF8B4513),
                              );
                            },
                          );
                        } else {
                          print(
                            '⚠️ UserDashboard: No profile image for ${data['name']}',
                          );
                          return const Icon(
                            Icons.person,
                            size: 30,
                            color: Color(0xFF8B4513),
                          );
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Lawyer Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        data['name'] as String? ?? 'Lawyer Name',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        data['specialization'] as String? ??
                            'Law Specialization',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Rating and Experience
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 12),
                          const SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              '${(data['rating'] as num?)?.toDouble() ?? 0.0}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.work, color: Colors.grey, size: 12),
                          const SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              _getCalculatedExperience(data),
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _viewLawyerDetails(data, index),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF8B4513)),
                      foregroundColor: const Color(0xFF8B4513),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      minimumSize: const Size(0, 32),
                    ),
                    child: const Text(
                      'Details',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _startChatWithLawyer(data, index),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      minimumSize: const Size(0, 32),
                    ),
                    child: const Text(
                      'Chat',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      // Navigate to booking screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LawyerBookingScreen(
                            lawyerId:
                                data['userId'] as String? ?? 'lawyer_$index',
                            lawyerData: data,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B4513),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      minimumSize: const Size(0, 32),
                    ),
                    child: const Text(
                      'Book',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
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

  Future<String?> _getLawyerProfileImage(Map<String, dynamic> data) async {
    try {
      // First check if profileImage exists in lawyers collection
      String? profileImage = data['profileImage'] as String?;

      if (profileImage != null && profileImage.isNotEmpty) {
        print(
          '✅ UserDashboard: Found profile image in lawyers collection: $profileImage',
        );
        return profileImage;
      }

      // If not found, check users collection
      String lawyerId =
          data['userId'] as String? ?? data['id'] as String? ?? '';
      if (lawyerId.isNotEmpty) {
        print(
          '🔄 UserDashboard: Checking users collection for lawyer: $lawyerId',
        );
        DocumentSnapshot userDoc = await _firestore
            .collection(AppConstants.usersCollection)
            .doc(lawyerId)
            .get();

        if (userDoc.exists) {
          Map<String, dynamic> userData =
              userDoc.data() as Map<String, dynamic>;
          String? userProfileImage = userData['profileImage'] as String?;

          if (userProfileImage != null && userProfileImage.isNotEmpty) {
            print(
              '✅ UserDashboard: Found profile image in users collection: $userProfileImage',
            );
            return userProfileImage;
          }
        }
      }

      print(
        '⚠️ UserDashboard: No profile image found for lawyer: ${data['name']}',
      );
      return null;
    } catch (e) {
      print('❌ UserDashboard: Error fetching profile image: $e');
      return null;
    }
  }

  Future<void> _viewLawyerDetails(Map<String, dynamic> data, int index) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LawyerDetailsScreen(
          lawyerId: data['id'] as String? ?? 'lawyer_$index',
          lawyerData: data,
        ),
      ),
    );
  }

  // Start chat with lawyer
  Future<void> _startChatWithLawyer(
    Map<String, dynamic> data,
    int index,
  ) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Get current user
      final session = await AuthService.getSavedUserSession();

      String userId = session['userId'] as String;
      String lawyerId = data['userId'] as String? ?? 'lawyer_$index';

      // Extract lawyer information
      String lawyerName = data['name'] as String? ?? 'Unknown Lawyer';
      String lawyerEmail = data['email'] as String? ?? 'lawyer@servipak.com';
      String? lawyerProfileImage = data['profileImage'] as String?;

      // Create or get existing chat
      await RealtimeChatService.createChatRealtime(
        lawyerId: lawyerId,
        userId: userId,
      );

      // Create ChatModel for navigation
      ChatModel chat = ChatModel(
        id: _generateChatId(lawyerId, userId),
        lawyerId: lawyerId,
        lawyerName: lawyerName,
        lawyerEmail: lawyerEmail,
        lawyerProfileImage: lawyerProfileImage,
        userId: userId,
        userName: session['name'] ?? 'User',
        userEmail: session['email'] ?? 'user@servipak.com',
        userProfileImage: session['profileImage'],
        createdAt: DateTime.now(),
        consultationIds: [],
      );

      Navigator.pop(context); // Close loading dialog

      // Navigate to chat screen
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => UserChatScreen(chat: chat)),
      );
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start chat: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Generate unique chat ID
  String _generateChatId(String lawyerId, String userId) {
    List<String> ids = [lawyerId, userId];
    ids.sort();
    return '${ids[0]}_${ids[1]}';
  }

  Widget _buildFindLawyers() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with category filter
          if (_selectedCategory != null) ...[
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      _selectedCategory = null;
                    });
                  },
                  icon: const Icon(Icons.arrow_back, color: Color(0xFF8B4513)),
                ),
                Expanded(
                  child: Text(
                    '$_selectedCategory Lawyers',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8B4513),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ] else ...[
            const Text(
              'Find Lawyers',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Search Bar
          Row(
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
                    onChanged: (value) {
                      // Clear search when user types
                      if (value.isEmpty) {
                        setState(() {
                          _searchQuery = null;
                        });
                      }
                    },
                    decoration: InputDecoration(
                      hintText: _searchQuery != null
                          ? 'Search results for "$_searchQuery"'
                          : 'Search lawyers...',
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFF8B4513),
                      ),
                      suffixIcon: _searchQuery != null
                          ? IconButton(
                              onPressed: () {
                                setState(() {
                                  _searchQuery = null;
                                  _searchController.clear();
                                });
                              },
                              icon: const Icon(Icons.clear, color: Colors.grey),
                            )
                          : null,
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
                child: const Text(
                  'Search',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Lawyers List
          StreamBuilder<QuerySnapshot>(
            stream: _getLawyersStream(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              // Apply search filter
              final filteredDocs = _filterLawyersBySearch(snapshot.data!.docs);

              if (filteredDocs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.search_off,
                        size: 80,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _selectedCategory != null
                            ? 'No $_selectedCategory lawyers found'
                            : _searchQuery != null
                            ? 'No lawyers found for "$_searchQuery"'
                            : 'No verified lawyers available',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: MediaQuery.of(context).size.width > 600
                      ? 2
                      : 1,
                  childAspectRatio: MediaQuery.of(context).size.width > 600
                      ? 1.2
                      : 2.5,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: filteredDocs.length,
                itemBuilder: (context, index) {
                  final doc = filteredDocs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  return _buildResponsiveLawyerCard(data, index);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // Get Lawyers Stream based on filters
  Stream<QuerySnapshot> _getLawyersStream() {
    Query query = _firestore
        .collection(AppConstants.lawyersCollection)
        .where('status', isEqualTo: AppConstants.verifiedStatus);

    // Add category filter if selected
    if (_selectedCategory != null) {
      query = query.where('specialization', isEqualTo: _selectedCategory);
    }

    return query.snapshots();
  }

  // Filter lawyers based on search query
  List<DocumentSnapshot> _filterLawyersBySearch(List<DocumentSnapshot> docs) {
    if (_searchQuery == null || _searchQuery!.isEmpty) {
      return docs;
    }

    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final name = (data['name'] as String? ?? '').toLowerCase();
      final specialization = (data['specialization'] as String? ?? '')
          .toLowerCase();
      final searchTerm = _searchQuery!.toLowerCase();

      return name.contains(searchTerm) || specialization.contains(searchTerm);
    }).toList();
  }

  // Category Tap Handler
  void _onCategoryTap(String categoryName, String specialization) {
    // Navigate to Find Lawyers tab with category filter
    setState(() {
      _selectedIndex = 1;
      _selectedCategory = specialization;
      _searchQuery = null; // Clear search when selecting category
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Showing $categoryName lawyers'),
        backgroundColor: const Color(0xFF8B4513),
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

  void _searchCategoryLawyers(String specialization) {
    setState(() => _selectedIndex = 1); // Navigate to Find Lawyers
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Searching for $specialization lawyers...'),
        backgroundColor: Colors.blue,
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
    setState(() {
      _selectedIndex = 1;
      _searchQuery = query.trim();
      _selectedCategory = null; // Clear category filter when searching
    });

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
            itemCount: 13,
            itemBuilder: (context, index) {
              final categories = [
                {
                  'name': 'Test Booking',
                  'icon': Icons.science,
                  'color': Colors.purple,
                  'isTest': true,
                },
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
                  if (category['isTest'] == true) {
                    // Navigate to test screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const WorkingBookingDemo(),
                      ),
                    );
                  } else {
                    _searchCategoryLawyers(category['name'] as String);
                  }
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

  String _getCalculatedExperience(Map<String, dynamic> data) {
    // Check if firstCaseDate exists
    if (data['firstCaseDate'] != null) {
      try {
        final firstCaseDate = (data['firstCaseDate'] as Timestamp).toDate();
        final now = DateTime.now();
        final difference = now.difference(firstCaseDate);
        final years = (difference.inDays / 365).floor();
        final months = ((difference.inDays % 365) / 30).floor();

        if (years > 0) {
          return months > 0 ? '$years years $months months' : '$years years';
        } else if (months > 0) {
          return '$months months';
        } else {
          return 'Less than 1 month';
        }
      } catch (e) {
        // Fallback to manual experience
        return '${data['experience'] as String? ?? '0'} years';
      }
    }

    // Fallback to manual experience
    return '${data['experience'] as String? ?? '0'} years';
  }
}
