import 'package:flutter/material.dart';
import '../../services/animation_service.dart';

class ShimmerFooter extends StatefulWidget {
  const ShimmerFooter({super.key});

  @override
  State<ShimmerFooter> createState() => _ShimmerFooterState();
}

class _ShimmerFooterState extends State<ShimmerFooter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutSine,
    );
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
          animation: _animation,
          builder: (context, child) {
            return ShaderMask(
              shaderCallback: (bounds) {
                return LinearGradient(
                  begin: Alignment(-1.0 + _animation.value * 2, 0),
                  end: Alignment(1.0 - _animation.value * 2, 0),
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
