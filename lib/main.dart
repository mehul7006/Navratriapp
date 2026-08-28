import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/locale_provider.dart';
import 'l10n/app_localizations.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/user/home_screen.dart';
import 'screens/organizer/dashboard_screen.dart';
import 'screens/sponsor/dashboard_screen.dart';
import 'database/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppLocalizations.init();
  DatabaseHelper.connect();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppTheme.purpleDark,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  runApp(const NavratriApp());
}

class NavratriApp extends StatelessWidget {
  const NavratriApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, _) {
          AppLocalizations.loadLocale(localeProvider.locale);
          return MaterialApp(
            title: 'Navratri 2026 - Nishitpark',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.darkTheme,
            locale: localeProvider.locale,
            supportedLocales: const [
              Locale('en'),
              Locale('hi'),
              Locale('gu'),
            ],
            initialRoute: '/',
            routes: {
              '/': (context) => const SplashScreen(),
              '/login': (context) => const LoginScreen(),
              '/register': (context) => const RegisterScreen(),
              '/user/home': (context) => const UserHomeScreen(),
              '/organizer/dashboard': (context) => const OrganizerDashboardScreen(),
              '/sponsor/dashboard': (context) => const SponsorDashboardScreen(),
            },
          );
        },
      ),
    );
  }
}
