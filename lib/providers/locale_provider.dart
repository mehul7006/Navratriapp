import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');
  int? _userId;
  static const String _prefPrefix = 'app_locale_';

  Locale get locale => _locale;

  LocaleProvider() {
    _loadSavedLocale();
  }

  Future<void> _loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('${_prefPrefix}default') ?? 'en';
    _locale = Locale(code);
    AppLocalizations.loadLocale(_locale);
    notifyListeners();
  }

  Future<void> setLocale(Locale locale, {int? userId}) async {
    if (_locale == locale) return;
    _locale = locale;
    _userId = userId;
    AppLocalizations.loadLocale(locale);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    final key = userId != null ? '${_prefPrefix}$userId' : '${_prefPrefix}default';
    await prefs.setString(key, locale.languageCode);
    await prefs.setString('${_prefPrefix}default', locale.languageCode);
  }

  Future<void> loadUserLocale(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${_prefPrefix}$userId';
    final code = prefs.getString(key) ?? prefs.getString('${_prefPrefix}default') ?? 'en';
    final newLocale = Locale(code);
    if (_locale != newLocale) {
      _locale = newLocale;
      _userId = userId;
      AppLocalizations.loadLocale(_locale);
      notifyListeners();
    }
  }

  String get languageName {
    switch (_locale.languageCode) {
      case 'hi':
        return 'हिंदी';
      case 'gu':
        return 'ગુજરાતી';
      default:
        return 'English';
    }
  }
}
