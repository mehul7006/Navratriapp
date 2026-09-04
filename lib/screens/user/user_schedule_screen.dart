import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../database/database_helper.dart';
import 'package:navratri_app/widgets/background_scaffold.dart';

class UserScheduleScreen extends StatefulWidget {
  const UserScheduleScreen({super.key});

  @override
  State<UserScheduleScreen> createState() => _UserScheduleScreenState();
}

class _UserScheduleScreenState extends State<UserScheduleScreen> {
  List<Map<String, dynamic>> _days = [];
  int _selectedDay = 1;
  List<Map<String, dynamic>> _schedule = [];
  bool _isLoading = true;

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

  @override
  Widget build(BuildContext context) {
    return BackgroundScaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.t('festival_schedule'), style: const TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.purpleDeep,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      child: Column(
        children: [
          _buildDaySelector(),
          _buildDayInfo(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.goldPrimary))
                : _schedule.isEmpty
                    ? _buildEmptyState()
                    : _buildScheduleList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySelector() {
    return Container(
      height: 65,
      color: AppTheme.purpleDeep.withValues(alpha: 0.3),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        itemCount: 9,
        itemBuilder: (context, index) {
          final day = index + 1;
          final dayData = _days.where((d) => d['day_number'] == day).toList();
          final goddess = dayData.isNotEmpty ? (dayData[0]['goddess_name'] ?? '').toString() : '';
          final isActive = dayData.isNotEmpty && dayData[0]['is_active'] == true;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedDay = day);
              _loadData();
            },
            child: Container(
              width: 75,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: _selectedDay == day ? AppTheme.goldPrimary : AppTheme.purpleCard,
                borderRadius: BorderRadius.circular(12),
                border: isActive ? Border.all(color: Colors.amber, width: 2) : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Day $day', style: TextStyle(
                    color: _selectedDay == day ? Colors.black : Colors.white,
                    fontWeight: FontWeight.bold, fontSize: 12,
                  )),
                  if (goddess.isNotEmpty)
                    Text(
                      goddess.length > 8 ? goddess.substring(0, 8) : goddess,
                      style: TextStyle(color: _selectedDay == day ? Colors.black87 : Colors.white70, fontSize: 9),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDayInfo() {
    final dayData = _days.where((d) => d['day_number'] == _selectedDay).toList();
    if (dayData.isEmpty) return const SizedBox.shrink();
    final data = dayData.first;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppTheme.goldPrimary.withValues(alpha: 0.3), AppTheme.purpleCard]),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.temple_hindu, color: AppTheme.goldPrimary, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['goddess_name'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                if (data['dress_code']?.toString().isNotEmpty == true)
                  Text('Dress: ${data['dress_code']}', style: const TextStyle(color: AppTheme.yellowLight, fontSize: 12)),
              ],
            ),
          ),
          if (data['is_completed'] == true)
            const Icon(Icons.check_circle, color: Colors.green, size: 20)
          else if (data['is_active'] == true)
            const Icon(Icons.circle, color: Colors.amber, size: 12),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 48, color: Colors.white24),
          SizedBox(height: 16),
          Text(AppLocalizations.t('no_events_scheduled'), style: TextStyle(color: Colors.white54)),
        ],
      ),
    );
  }

  Widget _buildScheduleList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: _schedule.length,
      itemBuilder: (context, index) {
        final event = _schedule[index];
        final time = event['event_time']?.toString() ?? '';
        return Card(
          color: AppTheme.purpleCard.withValues(alpha: 0.7),
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 60,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.goldPrimary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(time.length >= 5 ? time.substring(0, 5) : time,
                        style: const TextStyle(color: AppTheme.goldPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(event['event_name'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      if (event['event_description']?.toString().isNotEmpty == true) ...[
                        const SizedBox(height: 4),
                        Text('${event['event_description'] ?? ''}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      ],
                      if (event['location']?.toString().isNotEmpty == true) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 14, color: Colors.white54),
                            const SizedBox(width: 4),
                            Text('${event['location'] ?? ''}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
