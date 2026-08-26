import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../database/database_helper.dart';

class UserSnacksScreen extends StatefulWidget {
  const UserSnacksScreen({super.key});

  @override
  State<UserSnacksScreen> createState() => _UserSnacksScreenState();
}

class _UserSnacksScreenState extends State<UserSnacksScreen> {
  List<Map<String, dynamic>> _snacks = [];
  List<Map<String, dynamic>> _myOrders = [];
  bool _isLoading = true;
  bool _showMenu = true;
  int _selectedDay = 1;

  @override
  void initState() {
    super.initState();
    _loadData();
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
      appBar: AppBar(title: const Text('Snack Counter'), backgroundColor: AppTheme.purpleDeep, foregroundColor: AppTheme.goldPrimary),
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
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () => setState(() => _selectedDay = day),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: _selectedDay == day ? AppTheme.goldPrimary : AppTheme.purpleCard,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(child: Text('Day $day', style: TextStyle(color: _selectedDay == day ? AppTheme.purpleDark : Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
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
                child: Text('My Orders (${_myOrders.length})', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: !_showMenu ? AppTheme.purpleDark : AppTheme.textMuted)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSnackMenu() {
    if (_snacks.isEmpty) return const Center(child: Text('No snacks available', style: TextStyle(color: AppTheme.textMuted)));
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: _snacks.length,
      itemBuilder: (context, index) => _buildSnackCard(_snacks[index]),
    );
  }

  Widget _buildSnackCard(Map<String, dynamic> snack) {
    final available = (snack['quantity_available'] ?? 0) - (snack['quantity_sold'] ?? 0);
    int quantity = 1;

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
            if (available > 0)
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
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order placed!'), backgroundColor: Colors.green));
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(gradient: AppTheme.goldGradient, borderRadius: BorderRadius.circular(8)),
                      child: const Text('ORDER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.purpleDark)),
                    ),
                  ),
                ],
              )
            else
              const Text('SOLD OUT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.redAccent)),
          ],
        ),
      ),
    );
  }

  Widget _buildMyOrders() {
    if (_myOrders.isEmpty) return const Center(child: Text('No orders yet', style: TextStyle(color: AppTheme.textMuted)));
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
