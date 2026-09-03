import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
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
import 'user_song_request_screen.dart';
import 'user_shoutout_wall_screen.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  List<Map<String, dynamic>> _announcements = [];
  List<Map<String, dynamic>> _myBookings = [];
  List<Map<String, dynamic>> _myOrders = [];
  List<Map<String, dynamic>> _myGifts = [];
  List<Map<String, dynamic>> _days = [];
  Map<String, dynamic> _stats = {'bookings': 0, 'orders': 0, 'gifts': 0};
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) => _loadData());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    final authProvider = context.read<AuthProvider>();
    final houseNumber = authProvider.houseNumber ?? '';
    
    final announcements = await DatabaseHelper.getAnnouncements();
    final bookings = await DatabaseHelper.getMyAartiBookings(houseNumber);
    final orders = await DatabaseHelper.getMySnackOrders(houseNumber);
    final gifts = await DatabaseHelper.getMyGifts(houseNumber);
    final days = await DatabaseHelper.getNavratriDays();
    
    if (mounted) {
      setState(() {
        _announcements = announcements;
        _myBookings = bookings.where((b) => b['status'] != 'cancelled').toList();
        _myOrders = orders.where((o) => o['status'] != 'cancelled').toList();
        _myGifts = gifts;
        _days = days;
        _stats = {
          'bookings': _myBookings.length,
          'orders': _myOrders.length,
          'gifts': _myGifts.length,
        };
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.purpleDark,
      appBar: AppBar(
        title: Text(AppLocalizations.t('navratri_2026_short'), style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.purpleDeep,
        foregroundColor: AppTheme.goldPrimary,
        iconTheme: const IconThemeData(color: AppTheme.goldPrimary),
        elevation: 0,
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
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppTheme.goldPrimary,
        backgroundColor: AppTheme.purpleDark,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileCard(user),
              const SizedBox(height: 16),
              _buildCurrentDayBanner(),
              const SizedBox(height: 16),
              _buildMyBookingsSummary(),
              const SizedBox(height: 16),
              _buildQuickActions(context, user),
              const SizedBox(height: 16),
              _buildStatsRow(),
              const SizedBox(height: 16),
              if (_announcements.isNotEmpty) ...[
                _buildSectionTitle(AppLocalizations.t('announcements')),
                const SizedBox(height: 8),
                _buildAnnouncementsCard(),
                const SizedBox(height: 16),
              ],
            ],
          ),
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
            width: 56, height: 56,
            decoration: const BoxDecoration(gradient: AppTheme.goldGradient, shape: BoxShape.circle),
            child: Center(
              child: Text(user?['name']?.toString().substring(0, 1).toUpperCase() ?? 'U',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.purpleDark)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user?['name'] ?? 'User', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 3),
                Row(children: [
                  const Icon(Icons.home, size: 13, color: AppTheme.goldPrimary),
                  const SizedBox(width: 4),
                  Text('${user?['house_number'] ?? 'N/A'}', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                  const SizedBox(width: 12),
                  const Icon(Icons.phone, size: 13, color: AppTheme.goldPrimary),
                  const SizedBox(width: 4),
                  Text('${user?['mobile_number'] ?? 'N/A'}', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentDayBanner() {
    final activeDay = _days.where((d) => d['is_active'] == true).toList();
    final dayData = activeDay.isNotEmpty ? activeDay.first : (_days.isNotEmpty ? _days.first : null);
    final dayNum = dayData?['day_number'] ?? 1;
    final goddess = dayData?['goddess_name'] ?? 'Festival';
    final dressCode = dayData?['dress_code'] ?? '';
    final dateStr = dayData?['date'] ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1a0a3e), Color(0xFF2d1b69)]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.goldPrimary.withOpacity(0.5), width: 2),
      ),
      child: Row(
        children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(color: AppTheme.goldPrimary.withOpacity(0.15), borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.goldPrimary.withOpacity(0.3))),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('D$dayNum', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.goldPrimary)),
                const SizedBox(height: 2),
                Text(dateStr.split('T').first.split('-').last, style: const TextStyle(fontSize: 10, color: Colors.white70)),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(goddess, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                if (dressCode.isNotEmpty)
                  Text('Dress: $dressCode', style: const TextStyle(fontSize: 12, color: AppTheme.goldPrimary)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: AppTheme.goldPrimary, borderRadius: BorderRadius.circular(20)),
            child: Text('DAY $dayNum', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.purpleDark)),
          ),
        ],
      ),
    );
  }

  Widget _buildMyBookingsSummary() {
    final activeBookings = _myBookings.where((b) => b['status'] == 'approved' || b['status'] == 'pending').toList();
    final activeOrders = _myOrders.where((o) => o['status'] != 'delivered' && o['status'] != 'cancelled').toList();
    
    if (activeBookings.isEmpty && activeOrders.isEmpty && _myGifts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(AppLocalizations.t('my_activity')),
        const SizedBox(height: 8),
        Row(
          children: [
            if (activeBookings.isNotEmpty)
              _buildActivityChip(Icons.self_improvement, '${activeBookings.length} Aarti', Colors.orange),
            if (activeOrders.isNotEmpty)
              _buildActivityChip(Icons.restaurant, '${activeOrders.length} Food', Colors.blue),
            if (_myGifts.isNotEmpty)
              _buildActivityChip(Icons.card_giftcard, '${_myGifts.length} Gifts', Colors.purple),
          ],
        ),
      ],
    );
  }

  Widget _buildActivityChip(IconData icon, String text, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.4))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.goldPrimary));
  }

  Widget _buildQuickActions(BuildContext context, Map<String, dynamic>? user) {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 0.85,
      children: [
        _buildActionCard(icon: Icons.self_improvement, title: AppLocalizations.t('book_aarti'), badge: _stats['bookings'] > 0 ? '${_stats['bookings']}' : null,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserAartiScreen()))),
        _buildActionCard(icon: Icons.restaurant, title: AppLocalizations.t('food'), badge: _stats['orders'] > 0 ? '${_stats['orders']}' : null,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserSnacksScreen()))),
        _buildActionCard(icon: Icons.card_giftcard, title: AppLocalizations.t('gifts'), badge: _stats['gifts'] > 0 ? '${_stats['gifts']}' : null,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserGiftsScreen()))),
        _buildActionCard(icon: Icons.confirmation_number, title: AppLocalizations.t('my_tickets'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => UserCouponScreen(houseNumber: user?['house_number'] ?? '', userName: user?['name'] ?? '')))),
        _buildActionCard(icon: Icons.person, title: AppLocalizations.t('profile'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserProfileScreen()))),
        _buildActionCard(icon: Icons.event, title: AppLocalizations.t('schedule'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserScheduleScreen()))),
        _buildActionCard(icon: Icons.emoji_events, title: AppLocalizations.t('winners'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserWinnersScreen()))),
        _buildActionCard(icon: Icons.receipt_long, title: AppLocalizations.t('payments'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserPaymentHistoryScreen()))),
        _buildActionCard(icon: Icons.music_note, title: AppLocalizations.t('songs'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserSongRequestScreen()))),
        _buildActionCard(icon: Icons.celebration, title: AppLocalizations.t('shoutout'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserShoutoutWallScreen()))),
      ],
    );
  }

  Widget _buildActionCard({required IconData icon, required String title, String? badge, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: AppTheme.hubItemDecoration,
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 28, color: AppTheme.goldPrimary),
                  const SizedBox(height: 6),
                  Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white), textAlign: TextAlign.center),
                ],
              ),
            ),
            if (badge != null)
              Positioned(
                right: 6, top: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(8)),
                  child: Text(badge, style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
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
        _buildMiniStat(AppLocalizations.t('aarti'), '${_stats['bookings']}', Icons.self_improvement, Colors.orange),
        const SizedBox(width: 8),
        _buildMiniStat(AppLocalizations.t('orders'), '${_stats['orders']}', Icons.restaurant, Colors.blue),
        const SizedBox(width: 8),
        _buildMiniStat(AppLocalizations.t('gifts'), '${_stats['gifts']}', Icons.card_giftcard, Colors.purple),
        const SizedBox(width: 8),
        _buildMiniStat(AppLocalizations.t('tickets'), '${_myBookings.length}', Icons.confirmation_number, Colors.amber),
      ],
    );
  }

  Widget _buildMiniStat(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: AppTheme.hubItemDecoration,
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: const TextStyle(fontSize: 9, color: AppTheme.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnouncementsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.hubItemDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ..._announcements.take(3).map((a) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppTheme.purpleDark.withOpacity(0.5), borderRadius: BorderRadius.circular(8)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a['title'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                const SizedBox(height: 4),
                Text(a['message'] ?? '', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
