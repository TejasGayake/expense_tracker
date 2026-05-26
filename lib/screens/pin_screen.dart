import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _PinScreenState extends State<PinScreen>
    with TickerProviderStateMixin {
  final SecurityService _security = SecurityService();
  final TextEditingController _pinController = TextEditingController();

  String _message = '';
  bool _isLoading = false;
  String _enteredPin = '';
  bool _isConfirming = false;
  bool _successCalled = false;

  // Animation controllers
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  late AnimationController _successController;
  late Animation<double> _successScaleAnimation;
  int _lastPinLength = 0;

  @override
  void initState() {
    super.initState();

    // Shake animation for wrong PIN
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -8), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -8, end: 8), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8, end: -6), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -6, end: 6), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 6, end: -3), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -3, end: 0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.easeOutCubic,
    ));

    // Success animation
    _successController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _successScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 0.9), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _successController,
      curve: Curves.easeOutCubic,
    ));
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
          _successController.forward().then((_) {
            widget.onSuccess();
          });
        }
      } else {
        _triggerShake();
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

    if (await _security.isLockedOut()) {
      final remaining = await _security.getRemainingLockoutSeconds();
      _triggerShake();
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
      _successController.forward().then((_) {
        widget.onSuccess();
      });
    } else {
      final attempts = await _security.getFailedAttempts();
      final remaining = _maxFailedAttempts - attempts;
      _triggerShake();
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

  void _triggerShake() {
    HapticFeedback.heavyImpact();
    _shakeController.forward(from: 0);
  }

  void _handleKeyPress(String key) {
    if (_isLoading || _successCalled) return;

    HapticFeedback.lightImpact();

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
                    ScaleTransition(
                      scale: _successScaleAnimation,
                      child: Container(
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
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: _message.isNotEmpty
                          ? Padding(
                              key: ValueKey(_message),
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                _message,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),

              // PIN Dots with shake
              Expanded(
                flex: 1,
                child: AnimatedBuilder(
                  animation: _shakeAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(_shakeAnimation.value, 0),
                      child: child,
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(6, (index) {
                      final isFilled = index < _pinController.text.length;
                      final isNew = index == _pinController.text.length - 1 &&
                          _pinController.text.length > _lastPinLength;

                      return _PinDot(
                        isFilled: isFilled,
                        isNew: isNew,
                        primaryColor: Theme.of(context).primaryColor,
                      );
                    }),
                  ),
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

              const SizedBox(height: 16),
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
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Semantics(
                label: key == '⌫' ? 'Backspace' : key == '✓' ? 'Confirm' : 'Key $key',
                button: true,
                child: Material(
                color: key == '⌫' || key == '✓'
                    ? Theme.of(context).primaryColor.withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () => _handleKeyPress(key),
                  borderRadius: BorderRadius.circular(12),
                  splashColor: Theme.of(context).primaryColor.withOpacity(0.15),
                  highlightColor: Theme.of(context).primaryColor.withOpacity(0.08),
                  child: Center(
                    child: key == '⌫'
                        ? const Tooltip(
                            message: 'Backspace',
                            child: Icon(Icons.backspace_outlined),
                          )
                        : key == '✓'
                            ? const Tooltip(
                                message: 'Confirm',
                                child: Icon(Icons.check),
                              )
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
    _shakeController.dispose();
    _successController.dispose();
    super.dispose();
  }
}

// Animated PIN dot
class _PinDot extends StatefulWidget {
  final bool isFilled;
  final bool isNew;
  final Color primaryColor;

  const _PinDot({
    required this.isFilled,
    required this.isNew,
    required this.primaryColor,
  });

  @override
  State<_PinDot> createState() => _PinDotState();
}

class _PinDotState extends State<_PinDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.4), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    if (widget.isNew) {
      _controller.forward(from: 0);
    }
  }

  @override
  void didUpdateWidget(_PinDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isNew && !oldWidget.isNew) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 8),
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.isFilled
              ? widget.primaryColor
              : Colors.grey.withOpacity(0.3),
        ),
      ),
    );
  }
}
