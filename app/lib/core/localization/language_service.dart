import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_strings.dart';

class LanguageService extends ChangeNotifier {
  static final LanguageService _instance = LanguageService._internal();
  factory LanguageService() => _instance;

  LanguageService._internal() {
    _loadLanguage();
  }

  bool _isTamil = false;

  bool get isTamil => _isTamil;
  String get currentCode => _isTamil ? 'ta' : 'en';

  Future<void> _loadLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isTamil = prefs.getBool('app_is_tamil') ?? false;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> toggleLanguage() async {
    _isTamil = !_isTamil;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('app_is_tamil', _isTamil);
    } catch (_) {}
  }

  Future<void> setLanguage(bool toTamil) async {
    if (_isTamil == toTamil) return;
    _isTamil = toTamil;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('app_is_tamil', _isTamil);
    } catch (_) {}
  }

  String tr(String key) {
    return AppStrings.get(key, isTamil: _isTamil);
  }
}

String tr(String key) => LanguageService().tr(key);

/// 1-Click Language Toggle Button
class LanguageToggleButton extends StatelessWidget {
  final Color? color;
  final Color? backgroundColor;
  final bool isCompact;

  const LanguageToggleButton({
    super.key,
    this.color,
    this.backgroundColor,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: LanguageService(),
      builder: (context, _) {
        final lang = LanguageService();
        final isTamil = lang.isTamil;

        return ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor ?? (isTamil ? Colors.deepOrange.shade600 : Colors.indigo.shade600),
            foregroundColor: color ?? Colors.white,
            elevation: 2,
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 10 : 14,
              vertical: isCompact ? 4 : 8,
            ),
            minimumSize: Size(isCompact ? 72 : 90, isCompact ? 32 : 38),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          icon: Icon(Icons.translate, size: isCompact ? 15 : 17),
          label: Text(
            isTamil ? 'English' : 'தமிழ்',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isCompact ? 12 : 13,
            ),
          ),
          onPressed: () {
            lang.toggleLanguage();
          },
        );
      },
    );
  }
}
