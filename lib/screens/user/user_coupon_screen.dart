import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../database/database_helper.dart';

class UserCouponScreen extends StatefulWidget {
  final String houseNumber;
  final String userName;

  const UserCouponScreen({
    super.key,
    required this.houseNumber,
    required this.userName,
  });

  @override
  State<UserCouponScreen> createState() => _UserCouponScreenState();
}

class _UserCouponScreenState extends State<UserCouponScreen> {
  List<Map<String, dynamic>> _tickets = [];
  bool _isLoading = true;
  int _selectedDay = 0;

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    setState(() => _isLoading = true);
    try {
      final tickets = await DatabaseHelper.getMyTickets(widget.houseNumber);
      setState(() {
        _tickets = tickets;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to load tickets');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.purpleDark,
      appBar: AppBar(
        title: const Text('My Coupons'),
        backgroundColor: AppTheme.purpleDeep,
        foregroundColor: AppTheme.goldPrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // User Info Card
                _buildUserInfoCard(),
                // Day Filter
                _buildDayFilter(),
                // Tickets List
                Expanded(
                  child: _tickets.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.confirmation_number_outlined, size: 60, color: AppTheme.textMuted),
                              SizedBox(height: 16),
                              Text(
                                'No coupons assigned yet',
                                style: TextStyle(color: AppTheme.textMuted, fontSize: 16),
                              ),
                            ],
                          ),
                        )
                      : _buildTicketsList(),
                ),
              ],
            ),
    );
  }

  Widget _buildUserInfoCard() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.redAccent.withOpacity(0.8),
            AppTheme.purpleCard.withOpacity(0.95),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.goldPrimary),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: AppTheme.goldGradient,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                widget.userName.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.purpleDark,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.userName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.home, size: 14, color: AppTheme.goldPrimary),
                    const SizedBox(width: 4),
                    Text(
                      'House: ${widget.houseNumber}',
                      style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Ticket Count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.goldPrimary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_tickets.length} Tickets',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.purpleDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayFilter() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildDayChip('All Days', 0),
          ...List.generate(9, (index) => _buildDayChip('Day ${index + 1}', index + 1)),
        ],
      ),
    );
  }

  Widget _buildDayChip(String label, int day) {
    final isSelected = _selectedDay == day;
    final count = day == 0
        ? _tickets.length
        : _tickets.where((t) => t['day_number'] == day).length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: () => setState(() => _selectedDay = day),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.goldPrimary : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppTheme.goldPrimary : AppTheme.goldPrimary.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? AppTheme.purpleDark : AppTheme.textMuted,
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.purpleDark.withOpacity(0.3)
                        : AppTheme.goldPrimary.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppTheme.purpleDark : AppTheme.goldPrimary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTicketsList() {
    final filteredTickets = _selectedDay == 0
        ? _tickets
        : _tickets.where((t) => t['day_number'] == _selectedDay).toList();

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: filteredTickets.length,
      itemBuilder: (context, index) {
        return _buildTicketCard(filteredTickets[index]);
      },
    );
  }

  Widget _buildTicketCard(Map<String, dynamic> ticket) {
    final isWinner = ticket['is_winner'] == true;
    final eventDate = ticket['event_date'] != null
        ? DateTime.parse(ticket['event_date'])
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.purpleCard.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isWinner ? Colors.green : AppTheme.goldPrimary.withOpacity(0.5),
          width: isWinner ? 2 : 1,
        ),
        boxShadow: isWinner
            ? [
                BoxShadow(
                  color: Colors.green.withOpacity(0.3),
                  blurRadius: 15,
                  spreadRadius: 2,
                )
              ]
            : [],
      ),
      child: Column(
        children: [
          // Header with Day
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isWinner
                  ? Colors.green.withOpacity(0.2)
                  : AppTheme.goldPrimary.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 14, color: AppTheme.goldPrimary),
                    const SizedBox(width: 6),
                    Text(
                      'Day ${ticket['day_number']}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.goldPrimary,
                      ),
                    ),
                  ],
                ),
                if (isWinner)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      '🏆 WINNER',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // QR Code Area
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.qr_code, size: 40, color: AppTheme.purpleDark),
                        const SizedBox(height: 4),
                        Text(
                          ticket['ticket_code']?.toString().substring(0, 8) ?? '',
                          style: const TextStyle(fontSize: 7, color: AppTheme.purpleDark),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ticket['goddess_name'] ?? '',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (eventDate != null)
                        Text(
                          DateFormat('dd MMM yyyy').format(eventDate),
                          style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        'Dress: ${ticket['dress_code'] ?? 'N/A'}',
                        style: const TextStyle(fontSize: 11, color: AppTheme.cyanAccent),
                      ),
                    ],
                  ),
                ),
                // Status
                Icon(
                  ticket['is_assigned'] == true ? Icons.check_circle : Icons.pending,
                  color: ticket['is_assigned'] == true ? Colors.green : Colors.orange,
                  size: 28,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
