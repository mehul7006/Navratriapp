import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/locale_provider.dart';

class AppLocalizations {
  static Map<String, String> _strings = {};
  static Map<String, String> _fallback = {};

  static Future<void> init() async {
    _fallback = await _loadJson('en');
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

  static Future<void> loadLocale(Locale locale) async {
    _strings = await _loadJson(locale.languageCode);
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
