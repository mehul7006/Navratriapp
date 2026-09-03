import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../database/database_helper.dart';
import '../../l10n/app_localizations.dart';
import 'garba_member_detail_screen.dart';

class GarbaParticipationScreen extends StatefulWidget {
  const GarbaParticipationScreen({super.key});

  @override
  State<GarbaParticipationScreen> createState() => _GarbaParticipationScreenState();
}

class _GarbaParticipationScreenState extends State<GarbaParticipationScreen> {
  List<Map<String, dynamic>> _houses = [];
  List<Map<String, dynamic>> _members = [];
  String? _selectedHouse;
  bool _isLoading = true;
  bool _isLoadingMembers = false;

  @override
  void initState() {
    super.initState();
    _loadHouses();
  }

  Future<void> _loadHouses() async {
    setState(() => _isLoading = true);
    try {
      _houses = await DatabaseHelper.getGarbaHouses();
      if (_houses.isNotEmpty && _selectedHouse == null) {
        _selectedHouse = _houses[0]['house_number'];
        _loadMembers();
      }
    } catch (e) {}
    setState(() => _isLoading = false);
  }

  Future<void> _loadMembers() async {
    if (_selectedHouse == null) return;
    setState(() => _isLoadingMembers = true);
    try {
      _members = await DatabaseHelper.getGarbaMembersByHouse(_selectedHouse!);
    } catch (e) {}
    setState(() => _isLoadingMembers = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.purpleDark,
      appBar: AppBar(
        title: Text(AppLocalizations.t('garba_participation'), style: const TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.purpleDeep,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () { _loadHouses(); _loadMembers(); },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.goldPrimary))
          : Column(
              children: [
                _buildHouseTabs(),
                Expanded(
                  child: _isLoadingMembers
                      ? const Center(child: CircularProgressIndicator(color: AppTheme.goldPrimary))
                      : _members.isEmpty
                          ? const Center(child: Text('No members found', style: TextStyle(color: AppTheme.textMuted)))
                          : _buildMembersList(),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.goldPrimary,
        onPressed: _showAddMemberDialog,
        child: const Icon(Icons.person_add, color: AppTheme.purpleDark),
      ),
    );
  }

  Widget _buildHouseTabs() {
    return Container(
      height: 60,
      color: AppTheme.purpleDeep.withValues(alpha: 0.3),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        itemCount: _houses.length,
        itemBuilder: (context, index) {
          final house = _houses[index];
          final houseNumber = house['house_number'] ?? '';
          final memberCount = house['member_count'] ?? 0;
          final isSelected = _selectedHouse == houseNumber;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedHouse = houseNumber);
                _loadMembers();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.goldPrimary : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppTheme.goldPrimary : AppTheme.goldPrimary.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'House $houseNumber',
                      style: TextStyle(
                        color: isSelected ? AppTheme.purpleDark : AppTheme.goldPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '$memberCount members',
                      style: TextStyle(
                        color: isSelected ? AppTheme.purpleDark.withOpacity(0.7) : AppTheme.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMembersList() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _members.length,
      itemBuilder: (context, index) {
        final member = _members[index];
        return _buildMemberCard(member);
      },
    );
  }

  Widget _buildMemberCard(Map<String, dynamic> member) {
    final name = member['name'] ?? '';
    final memberType = member['member_type'] ?? 'sub';
    final totalTickets = member['total_tickets'] ?? 0;
    final winningTickets = member['winning_tickets'] ?? 0;
    final lastPrizeLevel = member['last_prize_level'];
    final isActive = member['is_active'] == true;

    String prizeText = '';
    if (lastPrizeLevel == 1) prizeText = '🏆 1st';
    else if (lastPrizeLevel == 2) prizeText = '🥈 2nd';
    else if (lastPrizeLevel == 3) prizeText = '🥉 3rd';

    return Card(
      color: AppTheme.cardBg,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.goldPrimary.withOpacity(0.2)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: memberType == 'main' ? AppTheme.goldPrimary : Colors.blue,
          child: Text(
            name.substring(0, 1).toUpperCase(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  decoration: isActive ? null : TextDecoration.lineThrough,
                ),
              ),
            ),
            if (memberType == 'main')
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.goldPrimary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('PAID', style: TextStyle(fontSize: 8, color: AppTheme.goldPrimary, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
        subtitle: Row(
          children: [
            Icon(Icons.confirmation_number, size: 12, color: Colors.white54),
            const SizedBox(width: 4),
            Text('$totalTickets tickets', style: const TextStyle(color: Colors.white70, fontSize: 11)),
            if (winningTickets > 0) ...[
              const SizedBox(width: 8),
              Icon(Icons.emoji_events, size: 12, color: Colors.amber),
              const SizedBox(width: 4),
              Text('$winningTickets wins', style: const TextStyle(color: Colors.amber, fontSize: 11)),
            ],
            if (prizeText.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(prizeText, style: const TextStyle(fontSize: 11)),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white54, size: 20),
          onSelected: (value) => _handleMemberAction(value, member),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'view', child: Text('View Details')),
            const PopupMenuItem(value: 'move', child: Text('Move to House')),
            const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
          ],
        ),
        onTap: () => _viewMemberDetails(member),
      ),
    );
  }

  void _handleMemberAction(String action, Map<String, dynamic> member) {
    if (action == 'view') {
      _viewMemberDetails(member);
    } else if (action == 'move') {
      _showMoveDialog(member);
    } else if (action == 'delete') {
      _showDeleteConfirmation(member);
    }
  }

  void _viewMemberDetails(Map<String, dynamic> member) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GarbaMemberDetailScreen(memberId: member['id'], memberName: member['name']),
      ),
    );
  }

  void _showMoveDialog(Map<String, dynamic> member) {
    String targetHouse = _selectedHouse ?? '';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: Text('Move ${member['name']}', style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Move to house:', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: targetHouse.isNotEmpty ? targetHouse : null,
              dropdownColor: AppTheme.purpleDeep,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'House Number', labelStyle: TextStyle(color: Colors.white70)),
              items: _houses.map((h) => DropdownMenuItem<String>(
                value: h['house_number'],
                child: Text('House ${h['house_number']}'),
              )).toList(),
              onChanged: (v) => targetHouse = v ?? '',
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await DatabaseHelper.moveGarbaMember(member['id'], targetHouse);
              _loadHouses();
              _loadMembers();
            },
            child: const Text('Move'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(Map<String, dynamic> member) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: const Text('Delete Member', style: TextStyle(color: Colors.white)),
        content: Text('Delete ${member['name']}? This cannot be undone.', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await DatabaseHelper.deleteGarbaMember(member['id']);
              _loadHouses();
              _loadMembers();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddMemberDialog() {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: const Text('Add Member', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Adding to House ${_selectedHouse ?? ""}', style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Member Name',
                labelStyle: const TextStyle(color: Colors.white70),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.white38)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              await DatabaseHelper.addGarbaMember(
                name: nameController.text.trim(),
                houseNumber: _selectedHouse ?? '',
              );
              _loadHouses();
              _loadMembers();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
