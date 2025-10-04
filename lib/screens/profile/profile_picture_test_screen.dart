import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';

class ProfilePictureTestScreen extends StatefulWidget {
  const ProfilePictureTestScreen({super.key});

  @override
  State<ProfilePictureTestScreen> createState() =>
      _ProfilePictureTestScreenState();
}

class _ProfilePictureTestScreenState extends State<ProfilePictureTestScreen> {
  UserModel? currentUser;
  bool hasProfilePic = false;
  String? profilePicUrl;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      // Get current user
      String? userId = AuthService.currentUser?.uid;
      if (userId != null) {
        currentUser = await AuthService.getUserById(userId);
      }

      if (currentUser != null) {
        // Check if user has profile picture
        hasProfilePic = await AuthService.hasProfilePicture(currentUser!.id);

        // Get profile picture URL
        profilePicUrl = await AuthService.getUserProfilePicture(
          currentUser!.id,
        );
      }
    } catch (e) {
      print('Error loading user data: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Picture Test'),
        backgroundColor: const Color(0xFF8B4513),
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Info Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'User Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('Name: ${currentUser?.name ?? 'N/A'}'),
                          Text('Email: ${currentUser?.email ?? 'N/A'}'),
                          Text('Role: ${currentUser?.role ?? 'N/A'}'),
                          Text('Status: ${currentUser?.status ?? 'N/A'}'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Profile Picture Status Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Profile Picture Status',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                hasProfilePic
                                    ? Icons.check_circle
                                    : Icons.cancel,
                                color: hasProfilePic
                                    ? Colors.green
                                    : Colors.red,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                hasProfilePic
                                    ? 'Has Profile Picture'
                                    : 'No Profile Picture',
                                style: TextStyle(
                                  color: hasProfilePic
                                      ? Colors.green
                                      : Colors.red,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          if (profilePicUrl != null) ...[
                            const SizedBox(height: 8),
                            const Text('Profile Picture URL:'),
                            Text(
                              profilePicUrl!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Profile Picture Preview
                  if (hasProfilePic && profilePicUrl != null)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Profile Picture Preview',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Center(
                              child: CircleAvatar(
                                radius: 50,
                                backgroundImage: NetworkImage(profilePicUrl!),
                                onBackgroundImageError: (exception, stackTrace) {
                                  print(
                                    'Error loading profile image: $exception',
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const Spacer(),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _loadUserData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B4513),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Refresh Data'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Go Back'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
