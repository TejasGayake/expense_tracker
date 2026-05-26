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
  FooterAnimationType _currentType = FooterAnimationType.shimmer;

  @override
  void initState() {
    super.initState();
    _currentType = _animationService.currentType;
  }

  @override
  Widget build(BuildContext context) {
    switch (_currentType) {
      case FooterAnimationType.shimmer:
        return const ShimmerFooter();
      case FooterAnimationType.flowing:
        return const FlowingFooter();
    }
  }
}