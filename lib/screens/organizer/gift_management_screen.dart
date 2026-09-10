import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../database/database_helper.dart';
import 'package:navratri_app/widgets/background_scaffold.dart';

class GiftManagementScreen extends StatefulWidget {
  const GiftManagementScreen({super.key});

  @override
  State<GiftManagementScreen> createState() => _GiftManagementScreenState();
}

class _GiftManagementScreenState extends State<GiftManagementScreen> {
  List<Map<String, dynamic>> _allDistributions = [];
  List<Map<String, dynamic>> _days = [];
  bool _isLoading = true;
  int _selectedDay = 0;
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  bool _isDayCompleted(int dayNumber) {
    final day = _days.firstWhere((d) => d['day_number'] == dayNumber, orElse: () => {});
    if (day.isEmpty) return false;
    return day['is_completed'] == true || day['is_completed'] == 1;
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    _days = await DatabaseHelper.getNavratriDays();
    _allDistributions = await DatabaseHelper.getGiftAssignments();
    if (mounted) setState(() => _isLoading = false);
  }

  List<Map<String, dynamic>> get _filteredDistributions {
    var list = _selectedDay == 0 ? _allDistributions : _allDistributions.where((d) => d['day_number'] == _selectedDay).toList();
    if (_selectedStatus != null) {
      if (_selectedStatus == 'cancelled') {
        list = list.where((d) => d['status'] == 'cancelled' || d['status'] == 'rejected').toList();
      } else {
        list = list.where((d) => d['status'] == _selectedStatus).toList();
      }
    }
    return list;
  }

  Map<int, List<Map<String, dynamic>>> get _distributionsByDay {
    final map = <int, List<Map<String, dynamic>>>{};
    for (final d in _allDistributions) {
      final day = d['day_number'] ?? 0;
      map.putIfAbsent(day, () => []).add(d);
    }
    return map;
  }

  int _getCount(int dayNumber) {
    return _allDistributions.where((d) => d['day_number'] == dayNumber && d['status'] != 'cancelled' && d['status'] != 'rejected').length;
  }

  int _getPendingCount(int dayNumber) {
    return _allDistributions.where((d) => d['day_number'] == dayNumber && (d['status'] ?? 'pending') == 'pending').length;
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
                        : _buildDayDistributionsList(),
              ),
            ],
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              backgroundColor: AppTheme.goldPrimary,
              onPressed: () => _showDistributionForm(),
              child: const Icon(Icons.add, color: AppTheme.purpleDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final total = _allDistributions.length;
    final pending = _allDistributions.where((d) => (d['status'] ?? 'pending') == 'pending').length;
    final approved = _allDistributions.where((d) => d['status'] == 'approved').length;
    final cancelled = _allDistributions.where((d) => d['status'] == 'cancelled' || d['status'] == 'rejected').length;

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
    final activeCount = _allDistributions.where((d) => d['status'] != 'cancelled' && d['status'] != 'rejected').length;
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildChip(0, 'All', activeCount),
          for (int day = 1; day <= 10; day++)
            _buildChip(day, 'Day $day', _getCount(day)),
        ],
      ),
    );
  }

  Widget _buildChip(int day, String label, int count) {
    final isSelected = _selectedDay == day;
    final completed = day > 0 && _isDayCompleted(day);
    final pending = day > 0 ? _getPendingCount(day) : _allDistributions.where((d) => (d['status'] ?? 'pending') == 'pending').length;

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
    final filtered = _filteredDistributions;
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
            Icon(Icons.event_busy, size: 48, color: AppTheme.textMuted),
            const SizedBox(height: 12),
            Text('No gift distributions yet', style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
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
                            Text('${dayItems.length} distributions', style: TextStyle(fontSize: 13, color: AppTheme.textMuted)),
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
              ...dayItems.take(3).map((d) => _buildDistributionTile(d)),
              if (dayItems.length > 3)
                GestureDetector(
                  onTap: () => setState(() => _selectedDay = day),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    child: Center(
                      child: Text('View all ${dayItems.length} distributions \u2192', style: TextStyle(fontSize: 13, color: AppTheme.goldPrimary, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDayDistributionsList() {
    final dayItems = _filteredDistributions;

    if (dayItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 48, color: AppTheme.textMuted),
            const SizedBox(height: 12),
            Text(_selectedStatus != null ? 'No ${_selectedStatus} distributions' : 'No distributions for Day $_selectedDay', style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
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
          return _buildDistributionCard(d, showActions: showActions, showCancel: showCancel);
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
          ...pending.map((d) => _buildDistributionCard(d, showActions: true)),
          const SizedBox(height: 12),
        ],
        if (approved.isNotEmpty) ...[
          _buildSectionHeader('Approved', Colors.green, approved.length),
          ...approved.map((d) => _buildDistributionCard(d, showCancel: true)),
          const SizedBox(height: 12),
        ],
        if (cancelled.isNotEmpty) ...[
          _buildSectionHeader('Cancelled / Rejected', Colors.red, cancelled.length),
          ...cancelled.map((d) => _buildDistributionCard(d)),
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

  Widget _buildDistributionTile(Map<String, dynamic> dist) {
    final status = dist['status'] ?? 'pending';
    final statusColor = status == 'approved' ? Colors.green : (status == 'rejected' ? Colors.red : Colors.orange);
    final parsed = _parseDist(dist);
    final distributorName = parsed[0];
    final houseNumber = parsed[2];

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
              child: Text(houseNumber.isNotEmpty ? houseNumber : 'G', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.purpleDark)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(distributorName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                Text('H:$houseNumber \u2022 Day ${dist['day_number'] ?? ''}', style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
              ],
            ),
          ),
          Icon(statusIcon, color: statusColor, size: 20),
        ],
      ),
    );
  }

  Widget _buildDistributionCard(Map<String, dynamic> dist, {bool showActions = false, bool showCancel = false}) {
    final status = dist['status'] ?? 'pending';
    final statusColor = status == 'approved' ? Colors.green : (status == 'rejected' ? Colors.red : Colors.orange);
    final parsed = _parseDist(dist);
    final distributorName = parsed[0];
    final giftName = parsed[1];
    final houseNumber = parsed[2];

    final hasOrgExpense = dist['notes'].toString().contains('|ORG_EXPENSE:');
    final hasSponsorExpense = dist['notes'].toString().contains('|SPONSOR_EXPENSE:');
    final distBadge = hasOrgExpense ? 'Organizer' : (hasSponsorExpense ? 'Sponsor' : '');

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
                  child: Text(houseNumber.isNotEmpty ? houseNumber : '?', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.purpleDark)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(distributorName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
                    const SizedBox(height: 2),
                    if (houseNumber.isNotEmpty)
                      Text('House: $houseNumber', style: const TextStyle(fontSize: 15, color: AppTheme.textMuted)),
                  ],
                ),
              ),
              Icon(statusIcon, color: statusColor, size: 24),
              if (showCancel) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () async {
                    await DatabaseHelper.updateGiftAssignmentStatus(dist['id'], 'rejected');
                    await _deleteExpenseIfNeeded(dist);
                    _loadData();
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Distribution cancelled for $distributorName'), backgroundColor: Colors.red));
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
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppTheme.purpleDark.withOpacity(0.3), borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                Icon(Icons.card_giftcard, size: 18, color: AppTheme.goldPrimary),
                const SizedBox(width: 6),
                Text(giftName.isNotEmpty ? giftName : 'Gift Day ${dist['day_number'] ?? ''}', style: const TextStyle(fontSize: 15, color: Colors.white)),
                if (distBadge.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: AppTheme.goldPrimary.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                    child: Text(distBadge, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.goldPrimary)),
                  ),
                ],
              ],
            ),
          ),
          if (showActions) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildActionBtn('CONFIRM', Icons.check, Colors.green, () async {
                    await DatabaseHelper.updateGiftAssignmentStatus(dist['id'], 'approved');
                    await _createExpenseIfNeeded(dist);
                    _loadData();
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Distribution confirmed for $distributorName'), backgroundColor: Colors.green));
                  }),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildActionBtn('REJECT', Icons.close, Colors.red, () async {
                    await DatabaseHelper.updateGiftAssignmentStatus(dist['id'], 'rejected');
                    _loadData();
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Distribution rejected for $distributorName'), backgroundColor: Colors.red));
                  }),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionBtn(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  void _showDistributionForm() {
    final distributorController = TextEditingController();
    final houseNumberController = TextEditingController();
    final giftNameController = TextEditingController();
    final expenseAmountController = TextEditingController();
    bool isOrganizerDistribution = true;
    int formDay = _selectedDay > 0 ? _selectedDay : 1;
    List<Map<String, dynamic>> allMembers = [];
    List<Map<String, dynamic>> filteredMembers = [];

    DatabaseHelper.query("SELECT id, house_number, name FROM users WHERE member_type = 'main' ORDER BY house_number").then((rows) {
      allMembers = rows;
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.purpleCard.withOpacity(0.6),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          if (allMembers.isEmpty) {
            DatabaseHelper.query("SELECT id, house_number, name FROM users WHERE member_type = 'main' ORDER BY house_number").then((rows) {
              allMembers = rows;
              setModalState(() {});
            });
          }
          return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Gift & Prize Distribution', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.goldPrimary)),
                const SizedBox(height: 6),
                Text('Create a new distribution record', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                const SizedBox(height: 16),
                Text('Who will distribute?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.goldPrimary)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<bool>(
                        title: const Text('Organizer', style: TextStyle(color: Colors.white, fontSize: 12)),
                        value: true, groupValue: isOrganizerDistribution,
                        onChanged: (val) => setModalState(() => isOrganizerDistribution = val!),
                        activeColor: AppTheme.goldPrimary, contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<bool>(
                        title: const Text('Other (Sponsor)', style: TextStyle(color: Colors.white, fontSize: 12)),
                        value: false, groupValue: isOrganizerDistribution,
                        onChanged: (val) => setModalState(() => isOrganizerDistribution = val!),
                        activeColor: AppTheme.goldPrimary, contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildField(controller: houseNumberController, label: 'House Number (e.g. A-402)', icon: Icons.home, textCapitalization: TextCapitalization.characters, onChanged: (val) {
                  final upper = val.toUpperCase();
                  if (val != upper) houseNumberController.value = houseNumberController.value.copyWith(text: upper, selection: TextSelection.collapsed(offset: upper.length));
                  setModalState(() {
                    if (upper.length >= 2) {
                      filteredMembers = allMembers.where((m) => (m['house_number'] ?? '').toString().toUpperCase().contains(upper)).toList();
                    } else {
                      filteredMembers = [];
                    }
                  });
                }),
                if (filteredMembers.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 150),
                    decoration: BoxDecoration(color: AppTheme.purpleDark, borderRadius: BorderRadius.circular(8)),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: filteredMembers.length,
                      itemBuilder: (ctx, i) {
                        final m = filteredMembers[i];
                        return Material(
                          color: Colors.transparent,
                          child: ListTile(
                            dense: true,
                            title: Text('${m['house_number']}', style: const TextStyle(color: Colors.white, fontSize: 13)),
                            subtitle: Text('${m['name']}', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                            onTap: () {
                              houseNumberController.text = (m['house_number'] ?? '').toString().toUpperCase();
                              distributorController.text = (m['name'] ?? '').toString();
                              setModalState(() => filteredMembers = []);
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                _buildField(controller: distributorController, label: 'Distributor Name', icon: Icons.person),
                const SizedBox(height: 12),
                _buildField(controller: giftNameController, label: 'Gift Name (optional)', icon: Icons.card_giftcard),
                const SizedBox(height: 12),
                SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 10,
                    itemBuilder: (context, index) {
                      final day = index + 1;
                      final isSelected = formDay == day;
                      final completed = _isDayCompleted(day);
                      return GestureDetector(
                        onTap: completed ? null : () => setModalState(() => formDay = day),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.goldPrimary : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: completed ? Colors.red.withOpacity(0.6) : AppTheme.goldPrimary.withOpacity(0.5)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('D$day', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: completed ? Colors.red.withOpacity(0.7) : (isSelected ? AppTheme.purpleDark : AppTheme.textMuted))),
                              if (completed) ...[const SizedBox(width: 3), Icon(Icons.lock, size: 10, color: Colors.red.withOpacity(0.7))],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                if (isOrganizerDistribution) ...[
                  const SizedBox(height: 8),
                  _buildField(controller: expenseAmountController, label: 'Amount (\u20B9)', icon: Icons.currency_rupee, keyboardType: TextInputType.number),
                  const SizedBox(height: 4),
                  Text('Organizer expense → Prizes & Gifts', style: TextStyle(fontSize: 11, color: AppTheme.goldPrimary.withOpacity(0.7), fontStyle: FontStyle.italic)),
                ],
                if (!isOrganizerDistribution) ...[
                  const SizedBox(height: 4),
                  Text('Sponsored by outsider → Sponsor Expense', style: TextStyle(fontSize: 11, color: AppTheme.goldPrimary.withOpacity(0.7), fontStyle: FontStyle.italic)),
                ],
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    if (distributorController.text.isEmpty) {
                      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Please enter distributor name'), backgroundColor: Colors.orange));
                      return;
                    }
                    String notes = '';
                    final houseNum = houseNumberController.text.trim().toUpperCase();
                    if (houseNum.isNotEmpty) notes += '[$houseNum] ';
                    notes += giftNameController.text.trim().isNotEmpty
                        ? '${distributorController.text.trim()} - ${giftNameController.text.trim()}'
                        : distributorController.text.trim();
                    if (isOrganizerDistribution) {
                      final amt = double.tryParse(expenseAmountController.text) ?? 0;
                      notes += '|ORG_EXPENSE:$amt:Gifts';
                    } else {
                      notes += '|SPONSOR_EXPENSE:0:${distributorController.text.trim()}';
                    }
                    final gifts = await DatabaseHelper.getGifts(dayNumber: formDay);
                    final giftId = gifts.isNotEmpty ? gifts.first['id'] : null;
                    await DatabaseHelper.assignGift(
                      giftId: giftId, userId: 0, houseNumber: houseNum.isNotEmpty ? houseNum : 'ORG-DIST',
                      dayNumber: formDay, assignedBy: 0, notes: notes, status: 'pending',
                    );
                    Navigator.pop(ctx);
                    _loadData();
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Distribution created - pending confirmation'), backgroundColor: Colors.green));
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.goldPrimary, foregroundColor: AppTheme.purpleDark, padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: const Text('CREATE DISTRIBUTION', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
        },
      ),
    );
  }

  Widget _buildField({required TextEditingController controller, required String label, required IconData icon, TextInputType keyboardType = TextInputType.text, TextCapitalization textCapitalization = TextCapitalization.none, ValueChanged<String>? onChanged}) {
    return TextFormField(
      controller: controller, keyboardType: keyboardType, style: const TextStyle(color: Colors.white),
      textCapitalization: textCapitalization, onChanged: onChanged,
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

  List<String> _parseDist(Map<String, dynamic> dist) {
    var raw = dist['notes'].toString().split('|ORG_EXPENSE:')[0].split('|SPONSOR_EXPENSE:')[0];
    String houseNum = '';
    if (raw.startsWith('[') && raw.contains(']')) {
      houseNum = raw.substring(1, raw.indexOf(']'));
      raw = raw.substring(raw.indexOf(']') + 1).trim();
    }
    if (raw.contains(' - ')) {
      final parts = raw.split(' - ');
      return [parts[0], parts.sublist(1).join(' - '), houseNum];
    }
    if (raw.isNotEmpty) return [raw, dist['gift_name'] ?? '', houseNum];
    return [dist['user_name'] ?? 'Distributor', dist['gift_name'] ?? '', houseNum];
  }

  String? _extractExpenseTag(String? notes) {
    if (notes == null) return null;
    if (notes.contains('|ORG_EXPENSE:')) {
      try { return 'ORG:' + notes.split('|ORG_EXPENSE:')[1]; } catch (_) { return null; }
    }
    if (notes.contains('|SPONSOR_EXPENSE:')) {
      try { return 'SPONSOR:' + notes.split('|SPONSOR_EXPENSE:')[1]; } catch (_) { return null; }
    }
    return null;
  }

  Future<void> _createExpenseIfNeeded(Map<String, dynamic> dist) async {
    final tag = _extractExpenseTag(dist['notes']);
    if (tag == null) return;
    final isOrg = tag.startsWith('ORG:');
    final data = tag.substring(isOrg ? 4 : 8);
    final parts = data.split(':');
    if (parts.length < 1) return;
    final amount = double.tryParse(parts[0]) ?? 0;
    final info = _parseDist(dist);
    final houseNum = info.length > 2 ? info[2] : '';
    final distName = info[0];
    final giftName = info[1];
    final dayNum = dist['day_number'] ?? 0;
    final tagLabel = isOrg ? '[Organizer]' : '[Sponsor]';
    final itemName = '$tagLabel Gift: ${giftName.isNotEmpty ? giftName : "Day $dayNum"} - $distName${houseNum.isNotEmpty ? " ($houseNum)" : ""}';
    final noteText = 'Day $dayNum - ${giftName.isNotEmpty ? giftName : "Gift"} donated by $distName${houseNum.isNotEmpty ? " ($houseNum)" : ""}';
    try {
      if (!isOrg) {
        try {
          await DatabaseHelper.execute(
            "INSERT INTO expense_categories (id, name, description, is_active) SELECT 7, 'Sponsor Expense', 'Sponsored distributions', true WHERE NOT EXISTS (SELECT 1 FROM expense_categories WHERE id = 7)",
          );
        } catch (_) {}
      }
      await DatabaseHelper.execute(
        'INSERT INTO expenses (category_id, item_name, amount, paid_to, expense_date, notes, paid_by) VALUES (@catId, @item, @amount, @paidTo, @date, @notes, @paidBy)',
        substitutionValues: {
          'catId': isOrg ? 5 : 7,
          'item': itemName,
          'amount': amount,
          'paidTo': distName,
          'date': DateTime.now().toIso8601String(),
          'notes': noteText,
          'paidBy': isOrg ? 'organizer' : 'sponsor',
        },
      );
    } catch (e) {
      debugPrint('Expense create failed: $e');
    }
  }

  Future<void> _deleteExpenseIfNeeded(Map<String, dynamic> dist) async {
    final tag = _extractExpenseTag(dist['notes']);
    if (tag == null) return;
    final isOrg = tag.startsWith('ORG:');
    final info = _parseDist(dist);
    try {
      await DatabaseHelper.execute(
        "DELETE FROM expenses WHERE item_name = @item AND paid_by = @paidBy AND paid_to = @paidTo",
        substitutionValues: {
          'item': isOrg ? 'Gift Distribution - ${info[0]}' : 'Sponsor Distribution - ${info[0]}',
          'paidBy': isOrg ? 'organizer' : 'sponsor',
          'paidTo': info[0],
        },
      );
    } catch (e) {
      debugPrint('Expense delete failed: $e');
    }
  }
}
