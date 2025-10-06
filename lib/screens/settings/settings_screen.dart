import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/theme_service.dart';
import '../../constants/app_constants.dart';
import '../auth/login_screen.dart';
import '../profile/edit_profile_screen.dart';
import '../admin/admin_dashboard.dart';
import '../../models/user_model.dart';

class SettingsScreen extends StatefulWidget {
  final String userRole;
  final UserModel? user;

  const SettingsScreen({super.key, required this.userRole, this.user});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  String _selectedLanguage = 'English';
  String _selectedCity = 'Lahore';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _darkModeEnabled = prefs.getBool('dark_mode_enabled') ?? false;
      _selectedLanguage = prefs.getString('selected_language') ?? 'English';
      _selectedCity = prefs.getString('selected_city') ?? 'Lahore';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', _notificationsEnabled);
    await prefs.setBool('dark_mode_enabled', _darkModeEnabled);
    await prefs.setString('selected_language', _selectedLanguage);
    await prefs.setString('selected_city', _selectedCity);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings saved successfully')),
    );
  }

  Future<void> _logout() async {
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
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await AuthService.signOut();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Color(0xFF8B4513),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF8B4513)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _saveSettings,
            child: const Text(
              'Save',
              style: TextStyle(color: Color(0xFF8B4513)),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildProfileSection(),
          const SizedBox(height: 24),
          _buildGeneralSettings(),
          const SizedBox(height: 24),
          _buildNotificationSettings(),
          const SizedBox(height: 24),
          _buildAppearanceSettings(),
          const SizedBox(height: 24),
          _buildLanguageSettings(),
          const SizedBox(height: 24),
          _buildLocationSettings(),
          const SizedBox(height: 24),
          _buildAccountSettings(),
          if (widget.userRole == AppConstants.adminRole) ...[
            const SizedBox(height: 24),
            _buildAdminSettings(),
          ],
          const SizedBox(height: 24),
          _buildDangerZone(),
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: const Color(0xFF8B4513).withOpacity(0.1),
              backgroundImage: widget.user?.profileImage != null
                  ? NetworkImage(widget.user!.profileImage!)
                  : null,
              child: widget.user?.profileImage == null
                  ? Icon(
                      widget.userRole == AppConstants.adminRole
                          ? Icons.admin_panel_settings
                          : widget.userRole == AppConstants.lawyerRole
                          ? Icons.gavel
                          : Icons.person,
                      size: 30,
                      color: const Color(0xFF8B4513),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.user?.name ?? widget.userRole.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.user?.email ?? 'Manage your account settings',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralSettings() {
    return _buildSection(
      title: 'General',
      children: [
        _buildListTile(
          icon: Icons.person,
          title: 'Edit Profile',
          subtitle: 'Update your personal information',
          onTap: () {
            if (widget.user != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProfileScreen(user: widget.user!),
                ),
              ).then((updatedUser) {
                if (updatedUser != null) {
                  // Refresh the settings screen with updated user data
                  setState(() {});
                }
              });
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('User data not available')),
              );
            }
          },
        ),
        _buildListTile(
          icon: Icons.history,
          title: 'My Consultations',
          subtitle: 'View your consultation history',
          onTap: () => _showConsultationHistory(),
        ),
        _buildListTile(
          icon: Icons.payment,
          title: 'Payment History',
          subtitle: 'View your payment records',
          onTap: () => _showPaymentHistory(),
        ),
        _buildListTile(
          icon: Icons.chat,
          title: 'My Chats',
          subtitle: 'View your chat conversations',
          onTap: () => _showMyChats(),
        ),
        _buildListTile(
          icon: Icons.security,
          title: 'Privacy & Security',
          subtitle: 'Manage your privacy settings',
          onTap: () {
            _showPrivacySettingsDialog();
          },
        ),
        _buildListTile(
          icon: Icons.help,
          title: 'Help & Support',
          subtitle: 'Get help and contact support',
          onTap: () {
            _showHelpSupportDialog();
          },
        ),
      ],
    );
  }

  Widget _buildNotificationSettings() {
    return _buildSection(
      title: 'Notifications',
      children: [
        SwitchListTile(
          title: const Text('Push Notifications'),
          subtitle: const Text('Receive notifications on your device'),
          value: _notificationsEnabled,
          onChanged: (value) {
            setState(() {
              _notificationsEnabled = value;
            });
          },
          secondary: const Icon(Icons.notifications),
        ),
        _buildListTile(
          icon: Icons.email,
          title: 'Email Notifications',
          subtitle: 'Manage email notification preferences',
          onTap: () {
            _showEmailSettingsDialog();
          },
        ),
      ],
    );
  }

  Widget _buildAppearanceSettings() {
    return _buildSection(
      title: 'Appearance',
      children: [
        Consumer<ThemeService>(
          builder: (context, themeService, child) {
            return SwitchListTile(
              title: const Text('Dark Mode'),
              subtitle: const Text('Switch between light and dark themes'),
              value: themeService.isDarkMode,
              onChanged: (value) {
                themeService.toggleTheme();
              },
              secondary: const Icon(Icons.dark_mode),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLanguageSettings() {
    return _buildSection(
      title: 'Language & Region',
      children: [
        _buildListTile(
          icon: Icons.language,
          title: 'Language',
          subtitle: _selectedLanguage,
          onTap: () {
            _showLanguageDialog();
          },
        ),
        _buildListTile(
          icon: Icons.location_on,
          title: 'Default City',
          subtitle: _selectedCity,
          onTap: () {
            _showCityDialog();
          },
        ),
      ],
    );
  }

  Widget _buildLocationSettings() {
    return _buildSection(
      title: 'Location',
      children: [
        _buildListTile(
          icon: Icons.my_location,
          title: 'Current Location',
          subtitle: 'Use your current location for services',
          onTap: () {
            _showLocationServicesDialog();
          },
        ),
        _buildListTile(
          icon: Icons.location_searching,
          title: 'Location History',
          subtitle: 'View your location history',
          onTap: () {
            _showLocationHistoryDialog();
          },
        ),
      ],
    );
  }

  Widget _buildAccountSettings() {
    return _buildSection(
      title: 'Account',
      children: [
        _buildListTile(
          icon: Icons.lock,
          title: 'Change Password',
          subtitle: 'Update your account password',
          onTap: () {
            _showChangePasswordDialog();
          },
        ),
        _buildListTile(
          icon: Icons.email,
          title: 'Change Email',
          subtitle: 'Update your email address',
          onTap: () {
            _showChangeEmailDialog();
          },
        ),
        _buildListTile(
          icon: Icons.phone,
          title: 'Change Phone',
          subtitle: 'Update your phone number',
          onTap: () {
            _showChangePhoneDialog();
          },
        ),
        _buildListTile(
          icon: Icons.download,
          title: 'Download My Data',
          subtitle: 'Export your account data',
          onTap: () {
            _showDownloadDataDialog();
          },
        ),
        _buildListTile(
          icon: Icons.info,
          title: 'Account Information',
          subtitle: 'View your account details',
          onTap: () {
            _showAccountInfoDialog();
          },
        ),
      ],
    );
  }

  Widget _buildAdminSettings() {
    return _buildSection(
      title: 'Admin Settings',
      children: [
        _buildListTile(
          icon: Icons.people,
          title: 'User Management',
          subtitle: 'Manage all users and their permissions',
          onTap: () => _showUserManagementDialog(),
        ),
        _buildListTile(
          icon: Icons.verified_user,
          title: 'Lawyer Verification',
          subtitle: 'Approve or reject lawyer applications',
          onTap: () => _showLawyerVerificationDialog(),
        ),
        _buildListTile(
          icon: Icons.analytics,
          title: 'Analytics & Reports',
          subtitle: 'View platform analytics and generate reports',
          onTap: () => _showAnalyticsDialog(),
        ),
        _buildListTile(
          icon: Icons.settings_system_daydream,
          title: 'System Settings',
          subtitle: 'Configure platform-wide settings',
          onTap: () => _showSystemSettingsDialog(),
        ),
        _buildListTile(
          icon: Icons.admin_panel_settings,
          title: 'Admin Dashboard',
          subtitle: 'Access full admin dashboard',
          onTap: () => _navigateToAdminDashboard(),
        ),
        _buildListTile(
          icon: Icons.security,
          title: 'Security Management',
          subtitle: 'Manage platform security settings',
          onTap: () => _showSecurityManagementDialog(),
        ),
        _buildListTile(
          icon: Icons.backup,
          title: 'Data Management',
          subtitle: 'Backup and restore platform data',
          onTap: () => _showDataManagementDialog(),
        ),
      ],
    );
  }

  Widget _buildDangerZone() {
    return _buildSection(
      title: 'Danger Zone',
      children: [
        _buildListTile(
          icon: Icons.delete_forever,
          title: 'Delete Account',
          subtitle: 'Permanently delete your account',
          onTap: () {
            _showDeleteAccountDialog();
          },
          textColor: Colors.red,
        ),
        _buildListTile(
          icon: Icons.logout,
          title: 'Logout',
          subtitle: 'Sign out of your account',
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
      leading: Icon(icon, color: textColor),
      title: Text(title, style: TextStyle(color: textColor)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  void _showLanguageDialog() {
    final languages = ['English', 'Urdu', 'Arabic', 'French', 'Spanish'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: languages.map((language) {
            return RadioListTile<String>(
              title: Text(language),
              value: language,
              groupValue: _selectedLanguage,
              onChanged: (value) {
                setState(() {
                  _selectedLanguage = value!;
                });
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showCityDialog() {
    final cities = [
      'Lahore',
      'Karachi',
      'Islamabad',
      'Rawalpindi',
      'Faisalabad',
      'Multan',
      'Peshawar',
      'Quetta',
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Default City'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: cities.map((city) {
            return RadioListTile<String>(
              title: Text(city),
              value: city,
              groupValue: _selectedCity,
              onChanged: (value) {
                setState(() {
                  _selectedCity = value!;
                });
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showDeleteAccountConfirmationDialog();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // Privacy Settings Dialog
  void _showPrivacySettingsDialog() {
    bool profileVisibility = true;
    bool showOnlineStatus = true;
    bool allowDirectMessages = true;
    bool shareLocation = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Privacy & Security'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: const Text('Profile Visibility'),
                  subtitle: const Text('Allow others to see your profile'),
                  value: profileVisibility,
                  onChanged: (value) {
                    setState(() {
                      profileVisibility = value;
                    });
                  },
                ),
                SwitchListTile(
                  title: const Text('Show Online Status'),
                  subtitle: const Text('Display when you are online'),
                  value: showOnlineStatus,
                  onChanged: (value) {
                    setState(() {
                      showOnlineStatus = value;
                    });
                  },
                ),
                SwitchListTile(
                  title: const Text('Allow Direct Messages'),
                  subtitle: const Text('Let others send you direct messages'),
                  value: allowDirectMessages,
                  onChanged: (value) {
                    setState(() {
                      allowDirectMessages = value;
                    });
                  },
                ),
                SwitchListTile(
                  title: const Text('Share Location'),
                  subtitle: const Text('Share your location with the app'),
                  value: shareLocation,
                  onChanged: (value) {
                    setState(() {
                      shareLocation = value;
                    });
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
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Privacy settings saved successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  // Help & Support Dialog
  void _showHelpSupportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Need help? We\'re here for you!',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildSupportOption(
                icon: Icons.phone,
                title: 'Call Support',
                subtitle: '+92-300-1234567',
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Calling support...')),
                  );
                },
              ),
              _buildSupportOption(
                icon: Icons.email,
                title: 'Email Support',
                subtitle: 'support@servirpak.com',
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Opening email client...')),
                  );
                },
              ),
              _buildSupportOption(
                icon: Icons.chat,
                title: 'Live Chat',
                subtitle: 'Available 24/7',
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Starting live chat...')),
                  );
                },
              ),
              _buildSupportOption(
                icon: Icons.help_outline,
                title: 'FAQ',
                subtitle: 'Frequently Asked Questions',
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Opening FAQ...')),
                  );
                },
              ),
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

  Widget _buildSupportOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF8B4513)),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  // Email Settings Dialog
  void _showEmailSettingsDialog() {
    bool consultationEmails = true;
    bool marketingEmails = false;
    bool systemEmails = true;
    bool weeklyDigest = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Email Notifications'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: const Text('Consultation Updates'),
                  subtitle: const Text(
                    'Get notified about consultation changes',
                  ),
                  value: consultationEmails,
                  onChanged: (value) {
                    setState(() {
                      consultationEmails = value;
                    });
                  },
                ),
                SwitchListTile(
                  title: const Text('Marketing Emails'),
                  subtitle: const Text(
                    'Receive promotional offers and updates',
                  ),
                  value: marketingEmails,
                  onChanged: (value) {
                    setState(() {
                      marketingEmails = value;
                    });
                  },
                ),
                SwitchListTile(
                  title: const Text('System Notifications'),
                  subtitle: const Text('Important system updates and alerts'),
                  value: systemEmails,
                  onChanged: (value) {
                    setState(() {
                      systemEmails = value;
                    });
                  },
                ),
                SwitchListTile(
                  title: const Text('Weekly Digest'),
                  subtitle: const Text('Weekly summary of your activity'),
                  value: weeklyDigest,
                  onChanged: (value) {
                    setState(() {
                      weeklyDigest = value;
                    });
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
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Email settings saved successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  // Location Services Dialog
  void _showLocationServicesDialog() {
    bool locationEnabled = true;
    bool preciseLocation = false;
    bool backgroundLocation = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Location Services'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: const Text('Enable Location'),
                  subtitle: const Text('Allow app to access your location'),
                  value: locationEnabled,
                  onChanged: (value) {
                    setState(() {
                      locationEnabled = value;
                      if (!value) {
                        preciseLocation = false;
                        backgroundLocation = false;
                      }
                    });
                  },
                ),
                SwitchListTile(
                  title: const Text('Precise Location'),
                  subtitle: const Text(
                    'Use precise location for better accuracy',
                  ),
                  value: preciseLocation,
                  onChanged: locationEnabled
                      ? (value) {
                          setState(() {
                            preciseLocation = value;
                          });
                        }
                      : null,
                ),
                SwitchListTile(
                  title: const Text('Background Location'),
                  subtitle: const Text(
                    'Allow location access when app is closed',
                  ),
                  value: backgroundLocation,
                  onChanged: locationEnabled
                      ? (value) {
                          setState(() {
                            backgroundLocation = value;
                          });
                        }
                      : null,
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
                    content: Text('Location settings saved successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  // Location History Dialog
  void _showLocationHistoryDialog() {
    final locationHistory = [
      {
        'location': 'Lahore, Punjab',
        'time': '2 hours ago',
        'type': 'Consultation',
      },
      {'location': 'Karachi, Sindh', 'time': '1 day ago', 'type': 'Meeting'},
      {
        'location': 'Islamabad, Federal',
        'time': '3 days ago',
        'type': 'Court Visit',
      },
      {
        'location': 'Rawalpindi, Punjab',
        'time': '1 week ago',
        'type': 'Client Meeting',
      },
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location History'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: locationHistory.length,
            itemBuilder: (context, index) {
              final item = locationHistory[index];
              return ListTile(
                leading: const Icon(
                  Icons.location_on,
                  color: Color(0xFF8B4513),
                ),
                title: Text(item['location']!),
                subtitle: Text('${item['time']} • ${item['type']}'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
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
                  content: Text('Location history cleared!'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: const Text('Clear History'),
          ),
        ],
      ),
    );
  }

  // Change Password Dialog
  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm New Password',
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
              if (newPasswordController.text ==
                  confirmPasswordController.text) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Password changed successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Passwords do not match!'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Change Password'),
          ),
        ],
      ),
    );
  }

  // Change Email Dialog
  void _showChangeEmailDialog() {
    final newEmailController = TextEditingController();
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Email'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: newEmailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'New Email Address',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
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
                  content: Text(
                    'Email change request sent! Please check your new email for verification.',
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Change Email'),
          ),
        ],
      ),
    );
  }

  // Change Phone Dialog
  void _showChangePhoneDialog() {
    final newPhoneController = TextEditingController();
    final otpController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Phone Number'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: newPhoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'New Phone Number',
                  border: OutlineInputBorder(),
                  hintText: '+92-300-1234567',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: otpController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'OTP Code',
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
                  content: Text('Phone number changed successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Change Phone'),
          ),
        ],
      ),
    );
  }

  // Delete Account Confirmation Dialog
  void _showDeleteAccountConfirmationDialog() {
    final reasonController = TextEditingController();
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'This action cannot be undone. All your data will be permanently deleted.',
                style: TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason for deletion (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Enter your password to confirm',
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
                  content: Text(
                    'Account deletion request submitted. You will receive a confirmation email.',
                  ),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );
  }

  // New methods for enhanced functionality
  void _showConsultationHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('My Consultations'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history, size: 64, color: Color(0xFF8B4513)),
            SizedBox(height: 16),
            Text(
              'View your consultation history',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Track all your past and upcoming consultations with lawyers.',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Navigate to consultation history screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Consultation history feature coming soon!'),
                  backgroundColor: Color(0xFF8B4513),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B4513),
              foregroundColor: Colors.white,
            ),
            child: const Text('View History'),
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
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.payment, size: 64, color: Color(0xFF8B4513)),
            SizedBox(height: 16),
            Text('View your payment records', style: TextStyle(fontSize: 16)),
            SizedBox(height: 8),
            Text(
              'Track all your payments, invoices, and transaction history.',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Navigate to payment history screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Payment history feature coming soon!'),
                  backgroundColor: Color(0xFF8B4513),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B4513),
              foregroundColor: Colors.white,
            ),
            child: const Text('View Payments'),
          ),
        ],
      ),
    );
  }

  void _showMyChats() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('My Chats'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat, size: 64, color: Color(0xFF8B4513)),
            SizedBox(height: 16),
            Text(
              'View your chat conversations',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Access all your conversations with lawyers and get support.',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Navigate to chat list screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Chat feature is available in the main dashboard!',
                  ),
                  backgroundColor: Color(0xFF8B4513),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B4513),
              foregroundColor: Colors.white,
            ),
            child: const Text('View Chats'),
          ),
        ],
      ),
    );
  }

  void _showDownloadDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Download My Data'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.download, size: 64, color: Color(0xFF8B4513)),
            SizedBox(height: 16),
            Text('Export your account data', style: TextStyle(fontSize: 16)),
            SizedBox(height: 8),
            Text(
              'Download a copy of your personal data including profile, consultations, and chat history.',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Data export request submitted. You will receive an email with download link.',
                  ),
                  backgroundColor: Color(0xFF8B4513),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B4513),
              foregroundColor: Colors.white,
            ),
            child: const Text('Request Download'),
          ),
        ],
      ),
    );
  }

  void _showAccountInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Account Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info, size: 64, color: Color(0xFF8B4513)),
            const SizedBox(height: 16),
            _buildInfoRow('Name', widget.user?.name ?? 'Not provided'),
            _buildInfoRow('Email', widget.user?.email ?? 'Not provided'),
            _buildInfoRow('Phone', widget.user?.phone ?? 'Not provided'),
            _buildInfoRow('Role', widget.userRole.toUpperCase()),
            _buildInfoRow(
              'Member Since',
              widget.user?.createdAt != null
                  ? '${widget.user!.createdAt.day}/${widget.user!.createdAt.month}/${widget.user!.createdAt.year}'
                  : 'Unknown',
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  // Admin Settings Dialog Methods
  void _showUserManagementDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('User Management'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people, size: 64, color: Color(0xFF8B4513)),
            SizedBox(height: 16),
            Text(
              'Manage all users and their permissions',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'View, edit, and manage user accounts, roles, and permissions across the platform.',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Navigate to user management screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('User Management feature coming soon!'),
                  backgroundColor: Color(0xFF8B4513),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B4513),
              foregroundColor: Colors.white,
            ),
            child: const Text('Manage Users'),
          ),
        ],
      ),
    );
  }

  void _showLawyerVerificationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lawyer Verification'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.verified_user, size: 64, color: Color(0xFF8B4513)),
            SizedBox(height: 16),
            Text(
              'Approve or reject lawyer applications',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Review lawyer applications, verify documents, and approve or reject lawyer registrations.',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Navigate to lawyer verification screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Lawyer Verification feature coming soon!'),
                  backgroundColor: Color(0xFF8B4513),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B4513),
              foregroundColor: Colors.white,
            ),
            child: const Text('Review Applications'),
          ),
        ],
      ),
    );
  }

  void _showAnalyticsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Analytics & Reports'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.analytics, size: 64, color: Color(0xFF8B4513)),
            SizedBox(height: 16),
            Text(
              'View platform analytics and generate reports',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Access detailed analytics, user statistics, and generate comprehensive reports.',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Navigate to analytics screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Analytics feature coming soon!'),
                  backgroundColor: Color(0xFF8B4513),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B4513),
              foregroundColor: Colors.white,
            ),
            child: const Text('View Analytics'),
          ),
        ],
      ),
    );
  }

  void _showSystemSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('System Settings'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.settings_system_daydream,
              size: 64,
              color: Color(0xFF8B4513),
            ),
            SizedBox(height: 16),
            Text(
              'Configure platform-wide settings',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Manage system configuration, platform settings, and global preferences.',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Navigate to system settings screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('System Settings feature coming soon!'),
                  backgroundColor: Color(0xFF8B4513),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B4513),
              foregroundColor: Colors.white,
            ),
            child: const Text('Configure'),
          ),
        ],
      ),
    );
  }

  void _navigateToAdminDashboard() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AdminDashboard()),
    );
  }

  void _showSecurityManagementDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Security Management'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.security, size: 64, color: Color(0xFF8B4513)),
            SizedBox(height: 16),
            Text(
              'Manage platform security settings',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Configure security policies, access controls, and platform protection settings.',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Security Management feature coming soon!'),
                  backgroundColor: Color(0xFF8B4513),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B4513),
              foregroundColor: Colors.white,
            ),
            child: const Text('Manage Security'),
          ),
        ],
      ),
    );
  }

  void _showDataManagementDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Data Management'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.backup, size: 64, color: Color(0xFF8B4513)),
            SizedBox(height: 16),
            Text(
              'Backup and restore platform data',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Create backups, restore data, and manage platform data integrity.',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Data Management feature coming soon!'),
                  backgroundColor: Color(0xFF8B4513),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B4513),
              foregroundColor: Colors.white,
            ),
            child: const Text('Manage Data'),
          ),
        ],
      ),
    );
  }
}
