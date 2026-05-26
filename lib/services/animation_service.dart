import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum FooterAnimationType {
  shimmer,
  flowing,
}

class AnimationService {
  static const String _animationPrefKey = 'footer_animation_type';
  
  // ✅ CHANGE DEFAULT TO FLOWING
  FooterAnimationType _currentType = FooterAnimationType.flowing;
  
  FooterAnimationType get currentType => _currentType;
  
  AnimationService() {
    _loadPreference();
  }
  
  Future<void> _loadPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final index = prefs.getInt(_animationPrefKey);
      if (index != null) {
        _currentType = FooterAnimationType.values[index];
      } else {
        // ✅ If no preference saved, set flowing as default
        _currentType = FooterAnimationType.flowing;
        await prefs.setInt(_animationPrefKey, FooterAnimationType.flowing.index);
      }
    } catch (e) {
      print('Error loading animation preference: $e');
    }
  }
  
  Future<void> setAnimationType(FooterAnimationType type) async {
    _currentType = type;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_animationPrefKey, type.index);
    } catch (e) {
      print('Error saving animation preference: $e');
    }
  }
  
  // 🎨 SMOOTH GRADIENT - 20 colors for seamless transition
  static const List<Color> footerColors = [
    Color(0xFF001219),
    Color(0xFF002834),
    Color(0xFF003D4A),
    Color(0xFF00535B),
    Color(0xFF0A6B6B),
    Color(0xFF2D827A),
    Color(0xFF569987),
    Color(0xFF7DB095),
    Color(0xFFA2C6A4),
    Color(0xFFC6DCB3),
    Color(0xFFE9D8A6),
    Color(0xFFEFC48C),
    Color(0xFFF5B072),
    Color(0xFFF99C58),
    Color(0xFFF8883E),
    Color(0xFFF0742F),
    Color(0xFFE86020),
    Color(0xFFDC4C1A),
    Color(0xFFCE3814),
    Color(0xFFC0240E),
    Color(0xFFAE2012),
    Color(0xFFA02117),
    Color(0xFF92221C),
    Color(0xFF842321),
    Color(0xFF762426),
    Color(0xFF9b2226),
  ];
  
  // Helper method to get a subset of colors if needed
  static List<Color> getGradientColors({int start = 0, int? end}) {
    end ??= footerColors.length;
    return footerColors.sublist(start, end);
  }
}