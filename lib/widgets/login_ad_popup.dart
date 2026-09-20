import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../database/database_helper.dart';

class LoginAdPopup extends StatefulWidget {
  final Widget child;
  const LoginAdPopup({super.key, required this.child});

  @override
  State<LoginAdPopup> createState() => _LoginAdPopupState();
}

class _LoginAdPopupState extends State<LoginAdPopup> {
  List<Map<String, dynamic>> _confirmedAds = [];
  bool _showAdPopup = false;
  Timer? _adCountdownTimer;
  final ValueNotifier<int> _adCountdown = ValueNotifier(15);
  bool _adCloseEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadConfirmedAds();
  }

  @override
  void dispose() {
    _adCountdownTimer?.cancel();
    _adCountdown.dispose();
    super.dispose();
  }

  Future<void> _loadConfirmedAds() async {
    try {
      final ads = await DatabaseHelper.getConfirmedAdsForLogin();
      if (mounted && ads.isNotEmpty) {
        setState(() => _confirmedAds = ads);
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) _openAdPopup();
      }
    } catch (_) {}
  }

  void _openAdPopup() {
    if (_confirmedAds.isEmpty || !mounted) return;
    _adCountdown.value = 15;
    _adCloseEnabled = false;
    setState(() => _showAdPopup = true);

    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) setState(() => _adCloseEnabled = true);
    });

    _adCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_adCountdown.value <= 1) {
        timer.cancel();
        _dismissAd();
      } else {
        _adCountdown.value--;
      }
    });
  }

  void _dismissAd() {
    _adCountdownTimer?.cancel();
    if (mounted) setState(() => _showAdPopup = false);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_showAdPopup) _buildAdPopup(),
      ],
    );
  }

  Widget _buildAdPopup() {
    if (_confirmedAds.isEmpty) return const SizedBox.shrink();
    final ad = _confirmedAds.first;
    final imageData = ad['image_data'] ?? '';
    final sponsorName = ad['sponsor_name'] ?? '';

    return GestureDetector(
      onTap: () {},
      child: Container(
        color: Colors.black.withOpacity(0.7),
        child: Center(
          child: Stack(
            children: [
              Container(
                width: 480,
                height: 360,
                margin: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.purpleCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.goldPrimary, width: 2),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.8), blurRadius: 30)],
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                        child: SizedBox(
                          width: double.infinity,
                          child: Image.memory(
                            base64Decode(imageData),
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(Icons.broken_image, color: Colors.white24, size: 60),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.purpleDeep,
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
                      ),
                      child: Text(
                        sponsorName.isNotEmpty ? 'Sponsored by $sponsorName' : 'Advertisement',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.goldPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 32,
                right: 32,
                child: ValueListenableBuilder<int>(
                  valueListenable: _adCountdown,
                  builder: (context, countdown, _) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.timer, color: countdown <= 5 ? Colors.red : AppTheme.goldPrimary, size: 14),
                        const SizedBox(width: 4),
                        Text('$countdown s', style: TextStyle(
                          color: countdown <= 5 ? Colors.red : Colors.white,
                          fontSize: 13, fontWeight: FontWeight.bold,
                        )),
                      ],
                    ),
                  ),
                ),
              ),
              if (_adCloseEnabled)
                Positioned(
                  top: 32,
                  left: 32,
                  child: GestureDetector(
                    onTap: _dismissAd,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.8),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 20),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
