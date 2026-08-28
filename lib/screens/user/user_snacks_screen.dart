import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../database/database_helper.dart';
import '../../l10n/app_localizations.dart';

class UserSnacksScreen extends StatefulWidget {
  const UserSnacksScreen({super.key});

  @override
  State<UserSnacksScreen> createState() => _UserSnacksScreenState();
}

class _UserSnacksScreenState extends State<UserSnacksScreen> {
  List<Map<String, dynamic>> _snacks = [];
  List<Map<String, dynamic>> _myOrders = [];
  List<Map<String, dynamic>> _days = [];
  bool _isLoading = true;
  bool _showMenu = true;
  int _selectedDay = 1;

  @override
  void initState() {
    super.initState();
    _initDay();
  }

  Future<void> _initDay() async {
    _days = await DatabaseHelper.getNavratriDays();
    final activeDay = await DatabaseHelper.getCurrentActiveDay();
    if (activeDay != null) _selectedDay = activeDay;
    _loadData();
  }

  bool _isDayBookable(int dayNumber) {
    final day = _days.firstWhere(
      (d) => d['day_number'] == dayNumber,
      orElse: () => {},
    );
    if (day.isEmpty) return false;
    if (day['is_completed'] == true) return false;
    if (day['is_active'] == true) return true;
    final activeDay = _days.firstWhere(
      (d) => d['is_active'] == true,
      orElse: () => {},
    );
    if (activeDay.isEmpty) return false;
    return dayNumber > (activeDay['day_number'] as int);
  }

  bool _isDayCompleted(int dayNumber) {
    final day = _days.firstWhere(
      (d) => d['day_number'] == dayNumber,
      orElse: () => {},
    );
    return day.isNotEmpty && day['is_completed'] == true;
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final authProvider = context.read<AuthProvider>();
    _snacks = await DatabaseHelper.getSnacks();
    _myOrders = await DatabaseHelper.getMySnackOrders(authProvider.houseNumber ?? '');
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.purpleDark,
      appBar: AppBar(title: Text(AppLocalizations.t('snack_counter')), backgroundColor: AppTheme.purpleDeep, foregroundColor: AppTheme.goldPrimary),
      body: Column(
        children: [
          _buildDaySelector(),
          _buildTabBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _showMenu ? _buildSnackMenu() : _buildMyOrders(),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySelector() {
    return Container(
      height: 50,
      color: AppTheme.purpleDeep.withValues(alpha: 0.3),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        itemCount: 9,
        itemBuilder: (context, index) {
          final day = index + 1;
          final bookable = _isDayBookable(day);
          final completed = _isDayCompleted(day);
          final isSelected = _selectedDay == day;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: bookable ? () => setState(() => _selectedDay = day) : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.goldPrimary : (completed ? Colors.red.withOpacity(0.15) : AppTheme.purpleCard),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: completed ? Colors.red.withOpacity(0.6) : (isSelected ? AppTheme.goldPrimary : Colors.transparent),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Day $day', style: TextStyle(color: completed ? Colors.red.withOpacity(0.7) : (isSelected ? AppTheme.purpleDark : Colors.white), fontWeight: FontWeight.bold, fontSize: 12)),
                    if (completed) ...[
                      const SizedBox(width: 4),
                      Icon(Icons.lock, size: 12, color: Colors.red.withOpacity(0.7)),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _showMenu = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _showMenu ? AppTheme.goldPrimary : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.goldPrimary.withOpacity(0.5)),
                ),
                child: Text('Menu (${_snacks.length})', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _showMenu ? AppTheme.purpleDark : AppTheme.textMuted)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _showMenu = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: !_showMenu ? AppTheme.goldPrimary : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.goldPrimary.withOpacity(0.5)),
                ),
                child: Text('My Bookings (${_myOrders.length})', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: !_showMenu ? AppTheme.purpleDark : AppTheme.textMuted)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSnackMenu() {
    if (_snacks.isEmpty) return Center(child: Text(AppLocalizations.t('no_snacks_available'), style: const TextStyle(color: AppTheme.textMuted)));
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: _snacks.length,
      itemBuilder: (context, index) => _buildSnackCard(_snacks[index]),
    );
  }

  Widget _buildSnackCard(Map<String, dynamic> snack) {
    final available = (snack['quantity_available'] ?? 0) - (snack['quantity_sold'] ?? 0);
    int quantity = 1;
    final dayBookable = _isDayBookable(_selectedDay);
    final completed = _isDayCompleted(_selectedDay);

    return StatefulBuilder(
      builder: (context, setCardState) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: AppTheme.hubItemDecoration,
        child: Row(
          children: [
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                color: (snack['is_vegetarian'] ?? true) ? Colors.green.withOpacity(0.2) : AppTheme.redAccent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon((snack['is_vegetarian'] ?? true) ? Icons.eco : Icons.restaurant, color: (snack['is_vegetarian'] ?? true) ? Colors.green : AppTheme.redAccent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(snack['name'] ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                  const SizedBox(height: 2),
                  Text(snack['description'] ?? '', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text('₹${snack['price']} • $available left', style: const TextStyle(fontSize: 12, color: AppTheme.goldPrimary)),
                ],
              ),
            ),
            if (!dayBookable)
              Icon(Icons.lock, color: Colors.red.withOpacity(0.6), size: 24)
            else if (available > 0)
              Column(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () { if (quantity > 1) setCardState(() => quantity--); },
                        child: Container(width: 28, height: 28, decoration: BoxDecoration(color: AppTheme.purpleCard, borderRadius: BorderRadius.circular(6)),
                          child: const Icon(Icons.remove, color: Colors.white, size: 16)),
                      ),
                      Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text('$quantity', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white))),
                      GestureDetector(
                        onTap: () { if (quantity < available) setCardState(() => quantity++); },
                        child: Container(width: 28, height: 28, decoration: BoxDecoration(color: AppTheme.purpleCard, borderRadius: BorderRadius.circular(6)),
                          child: const Icon(Icons.add, color: Colors.white, size: 16)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () async {
                      final authProvider = context.read<AuthProvider>();
                      await DatabaseHelper.orderSnack(
                        userId: authProvider.currentUser?['id'],
                        houseNumber: authProvider.houseNumber ?? '',
                        snackId: snack['id'],
                        dayNumber: _selectedDay,
                        quantity: quantity,
                      );
                      _loadData();
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.t('order_placed')), backgroundColor: Colors.green));
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(gradient: AppTheme.goldGradient, borderRadius: BorderRadius.circular(8)),
                      child: Text(AppLocalizations.t('book'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.purpleDark)),
                    ),
                  ),
                ],
              )
            else
              Text(AppLocalizations.t('sold_out'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.redAccent)),
          ],
        ),
      ),
    );
  }

  Widget _buildMyOrders() {
    if (_myOrders.isEmpty) return Center(child: Text(AppLocalizations.t('no_orders_yet'), style: const TextStyle(color: AppTheme.textMuted)));
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: _myOrders.length,
      itemBuilder: (context, index) {
        final order = _myOrders[index];
        final status = order['status'] ?? 'pending';
        Color statusColor;
        switch (status) {
          case 'delivered': statusColor = Colors.green; break;
          case 'preparing': statusColor = Colors.blue; break;
          case 'cancelled': statusColor = Colors.grey; break;
          default: statusColor = Colors.orange;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: AppTheme.hubItemDecoration,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${order['snack_name']} x${order['quantity']}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                    const SizedBox(height: 2),
                    Text('₹${order['total_price']} • Day ${order['day_number']}', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                  ],
                ),
              ),
              if (status != 'cancelled')
                IconButton(
                  icon: const Icon(Icons.cancel, color: Colors.red, size: 20),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: AppTheme.cardBg,
                        title: Text(AppLocalizations.t('cancel_order_title'), style: const TextStyle(color: Colors.white)),
                        content: Text(AppLocalizations.t('cancel_order_content'), style: const TextStyle(color: Colors.white70)),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppLocalizations.t('no'), style: const TextStyle(color: AppTheme.goldPrimary))),
                          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(AppLocalizations.t('yes_cancel'), style: const TextStyle(color: Colors.red))),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await DatabaseHelper.cancelSnackOrder(order['id']);
                      _loadData();
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.t('order_cancelled')), backgroundColor: Colors.orange));
                    }
                  },
                ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.2), borderRadius: BorderRadius.circular(20), border: Border.all(color: statusColor)),
                child: Text(status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor)),
              ),
            ],
          ),
        );
      },
    );
  }
}
