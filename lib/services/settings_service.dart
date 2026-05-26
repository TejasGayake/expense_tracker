import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  String _currencySymbol = '₹';
  String get currencySymbol => _currencySymbol;

  static const String _currencyKey = 'currency_symbol';

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _currencySymbol = prefs.getString(_currencyKey) ?? '₹';
  }

  Future<void> setCurrency(String symbol) async {
    _currencySymbol = symbol;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyKey, symbol);
  }

  static const List<Map<String, String>> availableCurrencies = [
    {'symbol': '₹', 'name': 'Indian Rupee'},
    {'symbol': '\$', 'name': 'US Dollar'},
    {'symbol': '€', 'name': 'Euro'},
    {'symbol': '£', 'name': 'British Pound'},
    {'symbol': '¥', 'name': 'Japanese Yen'},
    {'symbol': 'A\$', 'name': 'Australian Dollar'},
    {'symbol': 'C\$', 'name': 'Canadian Dollar'},
    {'symbol': 'CHF', 'name': 'Swiss Franc'},
    {'symbol': '₩', 'name': 'South Korean Won'},
    {'symbol': 'R\$', 'name': 'Brazilian Real'},
  ];
}
