import 'package:flutter/material.dart';
import '../screens/statistics_screen.dart';
import '../screens/security_settings_screen.dart';
import '../screens/sync_screen.dart';
import '../screens/categories_screen.dart';
import '../screens/search_screen.dart';
import '../screens/people_screen.dart';
import '../services/security_service.dart';
import 'ios_switch.dart'; // needed for the custom toggle widget
import 'package:expense_tracker/widgets/footers/footer_manager.dart';
import '../screens/animation_settings_screen.dart';

class AppDrawer extends StatelessWidget {
  final VoidCallback onThemeToggle;
  final bool isDarkMode;
  final Function(int) onMenuItemTap;

  const AppDrawer({
    super.key,
    required this.onThemeToggle,
    required this.isDarkMode,
    required this.onMenuItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1C1C1E)
            : Colors.white,
        child: SafeArea(
          child: Column(
            children: [
              // Header with app name
              Container(
                padding: const EdgeInsets.all(20),
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withOpacity(0.7),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'GT EXPENSER',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FutureBuilder<String?>(
                      future: _getUserName(),
                      builder: (context, snapshot) {
                        return Text(
                          snapshot.data ?? 'Welcome back!',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Menu items
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _buildMenuItem(
                      context,
                      icon: Icons.home,
                      label: 'Home',
                      onTap: () {
                        Navigator.pop(context);
                        onMenuItemTap(0);
                      },
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.bar_chart,
                      label: 'Statistics',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const StatisticsScreen(),
                          ),
                        );
                      },
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.security,
                      label: 'Security',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SecuritySettingsScreen(),
                          ),
                        );
                      },
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.photo_library,
                      label: 'Gallery',
                      onTap: () {
                        Navigator.pop(context);
                        // TODO: Navigate to gallery
                      },
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.category,
                      label: 'Categories',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CategoriesScreen(),
                          ),
                        );
                      },
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.search,
                      label: 'Search',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SearchScreen(),
                          ),
                        );
                      },
                    ),
                    // people menu item
                    _buildMenuItem(
                      context,
                      icon: Icons.people,
                      label: 'People',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PeopleScreen(),
                          ),
                        );
                      },
                    ),

                    const Divider(height: 32),

                    // Dark mode toggle
                    // Your existing dark mode toggle - FIND AND REPLACE THIS
                    // NEW iOS-style toggle - REPLACE WITH THIS
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isDarkMode ? Icons.nightlight_round : Icons.wb_sunny,
                                color: Theme.of(context).primaryColor,
                                size: 20,
                              ),
                              const SizedBox(width: 16),
                              const Text(
                                'Dark Mode',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          iOSSwitch(
                            value: isDarkMode,
                            onChanged: (value) {
                              onThemeToggle(); // This still works with your existing setup
                              Navigator.pop(context);
                            },
                            hapticFeedback: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    _buildMenuItem(
                      context,
                      icon: Icons.sync,
                      label: 'Sync Devices',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SyncScreen(),
                          ),
                        );
                      },
                    ),

                    _buildMenuItem(
                      context,
                      icon: Icons.settings,
                      label: 'Settings',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AnimationSettingsScreen(),
                          ),
                        );
                      },
                    ),

                    const Divider(height: 32),

                    _buildMenuItem(
                      context,
                      icon: Icons.download,
                      label: 'Export Data',
                      onTap: () {
                        Navigator.pop(context);
                        // TODO: Implement export
                      },
                    ),

                    _buildMenuItem(
                      context,
                      icon: Icons.info,
                      label: 'About',
                      onTap: () {
                        Navigator.pop(context);
                        _showAboutDialog(context);
                      },
                    ),

                    _buildMenuItem(
                      context,
                      icon: Icons.logout,
                      label: 'Logout',
                      onTap: () {
                        Navigator.pop(context);
                        _showLogoutDialog(context);
                      },
                      color: Colors.red,
                    ),
                  ],
                ),
              ),

              // Version info at bottom
              Column(
              children: [
                const FooterManager(),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Version 1.0.0',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: color ?? Theme.of(context).primaryColor,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      dense: true,
    );
  }

  Future<String?> _getUserName() async {
    // You can implement this to get actual user name
    return 'Welcome back!';
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About GT Expenser'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.attach_money,
                size: 40,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'GT Expenser v1.0.0',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your personal expense tracker with sync, splits, and beautiful charts.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
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
              // TODO: Implement logout
              Navigator.pop(context);
              Navigator.pop(context); // Close drawer
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}