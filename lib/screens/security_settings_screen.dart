import 'package:flutter/material.dart';
import '../services/security_service.dart';
import 'pin_screen.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  final SecurityService _security = SecurityService();
  
  bool _isPinEnabled = false;
  int _autoLockDelay = SecurityService.delayOptions['After 5 minutes']!;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final isPinEnabled = await _security.isPinEnabled();
    final autoLockDelay = await _security.getAutoLockDelay();
    
    setState(() {
      _isPinEnabled = isPinEnabled;
      _autoLockDelay = autoLockDelay;
      _isLoading = false;
    });
  }

  Future<void> _togglePin(bool value) async {
    if (value) {
      // Navigate to PIN setup
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PinScreen(
            isSetup: true,
            onSuccess: () {
              Navigator.pop(context, true);
            },
          ),
        ),
      );
      
      if (result == true) {
        _loadSettings();
      }
    } else {
      // Disable PIN
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Disable PIN?'),
          content: const Text('Your app will no longer be protected by PIN.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Disable'),
            ),
          ],
        ),
      );
      
      if (confirm == true) {
        await _security.disablePin();
        _loadSettings();
      }
    }
  }

  Future<void> _changeAutoLockDelay(int delay) async {
    await _security.setAutoLockDelay(delay);
    setState(() {
      _autoLockDelay = delay;
    });
  }

  String _getDelayLabel(int delay) {
    return SecurityService.delayOptions.entries
        .firstWhere((entry) => entry.value == delay)
        .key;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Settings'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                const SizedBox(height: 16),
                
                // PIN Lock Section
                _buildSection(
                  title: 'PIN Lock',
                  children: [
                    SwitchListTile(
                      title: const Text('Enable PIN Lock'),
                      subtitle: const Text('Protect app with 6-digit PIN'),
                      value: _isPinEnabled,
                      onChanged: _togglePin,
                      activeColor: Theme.of(context).primaryColor,
                    ),
                    if (_isPinEnabled) ...[
                      ListTile(
                        title: const Text('Change PIN'),
                        leading: const Icon(Icons.lock_reset),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PinScreen(
                                isSetup: true,
                                onSuccess: () {
                                  Navigator.pop(context);
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
                
                const Divider(),
                
                // Auto-lock Section
                if (_isPinEnabled)
                  _buildSection(
                    title: 'Auto-Lock',
                    children: [
                      ListTile(
                        title: const Text('Lock After'),
                        subtitle: Text(_getDelayLabel(_autoLockDelay)),
                        trailing: DropdownButton<int>(
                          value: _autoLockDelay,
                          items: SecurityService.delayOptions.entries
                              .map((entry) => DropdownMenuItem(
                                    value: entry.value,
                                    child: Text(entry.key),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              _changeAutoLockDelay(value);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                
                const Divider(),
                
                // Danger Zone
                _buildSection(
                  title: 'Danger Zone',
                  children: [
                    ListTile(
                      title: const Text(
                        'Reset All Security',
                        style: TextStyle(color: Colors.red),
                      ),
                      leading: const Icon(Icons.warning, color: Colors.red),
                      onTap: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Reset Security?'),
                            content: const Text(
                              'This will disable PIN authentication.'
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                child: const Text('Reset'),
                              ),
                            ],
                          ),
                        );
                        
                        if (confirm == true) {
                          await _security.resetSecurity();
                          _loadSettings();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Security settings reset'),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
        ),
        ...children,
      ],
    );
  }
}