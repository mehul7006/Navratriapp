import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../database/database_helper.dart';
import '../../l10n/app_localizations.dart';

class ExpenseManagementScreen extends StatefulWidget {
  const ExpenseManagementScreen({super.key});

  @override
  State<ExpenseManagementScreen> createState() => _ExpenseManagementScreenState();
}

class _ExpenseManagementScreenState extends State<ExpenseManagementScreen> {
  List<Map<String, dynamic>> _expenses = [];
  List<Map<String, dynamic>> _deletedExpenses = [];
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;
  String _selectedCategory = 'all';
  String _selectedPaidBy = 'all';
  String _selectedTab = 'active';
  String _sortBy = 'date_desc';
  DateTime? _dateFrom;
  DateTime? _dateTo;
  final _searchController = TextEditingController();

  @override
  void initState() { super.initState(); _loadData(); }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final expenses = await DatabaseHelper.getExpenses();
      final deleted = await DatabaseHelper.getDeletedExpenses();
      final cats = await DatabaseHelper.query("SELECT * FROM expense_categories WHERE is_active = TRUE ORDER BY name");
      setState(() {
        _expenses = expenses;
        _deletedExpenses = deleted;
        _categories = cats.map((row) => Map<String, dynamic>.from(row)).toList();
        _isLoading = false;
      });
    } catch (e) { setState(() => _isLoading = false); }
  }

  List<Map<String, dynamic>> get _filteredExpenses {
    var list = _expenses;
    if (_selectedCategory != 'all') list = list.where((e) => e['category_id'].toString() == _selectedCategory).toList();
    if (_selectedPaidBy != 'all') list = list.where((e) => (e['paid_by'] ?? 'organizer') == _selectedPaidBy).toList();
    final search = _searchController.text.toLowerCase();
    if (search.isNotEmpty) {
      list = list.where((e) =>
        (e['item_name']?.toString().toLowerCase().contains(search) ?? false) ||
        (e['paid_to']?.toString().toLowerCase().contains(search) ?? false) ||
        (e['category_name']?.toString().toLowerCase().contains(search) ?? false)
      ).toList();
    }
    if (_dateFrom != null) {
      list = list.where((e) {
        final d = e['expense_date']?.toString() ?? e['created_at']?.toString() ?? '';
        if (d.isEmpty) return false;
        try { return DateTime.parse(d).isAfter(_dateFrom!.subtract(const Duration(days: 1))); } catch (_) { return false; }
      }).toList();
    }
    if (_dateTo != null) {
      list = list.where((e) {
        final d = e['expense_date']?.toString() ?? e['created_at']?.toString() ?? '';
        if (d.isEmpty) return false;
        try { return DateTime.parse(d).isBefore(_dateTo!.add(const Duration(days: 1))); } catch (_) { return false; }
      }).toList();
    }
    list.sort((a, b) {
      switch (_sortBy) {
        case 'name_asc': return (a['item_name'] ?? '').toString().compareTo((b['item_name'] ?? '').toString());
        case 'name_desc': return (b['item_name'] ?? '').toString().compareTo((a['item_name'] ?? '').toString());
        case 'amount_asc': return (double.tryParse(a['amount'].toString()) ?? 0).compareTo(double.tryParse(b['amount'].toString()) ?? 0);
        case 'amount_desc': return (double.tryParse(b['amount'].toString()) ?? 0).compareTo(double.tryParse(a['amount'].toString()) ?? 0);
        case 'date_asc': return (a['expense_date'] ?? a['created_at'] ?? '').toString().compareTo((b['expense_date'] ?? b['created_at'] ?? '').toString());
        case 'date_desc':
        default: return (b['expense_date'] ?? b['created_at'] ?? '').toString().compareTo((a['expense_date'] ?? a['created_at'] ?? '').toString());
      }
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final isDeletedTab = _selectedTab == 'deleted';
    final filtered = isDeletedTab ? _deletedExpenses : _filteredExpenses;
    double totalOrg = 0, totalSponsor = 0;
    for (var e in _filteredExpenses) {
      final amt = double.tryParse(e['amount'].toString()) ?? 0;
      if ((e['paid_by'] ?? 'organizer') == 'organizer') totalOrg += amt;
      else totalSponsor += amt;
    }

    return Scaffold(
      backgroundColor: AppTheme.purpleDark,
      appBar: AppBar(
        title: Text(isDeletedTab ? 'Deleted Expenses' : AppLocalizations.t('expenses')),
        backgroundColor: AppTheme.purpleDeep,
        foregroundColor: AppTheme.goldPrimary,
        actions: [
          if (!isDeletedTab) ...[
            IconButton(icon: const Icon(Icons.sort), onPressed: _showSortDialog),
            IconButton(icon: const Icon(Icons.date_range), onPressed: _showDateRangeDialog),
            IconButton(icon: const Icon(Icons.add), onPressed: () => _showAddExpenseDialog()),
          ],
        ],
      ),
      body: Column(
        children: [
          _buildTabToggle(),
          if (!isDeletedTab) _buildSearchBar(),
          if (!isDeletedTab) _buildFilterRow(),
          if (!isDeletedTab) _buildStatsRow(totalOrg, totalSponsor),
          if (isDeletedTab)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.15), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.red.withOpacity(0.3))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.delete, color: Colors.red, size: 16),
                  const SizedBox(width: 6),
                  Text('${_deletedExpenses.length} deleted expenses', style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.goldPrimary))
                : filtered.isEmpty
                    ? Center(child: Text(isDeletedTab ? 'No deleted expenses' : AppLocalizations.t('no_expenses_recorded'), style: const TextStyle(color: AppTheme.textMuted)))
                    : _buildExpensesList(filtered),
          ),
        ],
      ),
    );
  }

  Widget _buildTabToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = 'active'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _selectedTab == 'active' ? AppTheme.goldPrimary : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppTheme.goldPrimary.withOpacity(0.5)),
                ),
                child: Text(AppLocalizations.t('active_tab'), textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _selectedTab == 'active' ? AppTheme.purpleDark : AppTheme.textMuted)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = 'deleted'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _selectedTab == 'deleted' ? Colors.red : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _selectedTab == 'deleted' ? Colors.red : Colors.white24),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.delete, size: 12, color: Colors.white70),
                    const SizedBox(width: 4),
                    Text('Deleted (${_deletedExpenses.length})', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _selectedTab == 'deleted' ? Colors.white : AppTheme.textMuted)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(10),
      color: AppTheme.purpleCard,
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: AppLocalizations.t('search_expenses'),
          hintStyle: TextStyle(color: AppTheme.textMuted.withOpacity(0.5)),
          prefixIcon: const Icon(Icons.search, color: AppTheme.goldPrimary),
          filled: true, fillColor: AppTheme.purpleDark.withOpacity(0.5),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.goldPrimary.withOpacity(0.3))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.goldPrimary.withOpacity(0.3))),
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }

  Widget _buildFilterRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Column(
        children: [
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _catChip(AppLocalizations.t('all'), 'all'),
                ..._categories.map((c) => _catChip(c['name'] ?? '', c['id'].toString())),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _paidByChip(AppLocalizations.t('all'), 'all'), const SizedBox(width: 6),
              _paidByChip(AppLocalizations.t('organizer_label'), 'organizer'), const SizedBox(width: 6),
              _paidByChip(AppLocalizations.t('sponsor_label'), 'sponsor'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _catChip(String label, String value) {
    final sel = _selectedCategory == value;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      child: GestureDetector(
        onTap: () => setState(() => _selectedCategory = value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: sel ? AppTheme.goldPrimary : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: sel ? AppTheme.goldPrimary : AppTheme.goldPrimary.withOpacity(0.3)),
          ),
          child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: sel ? AppTheme.purpleDark : AppTheme.textMuted)),
        ),
      ),
    );
  }

  Widget _paidByChip(String label, String value) {
    final sel = _selectedPaidBy == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPaidBy = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: sel ? (value == 'sponsor' ? Colors.purple : AppTheme.goldPrimary) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: sel ? (value == 'sponsor' ? Colors.purple : AppTheme.goldPrimary) : Colors.white24),
          ),
          child: Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: sel ? Colors.white : AppTheme.textMuted)),
        ),
      ),
    );
  }

  Widget _buildStatsRow(double totalOrg, double totalSponsor) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppTheme.redAccent.withOpacity(0.7), AppTheme.purpleCard]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.goldPrimary),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem(AppLocalizations.t('organizer_label'), '₹${totalOrg.toStringAsFixed(0)}', Colors.red),
          Container(height: 30, width: 1, color: AppTheme.goldPrimary.withOpacity(0.3)),
          _statItem(AppLocalizations.t('sponsor_label'), '₹${totalSponsor.toStringAsFixed(0)}', Colors.purple),
          Container(height: 30, width: 1, color: AppTheme.goldPrimary.withOpacity(0.3)),
          _statItem(AppLocalizations.t('total'), '₹${(totalOrg + totalSponsor).toStringAsFixed(0)}', Colors.orange),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Column(children: [
      Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(fontSize: 9, color: AppTheme.textMuted)),
    ]);
  }

  Widget _buildExpensesList(List<Map<String, dynamic>> list) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: list.length,
        itemBuilder: (context, i) => _buildExpenseCard(list[i]),
      ),
    );
  }

  Widget _buildExpenseCard(Map<String, dynamic> e) {
    final paidBy = e['paid_by'] ?? 'organizer';
    final isSponsor = paidBy == 'sponsor';
    final isDeleted = e['is_deleted'] == true;
    final dateStr = e['expense_date']?.toString() ?? '';
    String formattedDate = '';
    if (dateStr.isNotEmpty) {
      try { formattedDate = DateFormat('dd MMM yyyy').format(DateTime.parse(dateStr)); } catch (_) { formattedDate = dateStr; }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDeleted ? Colors.red.withOpacity(0.1) : null,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDeleted ? Colors.red.withOpacity(0.4) : AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: isDeleted ? Colors.red.withOpacity(0.2) : isSponsor ? Colors.purple.withOpacity(0.2) : AppTheme.redAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(isDeleted ? Icons.delete : isSponsor ? Icons.business : Icons.receipt, color: isDeleted ? Colors.red : isSponsor ? Colors.purple : AppTheme.redAccent, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e['item_name'] ?? '', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDeleted ? Colors.red : Colors.white)),
                    const SizedBox(height: 2),
                    Text('${e['category_name'] ?? ''} • Paid to: ${e['paid_to'] ?? 'N/A'}', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                    if (formattedDate.isNotEmpty) Text(formattedDate, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('₹${e['amount']}', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isSponsor ? Colors.purple : Colors.red)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: (isSponsor ? Colors.purple : Colors.orange).withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                    child: Text(isSponsor ? 'SPONSOR' : 'ORG', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: isSponsor ? Colors.purple : Colors.orange)),
                  ),
                ],
              ),
            ],
          ),
          if (e['notes']?.toString().isNotEmpty == true) ...[
            const SizedBox(height: 6),
            Text('Note: ${e['notes']}', style: const TextStyle(fontSize: 10, color: Colors.white54, fontStyle: FontStyle.italic)),
          ],
          if (isDeleted && e['deleted_reason']?.toString().isNotEmpty == true) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.red, size: 12),
                  const SizedBox(width: 4),
                  Expanded(child: Text('Deleted: ${e['deleted_reason']}', style: const TextStyle(fontSize: 10, color: Colors.red))),
                ],
              ),
            ),
          ],
          if (!isDeleted) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                _actionBtn(AppLocalizations.t('edit'), AppTheme.goldPrimary, Icons.edit, () => _showEditExpenseDialog(e)),
                const SizedBox(width: 6),
                _actionBtn(AppLocalizations.t('delete'), Colors.red, Icons.delete_outline, () => _showDeleteExpenseDialog(e)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _actionBtn(String label, Color color, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(6), border: Border.all(color: color.withOpacity(0.4))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: color)),
        ]),
      ),
    );
  }

  void _showEditExpenseDialog(Map<String, dynamic> e) {
    final itemCtrl = TextEditingController(text: e['item_name'] ?? '');
    final amountCtrl = TextEditingController(text: e['amount']?.toString() ?? '');
    final paidToCtrl = TextEditingController(text: e['paid_to'] ?? '');
    final notesCtrl = TextEditingController(text: e['notes'] ?? '');
    int? catId = e['category_id'];
    String paidBy = e['paid_by'] ?? 'organizer';
    DateTime expDate = DateTime.now();
    try { expDate = DateTime.parse(e['expense_date'] ?? DateTime.now().toIso8601String()); } catch (_) {}

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.purpleCard,
          title: Text(AppLocalizations.t('edit_expense'), style: const TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  value: catId,
                  dropdownColor: AppTheme.purpleDeep,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(labelText: AppLocalizations.t('category'), labelStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                  items: _categories.map((c) => DropdownMenuItem(value: c['id'] as int, child: Text('${c['name'] ?? ''}', style: const TextStyle(fontSize: 13)))).toList(),
                  onChanged: (v) => setDialogState(() => catId = v),
                ),
                const SizedBox(height: 8),
                _dlgField(itemCtrl, AppLocalizations.t('item_name'), Icons.inventory),
                const SizedBox(height: 8),
                _dlgField(amountCtrl, AppLocalizations.t('amount'), Icons.attach_money, TextInputType.number),
                const SizedBox(height: 8),
                _dlgField(paidToCtrl, AppLocalizations.t('paid_to'), Icons.store),
                const SizedBox(height: 8),
                _dlgField(notesCtrl, AppLocalizations.t('notes_optional'), Icons.notes),
                const SizedBox(height: 8),
                ListTile(
                  dense: true,
                  tileColor: AppTheme.purpleDark,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  title: Text('Date: ${DateFormat('dd MMM yyyy').format(expDate)}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                  trailing: const Icon(Icons.calendar_today, color: AppTheme.goldPrimary, size: 16),
                  onTap: () async {
                    final d = await showDatePicker(context: context, initialDate: expDate, firstDate: DateTime(2024), lastDate: DateTime.now());
                    if (d != null) setDialogState(() => expDate = d);
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: RadioListTile<String>(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: Text(AppLocalizations.t('organizer_label'), style: const TextStyle(color: Colors.white, fontSize: 11)),
                      value: 'organizer', groupValue: paidBy,
                      onChanged: (v) => setDialogState(() => paidBy = v!),
                      activeColor: AppTheme.goldPrimary,
                    )),
                    Expanded(child: RadioListTile<String>(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: Text(AppLocalizations.t('sponsor_label'), style: const TextStyle(color: Colors.white, fontSize: 11)),
                      value: 'sponsor', groupValue: paidBy,
                      onChanged: (v) => setDialogState(() => paidBy = v!),
                      activeColor: Colors.purple,
                    )),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocalizations.t('cancel'))),
            TextButton(
              onPressed: () async {
                if (paidToCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Paid To is required'), backgroundColor: AppTheme.redAccent));
                  return;
                }
                await DatabaseHelper.updateExpense(
                  e['id'],
                  categoryId: catId,
                  itemName: itemCtrl.text.isNotEmpty ? itemCtrl.text : null,
                  amount: double.tryParse(amountCtrl.text),
                  paidTo: paidToCtrl.text,
                  notes: notesCtrl.text.isNotEmpty ? notesCtrl.text : null,
                  expenseDate: expDate.toIso8601String(),
                  paidBy: paidBy,
                );
                Navigator.pop(ctx);
                _loadData();
              },
              child: Text(AppLocalizations.t('save'), style: const TextStyle(color: AppTheme.goldPrimary)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dlgField(TextEditingController ctrl, String label, IconData icon, [TextInputType? kb]) {
    return TextField(
      controller: ctrl, keyboardType: kb,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        labelText: label, labelStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
        prefixIcon: Icon(icon, color: AppTheme.goldPrimary, size: 16), isDense: true,
        filled: true, fillColor: AppTheme.purpleDark,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppTheme.goldPrimary.withOpacity(0.3))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppTheme.goldPrimary.withOpacity(0.3))),
      ),
    );
  }

  void _showDeleteExpenseDialog(Map<String, dynamic> e) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.cardBg,
          title: Text(AppLocalizations.t('delete_expense'), style: const TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Delete expense "${e['item_name']}" (₹${e['amount']})?',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 12),
              Text(AppLocalizations.t('reason_required'), style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextField(
                controller: reasonController,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: AppLocalizations.t('enter_reason_deletion'),
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
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocalizations.t('cancel'), style: const TextStyle(color: Colors.white70))),
            TextButton(
              onPressed: reasonController.text.trim().isEmpty
                  ? null
                  : () async {
                      await DatabaseHelper.deleteExpense(e['id'], reasonController.text.trim());
                      Navigator.pop(ctx);
                      _loadData();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(AppLocalizations.t('expense_deleted')), backgroundColor: Colors.red),
                        );
                      }
                    },
              child: Text(AppLocalizations.t('delete'), style: TextStyle(color: reasonController.text.trim().isEmpty ? Colors.white38 : Colors.red)),
            ),
          ],
        ),
      ),
    );
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.purpleCard,
        title: Text(AppLocalizations.t('sort_by'), style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _sortOpt(AppLocalizations.t('date_newest'), 'date_desc'), _sortOpt(AppLocalizations.t('date_oldest'), 'date_asc'),
            _sortOpt(AppLocalizations.t('name_az'), 'name_asc'), _sortOpt(AppLocalizations.t('name_za'), 'name_desc'),
            _sortOpt('Amount High→Low', 'amount_desc'), _sortOpt('Amount Low→High', 'amount_asc'),
          ],
        ),
      ),
    );
  }

  Widget _sortOpt(String label, String value) {
    return RadioListTile<String>(
      dense: true, value: value, groupValue: _sortBy,
      onChanged: (v) { setState(() => _sortBy = v!); Navigator.pop(context); },
      title: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      activeColor: AppTheme.goldPrimary, contentPadding: EdgeInsets.zero,
    );
  }

  void _showDateRangeDialog() async {
    final from = await showDatePicker(context: context, initialDate: _dateFrom ?? DateTime.now().subtract(const Duration(days: 30)), firstDate: DateTime(2024), lastDate: DateTime.now());
    if (from == null) return;
    final to = await showDatePicker(context: context, initialDate: _dateTo ?? DateTime.now(), firstDate: from, lastDate: DateTime.now().add(const Duration(days: 1)));
    setState(() { _dateFrom = from; _dateTo = to; });
  }

  void _showAddExpenseDialog() {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: AppTheme.purpleCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => _AddExpenseSheet(categories: _categories, onExpenseAdded: _loadData),
    );
  }
}

class _AddExpenseSheet extends StatefulWidget {
  final List<Map<String, dynamic>> categories;
  final VoidCallback onExpenseAdded;
  const _AddExpenseSheet({required this.categories, required this.onExpenseAdded});
  @override
  State<_AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<_AddExpenseSheet> {
  final _formKey = GlobalKey<FormState>();
  final _itemController = TextEditingController();
  final _amountController = TextEditingController();
  final _paidToController = TextEditingController();
  final _notesController = TextEditingController();
  int? _selectedCategoryId;
  DateTime _expenseDate = DateTime.now();
  String _paidBy = 'organizer';
  bool _isLoading = false;

  Future<void> _submitExpense() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select category'), backgroundColor: AppTheme.redAccent)); return; }
    if (_paidToController.text.trim().isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Paid To is required'), backgroundColor: AppTheme.redAccent)); return; }
    setState(() => _isLoading = true);
    try {
      await DatabaseHelper.execute(
        'INSERT INTO expenses (category_id, item_name, amount, paid_to, expense_date, notes, paid_by) VALUES (@catId, @item, @amount, @paidTo, @date, @notes, @paidBy)',
        substitutionValues: {
          'catId': _selectedCategoryId,
          'item': _itemController.text.trim(),
          'amount': double.parse(_amountController.text),
          'paidTo': _paidToController.text.trim(),
          'date': _expenseDate.toIso8601String(),
          'notes': _notesController.text.isNotEmpty ? _notesController.text.trim() : null,
          'paidBy': _paidBy,
        },
      );
      widget.onExpenseAdded();
      if (mounted) Navigator.pop(context);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.t('expense_added')), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.redAccent));
    } finally { setState(() => _isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(AppLocalizations.t('add_expense'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.goldPrimary)),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _selectedCategoryId,
                decoration: InputDecoration(
                  labelText: 'Category *', labelStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                  filled: true, fillColor: AppTheme.purpleDark.withOpacity(0.5),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppTheme.goldPrimary.withOpacity(0.3))),
                ),
                dropdownColor: AppTheme.purpleCard,
                style: const TextStyle(color: Colors.white),
                items: widget.categories.map((c) => DropdownMenuItem(value: c['id'] as int, child: Text('${c['name'] ?? ''}'))).toList(),
                onChanged: (v) => setState(() => _selectedCategoryId = v),
                validator: (v) => v == null ? 'Select category' : null,
              ),
              const SizedBox(height: 12),
              _buildField(_itemController, AppLocalizations.t('item_name'), Icons.inventory),
              const SizedBox(height: 12),
              _buildField(_amountController, AppLocalizations.t('amount_rs'), Icons.attach_money, TextInputType.number),
              const SizedBox(height: 12),
              _buildField(_paidToController, AppLocalizations.t('paid_to'), Icons.store),
              const SizedBox(height: 12),
              _buildField(_notesController, AppLocalizations.t('notes_optional'), Icons.notes),
              const SizedBox(height: 12),
              ListTile(
                title: const Text('Expense Date', style: TextStyle(color: Colors.white, fontSize: 13)),
                subtitle: Text(DateFormat('dd MMM yyyy').format(_expenseDate), style: const TextStyle(color: AppTheme.goldPrimary, fontSize: 12)),
                trailing: const Icon(Icons.calendar_today, color: AppTheme.goldPrimary, size: 18),
                onTap: () async {
                  final date = await showDatePicker(context: context, initialDate: _expenseDate, firstDate: DateTime(2024), lastDate: DateTime.now());
                  if (date != null) setState(() => _expenseDate = date);
                },
                tileColor: AppTheme.purpleDark.withOpacity(0.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              const SizedBox(height: 12),
              const Text('Paid By', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(child: GestureDetector(
                    onTap: () => setState(() => _paidBy = 'organizer'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _paidBy == 'organizer' ? AppTheme.goldPrimary : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _paidBy == 'organizer' ? AppTheme.goldPrimary : Colors.white24),
                      ),
                      child: Text(AppLocalizations.t('organizer_label'), textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _paidBy == 'organizer' ? AppTheme.purpleDark : Colors.white54)),
                    ),
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: GestureDetector(
                    onTap: () => setState(() => _paidBy = 'sponsor'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _paidBy == 'sponsor' ? Colors.purple : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _paidBy == 'sponsor' ? Colors.purple : Colors.white24),
                      ),
                      child: Text(AppLocalizations.t('sponsor_label'), textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _paidBy == 'sponsor' ? Colors.white : Colors.white54)),
                    ),
                  )),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitExpense,
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.goldPrimary, foregroundColor: AppTheme.purpleDark, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: _isLoading ? const CircularProgressIndicator(color: AppTheme.purpleDark) : Text(AppLocalizations.t('add_expense_btn'), style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, IconData icon, [TextInputType? kb]) {
    return TextFormField(
      controller: ctrl, keyboardType: kb, style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label, prefixIcon: Icon(icon, color: AppTheme.goldPrimary),
        labelStyle: const TextStyle(color: AppTheme.textMuted), filled: true, fillColor: AppTheme.purpleDark.withOpacity(0.5),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppTheme.goldPrimary.withOpacity(0.3))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppTheme.goldPrimary.withOpacity(0.3))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.goldPrimary)),
      ),
      validator: (v) => v == null || v.isEmpty ? AppLocalizations.t('required') : null,
    );
  }
}
