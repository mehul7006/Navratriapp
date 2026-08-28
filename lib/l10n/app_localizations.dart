import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLocalizations {
  static Map<String, String> _strings = {};
  static Map<String, String> _fallback = {};
  static Map<String, Map<String, String>> _cache = {};

  static Future<void> init() async {
    // Load all languages at startup for instant switching
    _cache['en'] = await _loadJson('en');
    _cache['hi'] = await _loadJson('hi');
    _cache['gu'] = await _loadJson('gu');
    _fallback = _cache['en']!;
    _strings = _fallback;
  }

  static Future<Map<String, String>> _loadJson(String langCode) async {
    try {
      final data = await rootBundle.loadString('assets/l10n/$langCode.json');
      final map = jsonDecode(data) as Map<String, dynamic>;
      return map.map((k, v) => MapEntry(k, v.toString()));
    } catch (_) {
      return {};
    }
  }

  static void loadLocale(Locale locale) {
    _strings = _cache[locale.languageCode] ?? _fallback;
  }

  static String translate(String key, {Map<String, String>? params}) {
    String value = _strings[key] ?? _fallback[key] ?? key;
    if (params != null) {
      for (final entry in params.entries) {
        value = value.replaceAll('{${entry.key}}', entry.value);
      }
    }
    return value;
  }

  static String t(String key, {Map<String, String>? params}) {
    return translate(key, params: params);
  }
}
