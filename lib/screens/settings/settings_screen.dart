import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/theme_service.dart';
import '../../constants/app_constants.dart';
import '../auth/login_screen.dart';
import '../profile/edit_profile_screen.dart';
import '../../models/user_model.dart';

class SettingsScreen extends StatefulWidget {
  final String userRole;
  final UserModel? user;

  const SettingsScreen({super.key, required this.userRole, this.user});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();
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
          _buildThemeSettings(),
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
              backgroundColor: Colors.deepPurple.withOpacity(0.1),
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
                      color: Colors.deepPurple,
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
          icon: Icons.security,
          title: 'Privacy & Security',
          subtitle: 'Manage your privacy settings',
          onTap: () {
            // TODO: Navigate to privacy settings
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Privacy Settings - Coming Soon')),
            );
          },
        ),
        _buildListTile(
          icon: Icons.help,
          title: 'Help & Support',
          subtitle: 'Get help and contact support',
          onTap: () {
            // TODO: Navigate to help screen
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Help & Support - Coming Soon')),
            );
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
            // TODO: Navigate to email settings
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Email Settings - Coming Soon')),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAppearanceSettings() {
    return _buildSection(
      title: 'Appearance',
      children: [
        SwitchListTile(
          title: const Text('Dark Mode'),
          subtitle: const Text('Switch between light and dark themes'),
          value: _darkModeEnabled,
          onChanged: (value) {
            setState(() {
              _darkModeEnabled = value;
            });
          },
          secondary: const Icon(Icons.dark_mode),
        ),
        _buildListTile(
          icon: Icons.palette,
          title: 'Theme Colors',
          subtitle: 'Customize app colors',
          onTap: () {
            // TODO: Navigate to theme settings
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Theme Settings - Coming Soon')),
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
            // TODO: Implement location services
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location Services - Coming Soon')),
            );
          },
        ),
        _buildListTile(
          icon: Icons.location_searching,
          title: 'Location History',
          subtitle: 'View your location history',
          onTap: () {
            // TODO: Show location history
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location History - Coming Soon')),
            );
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
            // TODO: Navigate to change password
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Change Password - Coming Soon')),
            );
          },
        ),
        _buildListTile(
          icon: Icons.email,
          title: 'Change Email',
          subtitle: 'Update your email address',
          onTap: () {
            // TODO: Navigate to change email
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Change Email - Coming Soon')),
            );
          },
        ),
        _buildListTile(
          icon: Icons.phone,
          title: 'Change Phone',
          subtitle: 'Update your phone number',
          onTap: () {
            // TODO: Navigate to change phone
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Change Phone - Coming Soon')),
            );
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
          onTap: () {
            // TODO: Navigate to user management
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('User Management - Coming Soon')),
            );
          },
        ),
        _buildListTile(
          icon: Icons.verified_user,
          title: 'Lawyer Verification',
          subtitle: 'Approve or reject lawyer applications',
          onTap: () {
            // TODO: Navigate to lawyer verification
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Lawyer Verification - Coming Soon'),
              ),
            );
          },
        ),
        _buildListTile(
          icon: Icons.analytics,
          title: 'Analytics & Reports',
          subtitle: 'View platform analytics and generate reports',
          onTap: () {
            // TODO: Navigate to analytics
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Analytics - Coming Soon')),
            );
          },
        ),
        _buildListTile(
          icon: Icons.settings_system_daydream,
          title: 'System Settings',
          subtitle: 'Configure platform-wide settings',
          onTap: () {
            // TODO: Navigate to system settings
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('System Settings - Coming Soon')),
            );
          },
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
            color: Colors.deepPurple,
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
              // TODO: Implement account deletion
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Account Deletion - Coming Soon')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSettings() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Theme Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF8B4513),
              ),
            ),
            const SizedBox(height: 16),
            Consumer<ThemeService>(
              builder: (context, themeService, child) {
                return Column(
                  children: [
                    ListTile(
                      leading: const Icon(
                        Icons.light_mode,
                        color: Color(0xFF8B4513),
                      ),
                      title: const Text('Light Mode'),
                      trailing: Radio<ThemeMode>(
                        value: ThemeMode.light,
                        groupValue: themeService.themeMode,
                        onChanged: (ThemeMode? value) {
                          if (value != null) {
                            themeService.setThemeMode(value);
                          }
                        },
                        activeColor: const Color(0xFF8B4513),
                      ),
                      onTap: () {
                        themeService.setThemeMode(ThemeMode.light);
                      },
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.dark_mode,
                        color: Color(0xFF8B4513),
                      ),
                      title: const Text('Dark Mode'),
                      trailing: Radio<ThemeMode>(
                        value: ThemeMode.dark,
                        groupValue: themeService.themeMode,
                        onChanged: (ThemeMode? value) {
                          if (value != null) {
                            themeService.setThemeMode(value);
                          }
                        },
                        activeColor: const Color(0xFF8B4513),
                      ),
                      onTap: () {
                        themeService.setThemeMode(ThemeMode.dark);
                      },
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.brightness_auto,
                        color: Color(0xFF8B4513),
                      ),
                      title: const Text('System Default'),
                      trailing: Radio<ThemeMode>(
                        value: ThemeMode.system,
                        groupValue: themeService.themeMode,
                        onChanged: (ThemeMode? value) {
                          if (value != null) {
                            themeService.setThemeMode(value);
                          }
                        },
                        activeColor: const Color(0xFF8B4513),
                      ),
                      onTap: () {
                        themeService.setThemeMode(ThemeMode.system);
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
