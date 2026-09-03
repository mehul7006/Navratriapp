import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../database/database_helper.dart';

class GarbaMemberDetailScreen extends StatefulWidget {
  final int memberId;
  final String memberName;
  const GarbaMemberDetailScreen({super.key, required this.memberId, required this.memberName});

  @override
  State<GarbaMemberDetailScreen> createState() => _GarbaMemberDetailScreenState();
}

class _GarbaMemberDetailScreenState extends State<GarbaMemberDetailScreen> {
  Map<String, dynamic>? _details;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    setState(() => _isLoading = true);
    try {
      _details = await DatabaseHelper.getGarbaMemberDetails(widget.memberId);
    } catch (e) {}
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.purpleDark,
      appBar: AppBar(
        title: Text(widget.memberName, style: const TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.purpleDeep,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.goldPrimary))
          : _details == null
              ? const Center(child: Text('No data found', style: TextStyle(color: AppTheme.textMuted)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildUserInfo(),
                      const SizedBox(height: 16),
                      _buildStatsRow(),
                      const SizedBox(height: 16),
                      _buildTicketsSection(),
                      const SizedBox(height: 16),
                      _buildWinsSection(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildUserInfo() {
    final user = _details!['user'] ?? {};
    return Card(
      color: AppTheme.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppTheme.goldPrimary,
              child: Text(
                (user['name'] ?? '?').substring(0, 1).toUpperCase(),
                style: const TextStyle(color: AppTheme.purpleDark, fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user['name'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.home, size: 14, color: AppTheme.goldPrimary),
                      const SizedBox(width: 4),
                      Text('House: ${user['house_number'] ?? ''}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.phone, size: 14, color: AppTheme.goldPrimary),
                      const SizedBox(width: 4),
                      Text(user['mobile_number'] ?? 'N/A', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    final tickets = _details!['tickets'] ?? [];
    final wins = _details!['wins'] ?? [];
    return Row(
      children: [
        _buildStatCard('Total Tickets', '${tickets.length}', Icons.confirmation_number, Colors.blue),
        const SizedBox(width: 8),
        _buildStatCard('Lucky Wins', '${wins.length}', Icons.emoji_events, Colors.amber),
        const SizedBox(width: 8),
        _buildStatCard('Days Played', '${_getUniqueDays(tickets)}', Icons.calendar_today, Colors.green),
      ],
    );
  }

  int _getUniqueDays(List tickets) {
    final days = <dynamic>{};
    for (final t in tickets) {
      if (t['day_number'] != null) days.add(t['day_number']);
    }
    return days.length;
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        color: color.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: color.withOpacity(0.3))),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
              Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTicketsSection() {
    final tickets = _details!['tickets'] ?? [];
    if (tickets.isEmpty) return const SizedBox.shrink();

    // Group by day
    final byDay = <int, List>{};
    for (final t in tickets) {
      final day = t['day_number'] ?? 0;
      byDay.putIfAbsent(day, () => []).add(t);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Tickets by Day', style: TextStyle(color: AppTheme.goldPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...byDay.entries.map((entry) {
          final dayTickets = entry.value;
          return Card(
            color: AppTheme.cardBg,
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 12),
              childrenPadding: const EdgeInsets.all(12),
              title: Text('Day ${entry.key}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: Text('${dayTickets.length} tickets', style: const TextStyle(color: Colors.white70, fontSize: 12)),
              iconColor: AppTheme.goldPrimary,
              collapsedIconColor: Colors.white54,
              children: dayTickets.map((t) {
                final ticketCode = t['ticket_code'] ?? '';
                final goddess = t['goddess_name'] ?? '';
                final isWinner = t['is_winner'] == true;
                final drawStatus = t['draw_status'];
                final prizeLevel = t['prize_level'];
                final isAssigned = t['is_assigned'] == true;

                String prizeText = '';
                if (prizeLevel == 1) prizeText = '[1st Prize]';
                else if (prizeLevel == 2) prizeText = '[2nd Prize]';
                else if (prizeLevel == 3) prizeText = '[3rd Prize]';

                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isWinner ? Colors.green.withOpacity(0.1) : AppTheme.purpleCard.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isWinner ? Colors.green : Colors.white24,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              ticketCode,
                              style: TextStyle(
                                color: isWinner ? Colors.green : Colors.white,
                                fontFamily: 'monospace',
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (isAssigned)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(color: Colors.blue.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                              child: const Text('ASSIGNED', style: TextStyle(fontSize: 8, color: Colors.blue)),
                            ),
                          if (isWinner)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(color: Colors.green.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                              child: const Text('WINNER', style: TextStyle(fontSize: 8, color: Colors.green)),
                            ),
                          if (drawStatus == 'cancelled')
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(color: Colors.orange.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                              child: const Text('CANCELLED', style: TextStyle(fontSize: 8, color: Colors.orange)),
                            ),
                        ],
                      ),
                      if (goddess.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(goddess, style: const TextStyle(color: Colors.white70, fontSize: 10)),
                      ],
                      if (prizeText.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(prizeText, style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildWinsSection() {
    final wins = _details!['wins'] ?? [];
    if (wins.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Lucky Draw Wins', style: TextStyle(color: AppTheme.goldPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...wins.map((w) {
          final prizeLevel = w['prize_level'];
          final goddess = w['goddess_name'] ?? '';
          final date = w['event_date'] ?? '';
          String prizeText = '';
          String prizeIcon = '';
          if (prizeLevel == 1) { prizeText = '1st Prize'; prizeIcon = '1'; }
          else if (prizeLevel == 2) { prizeText = '2nd Prize'; prizeIcon = '2'; }
          else if (prizeLevel == 3) { prizeText = '3rd Prize'; prizeIcon = '3'; }

          return Card(
            color: AppTheme.cardBg,
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: ListTile(
              leading: Text(prizeIcon, style: const TextStyle(fontSize: 28)),
              title: Text('$prizeText - Day ${w['day_number']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: Text('$goddess${date.isNotEmpty ? ' • $date' : ''}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ),
          );
        }),
      ],
    );
  }
}
