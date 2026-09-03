import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../database/database_helper.dart';
import '../../l10n/app_localizations.dart';

class AartiManagementScreen extends StatefulWidget {
  const AartiManagementScreen({super.key});

  @override
  State<AartiManagementScreen> createState() => _AartiManagementScreenState();
}

class _AartiManagementScreenState extends State<AartiManagementScreen> {
  List<Map<String, dynamic>> _slots = [];
  List<Map<String, dynamic>> _bookings = [];
  bool _isLoading = true;
  int _selectedDay = 1;
  bool _showBookings = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    _slots = await DatabaseHelper.getAartiSlots(_selectedDay);
    _bookings = await DatabaseHelper.getAartiBookings(dayNumber: _selectedDay);
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.purpleDark,
      appBar: AppBar(
        title: Text(AppLocalizations.t('aarti_bookings'), style: const TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.purpleDeep,
        iconTheme: const IconThemeData(color: AppTheme.goldPrimary),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          _buildDaySelector(),
          _buildTabBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _showBookings ? _buildBookingsList() : _buildSlotsList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.goldPrimary,
        onPressed: () => _showAddSlotDialog(),
        child: const Icon(Icons.add, color: AppTheme.purpleDark),
      ),
    );
  }

  Widget _buildDaySelector() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 9,
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

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _showBookings = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: !_showBookings ? AppTheme.goldPrimary : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.goldPrimary.withOpacity(0.5)),
                ),
                child: Text('Slots (${_slots.length})', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: !_showBookings ? AppTheme.purpleDark : AppTheme.textMuted)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _showBookings = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _showBookings ? AppTheme.goldPrimary : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.goldPrimary.withOpacity(0.5)),
                ),
                child: Text('Bookings (${_bookings.length})', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _showBookings ? AppTheme.purpleDark : AppTheme.textMuted)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotsList() {
    if (_slots.isEmpty) return Center(child: Text(AppLocalizations.t('no_slots_day'), style: TextStyle(color: AppTheme.textMuted)));
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: _slots.length,
      itemBuilder: (context, index) => _buildSlotCard(_slots[index]),
    );
  }

  Widget _buildSlotCard(Map<String, dynamic> slot) {
    final maxP = slot['max_participants'] ?? 1;
    final currentP = slot['current_participants'] ?? 0;
    final isFull = currentP >= maxP;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.hubItemDecoration,
      child: Row(
        children: [
          Container(
            width: 55, height: 55,
            decoration: BoxDecoration(
              gradient: isFull ? null : AppTheme.goldGradient,
              color: isFull ? AppTheme.textMuted.withOpacity(0.3) : null,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(slot['slot_time'] ?? '', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isFull ? AppTheme.textMuted : AppTheme.purpleDark)),
                const SizedBox(height: 2),
                Text('$currentP/$maxP', style: TextStyle(fontSize: 10, color: isFull ? AppTheme.textMuted : AppTheme.purpleDark)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(slot['slot_label'] ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                const SizedBox(height: 4),
                Text(isFull ? AppLocalizations.t('full') : '${maxP - currentP} spots left', style: TextStyle(fontSize: 12, color: isFull ? AppTheme.redAccent : AppTheme.cyanAccent)),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppTheme.goldPrimary),
            color: AppTheme.purpleCard,
            onSelected: (v) {
              if (v == 'delete') {
                DatabaseHelper.updateAartiSlot(slot['id'], isActive: false);
                _loadData();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'delete', child: Text(AppLocalizations.t('remove'), style: TextStyle(color: AppTheme.redAccent))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBookingsList() {
    if (_bookings.isEmpty) return Center(child: Text(AppLocalizations.t('no_bookings_day'), style: TextStyle(color: AppTheme.textMuted)));
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: _bookings.length,
      itemBuilder: (context, index) => _buildBookingCard(_bookings[index]),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    final status = booking['status'] ?? 'pending';
    final statusColor = status == 'approved' ? Colors.green : (status == 'rejected' ? Colors.red : Colors.orange);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.hubItemDecoration,
      child: Row(
        children: [
          Container(
            width: 50, height: 50,
            decoration: const BoxDecoration(gradient: AppTheme.goldGradient, borderRadius: BorderRadius.all(Radius.circular(12))),
            child: Center(
              child: Text((booking['house_number'] ?? '').toString().substring(0, 3), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.purpleDark)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(booking['user_name'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                const SizedBox(height: 2),
                Text('Slot: ${booking['slot_time'] ?? ''} (${booking['slot_label'] ?? ''})', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              ],
            ),
          ),
          if (status == 'pending') ...[
            _buildActionBtn(Icons.check, Colors.green, () async {
              await DatabaseHelper.updateBookingStatus(booking['id'], 'approved');
              _loadData();
            }),
            const SizedBox(width: 4),
            _buildActionBtn(Icons.close, AppTheme.redAccent, () async {
              await DatabaseHelper.updateBookingStatus(booking['id'], 'rejected');
              _loadData();
            }),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: statusColor.withOpacity(0.2), borderRadius: BorderRadius.circular(20), border: Border.all(color: statusColor)),
              child: Text(status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(width: 36, height: 36, decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(8), border: Border.all(color: color)),
        child: Icon(icon, color: color, size: 18)),
    );
  }

  void _showAddSlotDialog() {
    final timeController = TextEditingController();
    final labelController = TextEditingController();
    final maxController = TextEditingController(text: '5');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.purpleCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(AppLocalizations.t('add_aarti_slot'), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.goldPrimary)),
            const SizedBox(height: 16),
            _buildField(controller: timeController, label: AppLocalizations.t('time_hint'), icon: Icons.access_time),
            const SizedBox(height: 12),
            _buildField(controller: labelController, label: AppLocalizations.t('slot_label'), icon: Icons.label),
            const SizedBox(height: 12),
            _buildField(controller: maxController, label: AppLocalizations.t('max_participants'), icon: Icons.people, keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                if (timeController.text.isEmpty || labelController.text.isEmpty) return;
                await DatabaseHelper.addAartiSlot(
                  dayNumber: _selectedDay, slotTime: timeController.text.trim(),
                  slotLabel: labelController.text.trim(), maxParticipants: int.tryParse(maxController.text) ?? 5,
                );
                Navigator.pop(ctx);
                _loadData();
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.goldPrimary, foregroundColor: AppTheme.purpleDark, padding: const EdgeInsets.symmetric(vertical: 16)),
              child: Text(AppLocalizations.t('add_slot'), style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildField({required TextEditingController controller, required String label, required IconData icon, TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller, keyboardType: keyboardType, style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label, prefixIcon: Icon(icon, color: AppTheme.goldPrimary),
        labelStyle: const TextStyle(color: AppTheme.textMuted), filled: true,
        fillColor: AppTheme.purpleDark.withOpacity(0.5),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.goldPrimary.withOpacity(0.3))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.goldPrimary.withOpacity(0.3))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.goldPrimary)),
      ),
    );
  }
}
