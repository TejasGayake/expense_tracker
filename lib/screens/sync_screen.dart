import 'package:flutter/material.dart';
import '../services/sync_service.dart';

class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  final SyncService _syncService = SyncService();
  
  bool _isServerRunning = false;
  String? _connectedDevice;
  String _status = 'Initializing...';
  DateTime? _lastSync;
  bool _autoSync = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initSync();
  }

  Future<void> _initSync() async {
    // Set up callbacks
    _syncService.onConnectionChanged = (connected) {
      setState(() {
        _connectedDevice = connected ? 'Device Connected' : null;
      });
    };
    
    _syncService.onStatusChanged = (status) {
      setState(() {
        _status = status;
      });
    };
    
    // Check platform and start appropriate mode
    if (Theme.of(context).platform == TargetPlatform.windows) {
      // Windows acts as server
      _startServer();
    } else {
      // Android acts as client
      _startDiscovery();
    }
    
    // Load settings
    _autoSync = await _syncService.getAutoSyncEnabled();
    _lastSync = _syncService.lastSyncTime;
  }

  Future<void> _startServer() async {
    setState(() {
      _isLoading = true;
      _status = 'Starting server...';
    });
    
    final success = await _syncService.startServer();
    
    setState(() {
      _isServerRunning = success;
      _isLoading = false;
    });
  }

  Future<void> _startDiscovery() async {
    setState(() {
      _isLoading = true;
    });
    
    await _syncService.startDiscovery();
    
    setState(() {
      _isLoading = false;
    });
  }

  final TextEditingController _ipController = TextEditingController();

  Future<void> _syncNow() async {
    setState(() {
      _isLoading = true;
      _status = 'Syncing...';
    });

    try {
      if (_syncService.isConnected && _syncService.connectedServerIp != null) {
        // Already connected, trigger sync via the connected server
        await _syncService.syncWithServer(
          _syncService.connectedServerIp!,
          _syncService.connectedServerPort ?? SyncService.syncPort,
        );
        setState(() {
          _lastSync = DateTime.now();
          _status = 'Sync completed';
          _isLoading = false;
        });
      } else {
        // Not connected, show manual IP entry
        setState(() {
          _isLoading = false;
          _status = 'Not connected. Enter server IP.';
        });
        _showManualConnectDialog();
      }
    } catch (e) {
      setState(() {
        _status = 'Sync failed: $e';
        _isLoading = false;
      });
    }
  }

  void _showManualConnectDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Connect to PC'),
        content: TextField(
          controller: _ipController,
          decoration: const InputDecoration(
            labelText: 'Server IP Address',
            hintText: 'e.g. 192.168.1.100',
          ),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final ip = _ipController.text.trim();
              if (ip.isNotEmpty) {
                setState(() {
                  _isLoading = true;
                  _status = 'Connecting to $ip...';
                });
                await _syncService.connectToServerManual(ip, SyncService.syncPort);
                if (_syncService.isConnected) {
                  setState(() {
                    _lastSync = DateTime.now();
                    _status = 'Sync completed';
                    _isLoading = false;
                  });
                } else {
                  setState(() {
                    _status = 'Failed to connect';
                    _isLoading = false;
                  });
                }
              }
            },
            child: const Text('Connect & Sync'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWindows = Theme.of(context).platform == TargetPlatform.windows;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Sync'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Device Icon
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isWindows ? Icons.computer : Icons.phone_android,
                size: 50,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Mode Indicator
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isWindows ? Icons.settings_remote : Icons.wifi_tethering,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isWindows ? 'Server Mode' : 'Client Mode',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isWindows
                        ? 'Your PC is ready to receive connections'
                        : 'Looking for your PC on the network',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Status Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildStatusRow(
                    icon: Icons.wifi,
                    label: 'Network',
                    value: 'Checking...',
                    valueColor: Colors.grey,
                  ),
                  const Divider(),
                  _buildStatusRow(
                    icon: Icons.sync,
                    label: 'Status',
                    value: _status,
                  ),
                  const Divider(),
                  _buildStatusRow(
                    icon: Icons.devices,
                    label: 'Connected to',
                    value: _connectedDevice ?? 'None',
                    valueColor: _connectedDevice != null ? Colors.green : Colors.grey,
                  ),
                  const Divider(),
                  _buildStatusRow(
                    icon: Icons.access_time,
                    label: 'Last sync',
                    value: _lastSync != null
                        ? _formatDate(_lastSync!)
                        : 'Never',
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Auto-sync Switch
          Card(
            child: SwitchListTile(
              title: const Text('Auto-sync when on WiFi'),
              subtitle: const Text('Automatically sync when devices are on same network'),
              value: _autoSync,
              onChanged: (value) async {
                setState(() {
                  _autoSync = value;
                });
                await _syncService.setAutoSyncEnabled(value);
              },
              activeColor: Theme.of(context).primaryColor,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Sync Now Button
          if (!isWindows) ...[
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _syncNow,
              icon: const Icon(Icons.sync),
              label: Text(_isLoading ? 'Syncing...' : 'Sync Now'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
          
          const SizedBox(height: 8),
          
          // Stop Server Button (Windows only)
          if (isWindows && _isServerRunning) ...[
            OutlinedButton.icon(
              onPressed: () async {
                await _syncService.stopServer();
                setState(() {
                  _isServerRunning = false;
                  _status = 'Server stopped';
                });
              },
              icon: const Icon(Icons.stop),
              label: const Text('Stop Server'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                foregroundColor: Colors.red,
              ),
            ),
          ],
          
          const SizedBox(height: 16),
          
          // Info Card
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isWindows
                          ? 'Keep this app open on your PC to allow Android devices to sync'
                          : 'Make sure your phone and PC are on the same WiFi network',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

Widget _buildStatusRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: valueColor,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  void dispose() {
    _ipController.dispose();
    _syncService.dispose();
    super.dispose();
  }
}