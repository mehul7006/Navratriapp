import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import 'package:navratri_app/widgets/background_scaffold.dart';

class GatePassScreen extends StatelessWidget {
  final String holderName;

  const GatePassScreen({super.key, required this.holderName});

  @override
  Widget build(BuildContext context) {
    return BackgroundScaffold(
      child: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(context),
              // Content
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: _buildPassCard(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.purpleDeep.withOpacity(0.92),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.goldPrimary.withOpacity(0.4),
            width: 1.5,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios, color: AppTheme.goldPrimary),
          ),
          const Expanded(
            child: Text(
              'Digital Gate Pass',
              style: TextStyle(
                fontFamily: 'Cinzel',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.goldPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPassCard(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 380),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2A0A44), Color(0xFF120120)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: AppTheme.goldPrimary,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.goldPrimary.withOpacity(0.5),
            blurRadius: 45,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            // Pass Title
            const Text(
              'OFFICIAL NAVRATRI 2026 PASS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppTheme.goldPrimary,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Nishitpark Society',
              style: TextStyle(
                fontFamily: 'Cinzel',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$holderName | Valid for 9 Nights',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 24),

            // QR Code
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: QrImageView(
                data: 'NAVRATRI2026-$holderName-NISHITPARK',
                version: QrVersions.auto,
                size: 180,
                backgroundColor: Colors.white,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: AppTheme.purpleDark,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: AppTheme.purpleDark,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Verified Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.verified, color: AppTheme.cyanAccent, size: 18),
                SizedBox(width: 8),
                Text(
                  'Verified Gate Access',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.cyanAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // WhatsApp Share Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _shareViaWhatsApp(context),
                icon: const Icon(Icons.share, size: 20),
                label: const Text('Share Pass via WhatsApp'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.goldPrimary,
                  foregroundColor: AppTheme.purpleDark,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareViaWhatsApp(BuildContext context) async {
    final message = Uri.encodeComponent(
      'Navratri 2026 Digital Pass - Nishitpark Society\n'
      'Holder: $holderName\n'
      'Valid for 9 Nights\n'
      'Show this QR code at the gate for entry.',
    );
    final whatsappUrl = Uri.parse('https://wa.me/?text=$message');

    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not launch WhatsApp. Please install WhatsApp.'),
            backgroundColor: AppTheme.redAccent,
          ),
        );
      }
    }
  }
}
