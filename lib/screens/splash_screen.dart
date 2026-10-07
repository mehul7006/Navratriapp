import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../database/database_helper.dart';
import 'auth/login_screen.dart';
import '../widgets/background_scaffold.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _updateRequired = false;
  bool _downloading = false;
  bool _dlFailed = false;
  double _dlProgress = 0;
  String _dlStatus = '';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _controller.forward();

    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    final auth = context.read<AuthProvider>();
    await auth.sessionReady;
    if (!mounted) return;
    // Hard update gate (APK only): outdated builds never proceed further.
    if (await _isUpdateAvailable()) {
      setState(() => _updateRequired = true);
      _startDownload();
      return;
    }
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    _doNavigate(auth);
  }

  void _doNavigate(AuthProvider auth) {
    if (!mounted) return;
    if (auth.isLoggedIn) {
      final userType = auth.currentUser?['user_type'];
      switch (userType) {
        case 'organizer':
          Navigator.of(context).pushReplacementNamed('/organizer/dashboard');
          break;
        case 'sponsor':
          Navigator.of(context).pushReplacementNamed('/sponsor/dashboard');
          break;
        default:
          Navigator.of(context).pushReplacementNamed('/user/home');
      }
    } else {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 100),
        ),
      );
    }
  }

  /// True when the server reports a newer build than installed.
  /// Offline / unknown version fails OPEN (app stays usable).
  /// NOTE: split-per-abi release builds report versionCode = 2000 + N
  /// (verified: +2 -> 2002, +3 -> 2003, +4 -> 2004), NOT the raw N from
  /// pubspec. Always normalize before comparing with the server value.
  Future<bool> _isUpdateAvailable() async {
    if (kIsWeb) return false;
    try {
      final remote = int.tryParse(await DatabaseHelper.getConfig('apk_version')) ?? 0;
      if (remote <= 0) return false;
      final raw = int.tryParse((await PackageInfo.fromPlatform()).buildNumber) ?? 0;
      final local = _normalizeBuildNumber(raw);
      if (local <= 0) return false;
      return remote > local;
    } catch (_) {
      return false;
    }
  }

  Future<void> _startDownload() async {
    if (_downloading) return;
    setState(() {
      _downloading = true;
      _dlFailed = false;
      _dlStatus = 'Downloading update...';
    });
    try {
      await _downloadAndInstall();
      if (!mounted) return;
      setState(() {
        _downloading = false;
        _dlProgress = 1;
        _dlStatus = 'Download complete. Tap INSTALL below, then Continue.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _downloading = false;
        _dlFailed = true;
        _dlStatus = 'Download failed. Check internet and tap Retry.';
      });
    }
  }

  Future<void> _downloadAndInstall() async {
    final client = http.Client();
    try {
      final request = http.Request('GET', Uri.parse(DatabaseHelper.apkDownloadUrl));
      final response = await client.send(request).timeout(const Duration(minutes: 5));
      if (response.statusCode != 200) throw Exception('Server error ${response.statusCode}');
      final total = response.contentLength ?? 0;
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/navratri-update.apk');
      final sink = file.openWrite();
      int received = 0;
      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (total > 0 && mounted) {
          setState(() => _dlProgress = received / total);
        }
      }
      await sink.close();
      await OpenFilex.open(file.path);
    } finally {
      client.close();
    }
  }

  /// Maps a device buildNumber back to the pubspec +N release number.
  static int _normalizeBuildNumber(int raw) {
    if (raw >= 2000 && raw < 3000) return raw - 2000; // our split builds
    if (raw >= 1000) return raw ~/ 1000; // generic split-per-abi scheme
    return raw; // plain (non-split) builds
  }

  Future<void> _continueIfUpdated() async {
    if (await _isUpdateAvailable()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Still on old version. Install the update to continue.'), backgroundColor: Colors.red),
      );
      return;
    }
    if (!mounted) return;
    setState(() => _updateRequired = false);
    _doNavigate(context.read<AuthProvider>());
  }

  Widget _buildUpdateGate() {
    return BackgroundScaffold(
      backgroundImage: 'assets/images/LOGIN_BG.jpg',
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(colors: [AppTheme.goldPrimary, AppTheme.goldDark]),
                    boxShadow: [BoxShadow(color: AppTheme.goldPrimary.withOpacity(0.5), blurRadius: 25)],
                  ),
                  child: const Icon(Icons.system_update, size: 44, color: AppTheme.purpleDark),
                ),
                const SizedBox(height: 20),
                const Text('Update Required', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 8),
                const Text(
                  'A new version is available. You must update to continue using the app.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.white70),
                ),
                const SizedBox(height: 20),
                Text(_dlStatus, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: AppTheme.goldPrimary)),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: _dlProgress > 0 ? _dlProgress : null,
                  color: AppTheme.goldPrimary,
                  backgroundColor: Colors.white10,
                ),
                if (_dlProgress > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text('${(_dlProgress * 100).toStringAsFixed(0)}%', style: const TextStyle(color: AppTheme.goldPrimary, fontSize: 12)),
                  ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _downloading ? null : _startDownload,
                  icon: const Icon(Icons.download, size: 18),
                  label: Text(_dlFailed ? 'Retry Download' : 'Download / Install Update', style: const TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.goldPrimary,
                    foregroundColor: AppTheme.purpleDark,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _downloading ? null : _continueIfUpdated,
                  child: const Text("I've Updated — Continue", style: TextStyle(color: Colors.white70)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_updateRequired) return _buildUpdateGate();
    return BackgroundScaffold(
      backgroundImage: 'assets/images/LOGIN_BG.jpg',
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Glowing Circle
                    Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.goldPrimary,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.goldPrimary.withOpacity(0.6),
                            blurRadius: 35,
                            spreadRadius: 5,
                          ),
                        ],
                        color: AppTheme.purpleCard.withOpacity(0.7),
                      ),
                      child: Center(
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(colors: [AppTheme.goldPrimary, AppTheme.goldDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
                          ),
                          child: const Center(
                            child: Icon(Icons.self_improvement, size: 48, color: AppTheme.purpleDark),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Title
                    const Text(
                      'NAVRATRI 2026',
                      style: TextStyle(
                        fontFamily: 'Cinzel',
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.goldPrimary,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'NISHITPARK SOCIETY',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Raas-Rang Mahotsav',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Loading Indicator
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.goldPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Connecting to Ground Live Feed...',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.cyanAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
