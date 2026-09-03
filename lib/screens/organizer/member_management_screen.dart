import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../database/database_helper.dart';
import '../../l10n/app_localizations.dart';

class MemberManagementScreen extends StatefulWidget {
  const MemberManagementScreen({super.key});

  @override
  State<MemberManagementScreen> createState() => _MemberManagementScreenState();
}

class _MemberManagementScreenState extends State<MemberManagementScreen> {
  List<Map<String, dynamic>> _members = [];
  bool _isLoading = true;
  String _filter = 'all';
  String _sortBy = 'name';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    setState(() => _isLoading = true);
    _members = await DatabaseHelper.getAllMembers();
    setState(() => _isLoading = false);
  }

  List<Map<String, dynamic>> get _filteredMembers {
    var list = _members;
    if (_filter != 'all') list = list.where((m) => m['user_type'] == _filter).toList();
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
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            _buildHeader(),
            _buildFilterBar(),
            _buildSortRow(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredMembers.isEmpty
                      ? Center(child: Text(AppLocalizations.t('no_members_found'), style: const TextStyle(color: AppTheme.textMuted)))
                      : _buildMembersList(),
            ),
          ],
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            backgroundColor: AppTheme.goldPrimary,
            onPressed: () => _showAddMemberDialog(),
            child: const Icon(Icons.person_add, color: AppTheme.purpleDark),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: AppTheme.purpleCard,
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: AppLocalizations.t('search_name_house'),
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

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          _buildFilterChip(AppLocalizations.t('all'), 'all'),
          const SizedBox(width: 6),
          _buildFilterChip(AppLocalizations.t('users'), 'user'),
          const SizedBox(width: 6),
          _buildFilterChip('Sponsors', 'sponsor'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filter == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _filter = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.goldPrimary : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.goldPrimary.withOpacity(0.5)),
          ),
          child: Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isSelected ? AppTheme.purpleDark : AppTheme.textMuted)),
        ),
      ),
    );
  }

  Widget _buildSortRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          _buildSortChip(AppLocalizations.t('sort_by_name'), 'name'),
          const SizedBox(width: 8),
          _buildSortChip(AppLocalizations.t('sort_by_house'), 'house'),
        ],
      ),
    );
  }

  Widget _buildSortChip(String label, String value) {
    final isSelected = _sortBy == value;
    return GestureDetector(
      onTap: () => setState(() => _sortBy = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.goldPrimary.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? AppTheme.goldPrimary : AppTheme.goldPrimary.withOpacity(0.3)),
        ),
        child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isSelected ? AppTheme.goldPrimary : AppTheme.textMuted)),
      ),
    );
  }

  Widget _buildMembersList() {
    return RefreshIndicator(
      onRefresh: _loadMembers,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _filteredMembers.length,
        itemBuilder: (context, index) => _buildMemberCard(_filteredMembers[index]),
      ),
    );
  }

  Widget _buildMemberCard(Map<String, dynamic> member) {
    final isActive = member['is_active'] ?? true;
    final type = member['user_type'] ?? 'user';
    final typeColor = type == 'sponsor' ? Colors.orange : (type == 'organizer' ? Colors.purple : AppTheme.goldPrimary);

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
                (member['house_number'] ?? '').toString().substring(0, (member['house_number'] ?? '').toString().length > 3 ? 3 : (member['house_number'] ?? '').toString().length),
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
                Text(member['name'] ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                const SizedBox(height: 2),
                Text('${member['house_number']} • ${member['mobile_number'] ?? ''}', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: typeColor.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                        child: Text(type.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: typeColor)),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isActive ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(isActive ? AppLocalizations.t('active') : AppLocalizations.t('inactive'), style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isActive ? Colors.green : Colors.red)),
                      ),
                      const SizedBox(width: 6),
                      Text('₹${(double.tryParse(member['total_paid'].toString()) ?? 0).toStringAsFixed(0)}', style: const TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
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
              PopupMenuItem(value: 'edit', child: Text(AppLocalizations.t('edit_details'), style: const TextStyle(color: Colors.white))),
              PopupMenuItem(value: 'toggle', child: Text(isActive ? AppLocalizations.t('deactivate') : AppLocalizations.t('activate'), style: const TextStyle(color: Colors.white))),
              PopupMenuItem(value: 'delete', child: Text(AppLocalizations.t('delete'), style: const TextStyle(color: AppTheme.redAccent))),
            ],
          ),
        ],
      ),
    );
  }

  void _handleMemberAction(String action, Map<String, dynamic> member) async {
    if (action == 'edit') {
      _showEditMemberDialog(member);
    } else if (action == 'toggle') {
      await DatabaseHelper.updateUserStatus(member['id'], !(member['is_active'] ?? true));
      _loadMembers();
    } else if (action == 'delete') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppTheme.purpleCard,
          title: Text(AppLocalizations.t('delete_member'), style: const TextStyle(color: Colors.white)),
          content: Text(
            'Permanently delete ${member['name']} (${member['house_number']})?\n\nThis cannot be undone.',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppLocalizations.t('cancel'))),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(AppLocalizations.t('delete'), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      if (confirm == true) {
        await DatabaseHelper.deleteMember(member['id']);
        _loadMembers();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${member['name']} deleted permanently'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _showEditMemberDialog(Map<String, dynamic> member) {
    final nameController = TextEditingController(text: member['name'] ?? '');
    final houseController = TextEditingController(text: member['house_number'] ?? '');
    final mobileController = TextEditingController(text: member['mobile_number'] ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.purpleCard,
        title: const Text('Edit Member', style: TextStyle(color: AppTheme.goldPrimary, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Name', prefixIcon: const Icon(Icons.person, color: AppTheme.goldPrimary),
                  labelStyle: const TextStyle(color: AppTheme.textMuted), filled: true,
                  fillColor: AppTheme.purpleDark.withOpacity(0.5),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.goldPrimary.withOpacity(0.3))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.goldPrimary.withOpacity(0.3))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.goldPrimary)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: houseController,
                style: const TextStyle(color: Colors.white),
                textCapitalization: TextCapitalization.characters,
                onChanged: (v) {
                  final upper = v.toUpperCase();
                  if (v != upper) {
                    houseController.value = houseController.value.copyWith(text: upper, selection: TextSelection.collapsed(offset: upper.length));
                  }
                },
                decoration: InputDecoration(
                  labelText: AppLocalizations.t('house_number'), prefixIcon: const Icon(Icons.home, color: AppTheme.goldPrimary),
                  labelStyle: const TextStyle(color: AppTheme.textMuted), filled: true,
                  fillColor: AppTheme.purpleDark.withOpacity(0.5),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.goldPrimary.withOpacity(0.3))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.goldPrimary.withOpacity(0.3))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.goldPrimary)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: mobileController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  counterText: '',
                  labelText: AppLocalizations.t('mobile_number'), prefixIcon: const Icon(Icons.phone, color: AppTheme.goldPrimary),
                  labelStyle: const TextStyle(color: AppTheme.textMuted), filled: true,
                  fillColor: AppTheme.purpleDark.withOpacity(0.5),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.goldPrimary.withOpacity(0.3))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.goldPrimary.withOpacity(0.3))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.goldPrimary)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocalizations.t('cancel'), style: const TextStyle(color: Colors.white70))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.goldPrimary, foregroundColor: AppTheme.purpleDark),
            onPressed: () async {
              if (mobileController.text.trim().isNotEmpty && mobileController.text.trim().length != 10) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.t('enter_valid_10_digit_mobile')), backgroundColor: Colors.red));
                return;
              }
              if (nameController.text.isNotEmpty && houseController.text.isNotEmpty) {
                await DatabaseHelper.updateMember(
                  member['id'],
                  name: nameController.text.trim(),
                  houseNumber: houseController.text.trim(),
                  mobileNumber: mobileController.text.trim(),
                );
                Navigator.pop(ctx);
                _loadMembers();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Member updated! Login credentials changed.'), backgroundColor: Colors.green),
                  );
                }
              }
            },
            child: const Text('SAVE', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAddMemberDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.purpleCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => _AddMemberSheet(onAdded: _loadMembers),
    );
  }
}

class _AddMemberSheet extends StatefulWidget {
  final VoidCallback onAdded;
  const _AddMemberSheet({required this.onAdded});

  @override
  State<_AddMemberSheet> createState() => _AddMemberSheetState();
}

class _AddMemberSheetState extends State<_AddMemberSheet> {
  final _formKey = GlobalKey<FormState>();
  final _houseController = TextEditingController();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  String _userType = 'user';
  bool _isLoading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_mobileController.text.trim().length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.t('enter_valid_10_digit_mobile')), backgroundColor: Colors.red));
      return;
    }
    setState(() => _isLoading = true);
    try {
      await DatabaseHelper.registerUser(
        houseNumber: _houseController.text.trim().toUpperCase(),
        name: _nameController.text.trim(),
        mobileNumber: _mobileController.text.trim(),
        userType: _userType,
      );
      widget.onAdded();
      if (mounted) Navigator.pop(context);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.t('member_added')), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.redAccent));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(AppLocalizations.t('add_member'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.goldPrimary)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: RadioListTile<String>(title: Text(AppLocalizations.t('resident'), style: const TextStyle(color: Colors.white, fontSize: 12)), value: 'user', groupValue: _userType, onChanged: (v) => setState(() => _userType = v!), activeColor: AppTheme.goldPrimary, contentPadding: EdgeInsets.zero)),
                Expanded(child: RadioListTile<String>(title: Text(AppLocalizations.t('sponsor'), style: const TextStyle(color: Colors.white, fontSize: 12)), value: 'sponsor', groupValue: _userType, onChanged: (v) => setState(() => _userType = v!), activeColor: AppTheme.goldPrimary, contentPadding: EdgeInsets.zero)),
              ],
            ),
            _buildField(controller: _houseController, label: AppLocalizations.t('house_number'), icon: Icons.home, textCapitalization: TextCapitalization.characters, onChanged: (v) { final upper = v.toUpperCase(); if (v != upper) { _houseController.value = _houseController.value.copyWith(text: upper, selection: TextSelection.collapsed(offset: upper.length)); } }),
            const SizedBox(height: 12),
            _buildField(controller: _nameController, label: AppLocalizations.t('full_name'), icon: Icons.person),
            const SizedBox(height: 12),
            _buildField(controller: _mobileController, label: AppLocalizations.t('mobile_number'), icon: Icons.phone, keyboardType: TextInputType.phone, inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)]),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.goldPrimary, foregroundColor: AppTheme.purpleDark, padding: const EdgeInsets.symmetric(vertical: 16)),
              child: _isLoading ? const CircularProgressIndicator(color: AppTheme.purpleDark) : Text(AppLocalizations.t('add_member_btn'), style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildField({required TextEditingController controller, required String label, required IconData icon, TextInputType keyboardType = TextInputType.text, TextCapitalization textCapitalization = TextCapitalization.none, List<TextInputFormatter>? inputFormatters, ValueChanged<String>? onChanged}) {
    return TextFormField(
      controller: controller, keyboardType: keyboardType, style: const TextStyle(color: Colors.white),
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label, prefixIcon: Icon(icon, color: AppTheme.goldPrimary),
        labelStyle: const TextStyle(color: AppTheme.textMuted), filled: true,
        fillColor: AppTheme.purpleDark.withOpacity(0.5),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.goldPrimary.withOpacity(0.3))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.goldPrimary.withOpacity(0.3))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.goldPrimary)),
      ),
      validator: (v) => v == null || v.isEmpty ? AppLocalizations.t('required') : null,
    );
  }
}
