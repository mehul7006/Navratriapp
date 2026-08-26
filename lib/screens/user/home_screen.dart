import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../database/database_helper.dart';
import 'user_coupon_screen.dart';
import 'user_aarti_screen.dart';
import 'user_snacks_screen.dart';
import 'user_gifts_screen.dart';
import 'user_profile_screen.dart';
import 'user_schedule_screen.dart';
import 'user_winners_screen.dart';
import 'user_payment_history_screen.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  List<Map<String, dynamic>> _announcements = [];
  List<Map<String, dynamic>> _gifts = [];
  List<Map<String, dynamic>> _days = [];
  Map<String, dynamic> _stats = {'bookings': 0, 'orders': 0, 'gifts': 0};
  Timer? _countdownTimer;
  Duration _countdown = Duration.zero;
  bool _festivalStarted = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _startCountdown();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    final festivalStart = DateTime(2026, 9, 17);
    final now = DateTime.now();
    if (now.isAfter(festivalStart)) {
      setState(() => _festivalStarted = true);
      return;
    }
    _countdown = festivalStart.difference(now);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = festivalStart.difference(DateTime.now());
      if (remaining.isNegative) {
        timer.cancel();
        setState(() => _festivalStarted = true);
      } else {
        setState(() => _countdown = remaining);
      }
    });
  }

  Future<void> _loadData() async {
    final authProvider = context.read<AuthProvider>();
    final houseNumber = authProvider.houseNumber ?? '';
    
    final announcements = await DatabaseHelper.getAnnouncements();
    final gifts = await DatabaseHelper.getMyGifts(houseNumber);
    final bookings = await DatabaseHelper.getMyAartiBookings(houseNumber);
    final orders = await DatabaseHelper.getMySnackOrders(houseNumber);
    final days = await DatabaseHelper.getNavratriDays();
    
    setState(() {
      _announcements = announcements;
      _gifts = gifts;
      _days = days;
      _stats = {
        'bookings': bookings.length,
        'orders': orders.length,
        'gifts': gifts.length,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.purpleDark,
      appBar: AppBar(
        title: const Text('Navratri 2026'),
        backgroundColor: AppTheme.purpleDeep,
        foregroundColor: AppTheme.goldPrimary,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              authProvider.logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildProfileCard(user),
            const SizedBox(height: 16),
            if (!_festivalStarted) ...[
              _buildCountdownCard(),
              const SizedBox(height: 16),
            ],
            _buildQuickActions(context, user),
            const SizedBox(height: 16),
            _buildStatsRow(),
            const SizedBox(height: 16),
            _buildCurrentDayCard(),
            const SizedBox(height: 16),
            _buildAnnouncementsCard(),
            const SizedBox(height: 16),
            if (_gifts.isNotEmpty) _buildRecentGifts(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(Map<String, dynamic>? user) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppTheme.redAccent.withOpacity(0.8), AppTheme.purpleCard.withOpacity(0.95)]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.goldPrimary),
      ),
      child: Row(
        children: [
          Container(
            width: 60, height: 60,
            decoration: const BoxDecoration(gradient: AppTheme.goldGradient, shape: BoxShape.circle),
            child: Center(
              child: Text(user?['name']?.toString().substring(0, 1).toUpperCase() ?? 'U',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.purpleDark)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user?['name'] ?? 'User', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.home, size: 14, color: AppTheme.goldPrimary),
                  const SizedBox(width: 4),
                  Text('House: ${user?['house_number'] ?? 'N/A'}', style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
                ]),
                const SizedBox(height: 2),
                Row(children: [
                  const Icon(Icons.phone, size: 14, color: AppTheme.goldPrimary),
                  const SizedBox(width: 4),
                  Text('Mobile: ${user?['mobile_number'] ?? 'N/A'}', style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, Map<String, dynamic>? user) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.0,
      children: [
        _buildActionCard(
          icon: Icons.self_improvement,
          title: 'Book Aarti',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserAartiScreen())),
        ),
        _buildActionCard(
          icon: Icons.confirmation_number,
          title: 'My Coupons',
          onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => UserCouponScreen(houseNumber: user?['house_number'] ?? '', userName: user?['name'] ?? ''),
          )),
        ),
        _buildActionCard(
          icon: Icons.restaurant,
          title: 'Order Snacks',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserSnacksScreen())),
        ),
        _buildActionCard(
          icon: Icons.card_giftcard,
          title: 'My Gifts',
          badge: _stats['gifts'] > 0 ? '${_stats['gifts']}' : null,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserGiftsScreen())),
        ),
        _buildActionCard(
          icon: Icons.person,
          title: 'My Profile',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserProfileScreen())),
        ),
        _buildActionCard(
          icon: Icons.event,
          title: 'Schedule',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserScheduleScreen())),
        ),
        _buildActionCard(
          icon: Icons.emoji_events,
          title: 'Winners',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserWinnersScreen())),
        ),
        _buildActionCard(
          icon: Icons.receipt_long,
          title: 'Payments',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserPaymentHistoryScreen())),
        ),
      ],
    );
  }

  Widget _buildActionCard({required IconData icon, required String title, String? badge, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.hubItemDecoration,
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 36, color: AppTheme.goldPrimary),
                  const SizedBox(height: 8),
                  Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                ],
              ),
            ),
            if (badge != null)
              Positioned(
                right: 8, top: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                  child: Text(badge, style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        _buildMiniStat('Aarti', '${_stats['bookings']}', Icons.self_improvement, Colors.orange),
        const SizedBox(width: 8),
        _buildMiniStat('Orders', '${_stats['orders']}', Icons.restaurant, Colors.blue),
        const SizedBox(width: 8),
        _buildMiniStat('Gifts', '${_stats['gifts']}', Icons.card_giftcard, Colors.purple),
      ],
    );
  }

  Widget _buildMiniStat(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: AppTheme.hubItemDecoration,
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _buildCountdownCard() {
    final days = _countdown.inDays;
    final hours = _countdown.inHours % 24;
    final minutes = _countdown.inMinutes % 60;
    final seconds = _countdown.inSeconds % 60;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1a0a3e), Color(0xFF2d1b69)]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.goldPrimary.withValues(alpha: 0.5), width: 2),
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.timer, color: AppTheme.goldPrimary, size: 20),
              SizedBox(width: 8),
              Text('Festival Starts In', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.goldPrimary)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _countdownUnit(days, 'DAYS'),
              const Text(':', style: TextStyle(color: AppTheme.goldPrimary, fontSize: 24, fontWeight: FontWeight.bold)),
              _countdownUnit(hours, 'HRS'),
              const Text(':', style: TextStyle(color: AppTheme.goldPrimary, fontSize: 24, fontWeight: FontWeight.bold)),
              _countdownUnit(minutes, 'MIN'),
              const Text(':', style: TextStyle(color: AppTheme.goldPrimary, fontSize: 24, fontWeight: FontWeight.bold)),
              _countdownUnit(seconds, 'SEC'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _countdownUnit(int value, String label) {
    return Column(
      children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            color: AppTheme.goldPrimary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.goldPrimary.withValues(alpha: 0.3)),
          ),
          child: Center(
            child: Text(value.toString().padLeft(2, '0'),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 9, color: Colors.white.withValues(alpha: 0.6))),
      ],
    );
  }

  Widget _buildCurrentDayCard() {
    final now = DateTime.now();
    final activeDay = _days.where((d) => d['is_active'] == true).toList();
    final dayData = activeDay.isNotEmpty ? activeDay.first : (_days.isNotEmpty ? _days.first : null);
    final dayNum = dayData?['day_number'] ?? 1;
    final goddess = dayData?['goddess_name'] ?? 'Festival';
    final dressCode = dayData?['dress_code'] ?? '';
    final dateStr = dayData?['date'] ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.liveCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AppTheme.goldPrimary, borderRadius: BorderRadius.circular(10)),
            child: Text('DAY $dayNum : $goddess', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.purpleDark)),
          ),
          const SizedBox(height: 12),
          Text(goddess, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          if (dateStr.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(dateStr, style: const TextStyle(fontSize: 12, color: AppTheme.yellowLight)),
          ],
          if (dressCode.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Dress Code: $dressCode', style: const TextStyle(fontSize: 11, color: Colors.white)),
          ],
        ],
      ),
    );
  }

  Widget _buildAnnouncementsCard() {
    if (_announcements.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.hubItemDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.announcement, color: AppTheme.goldPrimary, size: 20),
              SizedBox(width: 8),
              Text('Announcements', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.goldPrimary)),
            ],
          ),
          const SizedBox(height: 12),
          ..._announcements.take(3).map((a) => _buildAnnouncementItem(a['title'] ?? '', a['message'] ?? '')),
        ],
      ),
    );
  }

  Widget _buildAnnouncementItem(String title, String message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: AppTheme.purpleDark.withOpacity(0.5), borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
          const SizedBox(height: 4),
          Text(message, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
        ],
      ),
    );
  }

  Widget _buildRecentGifts() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.hubItemDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.card_giftcard, color: AppTheme.goldPrimary, size: 20),
              SizedBox(width: 8),
              Text('Recent Gifts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.goldPrimary)),
            ],
          ),
          const SizedBox(height: 12),
          ..._gifts.take(3).map((g) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppTheme.purpleDark.withOpacity(0.5), borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                const Icon(Icons.card_giftcard, color: Colors.purple, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(g['gift_name'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white))),
                Text(g['assigned_at'] ?? '', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
