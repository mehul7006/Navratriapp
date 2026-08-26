import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../database/database_helper.dart';

class MemberManagementScreen extends StatefulWidget {
  const MemberManagementScreen({super.key});

  @override
  State<MemberManagementScreen> createState() => _MemberManagementScreenState();
}

class _MemberManagementScreenState extends State<MemberManagementScreen> {
  List<Map<String, dynamic>> _members = [];
  bool _isLoading = true;
  String _filter = 'all';
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
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.purpleDark,
      body: Column(
        children: [
          _buildHeader(),
          _buildFilterBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredMembers.isEmpty
                    ? const Center(child: Text('No members found', style: TextStyle(color: AppTheme.textMuted)))
                    : _buildMembersList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.goldPrimary,
        onPressed: () => _showAddMemberDialog(),
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
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: 'Search by name or house number...',
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
          _buildFilterChip('All', 'all'),
          const SizedBox(width: 6),
          _buildFilterChip('Users', 'user'),
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

  Widget _buildMembersList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: _filteredMembers.length,
      itemBuilder: (context, index) => _buildMemberCard(_filteredMembers[index]),
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
                      child: Text(isActive ? 'ACTIVE' : 'INACTIVE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isActive ? Colors.green : Colors.red)),
                    ),
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
              const PopupMenuItem(value: 'edit', child: Text('Edit Details', style: TextStyle(color: Colors.white))),
              PopupMenuItem(value: 'toggle', child: Text(isActive ? 'Deactivate' : 'Activate', style: const TextStyle(color: Colors.white))),
              const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppTheme.redAccent))),
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
          title: const Text('Delete Member?', style: TextStyle(color: Colors.white)),
          content: Text(
            'Permanently delete ${member['name']} (${member['house_number']})?\n\nThis cannot be undone.',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('DELETE', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
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
                decoration: InputDecoration(
                  labelText: 'House Number', prefixIcon: const Icon(Icons.home, color: AppTheme.goldPrimary),
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
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Mobile Number', prefixIcon: const Icon(Icons.phone, color: AppTheme.goldPrimary),
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
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.white70))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.goldPrimary, foregroundColor: AppTheme.purpleDark),
            onPressed: () async {
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
    setState(() => _isLoading = true);
    try {
      await DatabaseHelper.registerUser(
        houseNumber: _houseController.text.trim(),
        name: _nameController.text.trim(),
        mobileNumber: _mobileController.text.trim(),
        userType: _userType,
      );
      widget.onAdded();
      if (mounted) Navigator.pop(context);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Member added!'), backgroundColor: Colors.green));
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
            const Text('Add Member', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.goldPrimary)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: RadioListTile<String>(title: const Text('Resident', style: TextStyle(color: Colors.white, fontSize: 12)), value: 'user', groupValue: _userType, onChanged: (v) => setState(() => _userType = v!), activeColor: AppTheme.goldPrimary, contentPadding: EdgeInsets.zero)),
                Expanded(child: RadioListTile<String>(title: const Text('Sponsor', style: TextStyle(color: Colors.white, fontSize: 12)), value: 'sponsor', groupValue: _userType, onChanged: (v) => setState(() => _userType = v!), activeColor: AppTheme.goldPrimary, contentPadding: EdgeInsets.zero)),
              ],
            ),
            _buildField(controller: _houseController, label: 'House Number', icon: Icons.home),
            const SizedBox(height: 12),
            _buildField(controller: _nameController, label: 'Full Name', icon: Icons.person),
            const SizedBox(height: 12),
            _buildField(controller: _mobileController, label: 'Mobile Number', icon: Icons.phone, keyboardType: TextInputType.phone),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.goldPrimary, foregroundColor: AppTheme.purpleDark, padding: const EdgeInsets.symmetric(vertical: 16)),
              child: _isLoading ? const CircularProgressIndicator(color: AppTheme.purpleDark) : const Text('ADD MEMBER', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildField({required TextEditingController controller, required String label, required IconData icon, TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller, keyboardType: keyboardType, style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label, prefixIcon: Icon(icon, color: AppTheme.goldPrimary),
        labelStyle: const TextStyle(color: AppTheme.textMuted), filled: true,
        fillColor: AppTheme.purpleDark.withOpacity(0.5),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.goldPrimary.withOpacity(0.3))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.goldPrimary.withOpacity(0.3))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.goldPrimary)),
      ),
      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
    );
  }
}
