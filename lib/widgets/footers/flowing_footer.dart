import 'package:flutter/material.dart';
import '../../services/animation_service.dart';

class FlowingFooter extends StatefulWidget {
  const FlowingFooter({super.key});

  @override
  State<FlowingFooter> createState() => _FlowingFooterState();
}

class _FlowingFooterState extends State<FlowingFooter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return ShaderMask(
              shaderCallback: (bounds) {
                return LinearGradient(
                  begin: Alignment(-1.0 + _controller.value * 2, 0),
                  end: Alignment(1.0 - _controller.value * 2, 0),
                  colors: AnimationService.footerColors,
                ).createShader(bounds);
              },
              blendMode: BlendMode.srcIn,
              child: child,
            );
          },
          child: const Text(
            'Created by Tejas Gayake',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
