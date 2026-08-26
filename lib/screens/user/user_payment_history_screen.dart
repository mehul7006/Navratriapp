import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../database/database_helper.dart';

class UserPaymentHistoryScreen extends StatefulWidget {
  const UserPaymentHistoryScreen({super.key});

  @override
  State<UserPaymentHistoryScreen> createState() => _UserPaymentHistoryScreenState();
}

class _UserPaymentHistoryScreenState extends State<UserPaymentHistoryScreen> {
  List<Map<String, dynamic>> _payments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();
    final house = auth.houseNumber ?? '';
    final payments = await DatabaseHelper.getPaymentsByHouse(house);
    setState(() {
      _payments = payments;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.purpleDark,
      appBar: AppBar(
        title: const Text('My Payments', style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.purpleDeep,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _loadPayments),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.goldPrimary))
          : _payments.isEmpty
              ? const Center(child: Text('No payments found', style: TextStyle(color: AppTheme.textMuted)))
              : RefreshIndicator(
                  onRefresh: _loadPayments,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _payments.length,
                    itemBuilder: (context, index) => _buildPaymentCard(_payments[index]),
                  ),
                ),
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> payment) {
    final amount = payment['amount'] ?? 0;
    final method = (payment['payment_method'] ?? 'cash').toString().toUpperCase();
    final status = (payment['payment_status'] ?? 'paid').toString().toLowerCase();
    final date = payment['paid_date'] ?? payment['created_at'] ?? '';
    final notes = payment['notes'] ?? '';
    final Color statusColor;
    final IconData statusIcon;
    if (status == 'paid') {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else if (status == 'tentative') {
      statusColor = Colors.orange;
      statusIcon = Icons.schedule;
    } else {
      statusColor = Colors.red;
      statusIcon = Icons.pending;
    }

    return Card(
      color: AppTheme.cardBg,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('₹$amount', style: TextStyle(color: statusColor, fontSize: 20, fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    Icon(statusIcon, color: statusColor, size: 16),
                    const SizedBox(width: 4),
                    Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _infoChip(Icons.payment, method),
                const SizedBox(width: 8),
                if (date.toString().isNotEmpty) _infoChip(Icons.calendar_today, date.toString().split('T').first),
              ],
            ),
            if (notes.toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(notes, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppTheme.textMuted),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
        ],
      ),
    );
  }
}
