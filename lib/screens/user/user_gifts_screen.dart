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
  List<Map<String, dynamic>> _allAssignments = [];
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
    final all = await DatabaseHelper.getGiftAssignments();
    _allAssignments = all.where((a) => a['day_number'] == _selectedDay).toList();
    if (mounted) setState(() => _isLoading = false);
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
          IconButton(icon: const Icon(Icons.refresh, size: 20), onPressed: _loadData, constraints: const BoxConstraints(maxWidth: 36, maxHeight: 36)),
        ],
      ),
      floatingActionButton: _isDayBookable(_selectedDay)
          ? FloatingActionButton(
              backgroundColor: AppTheme.goldPrimary,
              onPressed: () => _showAddAssignmentSheet(),
              child: const Icon(Icons.add, color: AppTheme.purpleDark, size: 28),
            )
          : null,
      child: Column(
        children: [
          _buildDaySelector(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _allAssignments.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.card_giftcard_outlined, size: 48, color: AppTheme.goldPrimary.withOpacity(0.3)),
                            const SizedBox(height: 12),
                            Text('No gift assignments for Day $_selectedDay', style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
                            const SizedBox(height: 8),
                            Text('Tap + to add a gift assignment', style: TextStyle(color: AppTheme.goldPrimary.withOpacity(0.5), fontSize: 12)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _allAssignments.length,
                        itemBuilder: (context, index) => _buildAssignmentCard(_allAssignments[index]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySelector() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 10,
        itemBuilder: (context, index) {
          final day = index + 1;
          final isSelected = _selectedDay == day;
          final completed = _isDayCompleted(day);
          return GestureDetector(
            onTap: () {
              setState(() => _selectedDay = day);
              _loadData();
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.goldPrimary
                    : (completed ? Colors.red.withOpacity(0.15) : Colors.transparent),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: completed
                      ? Colors.red.withOpacity(0.6)
                      : (isSelected ? AppTheme.goldPrimary : AppTheme.goldPrimary.withOpacity(0.5)),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Day $day',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: completed
                          ? Colors.red.withOpacity(0.7)
                          : (isSelected ? AppTheme.purpleDark : AppTheme.textMuted),
                    ),
                  ),
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

  Widget _buildAssignmentCard(Map<String, dynamic> assignment) {
    final status = assignment['status'] ?? 'assigned';
    final Color statusColor;
    final IconData statusIcon;

    switch (status) {
      case 'assigned':
      case 'delivered':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
        break;
      case 'cancelled':
        statusColor = Colors.grey;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
    }

    final houseNumber = assignment['house_number']?.toString() ?? '';
    final name = assignment['user_name']?.toString() ?? '';
    final giftName = assignment['gift_name']?.toString() ?? '';
    final authProvider = context.read<AuthProvider>();
    final myHouse = authProvider.houseNumber ?? '';
    final isMyAssignment = houseNumber.toUpperCase() == myHouse.toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: AppTheme.hubItemDecoration,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 42,
            decoration: BoxDecoration(
              gradient: AppTheme.goldGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    houseNumber,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.purpleDark),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isNotEmpty ? '$name ($houseNumber)' : houseNumber,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                ),
                if (giftName.isNotEmpty)
                  Text(
                    giftName,
                    style: TextStyle(fontSize: 11, color: AppTheme.goldPrimary.withValues(alpha: 0.8)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Icon(statusIcon, size: 18, color: statusColor),
          if (isMyAssignment && status != 'cancelled') ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _cancelAssignment(assignment),
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 14),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _cancelAssignment(Map<String, dynamic> assignment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: const Text('Cancel Assignment', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to cancel this gift assignment?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No', style: TextStyle(color: AppTheme.goldPrimary))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Yes, Cancel', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      await DatabaseHelper.cancelGiftAssignment(assignment['id']);
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Assignment cancelled'), backgroundColor: Colors.orange),
        );
      }
    }
  }

  void _showDayOverviewPopup({
    required int selectedDay,
    required int userId,
    required String houseNumber,
    required String personName,
    required String giftName,
  }) async {
    final allAssignments = await DatabaseHelper.getGiftAssignments();

    final Map<int, List<Map<String, dynamic>>> dayAssignments = {};
    for (final a in allAssignments) {
      final s = a['status'] ?? '';
      if (s == 'cancelled') continue;
      final day = a['day_number'] as int;
      dayAssignments.putIfAbsent(day, () => []).add(a);
    }

    if (!mounted) return;

    int chosenDay = selectedDay;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF16042A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppTheme.goldPrimary.withValues(alpha: 0.6), width: 1.5),
          ),
          title: Column(
            children: [
              Text(
                'Day $selectedDay already has assignments',
                style: TextStyle(color: AppTheme.goldPrimary, fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Do you want to change any vacant day?',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
              ),
            ],
          ),
          content: SizedBox(
            width: 340,
            child: Opacity(
              opacity: 0.6,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 400;
                  final crossAxisCount = isMobile ? 2 : 3;
                  final fontSize = isMobile ? 14.0 : 16.0;
                  final subFontSize = isMobile ? 10.0 : 12.0;

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 1.8,
                    ),
                    itemCount: 10,
                    itemBuilder: (context, index) {
                      final day = index + 1;
                      final completed = _isDayCompleted(day);
                      final assignments = dayAssignments[day] ?? [];
                      final hasAssignments = assignments.isNotEmpty;
                      final isChosen = chosenDay == day;

                      return GestureDetector(
                        onTap: completed || hasAssignments
                            ? null
                            : () => setDialogState(() => chosenDay = day),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isChosen
                                ? AppTheme.goldPrimary.withValues(alpha: 0.2)
                                : hasAssignments
                                    ? Colors.green.withValues(alpha: 0.1)
                                    : Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isChosen
                                  ? AppTheme.goldPrimary
                                  : hasAssignments
                                      ? Colors.green.withValues(alpha: 0.5)
                                      : Colors.grey.withValues(alpha: 0.3),
                              width: isChosen ? 2.0 : 1.0,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Day $day',
                                style: TextStyle(
                                  fontSize: fontSize,
                                  fontWeight: FontWeight.bold,
                                  color: completed
                                      ? Colors.grey
                                      : isChosen
                                          ? AppTheme.goldPrimary
                                          : Colors.white,
                                ),
                              ),
                              const SizedBox(height: 3),
                              if (completed)
                                Icon(Icons.lock, size: 14, color: Colors.grey)
                              else if (hasAssignments)
                                Column(
                                  children: [
                                    Text(
                                      assignments.first['user_name']?.toString() ?? '',
                                      style: TextStyle(fontSize: subFontSize, color: Colors.green, fontWeight: FontWeight.w600),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      '(${assignments.first['house_number'] ?? ''})',
                                      style: TextStyle(fontSize: subFontSize - 1, color: Colors.green.withValues(alpha: 0.7)),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                )
                              else
                                Text(
                                  isChosen ? 'Selected' : 'Vacant',
                                  style: TextStyle(
                                    fontSize: subFontSize,
                                    color: isChosen ? AppTheme.goldPrimary : Colors.white70,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await DatabaseHelper.assignGift(
                    giftId: null,
                    userId: userId,
                    houseNumber: houseNumber,
                    dayNumber: chosenDay,
                    giftName: giftName,
                  );
                  _loadData();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Gift assignment sent for Day $chosenDay - awaiting approval'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.goldPrimary,
                foregroundColor: AppTheme.purpleDark,
              ),
              child: const Text('Submit', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddAssignmentSheet() {
    final nameController = TextEditingController();
    final giftController = TextEditingController();
    final authProvider = context.read<AuthProvider>();
    final myHouse = authProvider.houseNumber ?? '';
    final myName = authProvider.currentUser?['name']?.toString() ?? '';
    nameController.text = myName;
    int formDay = _selectedDay;
    void Function(VoidCallback)? sheetSetState;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.purpleCard.withOpacity(0.9),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          sheetSetState = setSheetState;
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Gift Distribution',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.goldPrimary),
                  ),
                  const SizedBox(height: 16),

                  Text('Select Day', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.goldPrimary)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 10,
                      itemBuilder: (context, index) {
                        final day = index + 1;
                        final isFormSelected = formDay == day;
                        final isCompleted = _isDayCompleted(day);
                        return GestureDetector(
                          onTap: isCompleted ? null : () => setSheetState(() => formDay = day),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isCompleted
                                  ? Colors.grey.withOpacity(0.3)
                                  : isFormSelected
                                      ? AppTheme.goldPrimary
                                      : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isCompleted
                                    ? Colors.grey.withOpacity(0.5)
                                    : AppTheme.goldPrimary.withOpacity(0.5),
                              ),
                            ),
                            child: isCompleted
                                ? Icon(Icons.lock, size: 10, color: Colors.grey)
                                : Text(
                                    'Day $day',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isFormSelected ? AppTheme.purpleDark : AppTheme.textMuted,
                                    ),
                                  ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    initialValue: myHouse,
                    readOnly: true,
                    style: const TextStyle(color: Colors.white70),
                    decoration: InputDecoration(
                      labelText: 'House Number',
                      prefixIcon: Icon(Icons.home, color: AppTheme.goldPrimary),
                      labelStyle: const TextStyle(color: AppTheme.textMuted),
                      filled: true,
                      fillColor: AppTheme.purpleDark.withOpacity(0.3),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.goldPrimary.withOpacity(0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.goldPrimary.withOpacity(0.3)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Name',
                      prefixIcon: Icon(Icons.person, color: AppTheme.goldPrimary),
                      labelStyle: const TextStyle(color: AppTheme.textMuted),
                      filled: true,
                      fillColor: AppTheme.purpleDark.withOpacity(0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.goldPrimary.withOpacity(0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.goldPrimary.withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.goldPrimary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: giftController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Gift Name (Optional)',
                      prefixIcon: Icon(Icons.card_giftcard, color: AppTheme.goldPrimary),
                      labelStyle: const TextStyle(color: AppTheme.textMuted),
                      filled: true,
                      fillColor: AppTheme.purpleDark.withOpacity(0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.goldPrimary.withOpacity(0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.goldPrimary.withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.goldPrimary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  ElevatedButton(
                    onPressed: _isDayCompleted(formDay)
                        ? null
                        : () async {
                            final personName = nameController.text.trim();
                            final giftName = giftController.text.trim();
                            if (personName.isEmpty) return;

                            int userId = authProvider.currentUser?['id'] ?? 0;

                            try {
                              final existingAssignments = await DatabaseHelper.getGiftAssignments(
                                dayNumber: formDay,
                              );
                              final activeAssignments = existingAssignments.where((a) {
                                final s = a['status'] ?? '';
                                return s != 'cancelled';
                              }).toList();

                              if (activeAssignments.isNotEmpty && ctx.mounted) {
                                Navigator.pop(ctx);
                                _showDayOverviewPopup(
                                  selectedDay: formDay,
                                  userId: userId,
                                  houseNumber: myHouse,
                                  personName: personName,
                                  giftName: giftName,
                                );
                              } else {
                                await DatabaseHelper.assignGift(
                                  giftId: null,
                                  userId: userId,
                                  houseNumber: myHouse,
                                  dayNumber: formDay,
                                  giftName: giftName,
                                );
                                if (ctx.mounted) Navigator.pop(ctx);
                                _loadData();
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Gift assignment sent for Day $formDay - awaiting approval'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
                                );
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isDayCompleted(formDay) ? Colors.grey : AppTheme.goldPrimary,
                      foregroundColor: AppTheme.purpleDark,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isDayCompleted(formDay)
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.lock, size: 16),
                              SizedBox(width: 6),
                              Text('Day Ended', style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          )
                        : const Text('SUBMIT ASSIGNMENT', style: TextStyle(fontWeight: FontWeight.bold)),
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
}
