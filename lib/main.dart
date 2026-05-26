import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/pin_screen.dart';
import 'services/security_service.dart';
import 'services/database_service.dart'; // ✅ Add this

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) {
    runApp(const MyApp());
  });
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  bool _isDarkMode = false;
  bool _isAuthenticated = false;
  bool _isFirstTime = true;
  bool _isLoading = true;
  final SecurityService _security = SecurityService();
  final DatabaseService _db = DatabaseService(); // ✅ Add this

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkAuthentication();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isAuthenticated) {
      if (state == AppLifecycleState.paused) {
        setState(() {
          _isAuthenticated = false;
        });
      } else if (state == AppLifecycleState.resumed) {
        _checkAuthentication();
      }
    }
  }

  Future<void> _checkAuthentication() async {
    setState(() => _isLoading = true);
    
    try {
      final shouldShowLock = await _security.shouldShowLockScreen();
      final isFirstTime = await _security.isFirstTimeSetup();
      final pinEnabled = await _security.isPinEnabled();
      
      print('Auth Check - shouldShowLock: $shouldShowLock, isFirstTime: $isFirstTime, pinEnabled: $pinEnabled');
      
      // Initialize app if authenticated
      if (pinEnabled && !shouldShowLock) {
        await _initializeApp();
      } else if (!pinEnabled) {
        await _initializeApp();
      }
      
      setState(() {
        _isAuthenticated = pinEnabled ? !shouldShowLock : true;
        _isFirstTime = isFirstTime;
        _isLoading = false;
      });
    } catch (e) {
      print('Error checking authentication: $e');
      setState(() {
        _isAuthenticated = true;
        _isLoading = false;
      });
    }
  }

  // ✅ NEW: Initialize app data
  Future<void> _initializeApp() async {
    try {
      print('🚀 Initializing app data...');
      await _db.initializeDefaultCategories();
      final categories = await _db.getCategories();
      print('📊 App initialized with ${categories.length} categories');
    } catch (e) {
      print('❌ Error initializing app: $e');
    }
  }

  void _handleAuthSuccess() async {
    print('Authentication successful');
    await _initializeApp(); // ✅ Initialize after PIN success
    setState(() {
      _isAuthenticated = true;
    });
  }

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GT Expenser',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: _isLoading
          ? _buildLoadingScreen()
          : _isAuthenticated
              ? HomeScreen(
                  onThemeToggle: _toggleTheme,
                  isDarkMode: _isDarkMode,
                )
              : PinScreen(
                  isSetup: _isFirstTime,
                  onSuccess: _handleAuthSuccess,
                ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_outline,
                size: 40,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Loading...',
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}