import 'package:flutter/material.dart';
import '../../services/animation_service.dart';
import 'shimmer_footer.dart';
import 'flowing_footer.dart';

class FooterManager extends StatefulWidget {
  const FooterManager({super.key});

  @override
  State<FooterManager> createState() => _FooterManagerState();
}

class _FooterManagerState extends State<FooterManager> {
  final AnimationService _animationService = AnimationService();

  @override
  void initState() {
    super.initState();
    _animationService.addListener(_onAnimationChanged);
  }

  @override
  void dispose() {
    _animationService.removeListener(_onAnimationChanged);
    super.dispose();
  }

  void _onAnimationChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeOutCubic,
      child: _animationService.currentType == FooterAnimationType.shimmer
          ? const ShimmerFooter(key: ValueKey('shimmer'))
          : const FlowingFooter(key: ValueKey('flowing')),
    );
  }
}
