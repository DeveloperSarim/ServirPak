import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import '../../services/auth_service.dart';
import '../../services/cloudinary_service.dart';
import '../../constants/app_constants.dart';
import '../../models/user_model.dart';
import '../auth/login_screen.dart';
import 'my_consultations_screen.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();
  UserModel? _currentUser;
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _isDarkMode = prefs.getBool('isDarkMode') ?? false;
      });
    } catch (e) {
      print('Error loading theme preference: $e');
    }
  }

  Future<void> _toggleTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _isDarkMode = !_isDarkMode;
      });
      await prefs.setBool('isDarkMode', _isDarkMode);
    } catch (e) {
      print('Error saving theme preference: $e');
    }
  }

  Future<void> _logout() async {
    try {
      await AuthService.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadUserData() async {
    try {
      final user = AuthService.currentUser;
      if (user != null) {
        final userDoc = await _firestore
            .collection(AppConstants.usersCollection)
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          setState(() {
            _currentUser = UserModel.fromFirestore(userDoc);
          });
          print('🔍 Debug: Profile data reloaded');
          print(
            '🔍 Debug: Current profile image: ${_currentUser?.profileImage}',
          );
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isDarkMode ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(
        backgroundColor: _isDarkMode ? Colors.grey[800] : Colors.white,
        elevation: 0,
        title: Text(
          'ServirPak',
          style: TextStyle(
            color: _isDarkMode ? Colors.white : const Color(0xFF8B4513),
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: _isDarkMode ? Colors.white : const Color(0xFF8B4513),
            ),
            onPressed: _toggleTheme,
          ),
          IconButton(
            icon: Icon(
              Icons.info_outline,
              color: _isDarkMode ? Colors.white : const Color(0xFF8B4513),
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('About ServirPak'),
                  content: const Text(
                    'ServirPak is your trusted legal consultation platform. Connect with verified lawyers and get expert legal advice.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: _currentUser == null
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF8B4513)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildProfileHeader(),
                  const SizedBox(height: 20),
                  _buildProfileStats(),
                  const SizedBox(height: 20),
                  _buildProfileOptions(),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _isDarkMode ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: const Color(0xFF8B4513).withOpacity(0.1),
                backgroundImage:
                    _currentUser?.profileImage != null &&
                        _currentUser!.profileImage!.isNotEmpty
                    ? NetworkImage(_currentUser!.profileImage!)
                    : null,
                child:
                    _currentUser?.profileImage == null ||
                        _currentUser!.profileImage!.isEmpty
                    ? Text(
                        _currentUser?.name?.substring(0, 1).toUpperCase() ??
                            'U',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8B4513),
                        ),
                      )
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _updateProfileImage,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B4513),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _isDarkMode ? Colors.grey[800]! : Colors.white,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _currentUser?.name ?? 'User',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _currentUser?.email ?? 'user@example.com',
            style: TextStyle(
              fontSize: 16,
              color: _isDarkMode ? Colors.grey[300] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          if (_currentUser?.phone != null && _currentUser!.phone!.isNotEmpty)
            Text(
              _currentUser!.phone!,
              style: TextStyle(
                fontSize: 14,
                color: _isDarkMode ? Colors.grey[400] : Colors.grey[500],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileStats() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _isDarkMode ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Consultations', '0', Icons.gavel),
          _buildStatItem('Completed', '0', Icons.check_circle),
          _buildStatItem('Pending', '0', Icons.schedule),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF8B4513), size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: _isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: _isDarkMode ? Colors.grey[300] : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileOptions() {
    return Container(
      decoration: BoxDecoration(
        color: _isDarkMode ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildListTile(
            icon: Icons.edit,
            title: 'Edit Profile',
            onTap: () {
              // Navigate to edit profile screen
            },
          ),
          _buildDivider(),
          _buildListTile(
            icon: Icons.gavel,
            title: 'My Consultations',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MyConsultationsScreen(),
                ),
              );
            },
          ),
          _buildDivider(),
          _buildListTile(
            icon: Icons.folder,
            title: 'My Cases',
            onTap: () {
              // Navigate to cases screen
            },
          ),
          _buildDivider(),
          _buildListTile(
            icon: Icons.payment,
            title: 'Payment History',
            onTap: () {
              // Navigate to payment history screen
            },
          ),
          _buildDivider(),
          _buildListTile(
            icon: Icons.help_outline,
            title: 'Help & Support',
            onTap: () {
              // Navigate to help screen
            },
          ),
          _buildDivider(),
          _buildListTile(
            icon: Icons.logout,
            title: 'Logout',
            onTap: _logout,
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : const Color(0xFF8B4513),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: isDestructive
              ? Colors.red
              : (_isDarkMode ? Colors.white : Colors.black87),
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
      ),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      color: _isDarkMode ? Colors.grey[700] : Colors.grey[200],
      indent: 16,
      endIndent: 16,
    );
  }

  Future<void> _updateProfileImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        // Show loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(color: Color(0xFF8B4513)),
          ),
        );

        try {
          String? imageUrl;
          if (kIsWeb) {
            // For web, convert to bytes
            final bytes = await image.readAsBytes();
            imageUrl = await CloudinaryService.uploadImageSimple(
              file: bytes,
              folder: 'user-profiles',
            );
          } else {
            // For mobile, use file path
            final file = File(image.path);
            imageUrl = await CloudinaryService.uploadImageSimple(
              file: file,
              folder: 'user-profiles',
            );
          }

          if (imageUrl != null) {
            // Update user profile in Firestore
            await _firestore
                .collection(AppConstants.usersCollection)
                .doc(AuthService.currentUser?.uid)
                .update({'profileImage': imageUrl});

            // Reload user data
            await _loadUserData();

            if (mounted) {
              Navigator.pop(context); // Close loading dialog
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Profile image updated successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } else {
            if (mounted) {
              Navigator.pop(context); // Close loading dialog
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Failed to upload image. Please try again.'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        } catch (e) {
          if (mounted) {
            Navigator.pop(context); // Close loading dialog
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error uploading image: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
