import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../database/database_helper.dart';

class UserAartiScreen extends StatefulWidget {
  const UserAartiScreen({super.key});

  @override
  State<UserAartiScreen> createState() => _UserAartiScreenState();
}

class _UserAartiScreenState extends State<UserAartiScreen> {
  List<Map<String, dynamic>> _slots = [];
  List<Map<String, dynamic>> _myBookings = [];
  bool _isLoading = true;
  int _selectedDay = 1;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final authProvider = context.read<AuthProvider>();
    _slots = await DatabaseHelper.getAartiSlots(_selectedDay);
    _myBookings = await DatabaseHelper.getMyAartiBookings(authProvider.houseNumber ?? '');
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.purpleDark,
      appBar: AppBar(title: const Text('Book Aarti Slot'), backgroundColor: AppTheme.purpleDeep, foregroundColor: AppTheme.goldPrimary),
      body: Column(
        children: [
          _buildDaySelector(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_myBookings.isNotEmpty) ...[
                          const Text('My Bookings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.goldPrimary)),
                          const SizedBox(height: 8),
                          ..._myBookings.map((b) => _buildMyBookingCard(b)),
                          const SizedBox(height: 16),
                        ],
                        const Text('Available Slots', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.goldPrimary)),
                        const SizedBox(height: 8),
                        if (_slots.isEmpty) const Center(child: Text('No slots available', style: TextStyle(color: AppTheme.textMuted))),
                        ..._slots.map((s) => _buildSlotCard(s)),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySelector() {
    return Container(
      height: 50, padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal, itemCount: 9,
        itemBuilder: (context, index) {
          final day = index + 1;
          final isSelected = _selectedDay == day;
          return GestureDetector(
            onTap: () { setState(() => _selectedDay = day); _loadData(); },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.goldPrimary : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.goldPrimary.withOpacity(0.5)),
              ),
              child: Text('Day $day', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isSelected ? AppTheme.purpleDark : AppTheme.textMuted)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMyBookingCard(Map<String, dynamic> booking) {
    final status = booking['status'] ?? 'pending';
    final statusColor = status == 'approved' ? Colors.green : (status == 'rejected' ? Colors.red : (status == 'cancelled' ? Colors.grey : Colors.orange));
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: statusColor.withOpacity(0.5))),
      child: Row(
        children: [
          Icon(status == 'approved' ? Icons.check_circle : (status == 'rejected' ? Icons.cancel : (status == 'cancelled' ? Icons.cancel : Icons.pending)), color: statusColor, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Slot: ${booking['slot_time']} - ${booking['slot_label']}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                const SizedBox(height: 2),
                Text('Day ${booking['day_number']} • Status: ${status.toUpperCase()}', style: TextStyle(fontSize: 12, color: statusColor)),
              ],
            ),
          ),
          if (status != 'cancelled' && status != 'rejected')
            IconButton(
              icon: const Icon(Icons.cancel, color: Colors.red, size: 22),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: AppTheme.cardBg,
                    title: const Text('Cancel Booking?', style: TextStyle(color: Colors.white)),
                    content: const Text('Are you sure you want to cancel this aarti booking?', style: TextStyle(color: Colors.white70)),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No', style: TextStyle(color: AppTheme.goldPrimary))),
                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Yes, Cancel', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                );
                if (confirm == true) {
                  await DatabaseHelper.cancelAartiBooking(booking['id']);
                  _loadData();
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Booking cancelled'), backgroundColor: Colors.orange));
                }
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSlotCard(Map<String, dynamic> slot) {
    final maxP = slot['max_participants'] ?? 1;
    final currentP = slot['current_participants'] ?? 0;
    final isFull = currentP >= maxP;
    final isBooked = _myBookings.any((b) => b['slot_id'] == slot['id'] && b['status'] != 'rejected');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.hubItemDecoration,
      child: Row(
        children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              gradient: (isFull || isBooked) ? null : AppTheme.goldGradient,
              color: (isFull || isBooked) ? AppTheme.textMuted.withOpacity(0.2) : null,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(slot['slot_time'] ?? '', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: (isFull || isBooked) ? AppTheme.textMuted : AppTheme.purpleDark)),
                const SizedBox(height: 2),
                Text('$currentP/$maxP', style: TextStyle(fontSize: 11, color: (isFull || isBooked) ? AppTheme.textMuted : AppTheme.purpleDark)),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(slot['slot_label'] ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                const SizedBox(height: 4),
                Text(isFull ? 'FULL' : '${maxP - currentP} spots left', style: TextStyle(fontSize: 12, color: isFull ? AppTheme.redAccent : AppTheme.cyanAccent)),
              ],
            ),
          ),
          if (!isFull && !isBooked)
            GestureDetector(
              onTap: () async {
                final authProvider = context.read<AuthProvider>();
                await DatabaseHelper.bookAartiSlot(
                  userId: authProvider.currentUser?['id'],
                  houseNumber: authProvider.houseNumber ?? '',
                  dayNumber: _selectedDay,
                  slotId: slot['id'],
                );
                _loadData();
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Booking request sent!'), backgroundColor: Colors.green));
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(gradient: AppTheme.goldGradient, borderRadius: BorderRadius.circular(12)),
                child: const Text('BOOK', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.purpleDark)),
              ),
            )
          else if (isBooked)
            const Icon(Icons.check_circle, color: Colors.green, size: 28)
          else
            const Text('FULL', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.redAccent)),
        ],
      ),
    );
  }
}
