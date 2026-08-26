import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/countdown_timer.dart';
import '../widgets/feature_card.dart';
import 'gate_pass_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Target date: Navratri 2026 start (example: October 15, 2026)
    final navratriStart = DateTime(2026, 10, 15, 19, 30, 0);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(context),
              // Main Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      // Society Pill
                      _buildSocietyPill(),
                      const SizedBox(height: 16),
                      // Hero Title
                      _buildHeroTitle(),
                      const SizedBox(height: 12),
                      // Subtitle
                      _buildSubtitle(),
                      const SizedBox(height: 24),
                      // Countdown Timer
                      CountdownTimer(targetDate: navratriStart),
                      const SizedBox(height: 32),
                      // Section Header
                      _buildSectionHeader(),
                      const SizedBox(height: 16),
                      // Live Event Card
                      _buildLiveEventCard(),
                      const SizedBox(height: 16),
                      // Feature Grid
                      _buildFeatureGrid(context),
                      const SizedBox(height: 16),
                      // Tonight's Music Card
                      _buildMusicCard(),
                      const SizedBox(height: 20),
                      // View Pass Button
                      _buildViewPassButton(context),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
              // Footer
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.purpleDeep.withOpacity(0.92),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.goldPrimary.withOpacity(0.4),
            width: 1.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 16,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Brand Logo
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: AppTheme.goldGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.goldPrimary.withOpacity(0.7),
                      blurRadius: 18,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.self_improvement,
                  color: AppTheme.purpleDark,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nishitpark',
                    style: TextStyle(
                      fontFamily: 'Cinzel',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.goldPrimary,
                    ),
                  ),
                  Text(
                    'NAVRATRI MAHOTSAV 2026',
                    style: TextStyle(
                      fontSize: 9,
                      color: AppTheme.textMuted,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Gate Pass Button
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const GatePassScreen(
                    holderName: 'Resident Pass (Flat A-402)',
                  ),
                ),
              );
            },
            icon: const Icon(Icons.qr_code_scanner, size: 18),
            label: const Text('Digital Gate Pass'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.goldPrimary,
              foregroundColor: AppTheme.purpleDark,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocietyPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.redAccent.withOpacity(0.4),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: AppTheme.goldPrimary.withOpacity(0.7),
          width: 1,
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_fire_department, color: AppTheme.goldPrimary, size: 16),
          SizedBox(width: 8),
          Text(
            'NISHPARK SOCIETY OFFICIAL FESTIVE PORTAL',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFFFFE382),
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroTitle() {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [Colors.white, Color(0xFFFFD875)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(bounds),
      child: const Text(
        'Raas, Garba &\nBhakti 2026',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Cinzel',
          fontSize: 36,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          height: 1.15,
        ),
      ),
    );
  }

  Widget _buildSubtitle() {
    return const Text(
      'Nine nights of celebration. Access gate QR passes, vote for Garba King & Queen, and book daily Aarti slots online.',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 14,
        color: AppTheme.textMuted,
        height: 1.5,
      ),
    );
  }

  Widget _buildSectionHeader() {
    return const Column(
      children: [
        Text(
          'Connected Application Screens',
          style: TextStyle(
            fontFamily: 'Cinzel',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppTheme.goldPrimary,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Theme 2: Royal Gold & Purple Navratri Special UI',
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildLiveEventCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.redAccent.withOpacity(0.88),
            AppTheme.purpleCard.withOpacity(0.95),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.goldPrimary,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.goldPrimary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'DAY 1 : SHAILPUTRI PUJA',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppTheme.purpleDark,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Maha Aarti & Dandiya Raas',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Aarti: 07:30 PM | Raas: 08:30 PM',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFFFFE382),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Dress Code: Royal Blue & Bandhani',
            style: TextStyle(
              fontSize: 11,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: [
        FeatureCard(
          icon: Icons.qr_code_scanner,
          title: 'Gate Pass',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const GatePassScreen(
                  holderName: 'Resident (Flat A-402)',
                ),
              ),
            );
          },
        ),
        FeatureCard(
          icon: Icons.emoji_events,
          title: 'King / Queen',
          onTap: () {
            _showSnackBar(context, 'Voting for Best Traditional Attire starts at 10 PM!');
          },
        ),
        FeatureCard(
          icon: Icons.calendar_month,
          title: 'Schedule',
          onTap: () {
            _showSnackBar(context, 'Daily Aarti: 7:30 PM | Raas: 8:30 PM | Prizes: 11:30 PM');
          },
        ),
        FeatureCard(
          icon: Icons.volunteer_activism,
          title: 'Aarti Booking',
          onTap: () {
            _showSnackBar(context, 'Book Aarti Thali for Day 2 to Day 9');
          },
        ),
      ],
    );
  }

  Widget _buildMusicCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.purpleCard.withOpacity(0.9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.goldPrimary.withOpacity(0.55),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: AppTheme.goldGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.music_note,
              color: AppTheme.purpleDark,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Tonight's Live Music",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.goldPrimary,
                  ),
                ),
                Text(
                  'Traditional Orchestra & Dhol Trance',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewPassButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const GatePassScreen(
                holderName: 'Flat A-402',
              ),
            ),
          );
        },
        icon: const Icon(Icons.confirmation_number, size: 20),
        label: const Text('View My QR Pass'),
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
    );
  }

  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: AppTheme.purpleDark.withOpacity(0.94),
        border: Border(
          top: BorderSide(
            color: AppTheme.goldPrimary.withOpacity(0.35),
            width: 1.5,
          ),
        ),
      ),
      child: const Text(
        '© 2026 Nishitpark Society Welfare Association.\nNavratri Mahotsav Special.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          color: AppTheme.textMuted,
          height: 1.4,
        ),
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.purpleCard,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: AppTheme.goldPrimary, width: 1),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
