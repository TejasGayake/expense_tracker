import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/database_service.dart';
import 'add_person_screen.dart';
import 'package:intl/intl.dart';
import 'person_details_screen.dart';
import '../services/reminder_service.dart';

class PeopleScreen extends StatefulWidget {
  const PeopleScreen({super.key});

  @override
  State<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends State<PeopleScreen> with SingleTickerProviderStateMixin {
  final DatabaseService _db = DatabaseService();
  late TabController _tabController;
  
  // Data for different tabs
  List<Map<String, dynamic>> _allPeople = [];
  List<Map<String, dynamic>> _peopleWhoOweMe = [];
  List<Map<String, dynamic>> _peopleIOwe = [];
  List<Map<String, dynamic>> _settledPeople = [];
  
  // Filtered data for search
  List<Map<String, dynamic>> _filteredAllPeople = [];
  List<Map<String, dynamic>> _filteredWhoOweMe = [];
  List<Map<String, dynamic>> _filteredIOwe = [];
  List<Map<String, dynamic>> _filteredSettled = [];
  
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // ✅ ADD THIS LISTENER - Updates FAB when tab changes
    _tabController.addListener(() {
      if (mounted) {
        setState(() {}); // Rebuild to show/hide FAB based on tab index
      }
    });

    _loadPeople();
    _searchController.addListener(_filterPeople);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.removeListener(_filterPeople);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPeople() async {
    setState(() => _isLoading = true);
    
    try {
      if (kDebugMode) {
        print('🔍 Loading all people data...');
      }
      
      // Load all data in parallel for better performance
      final results = await Future.wait([
        _db.getAllPeopleWithSummary(),
        _db.getPeopleWhoOweMe(),
        _db.getPeopleIOwe(),
        _db.getSettledPeople(),
      ]);
      
      if (kDebugMode) {
        print('📊 All People count: ${results[0].length}');
        print('📊 People who owe me count: ${results[1].length}');
        print('📊 People I owe count: ${results[2].length}');
        print('📊 Settled people count: ${results[3].length}');
      }
      
      // Print the actual data to see what's coming back
      if (kDebugMode) {
        print('📋 All people data:');
        for (var person in results[0]) {
          print('   - ${person['name']} (ID: ${person['id']})');
        }
      }
      
      setState(() {
        _allPeople = results[0];
        _peopleWhoOweMe = results[1];
        _peopleIOwe = results[2];
        _settledPeople = results[3];
        
        // Initialize filtered lists
        _filteredAllPeople = _allPeople;
        _filteredWhoOweMe = _peopleWhoOweMe;
        _filteredIOwe = _peopleIOwe;
        _filteredSettled = _settledPeople;
        
        _isLoading = false;
      });
      
      if (kDebugMode) {
        print('✅ People loaded successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading people: $e');
      }
      setState(() => _isLoading = false);
    }
  }

  void _filterPeople() {
    final query = _searchController.text.toLowerCase().trim();
    
    if (query.isEmpty) {
      setState(() {
        _filteredAllPeople = _allPeople;
        _filteredWhoOweMe = _peopleWhoOweMe;
        _filteredIOwe = _peopleIOwe;
        _filteredSettled = _settledPeople;
      });
      return;
    }

    setState(() {
      // Filter all people
      _filteredAllPeople = _allPeople.where((p) {
        final name = (p['name'] as String? ?? '').toLowerCase();
        final phone = (p['phone'] as String? ?? '').toLowerCase();
        final email = (p['email'] as String? ?? '').toLowerCase();
        return name.contains(query) || phone.contains(query) || email.contains(query);
      }).toList();

      // Filter other tabs
      _filteredWhoOweMe = _peopleWhoOweMe.where((p) {
        final name = (p['name'] as String? ?? '').toLowerCase();
        final phone = (p['phone'] as String? ?? '').toLowerCase();
        return name.contains(query) || phone.contains(query);
      }).toList();

      _filteredIOwe = _peopleIOwe.where((p) {
        final name = (p['name'] as String? ?? '').toLowerCase();
        final phone = (p['phone'] as String? ?? '').toLowerCase();
        return name.contains(query) || phone.contains(query);
      }).toList();

      _filteredSettled = _settledPeople.where((p) {
        final name = (p['name'] as String? ?? '').toLowerCase();
        final phone = (p['phone'] as String? ?? '').toLowerCase();
        return name.contains(query) || phone.contains(query);
      }).toList();
    });
  }

  String _formatAmount(double amount) {
    return '₹${amount.toStringAsFixed(2)}';
  }

  String _formatDate(int? timestamp) {
    if (timestamp == null) return 'No transactions';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('People'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search people...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                  ),
                ),
              ),
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: const [
                  Tab(text: 'All People'),
                  Tab(text: 'Owes Me'),
                  Tab(text: 'I Owe'),
                  Tab(text: 'Settled'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // All People Tab
                _buildAllPeopleList(_filteredAllPeople),
                // Other tabs
                _buildPeopleList(_filteredWhoOweMe, 'whoOweMe'),
                _buildPeopleList(_filteredIOwe, 'iOwe'),
                _buildPeopleList(_filteredSettled, 'settled'),
              ],
            ),
      floatingActionButton: _tabController.index == 0 
          ? FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddPersonScreen(),
                  ),
                );

                if (result == true) {
                  if (kDebugMode) {
                    print('🔄 Person added, refreshing list...');
                  }
                  _loadPeople(); // Refresh the list
                  // ✅ FAB will automatically reappear because we're still on tab 0
                }
              },
              backgroundColor: Theme.of(context).primaryColor,
              child: const Icon(Icons.person_add, color: Colors.white),
            )
          : null,
    );
  }

  // All People tab builder
  Widget _buildAllPeopleList(List<Map<String, dynamic>> people) {
    if (people.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No people yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to add your first person',
              style: TextStyle(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: people.length,
      itemBuilder: (context, index) {
        final person = people[index];
        return _buildAllPersonCard(person);
      },
    );
  }

  // All People card design - FIXED BUTTONS
  Widget _buildAllPersonCard(Map<String, dynamic> person) {
    final owedToMe = (person['owedToMe'] as num?)?.toDouble() ?? 0;
    final iOwe = (person['iOwe'] as num?)?.toDouble() ?? 0;
    final pendingCount = (person['pendingCount'] as num?)?.toInt() ?? 0;
    final lastTransaction = person['lastTransactionDescription'] ?? 'No transactions';
    final lastDate = person['lastTransactionDate'] as int?;
    
    // Determine status color
    Color statusColor;
    String statusText;
    IconData statusIcon;
    
    if (owedToMe > 0) {
      statusColor = Colors.green;
      statusText = 'Owes you ${_formatAmount(owedToMe)}';
      statusIcon = Icons.arrow_upward;
    } else if (iOwe > 0) {
      statusColor = Colors.orange;
      statusText = 'You owe ${_formatAmount(iOwe)}';
      statusIcon = Icons.arrow_downward;
    } else {
      statusColor = Colors.grey;
      statusText = 'Settled';
      statusIcon = Icons.check_circle;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PersonDetailsScreen(
                person: person,
              ),
            ),
          ).then((shouldRefresh) {
            if (shouldRefresh == true) {
              _loadPeople();
            }
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: statusColor,
                    child: Text(
                      (person['name']?[0] ?? '?').toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          person['name'] ?? 'Unknown',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (person['phone'] != null)
                          Text(
                            person['phone'],
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                  Icon(statusIcon, color: statusColor, size: 20),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.receipt,
                          size: 14,
                          color: statusColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$pendingCount pending',
                          style: TextStyle(
                            fontSize: 12,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 12,
                        color: statusColor,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (lastDate != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Last: $lastTransaction • ${_formatDate(lastDate)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
              ],
              const SizedBox(height: 8),
              // FIXED BUTTONS ROW - No more infinite width errors
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // ===============================
                  // Replace the Remind button section
                  if (owedToMe > 0 || iOwe > 0)
                    TextButton(
                      onPressed: () async {
                        final amount = owedToMe > 0 ? owedToMe : iOwe;

                        final result = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Remind ${person['name']}'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(owedToMe > 0 
                                    ? 'They owe you ${_formatAmount(amount)}'
                                    : 'You owe them ${_formatAmount(amount)}'),
                                const SizedBox(height: 16),
                                const Text('Send a reminder notification?'),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                ),
                                child: const Text('Send'),
                              ),
                            ],
                          ),
                        );

                        if (result == true) {
                          try {
                            final reminderService = ReminderService();
                            await reminderService.initialize();
                            await reminderService.sendReminder(
                              personName: person['name'],
                              amount: amount,
                            );

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Reminder sent to ${person['name']}'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.orange,
                        minimumSize: const Size(70, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.notifications, size: 16),
                          SizedBox(width: 4),
                          Text('Remind', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  // ===================================
                  const SizedBox(width: 4),
                  // Fixed width button using SizedBox
                  SizedBox(
                    width: 70,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PersonDetailsScreen(
                              person: person,
                            ),
                          ),
                        ).then((shouldRefresh) {
                          if (shouldRefresh == true) {
                            _loadPeople();
                          }
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(70, 36),
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.visibility, size: 14),
                          SizedBox(width: 2),
                          Text('View', style: TextStyle(fontSize: 11)),
                        ],
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

  // Other tabs list builder
  Widget _buildPeopleList(List<Map<String, dynamic>> people, String type) {
    if (people.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getEmptyIcon(type),
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _getEmptyMessage(type),
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: people.length,
      itemBuilder: (context, index) {
        final person = people[index];
        return _buildPersonCard(person, type);
      },
    );
  }

  // Other tabs card design - FIXED BUTTONS
  Widget _buildPersonCard(Map<String, dynamic> person, String type) {
    final owedToMe = (person['owedToMe'] as num?)?.toDouble() ?? 0;
    final iOwe = (person['iOwe'] as num?)?.toDouble() ?? 0;
    final pendingCount = (person['pendingCount'] as num?)?.toInt() ?? 0;
    final lastTransaction = person['lastTransactionDescription'] ?? 'No transactions';
    final lastDate = person['lastTransactionDate'] as int?;
    
    Color cardColor;
    IconData statusIcon;
    String amountText;
    Color amountColor;
    
    if (type == 'whoOweMe') {
      cardColor = Colors.green.shade50;
      statusIcon = Icons.arrow_upward;
      amountText = _formatAmount(owedToMe);
      amountColor = Colors.green;
    } else if (type == 'iOwe') {
      cardColor = Colors.orange.shade50;
      statusIcon = Icons.arrow_downward;
      amountText = _formatAmount(iOwe);
      amountColor = Colors.orange;
    } else {
      cardColor = Colors.grey.shade50;
      statusIcon = Icons.check_circle;
      amountText = 'Settled';
      amountColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: type == 'whoOweMe' ? Colors.green.shade200 : 
                 type == 'iOwe' ? Colors.orange.shade200 : 
                 Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PersonDetailsScreen(
                person: person,
              ),
            ),
          ).then((shouldRefresh) {
            if (shouldRefresh == true) {
              _loadPeople();
            }
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: type == 'whoOweMe' ? Colors.green : 
                                    type == 'iOwe' ? Colors.orange : 
                                    Colors.grey,
                    child: Text(
                      (person['name']?[0] ?? '?').toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          person['name'] ?? 'Unknown',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (person['phone'] != null)
                          Text(
                            person['phone'],
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                  Icon(statusIcon, color: amountColor, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    amountText,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: amountColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: type == 'whoOweMe' ? Colors.green.withOpacity(0.1) :
                             type == 'iOwe' ? Colors.orange.withOpacity(0.1) :
                             Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.receipt,
                          size: 14,
                          color: amountColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$pendingCount pending',
                          style: TextStyle(
                            fontSize: 12,
                            color: amountColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Last: $lastTransaction',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (lastDate != null) ...[
                const SizedBox(height: 4),
                Text(
                  _formatDate(lastDate),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
              ],
              const SizedBox(height: 8),
              // FIXED BUTTONS ROW - No more infinite width errors
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Replace the Remind button section
                  if (owedToMe > 0 || iOwe > 0)
                    TextButton(
                      onPressed: () async {
                        final amount = owedToMe > 0 ? owedToMe : iOwe;

                        final result = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Remind ${person['name']}'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(owedToMe > 0 
                                    ? 'They owe you ${_formatAmount(amount)}'
                                    : 'You owe them ${_formatAmount(amount)}'),
                                const SizedBox(height: 16),
                                const Text('Send a reminder notification?'),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                ),
                                child: const Text('Send'),
                              ),
                            ],
                          ),
                        );

                        if (result == true) {
                          try {
                            final reminderService = ReminderService();
                            await reminderService.initialize();
                            await reminderService.sendReminder(
                              personName: person['name'],
                              amount: amount,
                            );

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Reminder sent to ${person['name']}'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.orange,
                        minimumSize: const Size(70, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.notifications, size: 16),
                          SizedBox(width: 4),
                          Text('Remind', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  const SizedBox(width: 4),
                  // Fixed width button using SizedBox
                  SizedBox(
                    width: 70,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PersonDetailsScreen(
                              person: person,
                            ),
                          ),
                        ).then((shouldRefresh) {
                          if (shouldRefresh == true) {
                            _loadPeople();
                          }
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(70, 36),
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.visibility, size: 14),
                          SizedBox(width: 2),
                          Text('View', style: TextStyle(fontSize: 11)),
                        ],
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

  IconData _getEmptyIcon(String type) {
    switch (type) {
      case 'whoOweMe':
        return Icons.arrow_upward;
      case 'iOwe':
        return Icons.arrow_downward;
      default:
        return Icons.people;
    }
  }

  String _getEmptyMessage(String type) {
    switch (type) {
      case 'whoOweMe':
        return 'No one owes you money';
      case 'iOwe':
        return 'You don\'t owe anyone';
      default:
        return 'No settled people yet';
    }
  }
}