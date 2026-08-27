import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../database/database_helper.dart';

class DayManagementScreen extends StatefulWidget {
  const DayManagementScreen({super.key});

  @override
  State<DayManagementScreen> createState() => _DayManagementScreenState();
}

class _DayManagementScreenState extends State<DayManagementScreen> {
  List<Map<String, dynamic>> _days = [];
  List<Map<String, dynamic>> _schedule = [];
  bool _isLoading = true;
  int _selectedDay = 1;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final days = await DatabaseHelper.getNavratriDays();
      final schedule = await DatabaseHelper.getDailySchedule(_selectedDay);
      setState(() {
        _days = days;
        _schedule = schedule;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Map<String, dynamic>? _getDayData(int dayNum) {
    final matches = _days.where((d) => d['day_number'] == dayNum);
    return matches.isNotEmpty ? matches.first : null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.purpleDark,
      appBar: AppBar(
        title: const Text('Day & Schedule', style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.purpleDeep,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _loadData),
        ],
      ),
      body: Column(
        children: [
          _buildDayTabs(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.goldPrimary))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDayCard(),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Schedule', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.goldPrimary)),
                            TextButton.icon(
                              onPressed: _showAddEventDialog,
                              icon: const Icon(Icons.add, color: AppTheme.goldPrimary),
                              label: const Text('Add Event', style: TextStyle(color: AppTheme.goldPrimary)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _schedule.isEmpty ? _buildEmptySchedule() : _buildScheduleList(),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayTabs() {
    return Container(
      height: 70,
      color: AppTheme.purpleDeep.withValues(alpha: 0.3),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        itemCount: 9,
        itemBuilder: (context, index) {
          final dayNum = index + 1;
          final dayData = _getDayData(dayNum);
          final isActive = dayData?['is_active'] == true;
          final isCompleted = dayData?['is_completed'] == true;
          return GestureDetector(
            onTap: () { setState(() => _selectedDay = dayNum); _loadData(); },
            child: Container(
              width: 70,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: _selectedDay == dayNum ? AppTheme.goldPrimary : (isCompleted ? Colors.green.withValues(alpha: 0.3) : AppTheme.cardBg),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _selectedDay == dayNum ? AppTheme.goldPrimary : (isActive ? Colors.amber : Colors.white24), width: isActive ? 2 : 1),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('D$dayNum', style: TextStyle(color: _selectedDay == dayNum ? Colors.black : Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  if (dayData != null)
                    Text(
                      (dayData['goddess_name'] ?? '').toString().substring(0, [dayData['goddess_name']?.toString().length ?? 0, 6].reduce((a, b) => a < b ? a : b)),
                      style: TextStyle(color: _selectedDay == dayNum ? Colors.black87 : Colors.white70, fontSize: 9),
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (isCompleted) const Icon(Icons.check_circle, size: 12, color: Colors.green),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDayCard() {
    final dayData = _getDayData(_selectedDay);
    if (dayData == null) return const SizedBox.shrink();
    final isActive = dayData['is_active'] == true;
    final isCompleted = dayData['is_completed'] == true;

    return Card(
      color: AppTheme.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Day $_selectedDay', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.goldPrimary)),
                Row(
                  children: [
                    _statusBadge(isActive ? 'Active' : 'Inactive', isActive ? Colors.green : Colors.grey),
                    const SizedBox(width: 8),
                    _statusBadge(isCompleted ? 'Completed' : 'Pending', isCompleted ? Colors.blue : Colors.orange),
                  ],
                ),
              ],
            ),
            const Divider(color: Colors.white24),
            _infoRow(Icons.temple_hindu, 'Goddess', dayData['goddess_name'] ?? 'Not set'),
            _infoRow(Icons.checkroom, 'Dress Code', dayData['dress_code'] ?? 'Not set'),
            _infoRow(Icons.calendar_today, 'Date', dayData['date'] ?? 'Not set'),
            const SizedBox(height: 12),
            
            // Start/End Day buttons
            Row(
              children: [
                if (!isActive && !isCompleted)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: AppTheme.cardBg,
                            title: Text('Start Day $_selectedDay?', style: const TextStyle(color: Colors.white)),
                            content: Text('This will activate Day $_selectedDay and deactivate all other days.',
                            style: const TextStyle(color: Colors.white70)),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: AppTheme.goldPrimary))),
                              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Start', style: TextStyle(color: Colors.green))),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await DatabaseHelper.startDay(_selectedDay);
                          _loadData();
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Day $_selectedDay started!'), backgroundColor: Colors.green));
                        }
                      },
                      icon: const Icon(Icons.play_arrow, size: 18),
                      label: const Text('Start Day'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                    ),
                  ),
                if (isActive && !isCompleted) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: AppTheme.cardBg,
                            title: Text('End Day $_selectedDay?', style: const TextStyle(color: Colors.white)),
                            content: Text('This will complete Day $_selectedDay and auto-start the next day.',
                            style: const TextStyle(color: Colors.white70)),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: AppTheme.goldPrimary))),
                              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('End Day', style: TextStyle(color: Colors.red))),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await DatabaseHelper.endDay(_selectedDay);
                          _loadData();
                          if (mounted) {
                            final nextDay = (_selectedDay < 9) ? _selectedDay + 1 : null;
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(nextDay != null ? 'Day $_selectedDay ended! Day $nextDay auto-started.' : 'Day $_selectedDay ended! Festival complete.'),
                              backgroundColor: Colors.green,
                            ));
                          }
                        }
                      },
                      icon: const Icon(Icons.stop, size: 18),
                      label: const Text('End Day'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                    ),
                  ),
                ],
                if (isCompleted)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: AppTheme.cardBg,
                            title: Text('Reopen Day $_selectedDay?', style: const TextStyle(color: Colors.white)),
                            content: Text('This will reopen Day $_selectedDay and mark it as active again.',
                            style: const TextStyle(color: Colors.white70)),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: AppTheme.goldPrimary))),
                              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Reopen', style: TextStyle(color: Colors.orange))),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await DatabaseHelper.reopenDay(_selectedDay);
                          _loadData();
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Day $_selectedDay reopened!'), backgroundColor: Colors.orange));
                        }
                      },
                      icon: const Icon(Icons.undo, size: 18),
                      label: const Text('Reopen Day'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                    ),
                  ),
              ],
            ),

            // Go Back to Previous Day button (only when a day is active and not the first day)
            if (isActive && !isCompleted && _selectedDay > 1) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final prevDay = _selectedDay - 1;
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: AppTheme.cardBg,
                        title: Text('Go Back to Day $prevDay?', style: const TextStyle(color: Colors.white)),
                        content: Text('This will end Day $_selectedDay and reactivate Day $prevDay.',
                        style: const TextStyle(color: Colors.white70)),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: AppTheme.goldPrimary))),
                          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Go Back', style: TextStyle(color: Colors.orange))),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await DatabaseHelper.endDay(_selectedDay);
                      await DatabaseHelper.startDay(prevDay);
                      _loadData();
                      setState(() => _selectedDay = prevDay);
                      _loadData();
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Went back to Day $prevDay'), backgroundColor: Colors.orange));
                    }
                  },
                  icon: const Icon(Icons.arrow_back, size: 16),
                  label: Text('Go Back to Day ${_selectedDay - 1}'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.orange, side: const BorderSide(color: Colors.orange)),
                ),
              ),
            ],

            if (!isActive && !isCompleted) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showEditDayDialog(dayData),
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Edit Details'),
                      style: OutlinedButton.styleFrom(foregroundColor: AppTheme.goldPrimary, side: const BorderSide(color: AppTheme.goldPrimary)),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.white54),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(color: Colors.white54, fontSize: 13)),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _statusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildEmptySchedule() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.event, size: 48, color: Colors.white24),
            const SizedBox(height: 12),
            const Text('No events scheduled', style: TextStyle(color: Colors.white54)),
            const SizedBox(height: 8),
            const Text('Tap "Add Event" to create one', style: TextStyle(color: Colors.white38, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _schedule.length,
      itemBuilder: (context, index) {
        final event = _schedule[index];
        return Card(
          color: AppTheme.cardBg,
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.goldPrimary.withValues(alpha: 0.2),
              child: Text(event['event_time']?.toString().substring(0, 5) ?? '??',
                  style: const TextStyle(color: AppTheme.goldPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
            title: Text(event['event_name'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (event['event_description']?.toString().isNotEmpty == true)
                  Text('${event['event_description']}', style: const TextStyle(color: Colors.white70, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                if (event['location']?.toString().isNotEmpty == true)
                  Text('📍 ${event['location']}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete Event?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                );
                if (confirm == true) {
                  await DatabaseHelper.deleteScheduleEvent(event['id']);
                  _loadData();
                }
              },
            ),
          ),
        );
      },
    );
  }

  void _showEditDayDialog(Map<String, dynamic> dayData) {
    final goddessController = TextEditingController(text: dayData['goddess_name'] ?? '');
    final dressController = TextEditingController(text: dayData['dress_code'] ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: Text('Edit Day $_selectedDay', style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: goddessController, style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Goddess Name', labelStyle: TextStyle(color: Colors.white70))),
            const SizedBox(height: 12),
            TextField(controller: dressController, style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Dress Code', labelStyle: TextStyle(color: Colors.white70))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await DatabaseHelper.updateNavratriDay(_selectedDay, goddessName: goddessController.text, dressCode: dressController.text);
              Navigator.pop(ctx);
              _loadData();
            },
            child: const Text('Save', style: TextStyle(color: AppTheme.goldPrimary)),
          ),
        ],
      ),
    );
  }

  void _showAddEventDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final locationController = TextEditingController();
    final timeController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: const Text('Add Event', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: timeController, style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Time (HH:MM)', labelStyle: TextStyle(color: Colors.white70), hintText: '19:00')),
              const SizedBox(height: 12),
              TextField(controller: nameController, style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Event Name *', labelStyle: TextStyle(color: Colors.white70))),
              const SizedBox(height: 12),
              TextField(controller: descController, style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Description', labelStyle: TextStyle(color: Colors.white70))),
              const SizedBox(height: 12),
              TextField(controller: locationController, style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Location', labelStyle: TextStyle(color: Colors.white70))),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty && timeController.text.isNotEmpty) {
                await DatabaseHelper.addScheduleEvent(
                  dayNumber: _selectedDay, time: timeController.text, name: nameController.text,
                  description: descController.text, location: locationController.text,
                );
                Navigator.pop(ctx);
                _loadData();
              }
            },
            child: const Text('Add', style: TextStyle(color: AppTheme.goldPrimary)),
          ),
        ],
      ),
    );
  }
}
