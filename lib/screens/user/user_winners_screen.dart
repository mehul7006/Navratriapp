import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../database/database_helper.dart';

class UserWinnersScreen extends StatefulWidget {
  const UserWinnersScreen({super.key});

  @override
  State<UserWinnersScreen> createState() => _UserWinnersScreenState();
}

class _UserWinnersScreenState extends State<UserWinnersScreen> {
  List<Map<String, dynamic>> _winners = [];
  List<Map<String, dynamic>> _days = [];
  int _selectedDay = 0;
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
      final winners = await DatabaseHelper.getWinners(day: _selectedDay > 0 ? _selectedDay : null);
      setState(() {
        _days = days;
        _winners = winners;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.purpleDark,
      appBar: AppBar(
        title: Text(AppLocalizations.t('draw_winners'), style: const TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.purpleDeep,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _loadData),
        ],
      ),
      body: Column(
        children: [
          _buildDayFilter(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.goldPrimary))
                : _winners.isEmpty
                    ? _buildEmptyState()
                    : _buildWinnersList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDayFilter() {
    return Container(
      height: 55,
      color: AppTheme.purpleDeep.withValues(alpha: 0.3),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              label: Text(AppLocalizations.t('all_days')),
              selected: _selectedDay == 0,
              selectedColor: AppTheme.goldPrimary,
              onSelected: (s) { setState(() => _selectedDay = 0); _loadData(); },
              labelStyle: TextStyle(color: _selectedDay == 0 ? Colors.black : Colors.white),
            ),
          ),
          ...List.generate(9, (i) {
            final day = i + 1;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: FilterChip(
                label: Text('Day $day'),
                selected: _selectedDay == day,
                selectedColor: AppTheme.goldPrimary,
                onSelected: (s) { setState(() => _selectedDay = day); _loadData(); },
                labelStyle: TextStyle(color: _selectedDay == day ? Colors.black : Colors.white, fontSize: 12),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.emoji_events, size: 64, color: Colors.white24),
          const SizedBox(height: 16),
          Text(AppLocalizations.t('no_winners_announced'), style: const TextStyle(color: Colors.white54, fontSize: 16)),
          const SizedBox(height: 8),
          Text(AppLocalizations.t('winners_will_appear'), style: const TextStyle(color: Colors.white38, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildWinnersList() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _winners.length,
      itemBuilder: (context, index) {
        final winner = _winners[index];
        return _buildWinnerCard(winner, index);
      },
    );
  }

  Widget _buildWinnerCard(Map<String, dynamic> winner, int index) {
    final goddess = winner['goddess_name'] ?? '';
    final date = winner['event_date'] ?? '';
    return Card(
      color: Colors.green.withValues(alpha: 0.15),
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.green, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.amber,
              child: Text('#${index + 1}', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.emoji_events, color: Colors.amber, size: 18),
                      const SizedBox(width: 6),
                      Text(winner['user_name'] ?? 'Unknown', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('House: ${winner['house_number'] ?? ''}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  Text('Ticket: ${winner['ticket_code']?.toString().substring(0, [winner['ticket_code']?.toString().length ?? 0, 30].reduce((a, b) => a < b ? a : b)) ?? ''}',
                      style: const TextStyle(color: Colors.white54, fontSize: 11, fontFamily: 'monospace')),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: AppTheme.goldPrimary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                  child: Text('Day ${winner['day_number']}', style: const TextStyle(color: AppTheme.goldPrimary, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                if (goddess.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(goddess, style: const TextStyle(color: Colors.white54, fontSize: 10)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
