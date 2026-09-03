import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../database/database_helper.dart';
import '../../l10n/app_localizations.dart';

class TicketManagementScreen extends StatefulWidget {
  const TicketManagementScreen({super.key});

  @override
  State<TicketManagementScreen> createState() => _TicketManagementScreenState();
}

class _TicketManagementScreenState extends State<TicketManagementScreen> {
  List<Map<String, dynamic>> _tickets = [];
  List<Map<String, dynamic>> _days = [];
  bool _isLoading = true;
  int _selectedDay = 0;
  String _filter = 'all';
  bool _isMultiSelectMode = false;
  Set<int> _selectedTicketIds = {};

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
    if (dayNumber == 0) return true; // "All" filter is view-only
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

  void _toggleMultiSelect() {
    setState(() {
      _isMultiSelectMode = !_isMultiSelectMode;
      if (!_isMultiSelectMode) _selectedTicketIds.clear();
    });
  }

  void _toggleTicketSelection(int id) {
    setState(() {
      if (_selectedTicketIds.contains(id)) {
        _selectedTicketIds.remove(id);
      } else {
        _selectedTicketIds.add(id);
      }
    });
  }

  void _selectAll() {
    final filtered = _filter == 'winners' ? _tickets.where((t) => t['draw_status'] == 'confirmed').toList() : _tickets;
    setState(() {
      if (_selectedTicketIds.length == filtered.length) {
        _selectedTicketIds.clear();
      } else {
        _selectedTicketIds = filtered.map((t) => t['id'] as int).toSet();
      }
    });
  }

  void _showBatchDeleteDialog() {
    if (_selectedTicketIds.isEmpty) return;
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.cardBg,
          title: Text('Delete ${_selectedTicketIds.length} Tickets', style: const TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Permanently delete ${_selectedTicketIds.length} selected tickets?',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 12),
              const Text('Reason (required)', style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextField(
                controller: reasonController,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Enter reason for deletion...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
                  filled: true,
                  fillColor: AppTheme.purpleDark,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.red.withOpacity(0.5))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.red.withOpacity(0.5))),
                ),
                onChanged: (_) => setDialogState(() {}),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocalizations.t('cancel'), style: TextStyle(color: Colors.white70))),
            TextButton(
              onPressed: reasonController.text.trim().isEmpty
                  ? null
                  : () async {
                      await DatabaseHelper.batchDeleteTickets(_selectedTicketIds.toList(), reasonController.text.trim());
                      Navigator.pop(ctx);
                      setState(() { _isMultiSelectMode = false; _selectedTicketIds.clear(); });
                      _loadData();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(AppLocalizations.t('tickets_deleted')), backgroundColor: Colors.red),
                        );
                      }
                    },
              child: Text('Delete ${_selectedTicketIds.length}', style: TextStyle(color: reasonController.text.trim().isEmpty ? Colors.white38 : Colors.red)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final days = await DatabaseHelper.getNavratriDays();
      final dayParam = _selectedDay > 0 ? '$_selectedDay' : null;
      final assignedParam = _filter == 'assigned' ? 'true' : _filter == 'unassigned' ? 'false' : null;
      final tickets = await DatabaseHelper.getAllTickets(day: dayParam, assigned: assignedParam);
      setState(() {
        _days = days;
        _tickets = tickets;
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
        title: Text(_isMultiSelectMode ? '${_selectedTicketIds.length} Selected' : AppLocalizations.t('draw_tickets'), style: const TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.purpleDeep,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_isMultiSelectMode) ...[
            IconButton(
              icon: Icon(_selectedTicketIds.isEmpty ? Icons.select_all : Icons.deselect, color: Colors.white),
              onPressed: _selectAll,
              tooltip: _selectedTicketIds.isEmpty ? AppLocalizations.t('select_all') : AppLocalizations.t('deselect_all'),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _selectedTicketIds.isEmpty ? null : _showBatchDeleteDialog,
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white70),
              onPressed: _toggleMultiSelect,
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.checklist, color: Colors.white),
              onPressed: _toggleMultiSelect,
              tooltip: AppLocalizations.t('multi_select'),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _loadData,
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          _buildDaySelector(),
          _buildFilterChips(),
          _buildStats(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.goldPrimary))
                : _tickets.isEmpty
                    ? _buildEmptyState()
                    : _buildTicketList(),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
           FloatingActionButton.extended(
            heroTag: 'generate',
            backgroundColor: _isDayBookable(_selectedDay) ? AppTheme.goldPrimary : Colors.grey,
            onPressed: _isDayBookable(_selectedDay) ? _showGenerateDialog : null,
            icon: Icon(_isDayBookable(_selectedDay) ? Icons.add : Icons.lock, color: _isDayBookable(_selectedDay) ? Colors.black : Colors.white70),
            label: Text(
              _isDayBookable(_selectedDay) ? AppLocalizations.t('generate') : 'Day Closed',
              style: TextStyle(color: _isDayBookable(_selectedDay) ? Colors.black : Colors.white70, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'assign',
            backgroundColor: _isDayBookable(_selectedDay) ? Colors.blue : Colors.grey,
            onPressed: _isDayBookable(_selectedDay) ? _showAssignDialog : null,
            icon: Icon(_isDayBookable(_selectedDay) ? Icons.person_add : Icons.lock, color: Colors.white),
            label: Text(
              _isDayBookable(_selectedDay) ? AppLocalizations.t('assign_ticket') : 'Day Closed',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySelector() {
    return Container(
      height: 60,
      color: AppTheme.purpleDeep.withValues(alpha: 0.3),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              label: Text(AppLocalizations.t('all')),
              selected: _selectedDay == 0,
              selectedColor: AppTheme.goldPrimary,
              onSelected: (s) { setState(() => _selectedDay = 0); _loadData(); },
              labelStyle: TextStyle(color: _selectedDay == 0 ? Colors.black : Colors.white),
            ),
          ),
          ...List.generate(9, (i) {
            final dayNum = i + 1;
            final dayData = _days.where((d) => d['day_number'] == dayNum).toList();
            final goddess = dayData.isNotEmpty ? dayData[0]['goddess_name'] ?? '' : '';
            final completed = _isDayCompleted(dayNum);
            final bookable = _isDayBookable(dayNum);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: FilterChip(
                avatar: completed ? const Icon(Icons.lock, size: 14, color: Colors.red) : null,
                label: Text('D$dayNum${goddess.isNotEmpty ? " $goddess" : ""}'),
                selected: _selectedDay == dayNum,
                selectedColor: completed ? Colors.red.withValues(alpha: 0.3) : AppTheme.goldPrimary,
                onSelected: (s) { setState(() => _selectedDay = dayNum); _loadData(); },
                labelStyle: TextStyle(color: completed ? Colors.red.withValues(alpha: 0.7) : (_selectedDay == dayNum ? Colors.black : Colors.white), fontSize: 12),
                side: completed ? BorderSide(color: Colors.red.withOpacity(0.6)) : null,
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
          _chip(AppLocalizations.t('all'), 'all'),
          const SizedBox(width: 8),
          _chip(AppLocalizations.t('assigned'), 'assigned'),
          const SizedBox(width: 8),
          _chip(AppLocalizations.t('unassigned'), 'unassigned'),
          const SizedBox(width: 8),
          _chip(AppLocalizations.t('winner'), 'winners'),
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
      onSelected: (s) {
        setState(() => _filter = value);
        if (value != 'winners') _loadData();
      },
    );
  }

  Widget _buildStats() {
    final total = _tickets.length;
    final assigned = _tickets.where((t) => t['is_assigned'] == true).length;
    final winners = _tickets.where((t) => t['draw_status'] == 'confirmed').length;
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
          _statItem(AppLocalizations.t('total'), '$total', Colors.blue),
          _statItem(AppLocalizations.t('assigned'), '$assigned', Colors.green),
          _statItem(AppLocalizations.t('winner'), '$winners', Colors.amber),
          _statItem(AppLocalizations.t('unassigned'), '${total - assigned}', Colors.grey),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.white70)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.confirmation_number, size: 64, color: Colors.white24),
          SizedBox(height: 16),
          Text(AppLocalizations.t('no_tickets_found'), style: TextStyle(color: Colors.white54, fontSize: 16)),
          SizedBox(height: 8),
          Text(AppLocalizations.t('generate_tickets'), style: TextStyle(color: Colors.white38, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildTicketList() {
    final filtered = _filter == 'winners' ? _tickets.where((t) => t['draw_status'] == 'confirmed').toList() : _tickets;
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final ticket = filtered[index];
        return _buildTicketCard(ticket);
      },
    );
  }

  Widget _buildTicketCard(Map<String, dynamic> ticket) {
    final isWinner = ticket['is_winner'] == true;
    final isAssigned = ticket['is_assigned'] == true;
    final isSelected = _selectedTicketIds.contains(ticket['id']);
    final isCancelled = ticket['draw_status'] == 'cancelled';
    final hasDrawRecord = ticket['draw_status'] != null;
    
    return Card(
      color: isSelected
          ? Colors.blue.withOpacity(0.3)
          : isCancelled 
              ? Colors.orange.withOpacity(0.1)
              : isWinner ? Colors.green.withValues(alpha: 0.2) : AppTheme.cardBg,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? Colors.blue : isCancelled ? Colors.orange : isWinner ? Colors.green : isAssigned ? Colors.blue : Colors.white24,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        leading: _isMultiSelectMode
            ? Checkbox(
                value: isSelected,
                onChanged: (_) => _toggleTicketSelection(ticket['id']),
                activeColor: Colors.blue,
                checkColor: Colors.white,
              )
            : CircleAvatar(
                backgroundColor: isCancelled ? Colors.orange : isWinner ? Colors.green : isAssigned ? Colors.blue : Colors.grey,
                child: Icon(isCancelled ? Icons.cancel : isWinner ? Icons.emoji_events : isAssigned ? Icons.person : Icons.confirmation_number, color: Colors.white, size: 20),
              ),
        title: Text(
          ticket['ticket_code']?.toString().substring(0, [ticket['ticket_code']?.toString().length ?? 0, 30].reduce((a, b) => a < b ? a : b)) ?? 'Ticket',
          style: TextStyle(color: isSelected ? Colors.blue : Colors.white, fontSize: 12, fontFamily: 'monospace'),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Day ${ticket['day_number'] ?? '?'} • ${ticket['goddess_name'] ?? ''}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
            if (isAssigned)
              Text('House: ${ticket['assigned_house'] ?? ticket['house_number'] ?? ''} • ${ticket['user_name'] ?? ''}', style: const TextStyle(color: Colors.blue, fontSize: 11)),
            if (isWinner && !isCancelled)
              const Text('WINNER', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11)),
            if (isCancelled)
              const Text('CANCELLED', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 11)),
            if (isWinner && !isCancelled && ticket['prize_level'] != null)
              Text(
                (ticket['prize_level'] == 1 ? '[1st]' : ticket['prize_level'] == 2 ? '[2nd]' : '[3rd]') + ' Prize',
                style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 10),
              ),
            if (isCancelled && ticket['cancelled_reason'] != null)
              Text(
                'Reason: ${ticket['cancelled_reason']}',
                style: TextStyle(color: Colors.orange.withOpacity(0.7), fontSize: 10),
              ),
          ],
        ),
        trailing: _isMultiSelectMode
            ? null
            : PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white70),
                onSelected: (value) => _handleTicketAction(value, ticket),
                itemBuilder: (context) => [
                  if (!isWinner && !hasDrawRecord)
                    PopupMenuItem(value: 'winner', child: Text(AppLocalizations.t('mark_winner'))),
                  if (hasDrawRecord && !isCancelled)
                    const PopupMenuItem(value: 'cancel_prize', child: Text('Cancel Prize', style: TextStyle(color: Colors.orange))),
                  PopupMenuItem(value: 'delete', child: Text(AppLocalizations.t('delete'), style: TextStyle(color: Colors.red))),
                ],
              ),
      ),
    );
  }

  Future<void> _handleTicketAction(String action, Map<String, dynamic> ticket) async {
    if (action == 'winner') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(AppLocalizations.t('mark_winner_title')),
          content: Text('Mark ticket ${ticket['ticket_code']} as winner?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppLocalizations.t('cancel'))),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirm', style: TextStyle(color: Colors.green))),
          ],
        ),
      );
      if (confirm == true) {
        await DatabaseHelper.markWinner(ticket['id']);
        _loadData();
      }
    } else if (action == 'cancel_prize') {
      final reason = await _showCancelDialog();
      if (reason == null || reason.isEmpty) return;
      
      try {
        // Find the draw_id for this ticket - look for any draw record
        final drawHistory = await DatabaseHelper.getDailyDrawHistory(dayNumber: ticket['day_number']);
        final draw = drawHistory.firstWhere(
          (d) => d['ticket_code'] == ticket['ticket_code'],
          orElse: () => {},
        );
        
        if (draw.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No draw record found for this ticket'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
        
        // Check if already cancelled
        if (draw['status'] == 'cancelled') {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('This prize is already cancelled'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }
        
        await DatabaseHelper.cancelDraw(drawId: draw['id'], reason: reason);
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Prize cancelled successfully'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to cancel prize: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else if (action == 'delete') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(AppLocalizations.t('delete_ticket')),
          content: const Text('This cannot be undone.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppLocalizations.t('cancel'))),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(AppLocalizations.t('delete'), style: TextStyle(color: Colors.red))),
          ],
        ),
      );
      if (confirm == true) {
        await DatabaseHelper.deleteTicket(ticket['id']);
        _loadData();
      }
    }
  }

  Future<String?> _showCancelDialog() async {
    final reasonController = TextEditingController();
    bool _hasReason = false;
    
    return showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          reasonController.addListener(() {
            final hasText = reasonController.text.trim().isNotEmpty;
            if (hasText != _hasReason) {
              setDialogState(() => _hasReason = hasText);
            }
          });
          
          return AlertDialog(
            backgroundColor: AppTheme.cardBg,
            title: const Text('Cancel Prize', style: TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Are you sure you want to cancel this prize? The ticket will be returned to the pot for re-draw.',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Reason for cancellation *',
                    labelStyle: const TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.white38),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppTheme.goldPrimary),
                    ),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
              ),
              ElevatedButton(
                onPressed: _hasReason
                    ? () => Navigator.pop(ctx, reasonController.text.trim())
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Confirm Cancellation'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showGenerateDialog() {
    int selectedDay = 1;
    int count = 50;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.cardBg,
          title: Text(AppLocalizations.t('generate_tickets'), style: const TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                value: selectedDay,
                dropdownColor: AppTheme.purpleDeep,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Day', labelStyle: TextStyle(color: Colors.white70)),
                items: List.generate(9, (i) => DropdownMenuItem(value: i + 1, child: Text('Day ${i + 1}'))),
                onChanged: (v) => setDialogState(() => selectedDay = v ?? 1),
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: '50',
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Number of tickets', labelStyle: TextStyle(color: Colors.white70)),
                onChanged: (v) => count = int.tryParse(v) ?? 50,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocalizations.t('cancel'))),
            TextButton(
              onPressed: () async {
                await DatabaseHelper.generateTickets(dayNumber: selectedDay, count: count);
                Navigator.pop(ctx);
                _loadData();
              },
              child: Text(AppLocalizations.t('generate'), style: TextStyle(color: AppTheme.goldPrimary)),
            ),
          ],
        ),
      ),
    );
  }

  void _showAssignDialog() {
    String ticketCode = '';
    String houseNumber = '';
    List<Map<String, dynamic>> members = [];
    List<Map<String, dynamic>> ticketSuggestions = [];
    int? selectedUserId;
    bool showMembers = false;
    bool showAddMember = false;
    bool isSearching = false;
    bool isSearchingTickets = false;
    bool showTicketSuggestions = false;
    final ticketController = TextEditingController();
    final nameController = TextEditingController();
    final mobileController = TextEditingController();
    final houseController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.cardBg,
          title: Text(AppLocalizations.t('assign_ticket_title'), style: const TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: ticketController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: AppLocalizations.t('ticket_code'),
                    labelStyle: const TextStyle(color: Colors.white70),
                    hintText: AppLocalizations.t('type_ticket_search'),
                    suffixIcon: isSearchingTickets
                        ? const Padding(padding: EdgeInsets.all(10), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.goldPrimary)))
                        : (ticketCode.isNotEmpty ? const Icon(Icons.check, color: Colors.green, size: 18) : const Icon(Icons.search, color: Colors.white38, size: 18)),
                  ),
                  onChanged: (v) {
                    ticketCode = v;
                    if (v.length >= 2) {
                      setDialogState(() => isSearchingTickets = true);
                      DatabaseHelper.getAllTickets().then((results) {
                        if (!ctx.mounted) return;
                        final filtered = results.where((t) {
                          final code = (t['ticket_code'] ?? '').toString();
                          final isAssigned = t['is_assigned'] == true;
                          return !isAssigned && code.contains(v);
                        }).toList();
                        setDialogState(() {
                          ticketSuggestions = filtered;
                          showTicketSuggestions = filtered.isNotEmpty;
                          isSearchingTickets = false;
                        });
                      }).catchError((_) {
                        if (!ctx.mounted) return;
                        setDialogState(() { ticketSuggestions = []; showTicketSuggestions = false; isSearchingTickets = false; });
                      });
                    } else {
                      setDialogState(() { ticketSuggestions = []; showTicketSuggestions = false; isSearchingTickets = false; });
                    }
                  },
                ),
                if (showTicketSuggestions && ticketSuggestions.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 150),
                    decoration: BoxDecoration(
                      color: AppTheme.purpleDark,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.goldPrimary.withOpacity(0.3)),
                    ),
                    child: Container(
                    constraints: const BoxConstraints(maxHeight: 150),
                    decoration: BoxDecoration(
                      color: AppTheme.purpleDark,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.goldPrimary.withOpacity(0.3)),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: ticketSuggestions.map((t) {
                          return Material(
                            color: Colors.transparent,
                            child: ListTile(
                              dense: true,
                              leading: const Icon(Icons.confirmation_number, color: AppTheme.goldPrimary, size: 16),
                              title: Text(t['ticket_code'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'monospace')),
                              subtitle: Text('Day ${t['day_number']}', style: const TextStyle(color: Colors.white54, fontSize: 10)),
                              onTap: () {
                                ticketCode = t['ticket_code'] ?? '';
                                ticketController.text = ticketCode;
                                setDialogState(() { showTicketSuggestions = false; });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  ),
                ],
                const SizedBox(height: 12),
                TextFormField(
                  controller: houseController,
                  style: const TextStyle(color: Colors.white),
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: 'House Number',
                    labelStyle: const TextStyle(color: Colors.white70),
                    hintText: AppLocalizations.t('type_house_search'),
                    suffixIcon: isSearching
                        ? const Padding(padding: EdgeInsets.all(10), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.goldPrimary)))
                        : (showMembers && members.isNotEmpty)
                            ? const Icon(Icons.check, color: Colors.green, size: 18)
                            : null,
                  ),
                  onChanged: (v) {
                    final upper = v.toUpperCase();
                    if (v != upper) {
                      houseController.value = houseController.value.copyWith(text: upper, selection: TextSelection.collapsed(offset: upper.length));
                    }
                    houseNumber = upper;
                    if (v.length >= 2) {
                      setDialogState(() => isSearching = true);
                      DatabaseHelper.getMembersByHouse(houseNumber).then((result) {
                        if (!ctx.mounted) return;
                        setDialogState(() {
                          members = result;
                          showMembers = true;
                          selectedUserId = null;
                          isSearching = false;
                          showAddMember = false;
                        });
                      }).catchError((_) {
                        if (!ctx.mounted) return;
                        setDialogState(() {
                          members = [];
                          showMembers = true;
                          isSearching = false;
                          showAddMember = false;
                        });
                      });
                    } else {
                      setDialogState(() { members = []; showMembers = false; showAddMember = false; isSearching = false; });
                    }
                  },
                ),
                if (showMembers && members.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text('${members.length} member(s) in $houseNumber', style: const TextStyle(color: Colors.green, fontSize: 11)),
                  const SizedBox(height: 6),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 180),
                    decoration: BoxDecoration(
                      color: AppTheme.purpleDark,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.goldPrimary.withOpacity(0.3)),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: members.map((m) {
                          final isSelected = selectedUserId == m['id'];
                          final memberName = (m['name'] ?? '').toString();
                          final memberMobile = (m['mobile_number'] ?? '').toString();
                          return Material(
                            color: Colors.transparent,
                            child: ListTile(
                              dense: true,
                              leading: CircleAvatar(
                                backgroundColor: isSelected ? Colors.green : AppTheme.goldPrimary,
                                radius: 14,
                                child: Text(memberName.isNotEmpty ? memberName[0].toUpperCase() : '?',
                                    style: const TextStyle(fontSize: 11, color: AppTheme.purpleDark, fontWeight: FontWeight.bold)),
                              ),
                              title: Text(memberName, style: TextStyle(color: isSelected ? Colors.green : Colors.white, fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                              subtitle: memberMobile.isNotEmpty && memberMobile != '0' ? Text(memberMobile, style: const TextStyle(color: Colors.white54, fontSize: 11)) : null,
                              trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.green, size: 20) : null,
                              onTap: () {
                                setDialogState(() {
                                  selectedUserId = m['id'];
                                  showAddMember = false;
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
                if (showMembers && houseNumber.isNotEmpty && !isSearching) ...[
                  const SizedBox(height: 8),
                  if (!showAddMember)
                    GestureDetector(
                      onTap: () => setDialogState(() => showAddMember = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.goldPrimary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.goldPrimary.withOpacity(0.4)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.person_add, color: AppTheme.goldPrimary, size: 16),
                            const SizedBox(width: 6),
                            Text(AppLocalizations.t('add_new_member'), style: TextStyle(color: AppTheme.goldPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  if (showAddMember) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Add member to $houseNumber', style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
                              GestureDetector(
                                onTap: () {
                                  nameController.clear();
                                  mobileController.clear();
                                  setDialogState(() => showAddMember = false);
                                },
                                child: const Icon(Icons.close, color: Colors.white54, size: 16),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: nameController,
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                            textCapitalization: TextCapitalization.words,
                            decoration: InputDecoration(
                              hintText: AppLocalizations.t('member_name_hint'),
                              hintStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Colors.white24)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Colors.white24)),
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: mobileController,
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                            keyboardType: TextInputType.phone,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                            decoration: InputDecoration(
                              counterText: '',
                              hintText: AppLocalizations.t('mobile_optional'),
                              hintStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Colors.white24)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Colors.white24)),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, padding: const EdgeInsets.symmetric(vertical: 8)),
                              icon: const Icon(Icons.person_add, size: 14, color: Colors.white),
                              label: Text(AppLocalizations.t('add_select_ticket'), style: TextStyle(color: Colors.white, fontSize: 12)),
                              onPressed: () async {
                                if (mobileController.text.trim().isNotEmpty && mobileController.text.trim().length != 10) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.t('enter_valid_10_digit_mobile')), backgroundColor: Colors.red));
                                  return;
                                }
                                if (nameController.text.trim().isNotEmpty) {
                                  try {
                                    final userId = await DatabaseHelper.registerUser(
                                      houseNumber: houseNumber,
                                      name: nameController.text.trim(),
                                      mobileNumber: mobileController.text.trim().isNotEmpty ? mobileController.text.trim() : '0000000000',
                                      userType: 'user',
                                      memberType: 'sub',
                                    );
                                    final result = await DatabaseHelper.getMembersByHouse(houseNumber);
                                    if (!ctx.mounted) return;
                                    setDialogState(() {
                                      members = result;
                                      showMembers = true;
                                      selectedUserId = userId;
                                      showAddMember = false;
                                      nameController.clear();
                                      mobileController.clear();
                                    });
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Member added to $houseNumber'), backgroundColor: Colors.green),
                                      );
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                                      );
                                    }
                                  }
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                ticketController.dispose();
                nameController.dispose();
                mobileController.dispose();
                houseController.dispose();
                Navigator.pop(ctx);
              },
              child: Text(AppLocalizations.t('cancel')),
            ),
            TextButton(
              onPressed: (selectedUserId != null && ticketCode.isNotEmpty)
                  ? () async {
                      final nav = Navigator.of(ctx);
                      final messenger = ScaffoldMessenger.of(context);
                      await DatabaseHelper.assignTicket(
                        ticketCode: ticketCode,
                        userId: selectedUserId!,
                        houseNumber: houseNumber,
                      );
                      ticketController.dispose();
                      nameController.dispose();
                      mobileController.dispose();
                      houseController.dispose();
                      if (ctx.mounted) nav.pop();
                      _loadData();
                      if (mounted) {
                        messenger.showSnackBar(
                          SnackBar(content: const Text('Ticket assigned successfully'), backgroundColor: Colors.green),
                        );
                      }
                    }
                  : null,
              child: Text(AppLocalizations.t('assign_ticket'), style: TextStyle(color: selectedUserId != null ? AppTheme.goldPrimary : Colors.white38)),
            ),
          ],
        ),
      ),
    ).then((_) {
      ticketController.dispose();
      nameController.dispose();
      mobileController.dispose();
      houseController.dispose();
    });
  }
}
