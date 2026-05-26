import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/database_service.dart';
import '../widgets/transaction_card.dart';
import '../widgets/app_drawer.dart';
import '../utils/page_transitions.dart';
import 'add_transaction_screen.dart';
import 'transaction_detail_screen.dart';
import 'search_screen.dart';
import 'package:intl/intl.dart';
import '../services/settings_service.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onThemeToggle;
  final bool isDarkMode;

  const HomeScreen({
    super.key,
    required this.onThemeToggle,
    required this.isDarkMode,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseService _db = DatabaseService();
  List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> _pendingPeople = [];
  double _totalSpent = 0;
  double _pendingAmount = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    try {
      final transactionsData = await _db.getTransactionsWithPeople();
      final pendingData = await _db.getPendingAmounts();
      
      double totalPending = 0;
      
      for (var person in pendingData) {
        totalPending += (person['owedToMe'] as num?)?.toDouble() ?? 0;
      }
      
      double total = 0;
      for (var txn in transactionsData) {
        total += (txn['amount'] as num?)?.toDouble() ?? 0;
      }
      
      setState(() {
        _transactions = transactionsData;
        _pendingPeople = pendingData;
        _totalSpent = total;
        _pendingAmount = totalPending;
      });
      
    } catch (e) {
      if (kDebugMode) {
        print('Error loading transactions: $e');
      }
    }
  }

  // Format large numbers with commas
  String _formatAmount(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: SettingsService().currencySymbol,
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  // ===== SCAN RECEIPT =====
  final ImagePicker _imagePicker = ImagePicker();

  Future<void> _scanReceipt() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        height: 200,
        child: Column(
          children: [
            const Text(
              'Add Receipt',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.blue),
              title: const Text('Take Photo'),
              onTap: () async {
                Navigator.pop(context);
                final photo = await _imagePicker.pickImage(source: ImageSource.camera);
                if (photo != null && mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddTransactionScreen(
                        initialAttachmentPath: photo.path,
                      ),
                    ),
                  ).then((_) => _loadTransactions());
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.blue),
              title: const Text('Choose from Gallery'),
              onTap: () async {
                Navigator.pop(context);
                final photo = await _imagePicker.pickImage(source: ImageSource.gallery);
                if (photo != null && mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddTransactionScreen(
                        initialAttachmentPath: photo.path,
                      ),
                    ),
                  ).then((_) => _loadTransactions());
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // ===== MANAGE SPLIT =====
  Future<void> _manageSplit() async {
    if (_pendingPeople.isEmpty) {
      _showComingSoon('No pending splits');
      return;
    }
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        height: 400,
        child: Column(
          children: [
            const Text(
              'Pending Splits',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _pendingPeople.length,
                itemBuilder: (context, index) {
                  final person = _pendingPeople[index];
                  final amount = (person['owedToMe'] as double?) ?? 0;
                  if (amount <= 0) return const SizedBox();
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.withOpacity(0.1),
                        child: Text(
                          person['name']?[0]?.toUpperCase() ?? '?',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(person['name'] ?? 'Unknown'),
                      subtitle: Text('Owes you ${_formatAmount(amount)}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.notifications, color: Colors.orange),
                            onPressed: () {
                              Navigator.pop(context);
                              _remindPerson(person);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.check_circle, color: Colors.green),
                            onPressed: () {
                              Navigator.pop(context);
                              _markAsSettled(person);
                            },
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
      ),
    );
  }

  // ===== SHOW REMINDERS =====
  Future<void> _showReminders() async {
    if (_pendingPeople.isEmpty) {
      _showComingSoon('No pending reminders');
      return;
    }
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        height: 400,
        child: Column(
          children: [
            const Text(
              'Payment Reminders',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _pendingPeople.length,
                itemBuilder: (context, index) {
                  final person = _pendingPeople[index];
                  final amount = (person['owedToMe'] as double?) ?? 0;
                  if (amount <= 0) return const SizedBox();
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.orange.withOpacity(0.1),
                        child: Text(
                          person['name']?[0]?.toUpperCase() ?? '?',
                          style: const TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(person['name'] ?? 'Unknown'),
                      subtitle: Text('₹${amount.toStringAsFixed(2)} pending'),
                      trailing: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _remindPerson(person);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                        ),
                        child: const Text('Remind'),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== REMIND PERSON =====
  void _remindPerson(Map<String, dynamic> person) {
    final amount = (person['owedToMe'] as double?) ?? 0;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remind ${person['name']}'),
        content: Text('They owe you ${_formatAmount(amount)}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Reminder sent to ${person['name']}'),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2),
                ),
              );
              // TODO: Implement actual reminder (SMS/Notification)
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Send Reminder'),
          ),
        ],
      ),
    );
  }

  // ===== MARK AS SETTLED =====
  void _markAsSettled(Map<String, dynamic> person) {
    final amount = (person['owedToMe'] as double?) ?? 0;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Settle with ${person['name']}'),
        content: Text('Mark ₹${amount.toStringAsFixed(2)} as paid?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                // Get all pending transaction_people for this person and settle them
                final personId = person['id'] as String;
                final transactions = await _db.getPersonTransactions(personId);
                for (var txn in transactions) {
                  if (txn['status'] != 'settled') {
                    final tpRecords = await _db.getPeopleForTransaction(txn['id']);
                    for (var tp in tpRecords) {
                      if (tp['personId'] == personId && tp['status'] != 'settled') {
                        await _db.markTransactionAsSettled(tp['id']);
                      }
                    }
                  }
                }
                await _loadTransactions();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Payment from ${person['name']} recorded'),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error settling: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  // ===== HELPER: Show Coming Soon Dialog =====
  void _showComingSoon(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(feature),
        content: Text('This feature is coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Expenses'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        // ✅ ACTIONS SECTION WITH SEARCH BUTTON ADDED
        actions: [
          // 🔍 SEARCH BUTTON - ADDED HERE
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                SlideFadePageRoute(page: const SearchScreen()),
              );
            },
          ),
          
          // // Statistics Button
          // IconButton(
          //   icon: const Icon(Icons.bar_chart),
          //   onPressed: () {
          //     Navigator.push(
          //       context,
          //       MaterialPageRoute(
          //         builder: (context) => const StatisticsScreen(),
          //       ),
          //     );
          //   },
          // ),
          
          // Theme Toggle Button
          IconButton(
            icon: Icon(widget.isDarkMode ? Icons.sunny : Icons.dark_mode),
            onPressed: widget.onThemeToggle,
          ),
          
          // // Security Settings Button
          // IconButton(
          //   icon: const Icon(Icons.security),
          //   onPressed: () {
          //     Navigator.push(
          //       context,
          //       MaterialPageRoute(
          //         builder: (context) => const SecuritySettingsScreen(),
          //       ),
          //     );
          //   },
          // ),
        ],
      ),
      drawer: AppDrawer(
        onThemeToggle: widget.onThemeToggle,
        isDarkMode: widget.isDarkMode,
        onMenuItemTap: (index) {
          if (index == 0) {
            // Already on home
          }
        },
      ),
      body: RefreshIndicator(
        onRefresh: _loadTransactions,
        child: ListView(
          children: [
            // Summary Cards with staggered entrance
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: StaggeredSlideIn(
                      index: 0,
                      child: _buildSummaryCard(
                        title: 'Total Spent',
                        amount: _totalSpent,
                        icon: Icons.trending_down,
                        color: Colors.red,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StaggeredSlideIn(
                      index: 1,
                      child: _buildSummaryCard(
                        title: 'Pending',
                        amount: _pendingAmount,
                        icon: Icons.access_time,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Quick Actions with staggered entrance
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  StaggeredSlideIn(
                    index: 2,
                    child: _buildActionButton(
                      icon: Icons.add,
                      label: 'Add',
                      onTap: () => _navigateToAddTransaction(),
                    ),
                  ),
                  StaggeredSlideIn(
                    index: 3,
                    child: _buildActionButton(
                      icon: Icons.camera_alt,
                      label: 'Scan',
                      onTap: _scanReceipt,
                    ),
                  ),
                  StaggeredSlideIn(
                    index: 4,
                    child: _buildActionButton(
                      icon: Icons.people,
                      label: 'Split',
                      onTap: _manageSplit,
                    ),
                  ),
                  StaggeredSlideIn(
                    index: 5,
                    child: _buildActionButton(
                      icon: Icons.notifications,
                      label: 'Remind',
                      onTap: _showReminders,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // People who owe you section
            if (_pendingPeople.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'People who owe you',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _pendingPeople.length,
                itemBuilder: (context, index) {
                  final person = _pendingPeople[index];
                  final owedAmount = (person['owedToMe'] as double? ?? 0);
                  
                  if (owedAmount <= 0) return const SizedBox();
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                        child: Text(
                          person['name']?[0]?.toUpperCase() ?? '?',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        person['name'] ?? 'Unknown',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Pending',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.notifications, color: Colors.orange),
                            onPressed: () => _remindPerson(person),
                          ),
                          IconButton(
                            icon: const Icon(Icons.check_circle, color: Colors.green),
                            onPressed: () => _markAsSettled(person),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
            
            // Transactions Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Transactions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        SlideFadePageRoute(page: const SearchScreen()),
                      );
                    },
                    child: const Text('See All'),
                  ),
                ],
              ),
            ),
            
            // Transactions List with staggered entrance
            _transactions.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: _transactions.length > 5 ? 5 : _transactions.length,
                    itemBuilder: (context, index) {
                      final txn = _transactions[index];
                      return StaggeredSlideIn(
                        index: index,
                        delay: const Duration(milliseconds: 60),
                        child: TransactionCard(
                          transaction: txn,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TransactionDetailScreen(
                                  transaction: txn,
                                ),
                              ),
                            ).then((shouldRefresh) {
                              if (shouldRefresh == true) {
                                _loadTransactions();
                              }
                            });
                          },
                        ),
                      );
                    },
                  ),
            
            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddTransaction(),
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          CountingText(
            endValue: amount,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        splashColor: Theme.of(context).primaryColor.withOpacity(0.15),
        highlightColor: Theme.of(context).primaryColor.withOpacity(0.08),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.receipt_long,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No transactions yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to add your first expense',
              style: TextStyle(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _navigateToAddTransaction() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddTransactionScreen(),
      ),
    );
    
    if (result == true) {
      _loadTransactions();
    }
  }
}