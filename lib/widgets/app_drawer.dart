import 'package:flutter/material.dart';
import '../screens/statistics_screen.dart';
import '../screens/security_settings_screen.dart';
import '../screens/sync_screen.dart';
import '../screens/categories_screen.dart';
import '../screens/search_screen.dart';
import '../screens/people_screen.dart';
import '../screens/pin_screen.dart';
import '../screens/home_screen.dart';
import '../services/security_service.dart';
import '../services/export_service.dart';
import '../services/settings_service.dart';
import 'ios_switch.dart';
import 'package:expense_tracker/widgets/footers/footer_manager.dart';
import '../screens/animation_settings_screen.dart';
import '../screens/budget_screen.dart';
import '../screens/subscription_screen.dart';
import '../screens/templates_screen.dart';
import '../screens/goals_screen.dart';
import '../screens/expense_limits_screen.dart';
import '../screens/savings_challenge_screen.dart';
import '../screens/debt_tracker_screen.dart';
import '../screens/investment_screen.dart';
import '../screens/emergency_fund_screen.dart';
import '../screens/tax_report_screen.dart';
import '../screens/bill_reminders_screen.dart';
import '../screens/multi_account_screen.dart';
import '../screens/expense_calendar_screen.dart';
import '../screens/photo_gallery_screen.dart';
import '../screens/split_history_screen.dart';
import '../screens/spending_heatmap_screen.dart';

class AppDrawer extends StatefulWidget {
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
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  bool _financialExpanded = false;
  bool _uxExpanded = false;
  bool _toolsExpanded = false;

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
                    // Core items
                    _buildMenuItem(
                      context,
                      icon: Icons.home,
                      label: 'Home',
                      onTap: () {
                        Navigator.pop(context);
                        widget.onMenuItemTap(0);
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

                    const Divider(height: 16),

                    // Financial section
                    _buildSectionHeader(
                      context,
                      icon: Icons.account_balance,
                      label: 'Financial',
                      isExpanded: _financialExpanded,
                      onTap: () => setState(() => _financialExpanded = !_financialExpanded),
                    ),
                    if (_financialExpanded) ...[
                      _buildMenuItem(
                        context,
                        icon: Icons.description,
                        label: 'Templates',
                        indent: true,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const TemplatesScreen(),
                            ),
                          );
                        },
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.account_balance_wallet,
                        label: 'Budgets',
                        indent: true,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const BudgetScreen(),
                            ),
                          );
                        },
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.savings,
                        label: 'Goals',
                        indent: true,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const GoalsScreen(),
                            ),
                          );
                        },
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.speed,
                        label: 'Expense Limits',
                        indent: true,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ExpenseLimitsScreen(),
                            ),
                          );
                        },
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.emoji_events,
                        label: 'Savings Challenge',
                        indent: true,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SavingsChallengeScreen(),
                            ),
                          );
                        },
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.money_off,
                        label: 'Debt Tracker',
                        indent: true,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const DebtTrackerScreen(),
                            ),
                          );
                        },
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.trending_up,
                        label: 'Investments',
                        indent: true,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const InvestmentScreen(),
                            ),
                          );
                        },
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.security,
                        label: 'Emergency Fund',
                        indent: true,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const EmergencyFundScreen(),
                            ),
                          );
                        },
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.receipt_long,
                        label: 'Tax Report',
                        indent: true,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const TaxReportScreen(),
                            ),
                          );
                        },
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.notifications_active,
                        label: 'Bill Reminders',
                        indent: true,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const BillRemindersScreen(),
                            ),
                          );
                        },
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.account_balance,
                        label: 'Multi-Account',
                        indent: true,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MultiAccountScreen(),
                            ),
                          );
                        },
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.subscriptions,
                        label: 'Subscriptions',
                        indent: true,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SubscriptionScreen(),
                            ),
                          );
                        },
                      ),
                    ],

                    // UX section
                    _buildSectionHeader(
                      context,
                      icon: Icons.dashboard_customize,
                      label: 'UX & Insights',
                      isExpanded: _uxExpanded,
                      onTap: () => setState(() => _uxExpanded = !_uxExpanded),
                    ),
                    if (_uxExpanded) ...[
                      _buildMenuItem(
                        context,
                        icon: Icons.calendar_month,
                        label: 'Calendar',
                        indent: true,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ExpenseCalendarScreen(),
                            ),
                          );
                        },
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.photo_library,
                        label: 'Photo Gallery',
                        indent: true,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PhotoGalleryScreen(),
                            ),
                          );
                        },
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.history,
                        label: 'Split History',
                        indent: true,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SplitHistoryScreen(),
                            ),
                          );
                        },
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.grid_on,
                        label: 'Heatmap',
                        indent: true,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SpendingHeatmapScreen(),
                            ),
                          );
                        },
                      ),
                    ],

                    // Tools section
                    _buildSectionHeader(
                      context,
                      icon: Icons.build,
                      label: 'Tools',
                      isExpanded: _toolsExpanded,
                      onTap: () => setState(() => _toolsExpanded = !_toolsExpanded),
                    ),
                    if (_toolsExpanded) ...[
                      _buildMenuItem(
                        context,
                        icon: Icons.sync,
                        label: 'Sync Devices',
                        indent: true,
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
                        icon: Icons.download,
                        label: 'Export Data',
                        indent: true,
                        onTap: () async {
                          Navigator.pop(context);
                          try {
                            final exportService = ExportService();
                            final path = await exportService.exportTransactionsToCsv();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Exported to: $path'),
                                  backgroundColor: Colors.green,
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Export failed: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.currency_exchange,
                        label: 'Currency',
                        indent: true,
                        onTap: () {
                          Navigator.pop(context);
                          _showCurrencyPicker(context);
                        },
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.security,
                        label: 'Security',
                        indent: true,
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
                        icon: Icons.settings,
                        label: 'Settings',
                        indent: true,
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
                    ],

                    const Divider(height: 16),

                    // Dark mode toggle
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                widget.isDarkMode ? Icons.nightlight_round : Icons.wb_sunny,
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
                          IOSSwitch(
                            value: widget.isDarkMode,
                            onChanged: (value) {
                              widget.onThemeToggle();
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

  Widget _buildSectionHeader(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isExpanded,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Theme.of(context).primaryColor),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).primaryColor,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            Icon(
              isExpanded ? Icons.expand_less : Icons.expand_more,
              color: Theme.of(context).primaryColor,
            ),
          ],
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
    bool indent = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: color ?? Theme.of(context).primaryColor,
        size: indent ? 20 : 24,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w500,
          fontSize: indent ? 14 : 16,
        ),
      ),
      onTap: onTap,
      dense: true,
      contentPadding: EdgeInsets.only(
        left: indent ? 32 : 16,
        right: 16,
      ),
    );
  }

  Future<String?> _getUserName() async {
    return 'Welcome back!';
  }

  void _showCurrencyPicker(BuildContext context) {
    final settings = SettingsService();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Currency'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: SettingsService.availableCurrencies.length,
            itemBuilder: (context, index) {
              final currency = SettingsService.availableCurrencies[index];
              final isSelected = currency['symbol'] == settings.currencySymbol;
              return ListTile(
                leading: Text(
                  currency['symbol']!,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                title: Text(currency['name']!),
                trailing: isSelected ? Icon(Icons.check, color: Theme.of(context).primaryColor) : null,
                onTap: () async {
                  await settings.setCurrency(currency['symbol']!);
                  if (context.mounted) Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
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
            onPressed: () async {
              final security = SecurityService();
              await security.resetSecurity();
              if (!context.mounted) return;
              Navigator.pop(context);
              Navigator.pop(context); // Close drawer
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => PinScreen(
                    isSetup: true,
                    onSuccess: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HomeScreen(
                            onThemeToggle: widget.onThemeToggle,
                            isDarkMode: widget.isDarkMode,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
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
