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
  List<Map<String, dynamic>> _allMembers = [];
  List<Map<String, dynamic>> _filteredMembers = [];
  String _selectedHouse = 'all';
  String _sortBy = 'name';
  final _searchController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _houses = await DatabaseHelper.getGarbaHouses();
      _allMembers = [];
      for (final house in _houses) {
        final members = await DatabaseHelper.getGarbaMembersByHouse(house['house_number']);
        _allMembers.addAll(members);
      }
      _applyFilters();
    } catch (e) {}
    setState(() => _isLoading = false);
  }

  void _applyFilters() {
    var list = List<Map<String, dynamic>>.from(_allMembers);
    if (_selectedHouse != 'all') {
      list = list.where((m) => m['house_number'] == _selectedHouse).toList();
    }
    final search = _searchController.text.toLowerCase();
    if (search.isNotEmpty) {
      list = list.where((m) =>
        (m['name']?.toString().toLowerCase().contains(search) ?? false) ||
        (m['house_number']?.toString().toLowerCase().contains(search) ?? false)
      ).toList();
    }
    if (_sortBy == 'name') {
      list.sort((a, b) => (a['name'] ?? '').toString().compareTo((b['name'] ?? '').toString()));
    } else if (_sortBy == 'house') {
      list.sort((a, b) => (a['house_number'] ?? '').toString().compareTo((b['house_number'] ?? '').toString()));
    }
    _filteredMembers = list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.purpleDark,
      body: Column(
        children: [
          _buildHeader(),
          _buildHouseFilterChips(),
          _buildSortRow(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.goldPrimary))
                : _filteredMembers.isEmpty
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: AppTheme.purpleCard,
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        onChanged: (_) => setState(() => _applyFilters()),
        decoration: InputDecoration(
          hintText: 'Search name or house...',
          hintStyle: TextStyle(color: AppTheme.textMuted.withOpacity(0.5)),
          prefixIcon: const Icon(Icons.search, color: AppTheme.goldPrimary),
          filled: true,
          fillColor: AppTheme.purpleDark.withOpacity(0.5),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.goldPrimary.withOpacity(0.3))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.goldPrimary.withOpacity(0.3))),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildHouseFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('All', 'all'),
            const SizedBox(width: 6),
            ..._houses.map((h) {
              final houseNumber = h['house_number'] ?? '';
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: _buildFilterChip(houseNumber, houseNumber),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedHouse == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedHouse = value;
          _applyFilters();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.goldPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.goldPrimary.withOpacity(0.5)),
        ),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isSelected ? AppTheme.purpleDark : AppTheme.textMuted)),
      ),
    );
  }

  Widget _buildSortRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          _buildSortChip('Sort by Name', 'name'),
          const SizedBox(width: 8),
          _buildSortChip('Sort by House', 'house'),
          const Spacer(),
          Text('${_filteredMembers.length} members', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildSortChip(String label, String value) {
    final isSelected = _sortBy == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _sortBy = value;
          _applyFilters();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.goldPrimary.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppTheme.goldPrimary : Colors.white24),
        ),
        child: Text(label, style: TextStyle(fontSize: 11, color: isSelected ? AppTheme.goldPrimary : AppTheme.textMuted)),
      ),
    );
  }

  Widget _buildMembersList() {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.goldPrimary,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _filteredMembers.length,
        itemBuilder: (context, index) => _buildMemberCard(_filteredMembers[index]),
      ),
    );
  }

  Widget _buildMemberCard(Map<String, dynamic> member) {
    final name = member['name'] ?? '';
    final houseNumber = member['house_number'] ?? '';
    final memberType = member['member_type'] ?? 'sub';
    final totalTickets = member['total_tickets'] ?? 0;
    final winningTickets = member['winning_tickets'] ?? 0;
    final lastPrizeLevel = member['last_prize_level'];
    final isActive = member['is_active'] == true;

    String prizeText = '';
    if (lastPrizeLevel == 1) prizeText = '🏆 1st';
    else if (lastPrizeLevel == 2) prizeText = '🥈 2nd';
    else if (lastPrizeLevel == 3) prizeText = '🥉 3rd';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.hubItemDecoration,
      child: Row(
        children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(gradient: AppTheme.goldGradient, borderRadius: BorderRadius.circular(12)),
            child: Center(
              child: Text(
                houseNumber.toString().substring(0, houseNumber.toString().length > 3 ? 3 : houseNumber.toString().length),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.purpleDark),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white, decoration: isActive ? null : TextDecoration.lineThrough)),
                    ),
                    if (memberType == 'main')
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: AppTheme.goldPrimary.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                        child: const Text('PAID', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.goldPrimary)),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(houseNumber, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                const SizedBox(height: 2),
                Row(
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
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppTheme.goldPrimary),
            color: AppTheme.purpleCard,
            onSelected: (value) => _handleMemberAction(value, member),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'view', child: Text('View Details', style: TextStyle(color: Colors.white))),
              const PopupMenuItem(value: 'move', child: Text('Move to House', style: TextStyle(color: Colors.white))),
              const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
            ],
          ),
        ],
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
    String targetHouse = member['house_number'] ?? '';
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
                child: Text('${h['house_number']}'),
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
              _loadData();
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
              _loadData();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddMemberDialog() {
    final nameController = TextEditingController();
    final houseController = TextEditingController(text: _selectedHouse != 'all' ? _selectedHouse : '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: const Text('Add Member', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: houseController,
              style: const TextStyle(color: Colors.white),
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: 'House Number',
                labelStyle: const TextStyle(color: Colors.white70),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.white38)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              textCapitalization: TextCapitalization.words,
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
              final name = nameController.text.trim();
              final house = houseController.text.trim().toUpperCase();
              if (name.isEmpty || house.isEmpty) return;
              Navigator.pop(ctx);
              await DatabaseHelper.addGarbaMember(name: name, houseNumber: house);
              _loadData();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
