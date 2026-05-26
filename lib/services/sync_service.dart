import 'dart:io';
import 'dart:convert';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:bonsoir/bonsoir.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_service.dart';

class SyncService {
  static const String serviceType = '_expensetracker._tcp';
  static const int syncPort = 8080;
  
  final DatabaseService _db = DatabaseService();
  
  // Server instance (for Windows)
  HttpServer? _server;
  BonsoirService? _bonsoirService;
  BonsoirDiscovery? _bonsoirDiscovery;
  
  // Client instance (for Android) - placeholder for future implementation
  
  // Sync status
  bool _isServerRunning = false;
  bool _isConnected = false;
  String? _connectedDeviceName;
  DateTime? _lastSyncTime;
  
  // Callbacks
  Function(bool)? onConnectionChanged;
  Function(String)? onStatusChanged;
  
  // Getters
  bool get isServerRunning => _isServerRunning;
  bool get isConnected => _isConnected;
  String? get connectedDeviceName => _connectedDeviceName;
  DateTime? get lastSyncTime => _lastSyncTime;
  
  // ===== NETWORK UTILITIES =====
  
  Future<bool> isConnectedToWiFi() async {
    final connectivity = await Connectivity().checkConnectivity();
    return connectivity == ConnectivityResult.wifi;
  }
  
  Future<String?> getDeviceIP() async {
    try {
      final info = NetworkInfo();
      final ip = await info.getWifiIP();
      return ip;
    } catch (e) {
      print('Error getting IP: $e');
      return null;
    }
  }
  
  Future<String?> getDeviceName() async {
    try {
      // Try to get hostname
      return Platform.localHostname;
    } catch (e) {
      print('Error getting device name: $e');
      return 'Unknown Device';
    }
  }
  
  // ===== SERVER MODE (For Windows) =====
  
  Future<bool> startServer() async {
    try {
      // Check if already running
      if (_isServerRunning) {
        print('Server already running');
        return true;
      }
      
      // Get device IP
      final ip = await getDeviceIP();
      if (ip == null) {
        _updateStatus('No WiFi connection');
        return false;
      }
      
      // Start HTTP server
      _server = await HttpServer.bind(InternetAddress.anyIPv4, syncPort);
      _isServerRunning = true;
      
      _updateStatus('Server started on $ip:$syncPort');
      print('✅ Server started on $ip:$syncPort');
      
      // Advertise service via Bonjour/mDNS
      await _advertiseService();
      
      // Handle incoming requests
      _handleRequests();
      
      // Load last sync time
      await _loadLastSyncTime();
      
      return true;
    } catch (e) {
      print('Error starting server: $e');
      _updateStatus('Error starting server');
      return false;
    }
  }
  
  Future<void> _advertiseService() async {
    try {
      // Bonsoir service advertisement
      // Note: This is a simplified version that works with the package
      final deviceName = await getDeviceName() ?? 'ExpenseTracker';
      
      _bonsoirService = BonsoirService(
        name: 'ExpenseTracker-$deviceName',
        type: serviceType,
        port: syncPort,
      );
      
      print('✅ Service created: ${_bonsoirService?.name}');
    } catch (e) {
      print('Error creating service: $e');
      // Continue even if creation fails
    }
  }
  
  Future<void> _handleRequests() async {
    if (_server == null) return;
    
    await for (HttpRequest request in _server!) {
      // Handle CORS
      request.response.headers.add('Access-Control-Allow-Origin', '*');
      request.response.headers.add('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
      request.response.headers.add('Access-Control-Allow-Headers', 'Content-Type');
      
      if (request.method == 'OPTIONS') {
        request.response.statusCode = HttpStatus.ok;
        request.response.close();
        continue;
      }
      
      try {
        if (request.method == 'POST') {
          // For simplicity, we'll handle different endpoints
          
          if (request.uri.path == '/sync') {
            await _handleSyncRequest(request);
          } else if (request.uri.path == '/ping') {
            await _handlePingRequest(request);
          }
        } else if (request.method == 'GET') {
          if (request.uri.path == '/status') {
            await _handleStatusRequest(request);
          }
        }
      } catch (e) {
        print('Error handling request: $e');
        request.response.statusCode = HttpStatus.internalServerError;
        request.response.write('Error: $e');
        await request.response.close();
      }
    }
  }
  
  Future<void> _handleSyncRequest(HttpRequest request) async {
    print('📥 Received sync request');
    
    try {
      // Parse request body
      final content = await utf8.decoder.bind(request).join();
      json.decode(content); // parse but don't use for now
      
      // In a real implementation, we'd merge client and server data
      // For now, we'll just export our data
      
      // Get local changes
      final localTransactions = await _exportTransactions();
      
      // Prepare response
      final response = {
        'status': 'success',
        'serverTime': DateTime.now().toIso8601String(),
        'transactions': localTransactions,
        'people': await _exportPeople(),
      };
      
      request.response.statusCode = HttpStatus.ok;
      request.response.headers.contentType = ContentType.json;
      request.response.write(json.encode(response));
      await request.response.close();
      
      // Update last sync time
      await _updateLastSyncTime();
      
      _updateStatus('Sync completed');
      print('✅ Sync completed');
      
    } catch (e) {
      print('Error in sync: $e');
      request.response.statusCode = HttpStatus.internalServerError;
      request.response.write('Error: $e');
      await request.response.close();
    }
  }
  
  Future<void> _handlePingRequest(HttpRequest request) async {
    request.response.statusCode = HttpStatus.ok;
    request.response.write('pong');
    await request.response.close();
  }
  
  Future<void> _handleStatusRequest(HttpRequest request) async {
    final status = {
      'device': Platform.operatingSystem,
      'name': await getDeviceName(),
      'transactions': (await _db.getTransactions()).length,
      'lastSync': (await _getLastSyncTime())?.toIso8601String(),
    };
    
    request.response.statusCode = HttpStatus.ok;
    request.response.headers.contentType = ContentType.json;
    request.response.write(json.encode(status));
    await request.response.close();
  }
  
  Future<void> stopServer() async {
    try {
      await _bonsoirDiscovery?.stop();
      await _server?.close();
      _isServerRunning = false;
      _updateStatus('Server stopped');
      print('✅ Server stopped');
    } catch (e) {
      print('Error stopping server: $e');
    }
  }
  
  // ===== CLIENT MODE (For Android) =====
  
  Future<void> startDiscovery() async {
    try {
      _updateStatus('Looking for devices...');
      
      // For now, use a manual approach - user can enter IP address
      // In a production app, you'd use proper mDNS discovery
      
      // Placeholder: could implement proper discovery later
      print('Service discovery started (manual entry required)');
    } catch (e) {
      print('Error starting discovery: $e');
    }
  }
  
  Future<void> connectToServerManual(String ip, int port) async {
    try {
      _updateStatus('Connecting to $ip:$port');
      
      // Try to connect
      final client = HttpClient();
      
      // Ping to check connection
      final pingUrl = Uri.parse('http://$ip:$port/ping');
      final pingRequest = await client.getUrl(pingUrl);
      final pingResponse = await pingRequest.close();
      
      if (pingResponse.statusCode == HttpStatus.ok) {
        _isConnected = true;
        _connectedDeviceName = 'Device at $ip';
        _updateStatus('Connected to device');
        
        onConnectionChanged?.call(true);
        
        // Auto sync if enabled
        final autoSync = await getAutoSyncEnabled();
        if (autoSync) {
          syncWithServer(ip, port);
        }
      }
    } catch (e) {
      print('Error connecting: $e');
    }
  }
  
  Future<void> syncWithServer(String ip, int port) async {
    try {
      _updateStatus('Syncing...');
      
      final client = HttpClient();
      final url = Uri.parse('http://$ip:$port/sync');
      
      // Get local transactions
      final localTransactions = await _exportTransactions();
      final lastSync = await _getLastSyncTime();
      
      // Prepare request
      final request = await client.postUrl(url);
      request.headers.contentType = ContentType.json;
      request.write(json.encode({
        'transactions': localTransactions,
        'lastSync': lastSync?.toIso8601String(),
        'device': Platform.operatingSystem,
      }));
      
      // Get response
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      
      if (response.statusCode == HttpStatus.ok) {
        final data = json.decode(responseBody);
        
        // Import server transactions
        if (data['transactions'] != null) {
          await _importTransactions(data['transactions']);
        }
        
        if (data['people'] != null) {
          await _importPeople(data['people']);
        }
        
        await _updateLastSyncTime();
        _updateStatus('Sync completed');
        print('✅ Client sync completed');
      } else {
        _updateStatus('Sync failed');
      }
      
    } catch (e) {
      print('Error syncing: $e');
      _updateStatus('Sync error');
    }
  }
  
  void stopDiscovery() {
    _isConnected = false;
    _connectedDeviceName = null;
    _updateStatus('Discovery stopped');
  }
  
  // ===== DATA EXPORT/IMPORT =====
  
  Future<List<Map<String, dynamic>>> _exportTransactions() async {
    return await _db.getTransactions();
  }
  
  Future<List<Map<String, dynamic>>> _exportPeople() async {
    return await _db.getPeople();
  }
  
  Future<void> _importTransactions(List<dynamic> transactions) async {
    for (var txn in transactions) {
      try {
        // Check if exists
        final existing = await _db.getTransactionById(txn['id']);
        if (existing == null) {
          await _db.insertTransaction(txn);
        }
      } catch (e) {
        print('Error importing transaction: $e');
      }
    }
  }
  
  Future<void> _importPeople(List<dynamic> people) async {
    for (var person in people) {
      try {
        final existing = await _db.getPersonById(person['id']);
        if (existing == null) {
          await _db.insertPerson(person);
        }
      } catch (e) {
        print('Error importing person: $e');
      }
    }
  }
  
  // ===== SYNC SETTINGS =====
  
  Future<void> _updateLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    _lastSyncTime = DateTime.now();
    await prefs.setString('last_sync_time', _lastSyncTime!.toIso8601String());
  }
  
  Future<DateTime?> _getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timeStr = prefs.getString('last_sync_time');
    if (timeStr != null) {
      return DateTime.parse(timeStr);
    }
    return null;
  }
  
  Future<void> _loadLastSyncTime() async {
    _lastSyncTime = await _getLastSyncTime();
  }
  
  Future<bool> getAutoSyncEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('auto_sync') ?? true;
  }
  
  Future<void> setAutoSyncEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_sync', enabled);
  }
  
  // ===== UTILITY =====
  
  void _updateStatus(String status) {
    print('📱 Sync: $status');
    onStatusChanged?.call(status);
  }
  
  void dispose() {
    stopServer();
    stopDiscovery();
  }
}