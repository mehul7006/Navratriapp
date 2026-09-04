import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../database/database_helper.dart';
import '../../l10n/app_localizations.dart';

class DrawHistoryScreen extends StatefulWidget {
  const DrawHistoryScreen({super.key});

  @override
  State<DrawHistoryScreen> createState() => _DrawHistoryScreenState();
}

class _DrawHistoryScreenState extends State<DrawHistoryScreen> {
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;
  int _selectedDay = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final history = await DatabaseHelper.getDrawHistory();
      setState(() {
        _history = history;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredHistory {
    if (_selectedDay > 0) {
      return _history.where((t) => t['day_number'] == _selectedDay).toList();
    }
    return _history;
  }

  Map<int, List<Map<String, dynamic>>> get _groupedByDay {
    final map = <int, List<Map<String, dynamic>>>{};
    for (final item in _filteredHistory) {
      final day = item['day_number'] ?? 0;
      map.putIfAbsent(day, () => []).add(item);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupedByDay;
    final totalWinners = _filteredHistory.where((t) => t['prize_level'] != null).length;
    final totalCancelled = _filteredHistory.where((t) => t['status'] == 'cancelled').length;

    return Scaffold(
      backgroundColor: AppTheme.purpleDark,
      appBar: AppBar(
        title: Text(AppLocalizations.t('draw_history'), style: const TextStyle(color: AppTheme.goldPrimary)),
        backgroundColor: AppTheme.purpleDeep,
        foregroundColor: AppTheme.goldPrimary,
        iconTheme: const IconThemeData(color: AppTheme.goldPrimary),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _loadData),
        ],
      ),
      body: Column(
        children: [
          _buildDaySelector(),
          _buildStatsBar(totalWinners, totalCancelled),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.goldPrimary))
                : grouped.isEmpty
                    ? Center(child: Text(AppLocalizations.t('no_draw_history'), style: const TextStyle(color: AppTheme.textMuted)))
                    : _buildDayGroupedList(grouped),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySelector() {
    return Container(
      height: 50,
      color: AppTheme.purpleDeep.withValues(alpha: 0.3),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              label: Text(AppLocalizations.t('all_days_filter')),
              selected: _selectedDay == 0,
              selectedColor: AppTheme.goldPrimary,
              onSelected: (s) => setState(() => _selectedDay = 0),
              labelStyle: TextStyle(color: _selectedDay == 0 ? Colors.black : Colors.white, fontSize: 12),
            ),
          ),
          ...List.generate(9, (i) {
            final dayNum = i + 1;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: FilterChip(
                label: Text('Day $dayNum'),
                selected: _selectedDay == dayNum,
                selectedColor: AppTheme.goldPrimary,
                onSelected: (s) => setState(() => _selectedDay = dayNum),
                labelStyle: TextStyle(color: _selectedDay == dayNum ? Colors.black : Colors.white, fontSize: 12),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStatsBar(int totalWinners, int totalCancelled) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(children: [
            Text('${_filteredHistory.length}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
            const Text('Total Draws', style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
          ]),
          Column(children: [
            Text('$totalWinners', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.amber)),
            const Text('Winners', style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
          ]),
          Column(children: [
            Text('$totalCancelled', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red)),
            const Text('Cancelled', style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
          ]),
        ],
      ),
    );
  }

  Widget _buildDayGroupedList(Map<int, List<Map<String, dynamic>>> grouped) {
    final sortedDays = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedDays.length,
      itemBuilder: (context, index) {
        final day = sortedDays[index];
        final draws = grouped[day]!;
        final goddess = draws.first['goddess_name'] ?? '';
        final eventDate = (draws.first['event_date'] ?? '').toString().split('T').first;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [AppTheme.goldPrimary.withOpacity(0.2), AppTheme.purpleCard]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Day $day${goddess.isNotEmpty ? ' - $goddess' : ''}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.goldPrimary)),
                  if (eventDate.isNotEmpty) Text(eventDate, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ...draws.map((draw) => _buildDrawCard(draw)),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildDrawCard(Map<String, dynamic> draw) {
    final prizeLevel = draw['prize_level'];
    final status = (draw['status'] ?? '').toString();
    final isCancelled = status == 'cancelled';
    final cancelReason = draw['cancelled_reason'];
    final ticketCode = draw['ticket_code'] ?? '';
    final userName = draw['user_name'] ?? '';
    final houseNumber = draw['house_number'] ?? '';
    final goddess = draw['goddess_name'] ?? '';

    String prizeLabel = '';
    Color prizeColor;
    IconData prizeIcon;

    if (isCancelled) {
      prizeLabel = 'CANCELLED';
      prizeColor = Colors.red;
      prizeIcon = Icons.cancel;
    } else if (prizeLevel == 1) {
      prizeLabel = '1st Prize';
      prizeColor = Colors.amber;
      prizeIcon = Icons.emoji_events;
    } else if (prizeLevel == 2) {
      prizeLabel = '2nd Prize';
      prizeColor = Colors.grey;
      prizeIcon = Icons.emoji_events;
    } else if (prizeLevel == 3) {
      prizeLabel = '3rd Prize';
      prizeColor = const Color(0xFFCD7F32);
      prizeIcon = Icons.emoji_events;
    } else {
      prizeLabel = 'Winner';
      prizeColor = Colors.green;
      prizeIcon = Icons.check_circle;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isCancelled ? Colors.red.withOpacity(0.08) : prizeColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isCancelled ? Colors.red.withOpacity(0.3) : prizeColor.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: prizeColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(prizeIcon, size: 14, color: prizeColor),
                      const SizedBox(width: 4),
                      Text(prizeLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: prizeColor)),
                    ],
                  ),
                ),
                if (!isCancelled && goddess.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text('Goddess: $goddess', style: const TextStyle(fontSize: 10, color: Colors.white54)),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.confirmation_number, size: 14, color: Colors.white54),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(ticketCode, style: TextStyle(fontSize: 12, fontFamily: 'monospace', color: isCancelled ? Colors.white54 : Colors.white)),
                ),
              ],
            ),
            if (userName.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.person, size: 14, color: Colors.white54),
                  const SizedBox(width: 6),
                  Text('$userName', style: TextStyle(fontSize: 12, color: isCancelled ? Colors.white54 : Colors.white)),
                  if (houseNumber.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.home, size: 12, color: Colors.white54),
                    const SizedBox(width: 4),
                    Text(houseNumber, style: TextStyle(fontSize: 11, color: Colors.white54)),
                  ],
                ],
              ),
            ],
            if (isCancelled && cancelReason != null && cancelReason.toString().isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.red.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 14, color: Colors.red),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text('Reason: $cancelReason', style: const TextStyle(fontSize: 11, color: Colors.red)),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
