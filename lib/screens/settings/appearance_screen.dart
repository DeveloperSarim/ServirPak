import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/theme_service.dart';

class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Appearance',
          style: TextStyle(
            color: Color(0xFF8B4513),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF8B4513)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [_buildDarkModeSection(context)],
      ),
    );
  }

  Widget _buildDarkModeSection(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dark Mode',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF8B4513),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Switch between light and dark themes',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Consumer<ThemeService>(
              builder: (context, themeService, child) {
                return SwitchListTile(
                  title: const Text('Dark Mode'),
                  subtitle: const Text('Enable dark theme'),
                  value: themeService.isDarkMode,
                  onChanged: (value) {
                    themeService.toggleTheme();
                  },
                  secondary: const Icon(
                    Icons.dark_mode,
                    color: Color(0xFF8B4513),
                  ),
                  activeColor: const Color(0xFF8B4513),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
