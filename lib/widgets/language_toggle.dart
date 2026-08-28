import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/locale_provider.dart';
import '../l10n/app_localizations.dart';

class LanguageToggle extends StatelessWidget {
  const LanguageToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();
    final currentCode = localeProvider.locale.languageCode;

    return PopupMenuButton<String>(
      icon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.language, color: Colors.white, size: 20),
          const SizedBox(width: 2),
          Text(
            currentCode == 'hi' ? 'हिं' : currentCode == 'gu' ? 'ગુજ' : 'EN',
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      onSelected: (code) {
        localeProvider.setLocale(Locale(code));
        AppLocalizations.loadLocale(Locale(code));
      },
      itemBuilder: (_) => [
        _buildItem('en', 'English', 'EN', localeProvider),
        _buildItem('hi', 'हिंदी', 'HI', localeProvider),
        _buildItem('gu', 'ગુજરાતી', 'GU', localeProvider),
      ],
    );
  }

  PopupMenuItem<String> _buildItem(String code, String name, String short, LocaleProvider provider) {
    final isActive = provider.locale.languageCode == code;
    return PopupMenuItem(
      value: code,
      child: Row(
        children: [
          Text(name, style: TextStyle(
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? const Color(0xFFD4AF37) : Colors.white,
          )),
          const SizedBox(width: 8),
          if (isActive)
            const Icon(Icons.check, color: Color(0xFFD4AF37), size: 16),
        ],
      ),
    );
  }
}
