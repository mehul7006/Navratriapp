import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../database/database_helper.dart';
import '../../l10n/app_localizations.dart';

class GiftManagementScreen extends StatefulWidget {
  const GiftManagementScreen({super.key});

  @override
  State<GiftManagementScreen> createState() => _GiftManagementScreenState();
}

class _GiftManagementScreenState extends State<GiftManagementScreen> {
  List<Map<String, dynamic>> _gifts = [];
  List<Map<String, dynamic>> _assignments = [];
  bool _isLoading = true;
  int _selectedDay = 1;
  bool _showAssignments = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    _gifts = await DatabaseHelper.getGifts(dayNumber: _selectedDay);
    _assignments = await DatabaseHelper.getGiftAssignments(dayNumber: _selectedDay);
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.purpleDark,
      appBar: AppBar(
        title: Text(AppLocalizations.t('gifts_prizes'), style: const TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.purpleDeep,
        iconTheme: const IconThemeData(color: AppTheme.goldPrimary),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          _buildDaySelector(),
          _buildTabBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _showAssignments ? _buildAssignmentsList() : _buildGiftsList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.goldPrimary,
        onPressed: () => _showAddGiftDialog(),
        child: const Icon(Icons.add, color: AppTheme.purpleDark),
      ),
    );
  }

  Widget _buildDaySelector() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 9,
        itemBuilder: (context, index) {
          final day = index + 1;
          final isSelected = _selectedDay == day;
          return GestureDetector(
            onTap: () { setState(() => _selectedDay = day); _loadData(); },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.goldPrimary : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.goldPrimary.withOpacity(0.5)),
              ),
              child: Text('Day $day', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isSelected ? AppTheme.purpleDark : AppTheme.textMuted)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _showAssignments = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: !_showAssignments ? AppTheme.goldPrimary : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.goldPrimary.withOpacity(0.5)),
                ),
                child: Text('Gifts (${_gifts.length})', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: !_showAssignments ? AppTheme.purpleDark : AppTheme.textMuted)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _showAssignments = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _showAssignments ? AppTheme.goldPrimary : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.goldPrimary.withOpacity(0.5)),
                ),
                child: Text('Assigned (${_assignments.length})', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _showAssignments ? AppTheme.purpleDark : AppTheme.textMuted)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGiftsList() {
    if (_gifts.isEmpty) return Center(child: Text(AppLocalizations.t('no_gifts_day'), style: TextStyle(color: AppTheme.textMuted)));
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: _gifts.length,
      itemBuilder: (context, index) => _buildGiftCard(_gifts[index]),
    );
  }

  Widget _buildGiftCard(Map<String, dynamic> gift) {
    final type = gift['gift_type'] ?? 'daily';
    final typeColor = type == 'sponsor' ? Colors.orange : Colors.purple;
    final remaining = (gift['quantity'] ?? 0) - (gift['quantity_assigned'] ?? 0);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.hubItemDecoration,
      child: Row(
        children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
              color: typeColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.card_giftcard, color: typeColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(gift['name'] ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                const SizedBox(height: 2),
                Text(gift['description'] ?? '', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: typeColor.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                      child: Text(type.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: typeColor)),
                    ),
                    const SizedBox(width: 8),
                    Text('$remaining/${gift['quantity']} left', style: TextStyle(fontSize: 12, color: remaining > 0 ? Colors.green : AppTheme.redAccent)),
                    if (gift['sponsor_name'] != null) ...[
                      const SizedBox(width: 8),
                      Text('by ${gift['sponsor_name']}', style: const TextStyle(fontSize: 11, color: AppTheme.cyanAccent)),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentsList() {
    if (_assignments.isEmpty) return Center(child: Text(AppLocalizations.t('no_gifts_assigned'), style: TextStyle(color: AppTheme.textMuted)));
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: _assignments.length,
      itemBuilder: (context, index) => _buildAssignmentCard(_assignments[index]),
    );
  }

  Widget _buildAssignmentCard(Map<String, dynamic> assignment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.hubItemDecoration,
      child: Row(
        children: [
          Container(
            width: 50, height: 50,
            decoration: const BoxDecoration(gradient: AppTheme.goldGradient, borderRadius: BorderRadius.all(Radius.circular(12))),
            child: Center(
              child: Text((assignment['house_number'] ?? '').toString().substring(0, 3), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.purpleDark)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(assignment['user_name'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                const SizedBox(height: 2),
                Text('${assignment['gift_name']}', style: const TextStyle(fontSize: 12, color: AppTheme.goldPrimary)),
                const SizedBox(height: 2),
                Text(assignment['assigned_at'] ?? '', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
              ],
            ),
          ),
          const Icon(Icons.check_circle, color: Colors.green, size: 24),
        ],
      ),
    );
  }

  void _showAssignGiftDialog(Map<String, dynamic> gift) {
    List<Map<String, dynamic>> members = [];
    String searchQuery = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.purpleCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return FutureBuilder<List<Map<String, dynamic>>>(
            future: DatabaseHelper.getAllMembers(),
            builder: (ctx, snapshot) {
              if (!snapshot.hasData) return const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator()));
              members = snapshot.data!;
              if (searchQuery.isNotEmpty) {
                members = members.where((m) =>
                  (m['name']?.toString().toLowerCase().contains(searchQuery.toLowerCase()) ?? false) ||
                  (m['house_number']?.toString().toLowerCase().contains(searchQuery.toLowerCase()) ?? false)
                ).toList();
              }

              return Padding(
                padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Assign "${gift['name']}"', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.goldPrimary)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        style: const TextStyle(color: Colors.white),
                        onChanged: (v) => setModalState(() => searchQuery = v),
                        decoration: InputDecoration(
                          hintText: AppLocalizations.t('search_member'), prefixIcon: const Icon(Icons.search, color: AppTheme.goldPrimary),
                          filled: true, fillColor: AppTheme.purpleDark.withOpacity(0.5),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.goldPrimary.withOpacity(0.3))),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 300,
                      child: ListView.builder(
                        itemCount: members.length,
                        itemBuilder: (ctx, index) {
                          final m = members[index];
                          return ListTile(
                            leading: Container(
                              width: 40, height: 40,
                              decoration: const BoxDecoration(gradient: AppTheme.goldGradient, borderRadius: BorderRadius.all(Radius.circular(10))),
                              child: Center(child: Text((m['house_number'] ?? '').toString().substring(0, 3), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.purpleDark))),
                            ),
                            title: Text(m['name'] ?? '', style: const TextStyle(color: Colors.white)),
                            subtitle: Text(m['house_number'] ?? '', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                            trailing: const Icon(Icons.arrow_forward_ios, color: AppTheme.goldPrimary, size: 14),
                            onTap: () async {
                              await DatabaseHelper.assignGift(
                                giftId: gift['id'], userId: m['id'],
                                houseNumber: m['house_number'], dayNumber: _selectedDay,
                              );
                              Navigator.pop(ctx);
                              _loadData();
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddGiftDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final qtyController = TextEditingController(text: '1');
    String giftType = 'daily';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.purpleCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(AppLocalizations.t('add_gift'), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.goldPrimary)),
              const SizedBox(height: 16),
              _buildField(controller: nameController, label: AppLocalizations.t('gift_name'), icon: Icons.card_giftcard),
              const SizedBox(height: 12),
              _buildField(controller: descController, label: AppLocalizations.t('description'), icon: Icons.description),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: RadioListTile<String>(title: Text(AppLocalizations.t('daily'), style: TextStyle(color: Colors.white, fontSize: 12)), value: 'daily', groupValue: giftType, onChanged: (v) => setModalState(() => giftType = v!), activeColor: AppTheme.goldPrimary, contentPadding: EdgeInsets.zero)),
                  Expanded(child: RadioListTile<String>(title: const Text('Sponsor', style: TextStyle(color: Colors.white, fontSize: 12)), value: 'sponsor', groupValue: giftType, onChanged: (v) => setModalState(() => giftType = v!), activeColor: AppTheme.goldPrimary, contentPadding: EdgeInsets.zero)),
                ],
              ),
              _buildField(controller: qtyController, label: AppLocalizations.t('quantity'), icon: Icons.inventory, keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (nameController.text.isEmpty) return;
                  await DatabaseHelper.addGift(
                    name: nameController.text.trim(),
                    description: descController.text.trim(),
                    giftType: giftType, dayNumber: _selectedDay,
                    quantity: int.tryParse(qtyController.text) ?? 1,
                  );
                  Navigator.pop(ctx);
                  _loadData();
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.goldPrimary, foregroundColor: AppTheme.purpleDark, padding: const EdgeInsets.symmetric(vertical: 16)),
                child: Text(AppLocalizations.t('add_gift_btn'), style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 20),
            ],
          ),
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
    );
  }
}
