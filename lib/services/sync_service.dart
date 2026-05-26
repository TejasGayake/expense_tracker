import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:bonsoir/bonsoir.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_service.dart';
import 'sync_encryption_service.dart';

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
  String? _connectedServerIp;
  int? _connectedServerPort;
  DateTime? _lastSyncTime;
  
  // Callbacks
  Function(bool)? onConnectionChanged;
  Function(String)? onStatusChanged;
  
  // Getters
  bool get isServerRunning => _isServerRunning;
  bool get isConnected => _isConnected;
  String? get connectedDeviceName => _connectedDeviceName;
  String? get connectedServerIp => _connectedServerIp;
  int? get connectedServerPort => _connectedServerPort;
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
      if (kDebugMode) {
        print('Error getting IP: $e');
      }
      return null;
    }
  }
  
  Future<String?> getDeviceName() async {
    try {
      // Try to get hostname
      return Platform.localHostname;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting device name: $e');
      }
      return 'Unknown Device';
    }
  }
  
  // ===== SERVER MODE (For Windows) =====
  
  Future<bool> startServer() async {
    try {
      // Check if already running
      if (_isServerRunning) {
        if (kDebugMode) {
          print('Server already running');
        }
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
      if (kDebugMode) {
        print('✅ Server started on $ip:$syncPort');
      }
      
      // Advertise service via Bonjour/mDNS
      await _advertiseService();
      
      // Handle incoming requests
      _handleRequests();
      
      // Load last sync time
      await _loadLastSyncTime();
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error starting server: $e');
      }
      _updateStatus('Error starting server');
      return false;
    }
  }
  
  Future<void> _advertiseService() async {
    try {
      final deviceName = await getDeviceName() ?? 'ExpenseTracker';

      _bonsoirService = BonsoirService(
        name: 'ExpenseTracker-$deviceName',
        type: serviceType,
        port: syncPort,
      );

      final bonsoirBroadcast = BonsoirBroadcast(service: _bonsoirService!);
      await bonsoirBroadcast.ready;
      await bonsoirBroadcast.start();

      if (kDebugMode) {
        print('✅ Service advertised: ${_bonsoirService?.name}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error advertising service: $e');
      }
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
        if (kDebugMode) {
          print('Error handling request: $e');
        }
        request.response.statusCode = HttpStatus.internalServerError;
        request.response.write('Error: $e');
        await request.response.close();
      }
    }
  }
  
  Future<void> _handleSyncRequest(HttpRequest request) async {
    if (kDebugMode) {
      print('📥 Received sync request');
    }

    try {
      // Parse request body
      final rawContent = await utf8.decoder.bind(request).join();
      final data = json.decode(rawContent);

      // Decrypt if encrypted
      final encryptionService = SyncEncryptionService();
      final syncKey = await encryptionService.getKey();

      if (data['encrypted'] == true && syncKey != null) {
        encryptionService.decryptJson(data['data'], syncKey);
        if (kDebugMode) {
          print('🔓 Decrypted sync payload');
        }
      }

      // Get local changes
      final localTransactions = await _exportTransactions();
      final localPeople = await _exportPeople();

      // Prepare response
      final Map<String, dynamic> responseData = {
        'status': 'success',
        'serverTime': DateTime.now().toIso8601String(),
        'encrypted': syncKey != null,
      };

      if (syncKey != null) {
        responseData['data'] = encryptionService.encryptJson({
          'transactions': localTransactions,
          'people': localPeople,
        }, syncKey);
      } else {
        responseData['transactions'] = localTransactions;
        responseData['people'] = localPeople;
      }

      request.response.statusCode = HttpStatus.ok;
      request.response.headers.contentType = ContentType.json;
      request.response.write(json.encode(responseData));
      await request.response.close();

      await _updateLastSyncTime();
      _updateStatus('Sync completed');
      if (kDebugMode) {
        print('✅ Sync completed');
      }

    } catch (e) {
      if (kDebugMode) {
        print('Error in sync: $e');
      }
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
      if (kDebugMode) {
        print('✅ Server stopped');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error stopping server: $e');
      }
    }
  }
  
  // ===== CLIENT MODE (For Android) =====
  
  Future<void> startDiscovery() async {
    try {
      _updateStatus('Looking for devices...');

      _bonsoirDiscovery = BonsoirDiscovery(type: serviceType);
      await _bonsoirDiscovery!.ready;

      _bonsoirDiscovery!.eventStream!.listen((event) {
        if (event.type == BonsoirDiscoveryEventType.discoveryServiceFound) {
          final service = event.service!;
          _connectedDeviceName = service.name;
          _updateStatus('Found: ${service.name}');

          // Resolve the service to get IP/port
          _bonsoirDiscovery!.serviceResolver.resolveService(service);
        } else if (event.type == BonsoirDiscoveryEventType.discoveryServiceResolved) {
          final service = event.service as ResolvedBonsoirService;
          final ip = service.host;
          final port = service.port;
          _isConnected = true;
          _updateStatus('Resolved: ${service.name} at $ip:$port');
          onConnectionChanged?.call(true);

          // Auto-connect and sync
          if (ip != null) {
            connectToServerManual(ip, port);
          }
        } else if (event.type == BonsoirDiscoveryEventType.discoveryServiceLost) {
          _isConnected = false;
          _connectedDeviceName = null;
          _updateStatus('Device disconnected');
          onConnectionChanged?.call(false);
        }
      });

      await _bonsoirDiscovery!.start();
      if (kDebugMode) {
        print('Service discovery started');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error starting discovery: $e');
      }
      _updateStatus('Discovery failed: $e');
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
        _connectedServerIp = ip;
        _connectedServerPort = port;
        _updateStatus('Connected to device');

        onConnectionChanged?.call(true);

        // Auto sync if enabled
        final autoSync = await getAutoSyncEnabled();
        if (autoSync) {
          await syncWithServer(ip, port);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error connecting: $e');
      }
      _updateStatus('Connection failed: $e');
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

      // Encrypt payload if key exists
      final encryptionService = SyncEncryptionService();
      final syncKey = await encryptionService.getKey();

      final Map<String, dynamic> payload = {
        'transactions': localTransactions,
        'lastSync': lastSync?.toIso8601String(),
        'encrypted': syncKey != null,
      };

      if (syncKey != null) {
        payload['data'] = encryptionService.encryptJson({
          'transactions': localTransactions,
          'lastSync': lastSync?.toIso8601String(),
        }, syncKey);
        payload.remove('transactions');
        payload.remove('lastSync');
      }

      payload['device'] = Platform.operatingSystem;

      // Prepare request
      final request = await client.postUrl(url);
      request.headers.contentType = ContentType.json;
      request.write(json.encode(payload));

      // Get response
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode == HttpStatus.ok) {
        final data = json.decode(responseBody);

        // Decrypt response if encrypted
        List<dynamic>? transactions = data['transactions'];
        List<dynamic>? people = data['people'];

        if (data['encrypted'] == true && syncKey != null) {
          final decrypted = encryptionService.decryptJson(data['data'], syncKey);
          transactions = decrypted['transactions'];
          people = decrypted['people'];
        }

        if (data['encrypted'] == true && syncKey != null) {
          final decrypted = encryptionService.decryptJson(data['data'], syncKey);
          transactions = decrypted['transactions'];
          people = decrypted['people'];
        }

        // Import server transactions
        if (transactions != null) {
          await _importTransactions(transactions);
        }

        if (people != null) {
          await _importPeople(people);
        }
        
        await _updateLastSyncTime();
        _updateStatus('Sync completed');
        if (kDebugMode) {
          print('✅ Client sync completed');
        }
      } else {
        _updateStatus('Sync failed');
      }
      
    } catch (e) {
      if (kDebugMode) {
        print('Error syncing: $e');
      }
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
        if (kDebugMode) {
          print('Error importing transaction: $e');
        }
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
        if (kDebugMode) {
          print('Error importing person: $e');
        }
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
    if (kDebugMode) {
      print('📱 Sync: $status');
    }
    onStatusChanged?.call(status);
  }
  
  void dispose() {
    stopServer();
    stopDiscovery();
  }
}