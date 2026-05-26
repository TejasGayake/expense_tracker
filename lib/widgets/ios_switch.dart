import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class IOSSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool hapticFeedback;

  const IOSSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.hapticFeedback = true,
  });

  static const Color iosGreen = Color(0xFF34C759);

  void _handleTap(BuildContext context) {
    if (hapticFeedback) {
      HapticFeedback.selectionClick();
    }
    onChanged(!value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _handleTap(context),
      child: Container(
        width: 51,
        height: 31,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: value ? Colors.transparent : Colors.grey.shade400,
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
            // Background
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                color: value ? iosGreen : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(16),
              ),
            ),

            // Thumb (white circle)
            AnimatedAlign(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
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
