import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import '../../services/auth_service.dart';
import '../../services/cloudinary_service.dart';
import '../../services/payment_service.dart';
import '../../constants/app_constants.dart';
import '../../models/user_model.dart';
import '../auth/login_screen.dart';
import 'my_consultations_screen.dart';
import 'edit_profile_screen.dart';
import '../user/payment_history_screen.dart';

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
  List<Map<String, dynamic>> _paymentHistory = [];
  double _totalSpent = 0.0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadThemePreference();
    _loadPaymentData();
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

  Future<void> _loadPaymentData() async {
    try {
      final user = AuthService.currentUser;
      if (user != null) {
        // Load payment history
        List<Map<String, dynamic>> payments =
            await PaymentService.getUserPaymentHistory(user.uid);

        // Calculate total spent
        double totalSpent = 0.0;
        for (var payment in payments) {
          if (payment['paymentStatus'] == 'completed') {
            totalSpent += (payment['totalAmount'] ?? 0.0).toDouble();
          }
        }

        setState(() {
          _paymentHistory = payments;
          _totalSpent = totalSpent;
        });
      }
    } catch (e) {
      print('Error loading payment data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isDarkMode ? Colors.grey[900] : Colors.grey[50],
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
                        _currentUser!.name.substring(0, 1).toUpperCase(),
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
          if (_currentUser?.phone != null && _currentUser!.phone.isNotEmpty)
            Text(
              _currentUser!.phone,
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
    // Calculate payment statistics
    int totalPayments = _paymentHistory.length;
    int completedPayments = _paymentHistory
        .where((p) => p['paymentStatus'] == 'completed')
        .length;
    int pendingPayments = _paymentHistory
        .where((p) => p['paymentStatus'] == 'pending')
        .length;

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
          // Payment statistics
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'Total Payments',
                totalPayments.toString(),
                Icons.payment,
              ),
              _buildStatItem(
                'Completed',
                completedPayments.toString(),
                Icons.check_circle,
              ),
              _buildStatItem(
                'Pending',
                pendingPayments.toString(),
                Icons.schedule,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Total spent
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF8B4513).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF8B4513).withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.account_balance_wallet,
                  color: Color(0xFF8B4513),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Total Spent: PKR ${_totalSpent.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8B4513),
                  ),
                ),
              ],
            ),
          ),
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
              if (_currentUser != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        EditProfileScreen(user: _currentUser!),
                  ),
                ).then((updatedUser) {
                  if (updatedUser != null) {
                    // Refresh the profile screen with updated user data
                    _loadUserData();
                  }
                });
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('User data not available')),
                );
              }
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
            icon: Icons.payment,
            title: 'Payment History',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PaymentHistoryScreen(),
                ),
              );
            },
          ),
          _buildDivider(),
          _buildListTile(
            icon: Icons.help_outline,
            title: 'Help & Support',
            onTap: () {
              _showHelpSupportDialog();
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

  void _showHelpSupportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.help_outline, color: Color(0xFF8B4513)),
            const SizedBox(width: 8),
            const Text(
              'Help & Support',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF8B4513),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Contact Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8B4513),
                ),
              ),
              const SizedBox(height: 16),

              // Support Email
              _buildSupportItem(
                Icons.email,
                'Support Email',
                'support@servirpak.com',
                'Email us for any technical issues or general inquiries',
                () => _launchEmail('support@servirpak.com'),
              ),
              const SizedBox(height: 12),

              // Support Phone
              _buildSupportItem(
                Icons.phone,
                'Support Phone',
                '+92 300 1234567',
                'Call us for urgent legal assistance',
                () => _launchPhone('+923001234567'),
              ),
              const SizedBox(height: 12),

              // Business Hours
              _buildSupportItem(
                Icons.access_time,
                'Business Hours',
                'Mon-Fri: 9:00 AM - 6:00 PM',
                'Our support team is available during business hours',
                null,
              ),
              const SizedBox(height: 12),

              // WhatsApp Support
              _buildSupportItem(
                Icons.chat,
                'WhatsApp Support',
                '+92 300 1234567',
                'Quick support via WhatsApp',
                () => _launchWhatsApp('+923001234567'),
              ),
              const SizedBox(height: 16),

              const Divider(),
              const SizedBox(height: 12),

              const Text(
                'Frequently Asked Questions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8B4513),
                ),
              ),
              const SizedBox(height: 8),

              _buildFAQItem(
                'How do I book a consultation?',
                'Go to Find Lawyers, select a lawyer, and click Book Consultation.',
              ),
              _buildFAQItem(
                'How do I make payments?',
                'We accept credit/debit cards and bank transfers through secure payment gateways.',
              ),
              _buildFAQItem(
                'Can I cancel a booking?',
                'Yes, you can cancel bookings up to 24 hours before the scheduled time.',
              ),
            ],
          ),
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

  Widget _buildSupportItem(
    IconData icon,
    String title,
    String value,
    String description,
    VoidCallback? onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF8B4513), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Color(0xFF8B4513),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(color: Colors.grey[600], fontSize: 11),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Color(0xFF8B4513),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• $question',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 2),
          Text(answer, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        ],
      ),
    );
  }

  void _launchEmail(String email) {
    // You can implement email launching here
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening email: $email'),
        backgroundColor: const Color(0xFF8B4513),
      ),
    );
  }

  void _launchPhone(String phone) {
    // You can implement phone calling here
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calling: $phone'),
        backgroundColor: const Color(0xFF8B4513),
      ),
    );
  }

  void _launchWhatsApp(String phone) {
    // You can implement WhatsApp launching here
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening WhatsApp: $phone'),
        backgroundColor: const Color(0xFF8B4513),
      ),
    );
  }
}
