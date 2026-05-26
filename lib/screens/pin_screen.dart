import 'package:flutter/material.dart';
import '../services/security_service.dart';

class PinScreen extends StatefulWidget {
  final bool isSetup;
  final VoidCallback onSuccess;

  const PinScreen({
    super.key,
    required this.isSetup,
    required this.onSuccess,
  });

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  final SecurityService _security = SecurityService();
  final TextEditingController _pinController = TextEditingController();
  
  String _message = '';
  bool _isLoading = false;
  String _enteredPin = '';
  bool _isConfirming = false;
  bool _successCalled = false;

  @override
  void initState() {
    super.initState();
  }

  void _onPinEntered(String pin) {
    if (_successCalled) return;
    
    if (pin.length == 6) {
      if (widget.isSetup) {
        _handleSetupPin(pin);
      } else {
        _handleLoginPin(pin);
      }
    }
  }

  Future<void> _handleSetupPin(String pin) async {
    if (_successCalled) return;
    
    if (!_isConfirming) {
      setState(() {
        _enteredPin = pin;
        _isConfirming = true;
        _message = 'Confirm your PIN';
        _pinController.clear();
      });
    } else {
      if (pin == _enteredPin) {
        setState(() => _isLoading = true);
        
        await _security.enablePin(pin);
        await _security.updateLastActive();
        
        if (mounted && !_successCalled) {
          _successCalled = true;
          widget.onSuccess();
        }
      } else {
        setState(() {
          _message = 'PINs do not match. Try again.';
          _isConfirming = false;
          _enteredPin = '';
          _pinController.clear();
        });
      }
    }
  }

  Future<void> _handleLoginPin(String pin) async {
    if (_successCalled) return;

    // Check lockout before verifying
    if (await _security.isLockedOut()) {
      final remaining = await _security.getRemainingLockoutSeconds();
      setState(() {
        _message = 'Too many attempts. Try again in ${remaining}s';
        _isLoading = false;
        _pinController.clear();
      });
      return;
    }

    setState(() => _isLoading = true);

    final isValid = await _security.verifyPin(pin);

    if (isValid && mounted && !_successCalled) {
      _successCalled = true;
      await _security.updateLastActive();
      widget.onSuccess();
    } else {
      final attempts = await _security.getFailedAttempts();
      final remaining = _maxFailedAttempts - attempts;
      setState(() {
        if (remaining <= 0) {
          _message = 'Too many attempts. Locked for 30 seconds';
        } else {
          _message = 'Incorrect PIN. $remaining attempts remaining';
        }
        _isLoading = false;
        _pinController.clear();
      });
    }
  }

  static const int _maxFailedAttempts = 5;

  void _handleKeyPress(String key) {
    if (_isLoading || _successCalled) return;
    
    if (key == '⌫') {
      if (_pinController.text.isNotEmpty) {
        _pinController.text = _pinController.text.substring(
          0, _pinController.text.length - 1,
        );
      }
    } else if (key == '✓') {
      _onPinEntered(_pinController.text);
    } else {
      if (_pinController.text.length < 6) {
        _pinController.text += key;
      }
    }
    
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Logo/Header
              Expanded(
                flex: 2,
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
                    Text(
                      widget.isSetup ? 'Create PIN' : 'Enter PIN',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.isSetup
                          ? (_isConfirming ? 'Confirm your 6-digit PIN' : 'Choose a 6-digit PIN')
                          : 'Enter your 6-digit PIN',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    if (_message.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        _message,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // PIN Dots
              Expanded(
                flex: 1,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(6, (index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: index < _pinController.text.length
                            ? Theme.of(context).primaryColor
                            : Colors.grey.withOpacity(0.3),
                      ),
                    );
                  }),
                ),
              ),
              
              // Keypad
              Expanded(
                flex: 4,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                        children: [
                          _buildKeyRow(['1', '2', '3']),
                          _buildKeyRow(['4', '5', '6']),
                          _buildKeyRow(['7', '8', '9']),
                          _buildKeyRow(['⌫', '0', '✓']),
                        ],
                      ),
              ),
              
              const SizedBox(height: 16), // Simple spacing at bottom
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeyRow(List<String> keys) {
    return Expanded(
      child: Row(
        children: keys.map((key) {
          return Expanded(
            child: GestureDetector(
              onTap: () => _handleKeyPress(key),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: key == '⌫' || key == '✓'
                      ? Theme.of(context).primaryColor.withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: key == '⌫'
                      ? const Icon(Icons.backspace_outlined)
                      : key == '✓'
                          ? const Icon(Icons.check)
                          : Text(
                              key,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }
}