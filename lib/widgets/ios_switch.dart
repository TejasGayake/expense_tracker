import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class IOSSwitch extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool hapticFeedback;

  const IOSSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.hapticFeedback = true,
  });

  @override
  State<IOSSwitch> createState() => _IOSSwitchState();
}

class _IOSSwitchState extends State<IOSSwitch> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  static const Color iosGreen = Color(0xFF34C759);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    // Set initial position
    if (widget.value) {
      _animationController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(IOSSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Animate to new position when value changes externally
    if (widget.value != oldWidget.value) {
      if (widget.value) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTap() {
    // Provide haptic feedback
    if (widget.hapticFeedback) {
      switch (Theme.of(context).platform) {
        case TargetPlatform.iOS:
        case TargetPlatform.macOS:
          HapticFeedback.lightImpact();
          break;
        default:
          HapticFeedback.vibrate();
      }
    }
    
    // Toggle value
    widget.onChanged(!widget.value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: Container(
        width: 51,
        height: 31,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.value ? Colors.transparent : Colors.grey.shade400,
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 1,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background - ALWAYS GREEN when ON, grey when OFF
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                color: widget.value ? iosGreen : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            
            // Thumb (the white circle)
            AnimatedAlign(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut, // ✅ FIXED: Changed from Curves.spring to Curves.easeInOut
              alignment: widget.value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 27,
                height: 27,
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}