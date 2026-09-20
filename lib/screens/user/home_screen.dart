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
import 'user_reports_screen.dart';
import 'package:navratri_app/widgets/background_scaffold.dart';
import 'package:navratri_app/widgets/login_ad_popup.dart';

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
  List<Map<String, dynamic>> _myPayments = [];
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
    final days = await DatabaseHelper.getNavratriDays();
    List<Map<String, dynamic>> bookings = [];
    List<Map<String, dynamic>> orders = [];
    List<Map<String, dynamic>> gifts = [];
    List<Map<String, dynamic>> payments = [];
    if (houseNumber.isNotEmpty) {
      bookings = await DatabaseHelper.getMyAartiBookings(houseNumber);
      orders = await DatabaseHelper.getMySnackOrders(houseNumber);
      gifts = await DatabaseHelper.getMyGifts(houseNumber);
      payments = await DatabaseHelper.getPaymentsByHouse(houseNumber);
    }
    
    if (mounted) {
      setState(() {
        _announcements = announcements;
        _myBookings = bookings.where((b) => b['status'] != 'cancelled').toList();
        _myOrders = orders.where((o) => o['status'] != 'cancelled').toList();
        _myGifts = gifts;
        _myPayments = payments;
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

    return LoginAdPopup(
      child: BackgroundScaffold(
        appBar: AppBar(
        title: Text(AppLocalizations.t('navratri_2026_short'), style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.purpleDeep,
        foregroundColor: AppTheme.goldPrimary,
        iconTheme: const IconThemeData(color: AppTheme.goldPrimary),
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh, size: 20, color: AppTheme.goldPrimary), onPressed: _loadData),
          IconButton(
            icon: const Icon(Icons.logout, size: 20, color: AppTheme.goldPrimary),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        authProvider.logout();
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      child: RefreshIndicator(
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
    ),
    );
  }

  Widget _buildProfileCard(Map<String, dynamic>? user) {
    String paymentStatus = 'unpaid';
    double totalAmount = 0;
    double paidAmount = 0;
    for (var p in _myPayments) {
      final amt = double.tryParse(p['amount'].toString()) ?? 0;
      totalAmount += amt;
      if (p['payment_status'] == 'paid') paidAmount += amt;
      if (p['payment_status'] == 'pending' || p['payment_method']?.toString() == 'pay_later') paymentStatus = 'pay_later';
    }
    if (totalAmount > 0 && paidAmount >= totalAmount) paymentStatus = 'paid';
    else if (paidAmount > 0 && paidAmount < totalAmount) paymentStatus = 'partial';

    final Color statusColor;
    final String statusLabel;
    switch (paymentStatus) {
      case 'paid': statusColor = Colors.green; statusLabel = 'Paid'; break;
      case 'partial': statusColor = Colors.orange; statusLabel = 'Partial'; break;
      case 'pay_later': statusColor = Colors.orange; statusLabel = 'Pay Later'; break;
      default: statusColor = Colors.red; statusLabel = 'Unpaid'; break;
    }

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
                if (_myPayments.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(children: [
                    Icon(Icons.payment, size: 13, color: statusColor),
                    const SizedBox(width: 4),
                    Text(statusLabel, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: statusColor)),
                    if (paymentStatus != 'paid') ...[
                      const SizedBox(width: 8),
                      Text('₹${paidAmount.toStringAsFixed(0)}/₹${totalAmount.toStringAsFixed(0)}', style: TextStyle(fontSize: 11, color: statusColor.withOpacity(0.8))),
                    ],
                  ]),
                ],
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
          const Expanded(child: SizedBox.shrink()),
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
    final activeDay = _days.where((d) => d['is_active'] == true).toList();
    final todayNum = activeDay.isNotEmpty ? activeDay.first['day_number'] : (_days.isNotEmpty ? _days.first['day_number'] : 1);

    final todayBookings = _myBookings.where((b) => b['day_number'] == todayNum && b['status'] == 'approved').toList();
    final todayOrders = _myOrders.where((o) => o['day_number'] == todayNum && o['status'] == 'approved').toList();
    final todayGifts = _myGifts.where((g) => g['day_number'] == todayNum && (g['status'] == 'assigned' || g['status'] == 'delivered')).toList();

    if (todayBookings.isEmpty && todayOrders.isEmpty && todayGifts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Today\'s Bookings'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildTodayCard(
                icon: Icons.self_improvement,
                title: 'Aarti',
                color: Colors.orange,
                count: todayBookings.length,
                items: todayBookings.map((b) => '${b['person_name']?.toString() ?? ''} (${b['house_number']?.toString() ?? ''})').where((n) => n.isNotEmpty).toList(),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildTodayCard(
                icon: Icons.restaurant,
                title: 'Snacks',
                color: Colors.blue,
                count: todayOrders.length,
                items: todayOrders.map((o) => '${o['person_name']?.toString().isNotEmpty == true ? o['person_name'].toString() : ''} (${o['house_number']?.toString() ?? ''}) - ${o['snack_name']?.toString().isNotEmpty == true ? o['snack_name'].toString() : 'Snack'}').toList(),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildTodayCard(
                icon: Icons.card_giftcard,
                title: 'Gifts',
                color: Colors.purple,
                count: todayGifts.length,
                items: todayGifts.map((g) => '${g['user_name']?.toString().isNotEmpty == true ? g['user_name'].toString() : ''} (${g['house_number']?.toString() ?? ''}) - ${g['gift_name']?.toString().isNotEmpty == true ? g['gift_name'].toString() : 'Gift'}').toList(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTodayCard({required IconData icon, required String title, required Color color, required int count, required List<String> items}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: AppTheme.hubItemDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color), overflow: TextOverflow.ellipsis),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                child: Text('$count', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (items.isEmpty)
            Text('No bookings', style: TextStyle(fontSize: 12, color: AppTheme.textMuted))
          else
            for (final item in items.take(3))
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  item,
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          if (items.length > 3)
            Text('+${items.length - 3} more', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.goldPrimary));
  }

  Widget _buildQuickActions(BuildContext context, Map<String, dynamic>? user) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width > 600 ? 5 : (width > 400 ? 4 : 3);
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.2,
          children: [
            _buildActionCard(icon: Icons.self_improvement, title: AppLocalizations.t('book_aarti'), badge: _stats['bookings'] > 0 ? '${_stats['bookings']}' : null, isDesktop: width > 600,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserAartiScreen()))),
            _buildActionCard(icon: Icons.restaurant, title: AppLocalizations.t('food'), badge: _stats['orders'] > 0 ? '${_stats['orders']}' : null, isDesktop: width > 600,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserSnacksScreen()))),
            _buildActionCard(icon: Icons.card_giftcard, title: AppLocalizations.t('gifts'), badge: _stats['gifts'] > 0 ? '${_stats['gifts']}' : null, isDesktop: width > 600,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserGiftsScreen()))),
            _buildActionCard(icon: Icons.confirmation_number, title: AppLocalizations.t('my_tickets'), isDesktop: width > 600,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => UserCouponScreen(houseNumber: user?['house_number'] ?? '', userName: user?['name'] ?? '')))),
            _buildActionCard(icon: Icons.person, title: AppLocalizations.t('profile'), isDesktop: width > 600,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserProfileScreen()))),
            _buildActionCard(icon: Icons.event, title: AppLocalizations.t('schedule'), isDesktop: width > 600,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserScheduleScreen()))),
            _buildActionCard(icon: Icons.emoji_events, title: AppLocalizations.t('winners'), isDesktop: width > 600,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserWinnersScreen()))),
            _buildActionCard(icon: Icons.receipt_long, title: AppLocalizations.t('payments'), isDesktop: width > 600,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserPaymentHistoryScreen()))),
            _buildActionCard(icon: Icons.music_note, title: AppLocalizations.t('songs'), isDesktop: width > 600,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserSongRequestScreen()))),
            _buildActionCard(icon: Icons.analytics, title: AppLocalizations.t('reports_analytics_title'), isDesktop: width > 600,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserReportsScreen()))),
          ],
        );
      },
    );
  }

  Widget _buildActionCard({required IconData icon, required String title, String? badge, required VoidCallback onTap, bool isDesktop = false}) {
    final badgeFontSize = isDesktop ? 14.0 : 9.0;
    final badgePaddingH = isDesktop ? 10.0 : 5.0;
    final badgePaddingV = isDesktop ? 4.0 : 2.0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        clipBehavior: Clip.hardEdge,
        decoration: AppTheme.hubItemDecoration,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned.fill(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 32, color: AppTheme.goldPrimary),
                    const SizedBox(height: 3),
                    Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ),
            if (badge != null)
              Positioned(
                right: isDesktop ? 4 : 2, top: isDesktop ? 4 : 2,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: badgePaddingH, vertical: badgePaddingV),
                  decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(isDesktop ? 12 : 8)),
                  child: Text(badge, style: TextStyle(fontSize: badgeFontSize, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
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
