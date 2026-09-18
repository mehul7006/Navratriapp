import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../database/database_helper.dart';
import 'package:navratri_app/widgets/background_scaffold.dart';

class AartiManagementScreen extends StatefulWidget {
  const AartiManagementScreen({super.key});

  @override
  State<AartiManagementScreen> createState() => _AartiManagementScreenState();
}

class _AartiManagementScreenState extends State<AartiManagementScreen> {
  List<Map<String, dynamic>> _allBookings = [];
  List<Map<String, dynamic>> _days = [];
  bool _isLoading = true;
  int _selectedDay = 0;
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    final activeDay = await DatabaseHelper.getCurrentActiveDay();
    if (activeDay != null) _selectedDay = activeDay;
    await _loadData();
  }

  bool _isDayCompleted(int dayNumber) {
    final day = _days.firstWhere((d) => d['day_number'] == dayNumber, orElse: () => {});
    if (day.isEmpty) return false;
    return day['is_completed'] == true || day['is_completed'] == 1;
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    _days = await DatabaseHelper.getNavratriDays();
    _allBookings = await DatabaseHelper.getAartiBookings();
    if (mounted) setState(() => _isLoading = false);
  }

  List<Map<String, dynamic>> get _filteredBookings {
    var list = _selectedDay == 0 ? _allBookings : _allBookings.where((d) => d['day_number'] == _selectedDay).toList();
    if (_selectedStatus != null) {
      if (_selectedStatus == 'cancelled') {
        list = list.where((d) => d['status'] == 'cancelled' || d['status'] == 'rejected').toList();
      } else {
        list = list.where((d) => d['status'] == _selectedStatus).toList();
      }
    }
    return list;
  }

  int _getCount(int dayNumber) {
    return _allBookings.where((d) => d['day_number'] == dayNumber && d['status'] != 'cancelled' && d['status'] != 'rejected').length;
  }

  int _getPendingCount(int dayNumber) {
    return _allBookings.where((d) => d['day_number'] == dayNumber && (d['status'] ?? 'pending') == 'pending').length;
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundBody(
      child: Stack(
        children: [
          Column(
            children: [
              _buildHeader(),
              _buildDayChips(),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _selectedDay == 0
                        ? _buildAllDaysView()
                        : _buildDayBookingsList(),
              ),
            ],
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              backgroundColor: AppTheme.goldPrimary,
              onPressed: () => _showAddBookingDialog(),
              child: const Icon(Icons.add, color: AppTheme.purpleDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final total = _allBookings.length;
    final pending = _allBookings.where((d) => (d['status'] ?? 'pending') == 'pending').length;
    final approved = _allBookings.where((d) => d['status'] == 'approved').length;
    final cancelled = _allBookings.where((d) => d['status'] == 'cancelled' || d['status'] == 'rejected').length;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      padding: const EdgeInsets.all(12),
      decoration: AppTheme.hubItemDecoration,
      child: Row(
        children: [
          Expanded(child: _buildStatChip(Icons.pending_actions, '$pending', 'Pending', Colors.orange, isSelected: _selectedStatus == 'pending', onTap: () => setState(() => _selectedStatus = _selectedStatus == 'pending' ? null : 'pending'))),
          const SizedBox(width: 6),
          Expanded(child: _buildStatChip(Icons.check_circle, '$approved', 'Approved', Colors.green, isSelected: _selectedStatus == 'approved', onTap: () => setState(() => _selectedStatus = _selectedStatus == 'approved' ? null : 'approved'))),
          const SizedBox(width: 6),
          Expanded(child: _buildStatChip(Icons.cancel, '$cancelled', 'Cancelled', Colors.red, isSelected: _selectedStatus == 'cancelled', onTap: () => setState(() => _selectedStatus = _selectedStatus == 'cancelled' ? null : 'cancelled'))),
          const SizedBox(width: 6),
          Expanded(child: _buildStatChip(Icons.bookmark, '$total', 'Total', AppTheme.goldPrimary, isSelected: _selectedStatus == null, onTap: () => setState(() => _selectedStatus = null))),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String count, String label, Color color, {bool isSelected = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(isSelected ? 0.6 : 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 2),
            Text(count, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: TextStyle(fontSize: 10, color: color.withOpacity(0.7))),
          ],
        ),
      ),
    );
  }

  Widget _buildDayChips() {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildChip(0, 'All', _allBookings.where((d) => d['status'] != 'cancelled' && d['status'] != 'rejected').length),
          for (int day = 1; day <= 10; day++)
            _buildChip(day, 'Day $day', _getCount(day)),
        ],
      ),
    );
  }

  Widget _buildChip(int day, String label, int count) {
    final isSelected = _selectedDay == day;
    final completed = day > 0 && _isDayCompleted(day);
    final pending = day > 0 ? _getPendingCount(day) : _allBookings.where((d) => (d['status'] ?? 'pending') == 'pending').length;

    return GestureDetector(
      onTap: () => setState(() => _selectedDay = day),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.goldPrimary : AppTheme.goldPrimary.withOpacity(0.07),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: completed ? Colors.red.withOpacity(0.6) : AppTheme.goldPrimary.withOpacity(0.7),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isSelected ? AppTheme.purpleDark : Colors.white.withOpacity(0.9))),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.purpleDark.withOpacity(0.2) : AppTheme.goldPrimary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('$count', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isSelected ? AppTheme.purpleDark : AppTheme.goldPrimary)),
              ),
            ],
            if (pending > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(8)),
                child: Text('$pending', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAllDaysView() {
    final filtered = _filteredBookings;
    final byDay = <int, List<Map<String, dynamic>>>{};
    for (final d in filtered) {
      final day = d['day_number'] ?? 0;
      byDay.putIfAbsent(day, () => []).add(d);
    }
    final sortedDays = byDay.keys.toList()..sort();

    if (sortedDays.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.self_improvement, size: 48, color: AppTheme.textMuted),
            const SizedBox(height: 12),
            Text('No aarti bookings yet', style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: sortedDays.length,
      itemBuilder: (context, index) {
        final day = sortedDays[index];
        final dayItems = byDay[day]!;
        final dayData = _days.firstWhere((d) => d['day_number'] == day, orElse: () => {});
        final goddess = dayData['goddess_name'] ?? '';
        final completed = _isDayCompleted(day);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: AppTheme.hubItemDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => setState(() => _selectedDay = day),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          gradient: completed ? null : AppTheme.goldGradient,
                          color: completed ? Colors.red.withOpacity(0.2) : null,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text('D$day', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: completed ? Colors.red : AppTheme.purpleDark)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(goddess.isNotEmpty ? goddess : 'Day $day', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                            Text('${dayItems.length} bookings', style: TextStyle(fontSize: 13, color: AppTheme.textMuted)),
                          ],
                        ),
                      ),
                      if (completed)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: Colors.red.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                          child: const Text('COMPLETED', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.red)),
                        )
                      else
                        Icon(Icons.chevron_right, color: AppTheme.goldPrimary),
                    ],
                  ),
                ),
              ),
              ...dayItems.take(3).map((d) => _buildBookingTile(d)),
              if (dayItems.length > 3)
                GestureDetector(
                  onTap: () => setState(() => _selectedDay = day),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    child: Center(
                      child: Text('View all ${dayItems.length} bookings \u2192', style: TextStyle(fontSize: 13, color: AppTheme.goldPrimary, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBookingTile(Map<String, dynamic> booking) {
    final status = booking['status'] ?? 'pending';
    final statusColor = status == 'approved' ? Colors.green : (status == 'rejected' || status == 'cancelled' ? Colors.red : Colors.orange);
    final name = booking['user_name']?.toString() ?? '';
    final house = booking['house_number']?.toString() ?? '';
    final dayNum = booking['day_number'] ?? '';

    IconData statusIcon;
    if (status == 'approved') {
      statusIcon = Icons.check_circle;
    } else if (status == 'cancelled' || status == 'rejected') {
      statusIcon = Icons.cancel;
    } else {
      statusIcon = Icons.hourglass_empty;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(gradient: AppTheme.goldGradient, borderRadius: BorderRadius.circular(8)),
            child: Center(
              child:               Text(house, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.purpleDark)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name.isNotEmpty ? name : house, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                Text('H:$house \u2022 Day $dayNum', style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
              ],
            ),
          ),
          Icon(statusIcon, color: statusColor, size: 20),
        ],
      ),
    );
  }

  Widget _buildDayBookingsList() {
    final dayItems = _filteredBookings;

    if (dayItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.self_improvement, size: 48, color: AppTheme.textMuted),
            const SizedBox(height: 12),
            Text(_selectedStatus != null ? 'No ${_selectedStatus} bookings' : 'No bookings for Day $_selectedDay', style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
          ],
        ),
      );
    }

    if (_selectedStatus != null) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: dayItems.length,
        itemBuilder: (context, index) {
          final d = dayItems[index];
          final showActions = (d['status'] ?? 'pending') == 'pending';
          final showCancel = d['status'] == 'approved';
          return _buildBookingCard(d, showActions: showActions, showCancel: showCancel);
        },
      );
    }

    final pending = dayItems.where((d) => (d['status'] ?? 'pending') == 'pending').toList();
    final approved = dayItems.where((d) => d['status'] == 'approved').toList();
    final cancelled = dayItems.where((d) => d['status'] == 'cancelled' || d['status'] == 'rejected').toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      children: [
        if (pending.isNotEmpty) ...[
          _buildSectionHeader('Pending Approval', Colors.orange, pending.length),
          ...pending.map((d) => _buildBookingCard(d, showActions: true)),
          const SizedBox(height: 12),
        ],
        if (approved.isNotEmpty) ...[
          _buildSectionHeader('Approved', Colors.green, approved.length),
          ...approved.map((d) => _buildBookingCard(d, showCancel: true)),
          const SizedBox(height: 12),
        ],
        if (cancelled.isNotEmpty) ...[
          _buildSectionHeader('Cancelled / Rejected', Colors.red, cancelled.length),
          ...cancelled.map((d) => _buildBookingCard(d)),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, Color color, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(width: 3, height: 16, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: color)),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
            child: Text('$count', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking, {bool showActions = false, bool showCancel = false}) {
    final status = booking['status'] ?? 'pending';
    final statusColor = status == 'approved' ? Colors.green : (status == 'rejected' ? Colors.red : Colors.orange);
    final name = booking['user_name']?.toString() ?? '';
    final house = booking['house_number']?.toString() ?? '';
    final bookingId = booking['id']?.toString() ?? '';

    IconData statusIcon;
    if (status == 'approved') {
      statusIcon = Icons.check_circle;
    } else if (status == 'cancelled' || status == 'rejected') {
      statusIcon = Icons.cancel;
    } else {
      statusIcon = Icons.hourglass_empty;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.hubItemDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: const BoxDecoration(gradient: AppTheme.goldGradient, borderRadius: BorderRadius.all(Radius.circular(10))),
                child: Center(
                  child: Text(house, style: TextStyle(fontSize: house.length > 5 ? 9 : 11, fontWeight: FontWeight.bold, color: AppTheme.purpleDark)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name.isNotEmpty ? name : house, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
                    const SizedBox(height: 2),
                    Text('House: $house', style: const TextStyle(fontSize: 15, color: AppTheme.textMuted)),
                    const SizedBox(height: 2),
                    Text('Booking #$bookingId', style: TextStyle(fontSize: 11, color: AppTheme.goldPrimary.withOpacity(0.7))),
                  ],
                ),
              ),
              Icon(statusIcon, color: statusColor, size: 24),
              if (showCancel) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () async {
                    await DatabaseHelper.cancelAartiBooking(booking['id']);
                    _loadData();
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Booking cancelled'), backgroundColor: Colors.orange));
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: Colors.red.withOpacity(0.15), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.withOpacity(0.5))),
                    child: const Icon(Icons.close, color: Colors.red, size: 18),
                  ),
                ),
              ],
            ],
          ),
          if (showActions && status == 'pending') ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      await DatabaseHelper.updateBookingStatus(booking['id'], 'approved');
                      _loadData();
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Booking confirmed'), backgroundColor: Colors.green));
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.green.withOpacity(0.5)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check, color: Colors.green, size: 16),
                          const SizedBox(width: 6),
                          const Text('CONFIRM', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      await DatabaseHelper.updateBookingStatus(booking['id'], 'rejected');
                      _loadData();
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Booking rejected'), backgroundColor: Colors.red));
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.withOpacity(0.5)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.close, color: Colors.red, size: 16),
                          const SizedBox(width: 6),
                          const Text('REJECT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showAddBookingDialog() {
    final houseController = TextEditingController();
    final nameController = TextEditingController();
    int formDay = _selectedDay == 0 ? (_days.firstWhere((d) => d['is_active'] == true, orElse: () => {'day_number': 1})['day_number'] as int) : _selectedDay;
    List<Map<String, dynamic>> members = [];
    bool isSearching = false;
    void Function(VoidCallback)? sheetSetState;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.purpleCard.withOpacity(0.6),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          sheetSetState = setSheetState;
          return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Book Aarti Slot', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.goldPrimary)),
                const SizedBox(height: 16),
                Text('Select Day', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.goldPrimary)),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(10, (index) {
                    final day = index + 1;
                    final isFormSelected = formDay == day;
                    final isCompleted = _isDayCompleted(day);
                    return Expanded(
                      child: GestureDetector(
                        onTap: isCompleted ? null : () => setSheetState(() => formDay = day),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: isCompleted ? Colors.grey.withOpacity(0.3) : isFormSelected ? AppTheme.goldPrimary : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isCompleted ? Colors.grey.withOpacity(0.5) : AppTheme.goldPrimary.withOpacity(0.5)),
                          ),
                          child: isCompleted
                              ? Icon(Icons.lock, size: 10, color: Colors.grey)
                              : Text('D$day', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isFormSelected ? AppTheme.purpleDark : AppTheme.textMuted)),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                _buildField(controller: houseController, label: 'House Number (e.g. B437)', icon: Icons.home, textCapitalization: TextCapitalization.characters, autoCapitalize: true),
                const SizedBox(height: 4),
                if (isSearching)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Text('Searching...', style: TextStyle(color: AppTheme.goldPrimary, fontSize: 12)),
                  ),
                if (members.isNotEmpty)
                  Container(
                    constraints: const BoxConstraints(maxHeight: 150),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.goldPrimary.withOpacity(0.3))),
                    child: Material(
                      color: AppTheme.purpleDark,
                      borderRadius: BorderRadius.circular(8),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: members.length,
                        itemBuilder: (ctx, i) {
                          final m = members[i];
                          return ListTile(
                            dense: true,
                            title: Text(m['name'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 14)),
                            subtitle: Text(m['house_number'] ?? '', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                            onTap: () {
                              setSheetState(() {
                                nameController.text = m['name'] ?? '';
                                houseController.text = m['house_number'] ?? '';
                                members = [];
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                _buildField(controller: nameController, label: 'Name', icon: Icons.person),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isDayCompleted(formDay) ? null : () async {
                    if (houseController.text.isEmpty || nameController.text.isEmpty) return;
                    try {
                      final users = await DatabaseHelper.getMembersByHouse(houseController.text.trim().toUpperCase());
                      int userId = 0;
                      for (final u in users) {
                        if ((u['name'] ?? '').toString().toLowerCase() == nameController.text.trim().toLowerCase()) {
                          userId = u['id'] as int;
                          break;
                        }
                      }
                      await DatabaseHelper.bookAartiSlot(userId: userId, houseNumber: houseController.text.trim().toUpperCase(), dayNumber: formDay, slotId: 0);
                      if (ctx.mounted) Navigator.pop(ctx);
                      _loadData();
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Booking created for Day $formDay'), backgroundColor: Colors.green));
                    } catch (e) {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isDayCompleted(formDay) ? Colors.grey : AppTheme.goldPrimary,
                    foregroundColor: AppTheme.purpleDark,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isDayCompleted(formDay)
                      ? const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.lock, size: 16), SizedBox(width: 6), Text('Day Ended', style: TextStyle(fontWeight: FontWeight.bold))])
                      : const Text('BOOK SLOT', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
        },
      ),
    );

    houseController.addListener(() async {
      final text = houseController.text.trim();
      if (text.length < 2) {
        sheetSetState?.call(() { members = []; isSearching = false; });
        return;
      }
      sheetSetState?.call(() => isSearching = true);
      try {
        final results = await DatabaseHelper.getMembersByHouse(text);
        sheetSetState?.call(() { members = results; isSearching = false; });
      } catch (_) {
        sheetSetState?.call(() => isSearching = false);
      }
    });
  }

  Widget _buildField({required TextEditingController controller, required String label, required IconData icon, TextInputType keyboardType = TextInputType.text, TextCapitalization textCapitalization = TextCapitalization.none, bool autoCapitalize = false}) {
    return TextFormField(
      controller: controller, keyboardType: keyboardType, textCapitalization: textCapitalization, style: const TextStyle(color: Colors.white),
      onChanged: autoCapitalize ? (v) { final upper = v.toUpperCase(); if (v != upper) { controller.value = controller.value.copyWith(text: upper, selection: TextSelection.collapsed(offset: upper.length)); } } : null,
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
