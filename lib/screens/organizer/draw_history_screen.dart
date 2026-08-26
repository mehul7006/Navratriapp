import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../database/database_helper.dart';

class DrawHistoryScreen extends StatefulWidget {
  const DrawHistoryScreen({super.key});

  @override
  State<DrawHistoryScreen> createState() => _DrawHistoryScreenState();
}

class _DrawHistoryScreenState extends State<DrawHistoryScreen> {
  List<Map<String, dynamic>> _history = [];
  List<Map<String, dynamic>> _winners = [];
  bool _isLoading = true;
  int _selectedDay = 0;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final history = await DatabaseHelper.getDrawHistory();
      final winners = await DatabaseHelper.query(
        "SELECT * FROM draw_tickets WHERE is_winner = TRUE ORDER BY day_number DESC",
      );
      setState(() {
        _history = history;
        _winners = winners.map((e) => Map<String, dynamic>.from(e)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredHistory {
    var list = _history;
    if (_selectedDay > 0) {
      list = list.where((t) => t['day_number'] == _selectedDay).toList();
    }
    if (_filter == 'winners') {
      list = list.where((t) => t['is_winner'] == true).toList();
    } else if (_filter == 'assigned') {
      list = list.where((t) => t['is_assigned'] == true && t['is_winner'] != true).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredHistory;
    final winners = _selectedDay > 0
        ? _winners.where((w) => w['day_number'] == _selectedDay).toList()
        : _winners;

    return Scaffold(
      backgroundColor: AppTheme.purpleDark,
      appBar: AppBar(
        title: const Text('Draw History'),
        backgroundColor: AppTheme.purpleDeep,
        foregroundColor: AppTheme.goldPrimary,
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _loadData),
        ],
      ),
      body: Column(
        children: [
          _buildDaySelector(),
          _buildFilterChips(),
          _buildStatsBar(winners),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.goldPrimary))
                : filtered.isEmpty
                    ? const Center(child: Text('No draw history found', style: TextStyle(color: AppTheme.textMuted)))
                    : _buildHistoryList(filtered),
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
              label: const Text('All Days'),
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

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _chip('All', 'all'),
          const SizedBox(width: 8),
          _chip('Winners', 'winners'),
          const SizedBox(width: 8),
          _chip('Assigned', 'assigned'),
        ],
      ),
    );
  }

  Widget _chip(String label, String value) {
    final selected = _filter == value;
    return FilterChip(
      label: Text(label, style: TextStyle(color: selected ? Colors.black : Colors.white70, fontSize: 12)),
      selected: selected,
      selectedColor: AppTheme.goldPrimary,
      onSelected: (s) => setState(() => _filter = value),
    );
  }

  Widget _buildStatsBar(List<Map<String, dynamic>> winners) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
            const Text('Total', style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
          ]),
          Column(children: [
            Text('${winners.length}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.amber)),
            const Text('Winners', style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
          ]),
          Column(children: [
            Text('${_filteredHistory.where((t) => t['is_assigned'] == true).length}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
            const Text('Assigned', style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
          ]),
        ],
      ),
    );
  }

  Widget _buildHistoryList(List<Map<String, dynamic>> list) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final t = list[index];
        final isWinner = t['is_winner'] == true;
        return Card(
          color: isWinner ? Colors.amber.withOpacity(0.15) : AppTheme.cardBg,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: isWinner ? Colors.amber : Colors.white24),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isWinner ? Colors.amber : Colors.blue,
              child: Icon(isWinner ? Icons.emoji_events : Icons.confirmation_number, color: Colors.white, size: 18),
            ),
            title: Text(
              (t['ticket_code'] ?? '').toString().length > 30
                  ? '${(t['ticket_code'] ?? '').toString().substring(0, 30)}...'
                  : (t['ticket_code'] ?? 'Ticket'),
              style: TextStyle(color: isWinner ? Colors.amber : Colors.white, fontSize: 12, fontFamily: 'monospace'),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Day ${t['day_number'] ?? '?'} • ${t['goddess_name'] ?? ''}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                if (t['user_name'] != null) Text('${t['house_number']} • ${t['user_name']}', style: const TextStyle(color: Colors.blue, fontSize: 11)),
              ],
            ),
            trailing: isWinner
                ? const Icon(Icons.emoji_events, color: Colors.amber, size: 20)
                : const Icon(Icons.check_circle, color: Colors.green, size: 18),
          ),
        );
      },
    );
  }
}
