import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../database/database_helper.dart';
import '../../l10n/app_localizations.dart';
import 'package:navratri_app/widgets/background_scaffold.dart';

class UserGiftsScreen extends StatefulWidget {
  const UserGiftsScreen({super.key});

  @override
  State<UserGiftsScreen> createState() => _UserGiftsScreenState();
}

class _UserGiftsScreenState extends State<UserGiftsScreen> {
  List<Map<String, dynamic>> _myGifts = [];
  List<Map<String, dynamic>> _availableGifts = [];
  List<Map<String, dynamic>> _days = [];
  bool _isLoading = true;
  bool _showAssigned = true;
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
    _loadGifts();
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

  Future<void> _loadGifts() async {
    setState(() => _isLoading = true);
    final authProvider = context.read<AuthProvider>();
    _myGifts = await DatabaseHelper.getMyGifts(authProvider.houseNumber ?? '');
    _availableGifts = await DatabaseHelper.getGifts(dayNumber: _selectedDay);
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundScaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.t('my_gifts')),
        backgroundColor: AppTheme.purpleDeep,
        foregroundColor: AppTheme.goldPrimary,
        iconTheme: const IconThemeData(color: AppTheme.goldPrimary),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadGifts),
        ],
      ),
      child: Column(
        children: [
          _buildDaySelector(),
          _buildTabBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _showAssigned ? _buildMyGifts() : _buildAvailableGifts(),
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
              onTap: bookable ? () { setState(() => _selectedDay = day); _loadGifts(); } : null,
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
              onTap: () => setState(() => _showAssigned = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _showAssigned ? AppTheme.goldPrimary : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.goldPrimary.withOpacity(0.5)),
                ),
                child: Text('My Gifts (${_myGifts.length})', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _showAssigned ? AppTheme.purpleDark : AppTheme.textMuted)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _showAssigned = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: !_showAssigned ? AppTheme.goldPrimary : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.goldPrimary.withOpacity(0.5)),
                ),
                child: Text('Available (${_availableGifts.length})', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: !_showAssigned ? AppTheme.purpleDark : AppTheme.textMuted)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyGifts() {
    if (_myGifts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.card_giftcard_outlined, size: 80, color: AppTheme.textMuted.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(AppLocalizations.t('no_gifts_received'), style: const TextStyle(fontSize: 18, color: AppTheme.textMuted)),
            const SizedBox(height: 8),
            Text(AppLocalizations.t('gifts_will_appear'), style: const TextStyle(fontSize: 13, color: AppTheme.textMuted), textAlign: TextAlign.center),
          ],
        ),
      );
    }
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [AppTheme.goldPrimary.withOpacity(0.2), AppTheme.purpleCard]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.goldPrimary.withOpacity(0.5)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.card_giftcard, color: AppTheme.goldPrimary, size: 28),
              const SizedBox(width: 12),
              Text('${_myGifts.length} Gift${_myGifts.length != 1 ? 's' : ''} Received', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.goldPrimary)),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _myGifts.length,
            itemBuilder: (context, index) => _buildGiftCard(_myGifts[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildAvailableGifts() {
    if (_availableGifts.isEmpty) return Center(child: Text(AppLocalizations.t('no_gifts_available_day'), style: const TextStyle(color: AppTheme.textMuted)));
    final dayBookable = _isDayBookable(_selectedDay);
    final completed = _isDayCompleted(_selectedDay);
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: _availableGifts.length,
      itemBuilder: (context, index) {
        final gift = _availableGifts[index];
        final isAssigned = _myGifts.any((g) => g['gift_id'] == gift['id'] && g['day_number'] == _selectedDay);
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: AppTheme.hubItemDecoration,
          child: Row(
            children: [
              Container(
                width: 50, height: 50,
                decoration: const BoxDecoration(gradient: AppTheme.goldGradient, borderRadius: BorderRadius.all(Radius.circular(12))),
                child: const Center(child: Icon(Icons.card_giftcard, color: AppTheme.purpleDark, size: 24)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(gift['name'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                    const SizedBox(height: 2),
                    if (completed)
                      Text('Day completed - bookings closed', style: TextStyle(fontSize: 12, color: Colors.red.withOpacity(0.7)))
                    else
                      Text('Day ${gift['day_number']} • ${gift['sponsor_name'] ?? 'Community'}', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                  ],
                ),
              ),
              if (!dayBookable)
                Icon(Icons.lock, color: Colors.red.withOpacity(0.6), size: 24)
              else if (isAssigned)
                const Icon(Icons.check_circle, color: Colors.green, size: 28)
              else
                GestureDetector(
                  onTap: () async {
                    final auth = context.read<AuthProvider>();
                    try {
                      await DatabaseHelper.assignGift(
                        giftId: gift['id'],
                        userId: auth.currentUser?['id'] ?? 0,
                        houseNumber: auth.houseNumber ?? '',
                        dayNumber: _selectedDay,
                      );
                      _loadGifts();
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.t('gift_booked')), backgroundColor: Colors.green));
                    } catch (e) {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(gradient: AppTheme.goldGradient, borderRadius: BorderRadius.circular(12)),
                    child: Text(AppLocalizations.t('book'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.purpleDark)),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGiftCard(Map<String, dynamic> gift) {
    final type = gift['gift_type'] ?? 'daily';
    final typeColor = type == 'sponsor' ? Colors.orange : Colors.purple;
    final status = gift['status'] ?? 'assigned';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTheme.hubItemDecoration,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [typeColor.withOpacity(0.3), AppTheme.purpleCard]),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Icon(Icons.card_giftcard, color: typeColor, size: 18),
                const SizedBox(width: 8),
                Text(type == 'sponsor' ? AppLocalizations.t('sponsor_gift') : AppLocalizations.t('daily_gift'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: typeColor)),
                const Spacer(),
                Text('Day ${gift['day_number'] ?? ''}', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 60, height: 60,
                  decoration: const BoxDecoration(gradient: AppTheme.goldGradient, borderRadius: BorderRadius.all(Radius.circular(14))),
                  child: const Center(child: Icon(Icons.card_giftcard, color: AppTheme.purpleDark, size: 30)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(gift['gift_name'] ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 4),
                      Text('Assigned on ${gift['assigned_at'] ?? ''}', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                    ],
                  ),
                ),
                if (status != 'cancelled')
                  IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.red, size: 28),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: AppTheme.cardBg,
                          title: Text(AppLocalizations.t('cancel_gift_title'), style: const TextStyle(color: Colors.white)),
                          content: Text(AppLocalizations.t('cancel_gift_content'), style: const TextStyle(color: Colors.white70)),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppLocalizations.t('no'), style: const TextStyle(color: AppTheme.goldPrimary))),
                            TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(AppLocalizations.t('yes_cancel'), style: const TextStyle(color: Colors.red))),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await DatabaseHelper.cancelGiftAssignment(gift['id']);
                        _loadGifts();
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.t('gift_cancelled')), backgroundColor: Colors.orange));
                      }
                    },
                  )
                else
                  const Icon(Icons.cancel, color: Colors.grey, size: 28),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
