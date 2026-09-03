import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../database/database_helper.dart';
import 'member_management_screen.dart';
import 'payment_collection_screen.dart';
import 'expense_management_screen.dart';
import 'aarti_management_screen.dart';
import 'snack_management_screen.dart';
import 'gift_management_screen.dart';
import 'announcement_management_screen.dart';
import 'ticket_management_screen.dart';
import 'day_management_screen.dart';
import 'sponsor_management_screen.dart';
import 'reports_screen.dart';
import 'draw_history_screen.dart';
import 'lucky_draw_screen.dart';
import 'broadcast_management_screen.dart';
import 'dj_console_screen.dart';
import 'garba_participation_screen.dart';
import '../../widgets/language_toggle.dart';
import '../../l10n/app_localizations.dart';

class OrganizerDashboardScreen extends StatefulWidget {
  const OrganizerDashboardScreen({super.key});

  @override
  State<OrganizerDashboardScreen> createState() => _OrganizerDashboardScreenState();
}

class _OrganizerDashboardScreenState extends State<OrganizerDashboardScreen> {
  int _selectedIndex = 0;
  Map<String, dynamic> _stats = {
    'totalUsers': 0,
    'totalIncome': 0.0,
    'totalExpenses': 0.0,
    'pendingBookings': 0,
    'pendingOrders': 0,
    'totalPaid': 0,
    'totalPending': 0,
    'totalDenied': 0,
  };

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final members = await DatabaseHelper.getAllMembers();
      final payments = await DatabaseHelper.getAllPayments();
      final expenses = await DatabaseHelper.getExpenses();
      final bookings = await DatabaseHelper.getAartiBookings(status: 'pending');

      double totalIncome = 0;
      int totalPaid = 0;
      int totalPending = 0;
      int totalDenied = 0;
      for (var p in payments) {
        final amt = double.tryParse(p['amount'].toString()) ?? 0;
        final status = (p['payment_status'] ?? '').toString().toLowerCase();
        if (status == 'paid') {
          totalIncome += amt;
          totalPaid++;
        } else if (status == 'pending' || status == 'pay_later') {
          totalPending++;
        } else if (status == 'denied') {
          totalDenied++;
        }
      }

      double expenseTotal = 0;
      for (var e in expenses) {
        final paidBy = (e['paid_by'] ?? 'organizer').toString().toLowerCase();
        if (paidBy == 'organizer') {
          expenseTotal += double.tryParse(e['amount'].toString()) ?? 0;
        }
      }

      if (mounted) {
        setState(() {
          _stats = {
            'totalUsers': members.length,
            'totalIncome': totalIncome,
            'totalExpenses': expenseTotal,
            'pendingBookings': bookings.length,
            'pendingOrders': 0,
            'totalPaid': totalPaid,
            'totalPending': totalPending,
            'totalDenied': totalDenied,
          };
        });
      }
    } catch (e) {
      // ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return PopScope(
      canPop: _selectedIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _selectedIndex != 0) {
          setState(() { _selectedIndex = 0; });
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.purpleDark,
        appBar: AppBar(
          title: Text(_getTabTitle(), style: const TextStyle(color: AppTheme.goldPrimary)),
          backgroundColor: AppTheme.purpleDeep,
          foregroundColor: AppTheme.goldPrimary,
          iconTheme: const IconThemeData(color: AppTheme.goldPrimary),
          leading: _selectedIndex != 0
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () { setState(() { _selectedIndex = 0; }); },
                )
              : null,
          actions: [
            const LanguageToggle(),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadStats,
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                authProvider.logout();
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ),
        body: _buildBody(),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  String _getTabTitle() {
    switch (_selectedIndex) {
      case 0: return AppLocalizations.t('organizer_dashboard');
      case 1: return AppLocalizations.t('manage_members');
      case 2: return AppLocalizations.t('aarti_bookings');
      case 3: return AppLocalizations.t('snack_orders');
      case 4: return AppLocalizations.t('gifts_prizes');
      default: return AppLocalizations.t('organizer_dashboard');
    }
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0: return _buildHomeTab();
      case 1: return const MemberManagementScreen();
      case 2: return const AartiManagementScreen();
      case 3: return const SnackManagementScreen();
      case 4: return const GiftManagementScreen();
      default: return _buildHomeTab();
    }
  }

  Widget _buildHomeTab() {
    final income = double.tryParse(_stats['totalIncome'].toString()) ?? 0;
    final expenses = double.tryParse(_stats['totalExpenses'].toString()) ?? 0;
    final net = income - expenses;

    return RefreshIndicator(
      onRefresh: _loadStats,
      color: AppTheme.goldPrimary,
      backgroundColor: AppTheme.purpleDeep,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.t('dashboard_overview'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.goldPrimary)),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.6,
              children: [
                _buildStatCard(AppLocalizations.t('members'), '${_stats['totalUsers']}', Icons.people, Colors.blue),
                _buildStatCard(AppLocalizations.t('income'), '₹${income.toStringAsFixed(0)}', Icons.attach_money, Colors.green),
                _buildStatCard(AppLocalizations.t('expenses'), '₹${expenses.toStringAsFixed(0)}', Icons.receipt, Colors.red),
                _buildStatCard(AppLocalizations.t('aarti_pending'), '${_stats['pendingBookings']}', Icons.pending_actions, Colors.orange),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: net >= 0 ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: net >= 0 ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _miniStat(AppLocalizations.t('net_balance'), '₹${net.toStringAsFixed(0)}', net >= 0 ? Colors.green : Colors.red),
                  Container(width: 1, height: 30, color: Colors.white24),
                  _miniStat(AppLocalizations.t('paid'), '${_stats['totalPaid']}', Colors.green),
                  Container(width: 1, height: 30, color: Colors.white24),
                  _miniStat(AppLocalizations.t('pending'), '${_stats['totalPending']}', Colors.orange),
                  Container(width: 1, height: 30, color: Colors.white24),
                  _miniStat(AppLocalizations.t('denied'), '${_stats['totalDenied']}', Colors.red),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(AppLocalizations.t('management'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 12),
            _buildQuickAction(AppLocalizations.t('manage_members'), Icons.people, () => setState(() => _selectedIndex = 1)),
            _buildQuickAction(AppLocalizations.t('aarti_bookings'), Icons.self_improvement, () => setState(() => _selectedIndex = 2)),
            _buildQuickAction(AppLocalizations.t('snack_orders'), Icons.restaurant, () => setState(() => _selectedIndex = 3)),
            _buildQuickAction(AppLocalizations.t('gifts_prizes'), Icons.card_giftcard, () => setState(() => _selectedIndex = 4)),
            const SizedBox(height: 16),
            Text(AppLocalizations.t('finance_events'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 12),
            _buildQuickAction(AppLocalizations.t('collect_payment'), Icons.payment, () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentCollectionScreen()));
              _loadStats();
            }),
            _buildQuickAction(AppLocalizations.t('manage_expenses'), Icons.receipt_long, () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpenseManagementScreen()));
              _loadStats();
            }),
            _buildQuickAction(AppLocalizations.t('announcements'), Icons.announcement, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AnnouncementManagementScreen()));
            }),
            const SizedBox(height: 16),
            Text(AppLocalizations.t('draw_sponsors'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 12),
            _buildQuickAction(AppLocalizations.t('draw_tickets'), Icons.confirmation_number, () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const TicketManagementScreen()));
              _loadStats();
            }),
            _buildQuickAction(AppLocalizations.t('day_schedule'), Icons.calendar_today, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const DayManagementScreen()));
            }),
            _buildQuickAction(AppLocalizations.t('sponsors'), Icons.business, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SponsorManagementScreen()));
            }),
            _buildQuickAction(AppLocalizations.t('reports_analytics'), Icons.analytics, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen()));
            }),
            _buildQuickAction(AppLocalizations.t('draw_history'), Icons.emoji_events_outlined, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const DrawHistoryScreen()));
            }),
            _buildQuickAction(AppLocalizations.t('lucky_draw_spin'), Icons.casino, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const LuckyDrawScreen()));
            }),
            _buildQuickAction(AppLocalizations.t('garba_participation'), Icons.groups, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const GarbaParticipationScreen()));
            }),
            _buildQuickAction(AppLocalizations.t('broadcasts'), Icons.campaign, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const BroadcastManagementScreen()));
            }),
            _buildQuickAction(AppLocalizations.t('dj_console'), Icons.headset, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const DjConsoleScreen()));
            }),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: AppTheme.hubItemDecoration,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(title, style: const TextStyle(fontSize: 9, color: AppTheme.textMuted), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildQuickAction(String title, IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Container(
          width: 44, height: 44,
          decoration: const BoxDecoration(gradient: AppTheme.goldGradient, borderRadius: BorderRadius.all(Radius.circular(12))),
          child: Icon(icon, color: AppTheme.purpleDark),
        ),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.arrow_forward_ios, color: AppTheme.goldPrimary, size: 16),
        onTap: onTap,
        tileColor: AppTheme.purpleCard.withOpacity(0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(color: AppTheme.purpleDeep, border: Border(top: BorderSide(color: AppTheme.cardBorder))),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        selectedItemColor: AppTheme.goldPrimary,
        unselectedItemColor: AppTheme.textMuted,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.home), label: AppLocalizations.t('home')),
          BottomNavigationBarItem(icon: const Icon(Icons.people), label: AppLocalizations.t('members')),
          BottomNavigationBarItem(icon: const Icon(Icons.self_improvement), label: AppLocalizations.t('aarti')),
          BottomNavigationBarItem(icon: const Icon(Icons.restaurant), label: AppLocalizations.t('snacks')),
          BottomNavigationBarItem(icon: const Icon(Icons.card_giftcard), label: AppLocalizations.t('gifts')),
        ],
      ),
    );
  }
}
