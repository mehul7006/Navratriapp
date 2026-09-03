import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../database/database_helper.dart';
import '../../l10n/app_localizations.dart';

class UserAartiScreen extends StatefulWidget {
  const UserAartiScreen({super.key});

  @override
  State<UserAartiScreen> createState() => _UserAartiScreenState();
}

class _UserAartiScreenState extends State<UserAartiScreen> {
  List<Map<String, dynamic>> _slots = [];
  List<Map<String, dynamic>> _myBookings = [];
  List<Map<String, dynamic>> _days = [];
  bool _isLoading = true;
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
    _slots = await DatabaseHelper.getAartiSlots(_selectedDay);
    _myBookings = await DatabaseHelper.getMyAartiBookings(authProvider.houseNumber ?? '');
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.purpleDark,
      appBar: AppBar(title: Text(AppLocalizations.t('book_aarti_slot')), backgroundColor: AppTheme.purpleDeep, foregroundColor: AppTheme.goldPrimary, iconTheme: const IconThemeData(color: AppTheme.goldPrimary)),
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
                          Text(AppLocalizations.t('my_bookings'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.goldPrimary)),
                          const SizedBox(height: 8),
                          ..._myBookings.map((b) => _buildMyBookingCard(b)),
                          const SizedBox(height: 16),
                        ],
                        Text(AppLocalizations.t('available_slots'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.goldPrimary)),
                        const SizedBox(height: 8),
                        if (_slots.isEmpty) Center(child: Text(AppLocalizations.t('no_slots_available'), style: const TextStyle(color: AppTheme.textMuted))),
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
          final bookable = _isDayBookable(day);
          final completed = _isDayCompleted(day);
          return GestureDetector(
            onTap: bookable ? () { setState(() => _selectedDay = day); _loadData(); } : null,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.goldPrimary : (completed ? Colors.red.withOpacity(0.15) : Colors.transparent),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: completed ? Colors.red.withOpacity(0.6) : (isSelected ? AppTheme.goldPrimary : AppTheme.goldPrimary.withOpacity(0.5)),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Day $day', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: completed ? Colors.red.withOpacity(0.7) : (isSelected ? AppTheme.purpleDark : AppTheme.textMuted))),
                  if (completed) ...[
                    const SizedBox(width: 4),
                    Icon(Icons.lock, size: 12, color: Colors.red.withOpacity(0.7)),
                  ],
                ],
              ),
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
                    title: Text(AppLocalizations.t('cancel_booking_title'), style: const TextStyle(color: Colors.white)),
                    content: Text(AppLocalizations.t('cancel_booking_content'), style: const TextStyle(color: Colors.white70)),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppLocalizations.t('no'), style: const TextStyle(color: AppTheme.goldPrimary))),
                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(AppLocalizations.t('yes_cancel'), style: const TextStyle(color: Colors.red))),
                    ],
                  ),
                );
                if (confirm == true) {
                  await DatabaseHelper.cancelAartiBooking(booking['id']);
                  _loadData();
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.t('booking_cancelled')), backgroundColor: Colors.orange));
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
    final dayBookable = _isDayBookable(_selectedDay);
    final completed = _isDayCompleted(_selectedDay);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.hubItemDecoration,
      child: Row(
        children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              gradient: (!dayBookable || isFull || isBooked) ? null : AppTheme.goldGradient,
              color: (!dayBookable || isFull || isBooked) ? AppTheme.textMuted.withOpacity(0.2) : null,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(slot['slot_time'] ?? '', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: (!dayBookable || isFull || isBooked) ? AppTheme.textMuted : AppTheme.purpleDark)),
                const SizedBox(height: 2),
                Text('$currentP/$maxP', style: TextStyle(fontSize: 11, color: (!dayBookable || isFull || isBooked) ? AppTheme.textMuted : AppTheme.purpleDark)),
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
                if (completed)
                  Text('Day completed - bookings closed', style: TextStyle(fontSize: 12, color: Colors.red.withOpacity(0.7)))
                else if (isFull)
                  Text(AppLocalizations.t('full'), style: TextStyle(fontSize: 12, color: AppTheme.redAccent))
                else
                  Text('${maxP - currentP} spots left', style: const TextStyle(fontSize: 12, color: AppTheme.cyanAccent)),
              ],
            ),
          ),
          if (!dayBookable)
            Icon(Icons.lock, color: Colors.red.withOpacity(0.6), size: 24)
          else if (!isFull && !isBooked)
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
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.t('booking_request_sent')), backgroundColor: Colors.green));
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(gradient: AppTheme.goldGradient, borderRadius: BorderRadius.circular(12)),
                child: Text(AppLocalizations.t('book'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.purpleDark)),
              ),
            )
          else if (isBooked)
            const Icon(Icons.check_circle, color: Colors.green, size: 28)
          else
            Text(AppLocalizations.t('full'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.redAccent)),
        ],
      ),
    );
  }
}
