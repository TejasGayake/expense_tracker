import 'package:flutter/material.dart';
import '../services/animation_service.dart';
import '../widgets/footers/shimmer_footer.dart';
import '../widgets/footers/flowing_footer.dart';

class AnimationSettingsScreen extends StatefulWidget {
  const AnimationSettingsScreen({super.key});

  @override
  State<AnimationSettingsScreen> createState() => _AnimationSettingsScreenState();
}

class _AnimationSettingsScreenState extends State<AnimationSettingsScreen> {
  final AnimationService _animationService = AnimationService();
  FooterAnimationType _selectedType = FooterAnimationType.shimmer;

  @override
  void initState() {
    super.initState();
    _selectedType = _animationService.currentType;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Footer Animation'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Choose Animation Style',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          
          // Shimmer Effect Option
          Card(
            child: RadioListTile<FooterAnimationType>(
              title: const Text('Shimmer Effect'),
              subtitle: const Text('Light reflects across your name like silk'),
              value: FooterAnimationType.shimmer,
              groupValue: _selectedType,
              onChanged: (value) {
                if (value != null) {
                  _animationService.setAnimationType(value);
                  setState(() {
                    _selectedType = value;
                  });
                }
              },
              activeColor: Theme.of(context).primaryColor,
            ),
          ),
          
          // Flowing Gradient Option
          Card(
            child: RadioListTile<FooterAnimationType>(
              title: const Text('Flowing Gradient'),
              subtitle: const Text('Colors smoothly move left to right'),
              value: FooterAnimationType.flowing,
              groupValue: _selectedType,
              onChanged: (value) {
                if (value != null) {
                  _animationService.setAnimationType(value);
                  setState(() {
                    _selectedType = value;
                  });
                }
              },
              activeColor: Theme.of(context).primaryColor,
            ),
          ),
          
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          
          // Live Preview
          const Text(
            'Preview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey.shade900
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: _selectedType == FooterAnimationType.shimmer
                  ? const ShimmerFooter()
                  : const FlowingFooter(),
            ),
          ),
          
          const SizedBox(height: 16),
          Text(
            'Note: One animation must always be selected',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}