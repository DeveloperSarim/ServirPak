import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:typed_data';
import '../../services/auth_service.dart';
import '../../services/cloudinary_service.dart';
import '../../constants/app_constants.dart';
import '../../models/user_model.dart';
import '../auth/login_screen.dart';

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
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Color(0xFF8B4513),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [],
      ),
      body: _currentUser == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8B4513), Color(0xFFA0522D)],
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.white.withOpacity(0.2),
              backgroundImage: _currentUser?.profileImage?.isNotEmpty == true
                  ? NetworkImage(_currentUser!.profileImage!)
                  : null,
              child: _currentUser?.profileImage?.isNotEmpty == true
                  ? null
                  : Text(
                      (_currentUser?.name?.isNotEmpty == true)
                          ? (_currentUser!.name[0]).toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _currentUser?.name ?? 'User',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _currentUser?.email ?? '',
            style: const TextStyle(fontSize: 16, color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _currentUser?.role.toUpperCase() ?? 'USER',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection(AppConstants.consultationsCollection)
            .where('userId', isEqualTo: AuthService.currentUser?.uid ?? '')
            .snapshots(),
        builder: (context, snapshot) {
          int totalConsultations = 0;
          int completedConsultations = 0;
          int pendingConsultations = 0;

          if (snapshot.hasData) {
            totalConsultations = snapshot.data!.docs.length;
            for (var doc in snapshot.data!.docs) {
              final data = doc.data() as Map<String, dynamic>;
              final status = data['status'] as String? ?? '';
              if (status == 'completed') {
                completedConsultations++;
              } else if (status == 'pending') {
                pendingConsultations++;
              }
            }
          }

          return Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total',
                  totalConsultations.toString(),
                  Icons.chat,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Completed',
                  completedConsultations.toString(),
                  Icons.check_circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Pending',
                  pendingConsultations.toString(),
                  Icons.schedule,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF8B4513), size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF8B4513),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOptions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildOptionTile('Edit Profile', Icons.edit, () {
            _showEditProfileDialog();
          }),
          _buildOptionTile('My Consultations', Icons.chat, () {
            _showMyConsultations();
          }),
          _buildOptionTile('My Cases', Icons.folder, () {
            _showMyCases();
          }),
          _buildOptionTile('Payment History', Icons.payment, () {
            _showPaymentHistory();
          }),
          _buildOptionTile('Help & Support', Icons.help, () {
            _showHelpSupport();
          }),
          _buildOptionTile(
            'Dark Mode',
            _isDarkMode ? Icons.dark_mode : Icons.light_mode,
            () {
              _toggleTheme();
            },
          ),
          _buildOptionTile('Logout', Icons.logout, () {
            _showLogoutDialog();
          }),
        ],
      ),
    );
  }

  Widget _buildOptionTile(String title, IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF8B4513)),
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey,
        ),
        onTap: onTap,
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  // Profile Option Handlers
  void _showEditProfileDialog() {
    final nameController = TextEditingController(
      text: _currentUser?.name ?? '',
    );
    final phoneController = TextEditingController(
      text: _currentUser?.phone ?? '',
    );

    dynamic selectedImage;
    String? currentProfileImage = _currentUser?.profileImage;
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Edit Profile',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                // Profile Image Section
                _buildProfileImageSection(
                  currentProfileImage,
                  selectedImage,
                  (imageFile, imageBytes) => setDialogState(() {
                    selectedImage = imageFile ?? imageBytes;
                  }),
                ),

                const SizedBox(height: 20),

                // Name Field
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 16),

                // Phone Field
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                ),

                const SizedBox(height: 20),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isLoading
                            ? null
                            : () async {
                                setDialogState(() => isLoading = true);
                                await _updateProfileWithImage(
                                  nameController.text,
                                  phoneController.text,
                                  selectedImage,
                                );
                                if (mounted) Navigator.pop(context);
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B4513),
                          foregroundColor: Colors.white,
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImageSection(
    String? currentImage,
    dynamic selectedImage,
    Function(File?, Uint8List?) onImageSelected,
  ) {
    return Column(
      children: [
        // Profile Image Preview
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF8B4513), width: 3),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8B4513).withOpacity(0.3),
                spreadRadius: 2,
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipOval(
            child: _buildImagePreview(currentImage, selectedImage),
          ),
        ),

        const SizedBox(height: 12),

        // Action Buttons
        Wrap(
          spacing: 8,
          children: [
            ElevatedButton.icon(
              onPressed: () => _pickImageFromCamera(onImageSelected),
              icon: const Icon(Icons.camera_alt, size: 16),
              label: const Text('Camera', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[100],
                foregroundColor: Colors.blue[800],
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => _pickImageFromGallery(onImageSelected),
              icon: const Icon(Icons.photo_library, size: 16),
              label: const Text('Gallery', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[100],
                foregroundColor: Colors.green[800],
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
            if (selectedImage != null ||
                (currentImage != null && currentImage.isNotEmpty))
              ElevatedButton.icon(
                onPressed: () => onImageSelected(null, null),
                icon: const Icon(Icons.delete, size: 16),
                label: const Text('Remove', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[100],
                  foregroundColor: Colors.red[800],
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildImagePreview(String? currentImage, dynamic selectedImage) {
    if (selectedImage != null) {
      if (kIsWeb) {
        return Image.memory(
          selectedImage as Uint8List,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultAvatar();
          },
        );
      } else {
        return Image.file(
          selectedImage as File,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultAvatar();
          },
        );
      }
    } else if (currentImage != null) {
      return Image.network(
        currentImage,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildDefaultAvatar();
        },
      );
    } else {
      return _buildDefaultAvatar();
    }
  }

  Widget _buildDefaultAvatar() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFF8B4513).withOpacity(0.1),
      child: Icon(
        _currentUser?.name.isNotEmpty == true ? Icons.person : Icons.person_add,
        size: 40,
        color: const Color(0xFF8B4513),
      ),
    );
  }

  Future<void> _pickImageFromCamera(
    Function(File?, Uint8List?) onImageSelected,
  ) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 90,
      );

      if (image != null) {
        if (kIsWeb) {
          final Uint8List bytes = await image.readAsBytes();
          onImageSelected(null, bytes);
        } else {
          onImageSelected(File(image.path), null);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot select image from camera: $e')),
      );
    }
  }

  Future<void> _pickImageFromGallery(
    Function(File?, Uint8List?) onImageSelected,
  ) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 90,
      );

      if (image != null) {
        if (kIsWeb) {
          final Uint8List bytes = await image.readAsBytes();
          onImageSelected(null, bytes);
        } else {
          onImageSelected(File(image.path), null);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot select image from gallery: $e')),
      );
    }
  }

  Future<void> _updateProfileWithImage(
    String name,
    String phone,
    dynamic selectedImage,
  ) async {
    try {
      String? updatedProfileImage = _currentUser?.profileImage;

      // Upload image if selected
      if (selectedImage != null) {
        final user = AuthService.currentUser;
        if (user != null) {
          print('🔍 Debug: Starting image upload...');
          print('🔍 Debug: SelectedImage type: ${selectedImage.runtimeType}');
          print('🔍 Debug: User ID: ${user.uid}');

          String? imageUrl;
          if (kIsWeb && selectedImage is Uint8List) {
            // Web upload with bytes
            imageUrl = await CloudinaryService.uploadImage(
              file: selectedImage,
              folder: 'profile_images',
              publicId:
                  'profile_${user.uid}_${DateTime.now().millisecondsSinceEpoch}',
              originalFileName: 'profile_${user.uid}.jpg',
              width: 512,
              height: 512,
              crop: 'fill',
            );
          } else if (selectedImage is File) {
            // Mobile upload with file
            imageUrl = await CloudinaryService.uploadImage(
              file: selectedImage,
              folder: 'profile_images',
              publicId:
                  'profile_${user.uid}_${DateTime.now().millisecondsSinceEpoch}',
              width: 512,
              height: 512,
              crop: 'fill',
            );
          }

          print('🔍 Debug: CloudinaryService returned: $imageUrl');

          if (imageUrl != null) {
            updatedProfileImage = imageUrl;
            print('🔍 Debug: Image uploaded successfully! URL: $imageUrl');

            // Immediately update the current user to show new image
            setState(() {
              if (_currentUser != null) {
                _currentUser = _currentUser!.copyWith(profileImage: imageUrl);
              }
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '✅ Profile image uploaded! Click Save to update.',
                ),
                backgroundColor: Colors.green,
                action: SnackBarAction(
                  label: 'View Image',
                  textColor: Colors.white,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Image URL: ${imageUrl?.substring(0, 50)}...',
                        ),
                        duration: Duration(seconds: 3),
                      ),
                    );
                  },
                ),
              ),
            );
          } else {
            // Fallback with mock URL
            updatedProfileImage =
                'https://via.placeholder.com/300x300/8B4513/FFFFFF?text=${user.uid.substring(0, 4)}';
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('⚠️ Image upload failed, using demo URL'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }

      // Update profile
      print('🔍 Debug: Updated profile image URL: $updatedProfileImage');
      _updateUserProfile(name, phone, updatedProfileImage);

      // Wait a moment then refresh profile data
      await Future.delayed(Duration(seconds: 1));
      await _loadUserData(); // Refresh profile data
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Profile update error: $e')));
    }
  }

  void _updateUserProfile(
    String name,
    String phone,
    String? profileImage,
  ) async {
    try {
      final user = AuthService.currentUser;
      if (user != null) {
        print('🔍 Debug: Updating profile with image: $profileImage');

        Map<String, dynamic> updateData = {
          'name': name,
          'phone': phone,
          'updatedAt': Timestamp.now(),
        };

        if (profileImage != null) {
          updateData['profileImage'] = profileImage;
          print('🔍 Debug: Added profile image to update data');
        }

        print('🔍 Debug: Update data: $updateData');
        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(user.uid)
            .update(updateData);

        print('🔍 Debug: Profile updated in Firestore');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        _loadUserData(); // Reload user data
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showMyConsultations() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('My Consultations'),
        content: StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection(AppConstants.consultationsCollection)
              .where('userId', isEqualTo: AuthService.currentUser?.uid ?? '')
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.data!.docs.isEmpty) {
              return const Text('No consultations found.');
            }

            return SizedBox(
              height: 300,
              child: ListView.builder(
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final doc = snapshot.data!.docs[index];
                  final data = doc.data() as Map<String, dynamic>;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(data['type'] ?? 'Consultation'),
                      subtitle: Text(data['description'] ?? ''),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(
                            data['status'] ?? '',
                          ).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          (data['status'] ?? '').toUpperCase(),
                          style: TextStyle(
                            color: _getStatusColor(data['status'] ?? ''),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
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

  void _showMyCases() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('My Cases'),
        content: const Text(
          'Your case history and ongoing cases will be displayed here.',
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

  void _showPaymentHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment History'),
        content: const Text(
          'Your payment history and transaction details will be displayed here.',
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

  void _showHelpSupport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.phone),
              title: const Text('Call Support'),
              subtitle: const Text('+92-300-911-911'),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Calling support...'),
                    backgroundColor: Colors.blue,
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('Email Support'),
              subtitle: const Text('support@servirpak.com'),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Opening email...'),
                    backgroundColor: Colors.blue,
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat),
              title: const Text('Live Chat'),
              subtitle: const Text('Chat with our support team'),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Opening live chat...'),
                    backgroundColor: Colors.blue,
                  ),
                );
              },
            ),
          ],
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
