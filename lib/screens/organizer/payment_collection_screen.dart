import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../database/database_helper.dart';
import '../../l10n/app_localizations.dart';
import 'package:navratri_app/widgets/background_scaffold.dart';

class PaymentCollectionScreen extends StatefulWidget {
  const PaymentCollectionScreen({super.key});

  @override
  State<PaymentCollectionScreen> createState() => _PaymentCollectionScreenState();
}

class _PaymentCollectionScreenState extends State<PaymentCollectionScreen> {
  List<Map<String, dynamic>> _payments = [];
  List<Map<String, dynamic>> _deletedPayments = [];
  bool _isLoading = true;
  String _selectedFilter = 'all';
  String _sortBy = 'date_desc';
  DateTime? _dateFrom;
  DateTime? _dateTo;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    setState(() => _isLoading = true);
    try {
      final payments = await DatabaseHelper.getAllPayments();
      final deleted = await DatabaseHelper.getDeletedPayments();
      setState(() { _payments = payments; _deletedPayments = deleted; _isLoading = false; });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredPayments {
    var list = _payments;
    if (_selectedFilter == 'paid') {
      list = list.where((p) => p['payment_status'] == 'paid').toList();
    } else if (_selectedFilter == 'pending') {
      list = list.where((p) => p['payment_status'] == 'pending').toList();
    } else if (_selectedFilter == 'denied') {
      list = list.where((p) => p['payment_status'] == 'denied').toList();
    }
    final search = _searchController.text.toLowerCase();
    if (search.isNotEmpty) {
      list = list.where((p) =>
        (p['house_number']?.toString().toLowerCase().contains(search) ?? false) ||
        (p['payer_name']?.toString().toLowerCase().contains(search) ?? false) ||
        (p['user_name']?.toString().toLowerCase().contains(search) ?? false)
      ).toList();
    }
    if (_dateFrom != null) {
      list = list.where((p) {
        final d = p['created_at']?.toString() ?? '';
        if (d.isEmpty) return false;
        try { return DateTime.parse(d).isAfter(_dateFrom!.subtract(const Duration(days: 1))); } catch (_) { return false; }
      }).toList();
    }
    if (_dateTo != null) {
      list = list.where((p) {
        final d = p['created_at']?.toString() ?? '';
        if (d.isEmpty) return false;
        try { return DateTime.parse(d).isBefore(_dateTo!.add(const Duration(days: 1))); } catch (_) { return false; }
      }).toList();
    }
    list.sort((a, b) {
      switch (_sortBy) {
        case 'name_asc': return (a['payer_name'] ?? a['user_name'] ?? '').toString().compareTo((b['payer_name'] ?? b['user_name'] ?? '').toString());
        case 'name_desc': return (b['payer_name'] ?? b['user_name'] ?? '').toString().compareTo((a['payer_name'] ?? a['user_name'] ?? '').toString());
        case 'house_asc': return (a['house_number'] ?? '').toString().compareTo((b['house_number'] ?? '').toString());
        case 'house_desc': return (b['house_number'] ?? '').toString().compareTo((a['house_number'] ?? '').toString());
        case 'date_asc': return (a['created_at'] ?? '').toString().compareTo((b['created_at'] ?? '').toString());
        case 'date_desc':
        default: return (b['created_at'] ?? '').toString().compareTo((a['created_at'] ?? '').toString());
      }
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _selectedFilter == 'deleted' ? _deletedPayments : _filteredPayments;
    double totalPaid = 0, totalPending = 0;
    for (var p in _filteredPayments) {
      final amt = double.tryParse(p['amount'].toString()) ?? 0;
      if (p['payment_status'] == 'paid') totalPaid += amt;
      else if (p['payment_status'] == 'pending') totalPending += amt;
    }

    return BackgroundScaffold(
      appBar: AppBar(
        title: Text(_selectedFilter == 'deleted' ? 'Deleted Payments' : 'Payment Collection'),
        backgroundColor: AppTheme.purpleDeep,
        foregroundColor: AppTheme.goldPrimary,
        iconTheme: const IconThemeData(color: AppTheme.goldPrimary),
        actions: [
          if (_selectedFilter != 'deleted') ...[
            IconButton(icon: const Icon(Icons.sort), onPressed: _showSortDialog),
            IconButton(icon: const Icon(Icons.date_range), onPressed: _showDateRangeDialog),
            IconButton(icon: const Icon(Icons.add), onPressed: () => _showAddPaymentDialog()),
          ],
        ],
      ),
      child: Column(
        children: [
          if (_selectedFilter != 'deleted') _buildSearchBar(),
          _buildFilterChips(),
          if (_selectedFilter != 'deleted') _buildStatsRow(totalPaid, totalPending, _filteredPayments.length),
          if (_selectedFilter == 'deleted')
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.15), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.red.withOpacity(0.3))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.delete, color: Colors.red, size: 16),
                  const SizedBox(width: 6),
                  Text('${_deletedPayments.length} deleted payments', style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.goldPrimary))
                : filtered.isEmpty
                    ? Center(child: Text(_selectedFilter == 'deleted' ? 'No deleted payments' : AppLocalizations.t('no_payments_found'), style: const TextStyle(color: AppTheme.textMuted)))
                    : _buildPaymentsList(filtered),
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
          hintText: AppLocalizations.t('search_payment'),
          hintStyle: TextStyle(color: AppTheme.textMuted.withOpacity(0.5)),
          prefixIcon: const Icon(Icons.search, color: AppTheme.goldPrimary),
          filled: true,
          fillColor: AppTheme.purpleDark.withOpacity(0.5),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.goldPrimary.withOpacity(0.3))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.goldPrimary.withOpacity(0.3))),
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          _chip(AppLocalizations.t('all'), 'all'), const SizedBox(width: 6),
          _chip(AppLocalizations.t('paid'), 'paid'), const SizedBox(width: 6),
          _chip(AppLocalizations.t('pending'), 'pending'), const SizedBox(width: 6),
          _chip(AppLocalizations.t('denied'), 'denied'), const SizedBox(width: 6),
          _chip(AppLocalizations.t('deleted'), 'deleted'),
        ],
      ),
    );
  }

  Widget _chip(String label, String value) {
    final sel = _selectedFilter == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedFilter = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: sel ? AppTheme.goldPrimary : AppTheme.cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: sel ? AppTheme.goldPrimary : AppTheme.goldPrimary.withOpacity(0.9)),
          ),
          child: Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: sel ? AppTheme.purpleDark : AppTheme.textMuted)),
        ),
      ),
    );
  }

  Widget _buildStatsRow(double totalPaid, double totalPending, int count) {
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
          _statItem(AppLocalizations.t('collected'), '₹${totalPaid.toStringAsFixed(0)}', Colors.green),
          Container(height: 30, width: 1, color: AppTheme.goldPrimary.withOpacity(0.3)),
          _statItem(AppLocalizations.t('pending'), '₹${totalPending.toStringAsFixed(0)}', Colors.orange),
          Container(height: 30, width: 1, color: AppTheme.goldPrimary.withOpacity(0.3)),
          _statItem(AppLocalizations.t('total'), '$count', AppTheme.cyanAccent),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Column(children: [
      Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
    ]);
  }

  Widget _buildPaymentsList(List<Map<String, dynamic>> list) {
    return RefreshIndicator(
      onRefresh: _loadPayments,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: list.length,
        itemBuilder: (context, i) => _buildPaymentCard(list[i]),
      ),
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> p) {
    final status = p['payment_status'] ?? 'pending';
    final isDeleted = p['is_deleted'] == true;
    final Color statusColor;
    final String statusLabel;
    if (isDeleted) {
      statusColor = Colors.red;
      statusLabel = 'DELETED';
    } else {
      switch (status) {
        case 'paid': statusColor = Colors.green; statusLabel = 'PAID'; break;
        case 'denied': statusColor = Colors.red; statusLabel = 'DENIED'; break;
        default: statusColor = Colors.orange; statusLabel = 'PENDING'; break;
      }
    }
    final name = p['payer_name'] ?? p['user_name'] ?? 'Unknown';

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
                width: 48, height: 48,
                decoration: BoxDecoration(
                  gradient: isDeleted ? null : AppTheme.goldGradient,
                  color: isDeleted ? Colors.red.withOpacity(0.2) : null,
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                ),
                child: Center(child: Text(p['house_number'] ?? '', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDeleted ? Colors.red : AppTheme.purpleDark), textAlign: TextAlign.center)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDeleted ? Colors.red : Colors.white)),
                    const SizedBox(height: 2),
                    Text('₹${p['amount']} • ${p['payment_method']?.toString().toUpperCase() ?? ''}', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.2), borderRadius: BorderRadius.circular(14), border: Border.all(color: statusColor)),
                child: Text(statusLabel, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: statusColor)),
              ),
            ],
          ),
          if (isDeleted && p['deleted_reason']?.toString().isNotEmpty == true) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.red, size: 12),
                  const SizedBox(width: 4),
                  Expanded(child: Text('Deleted: ${p['deleted_reason']}', style: const TextStyle(fontSize: 10, color: Colors.red))),
                ],
              ),
            ),
          ],
          if (!isDeleted) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (status == 'pending') ...[
                  _actionBtn(AppLocalizations.t('mark_paid'), Colors.green, Icons.check, () => _showMarkPaidDialog(p)),
                  const SizedBox(width: 6),
                  _actionBtn(AppLocalizations.t('deny'), Colors.red, Icons.close, () => _denyPayment(p)),
                  const SizedBox(width: 6),
                ],
                _actionBtn('Edit', AppTheme.goldPrimary, Icons.edit, () => _showEditPaymentDialog(p)),
                const SizedBox(width: 6),
                _actionBtn(AppLocalizations.t('delete'), Colors.red, Icons.delete_outline, () => _showDeletePaymentDialog(p)),
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withOpacity(0.4))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
        ]),
      ),
    );
  }

  void _showMarkPaidDialog(Map<String, dynamic> p) {
    String method = 'cash';
    DateTime paidDate = DateTime.now();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.purpleCard,
          title: Text(AppLocalizations.t('mark_as_paid'), style: const TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('House: ${p['house_number']} • ₹${p['amount']}', style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 16),
              Text(AppLocalizations.t('payment_method'), style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _methodBtn(AppLocalizations.t('cash'), 'cash', method, (v) => setDialogState(() => method = v))),
                  const SizedBox(width: 8),
                  Expanded(child: _methodBtn(AppLocalizations.t('upi'), 'online', method, (v) => setDialogState(() => method = v))),
                ],
              ),
              const SizedBox(height: 12),
              ListTile(
                dense: true,
                tileColor: AppTheme.purpleDark,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                title: Text('Date: ${DateFormat('dd MMM yyyy').format(paidDate)}', style: const TextStyle(color: Colors.white, fontSize: 13)),
                trailing: const Icon(Icons.calendar_today, color: AppTheme.goldPrimary, size: 18),
                onTap: () async {
                  final d = await showDatePicker(context: context, initialDate: paidDate, firstDate: DateTime(2024), lastDate: DateTime.now().add(const Duration(days: 1)));
                  if (d != null) setDialogState(() => paidDate = d);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocalizations.t('cancel'))),
            TextButton(
              onPressed: () async {
                await DatabaseHelper.updatePaymentStatus(
                  p['id'], status: 'paid', paidDate: paidDate.toIso8601String(), paymentMethod: method,
                );
                Navigator.pop(ctx);
                _loadPayments();
              },
              child: const Text('Confirm', style: TextStyle(color: Colors.green)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _methodBtn(String label, String value, String current, ValueChanged<String> onTap) {
    final sel = current == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: sel ? AppTheme.goldPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: sel ? AppTheme.goldPrimary : Colors.white24),
        ),
        child: Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: sel ? AppTheme.purpleDark : Colors.white54)),
      ),
    );
  }

  void _denyPayment(Map<String, dynamic> p) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.purpleCard,
          title: Text(AppLocalizations.t('deny_payment'), style: const TextStyle(color: Colors.white)),
          content: Text('Deny payment for ${p['house_number']} (₹${p['amount']})?', style: const TextStyle(color: Colors.white70)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppLocalizations.t('cancel'))),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(AppLocalizations.t('deny'), style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      await DatabaseHelper.updatePaymentStatus(p['id'], status: 'denied');
      _loadPayments();
    }
  }

  void _showEditPaymentDialog(Map<String, dynamic> p) {
    final amountCtrl = TextEditingController(text: p['amount']?.toString() ?? '');
    final nameCtrl = TextEditingController(text: p['payer_name'] ?? '');
    final notesCtrl = TextEditingController(text: p['notes'] ?? '');
    String method = p['payment_method'] ?? 'cash';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.purpleCard,
          title: Text(AppLocalizations.t('edit_payment'), style: const TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('House: ${p['house_number']}', style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 12),
                _dialogField(amountCtrl, AppLocalizations.t('amount'), Icons.attach_money, TextInputType.number),
                const SizedBox(height: 10),
                _dialogField(nameCtrl, AppLocalizations.t('payer_name'), Icons.person),
                const SizedBox(height: 10),
                _dialogField(notesCtrl, AppLocalizations.t('notes'), Icons.notes),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: RadioListTile<String>(
                      contentPadding: EdgeInsets.zero, dense: true,
                      title: Text(AppLocalizations.t('cash'), style: const TextStyle(color: Colors.white, fontSize: 12)),
                      value: 'cash', groupValue: method,
                      onChanged: (v) => setDialogState(() => method = v!),
                      activeColor: AppTheme.goldPrimary,
                    )),
                    Expanded(child: RadioListTile<String>(
                      contentPadding: EdgeInsets.zero, dense: true,
                      title: Text(AppLocalizations.t('upi'), style: const TextStyle(color: Colors.white, fontSize: 12)),
                      value: 'online', groupValue: method,
                      onChanged: (v) => setDialogState(() => method = v!),
                      activeColor: AppTheme.goldPrimary,
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
                await DatabaseHelper.updatePayment(
                  p['id'],
                  amount: double.tryParse(amountCtrl.text),
                  payerName: nameCtrl.text.isNotEmpty ? nameCtrl.text : null,
                  paymentMethod: method,
                  notes: notesCtrl.text.isNotEmpty ? notesCtrl.text : null,
                );
                Navigator.pop(ctx);
                _loadPayments();
            },
            child: Text(AppLocalizations.t('save'), style: const TextStyle(color: AppTheme.goldPrimary)),
          ),
        ],
        ),
      ),
    );
  }

  Widget _dialogField(TextEditingController ctrl, String label, IconData icon, [TextInputType? kb]) {
    return TextField(
      controller: ctrl,
      keyboardType: kb,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
        prefixIcon: Icon(icon, color: AppTheme.goldPrimary, size: 18),
        isDense: true,
        filled: true,
        fillColor: AppTheme.purpleDark,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppTheme.goldPrimary.withOpacity(0.3))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppTheme.goldPrimary.withOpacity(0.3))),
      ),
    );
  }

  void _showDeletePaymentDialog(Map<String, dynamic> p) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.cardBg,
          title: const Text('Delete Payment', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Delete payment of ₹${p['amount']} from ${p['payer_name'] ?? p['user_name'] ?? 'Unknown'}?',
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
                      await DatabaseHelper.deletePayment(p['id'], reasonController.text.trim());
                      Navigator.pop(ctx);
                      _loadPayments();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(AppLocalizations.t('payment_deleted')), backgroundColor: Colors.red),
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
            _sortOption(AppLocalizations.t('date_newest'), 'date_desc'), _sortOption(AppLocalizations.t('date_oldest'), 'date_asc'),
            _sortOption(AppLocalizations.t('name_az'), 'name_asc'), _sortOption(AppLocalizations.t('name_za'), 'name_desc'),
            _sortOption('House A→Z', 'house_asc'), _sortOption('House Z→A', 'house_desc'),
          ],
        ),
      ),
    );
  }

  Widget _sortOption(String label, String value) {
    return RadioListTile<String>(
      dense: true,
      value: value,
      groupValue: _sortBy,
      onChanged: (v) { setState(() => _sortBy = v!); Navigator.pop(context); },
      title: Text(label, style: const TextStyle(color: Colors.white, fontSize: 13)),
      activeColor: AppTheme.goldPrimary,
      contentPadding: EdgeInsets.zero,
    );
  }

  void _showDateRangeDialog() async {
    final from = await showDatePicker(context: context, initialDate: _dateFrom ?? DateTime.now().subtract(const Duration(days: 30)), firstDate: DateTime(2024), lastDate: DateTime.now());
    if (from == null) return;
    final to = await showDatePicker(context: context, initialDate: _dateTo ?? DateTime.now(), firstDate: from, lastDate: DateTime.now().add(const Duration(days: 1)));
    setState(() { _dateFrom = from; _dateTo = to; });
  }

  void _showAddPaymentDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.purpleCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => _AddPaymentSheet(onPaymentAdded: _loadPayments),
    );
  }
}

class _AddPaymentSheet extends StatefulWidget {
  final VoidCallback onPaymentAdded;
  const _AddPaymentSheet({required this.onPaymentAdded});
  @override
  State<_AddPaymentSheet> createState() => _AddPaymentSheetState();
}

class _AddPaymentSheetState extends State<_AddPaymentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _houseController = TextEditingController();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  String _paymentMethod = 'cash';
  String _paymentStatus = 'paid';
  DateTime? _paymentDate;
  bool _isLoading = false;
  List<Map<String, dynamic>> _houseMembers = [];
  bool _showMembers = false;

  @override
  void dispose() { _houseController.dispose(); _nameController.dispose(); _amountController.dispose(); super.dispose(); }

  Future<void> _loadHouseMembers(String house) async {
    final upperHouse = house.toUpperCase();
    if (house.isNotEmpty && upperHouse != house) {
      _houseController.value = _houseController.value.copyWith(text: upperHouse, selection: TextSelection.collapsed(offset: upperHouse.length));
    }
    if (upperHouse.isEmpty) { setState(() { _houseMembers = []; _showMembers = false; }); return; }
    try {
      final members = await DatabaseHelper.getMembersByHouse(upperHouse);
      setState(() { _houseMembers = members; _showMembers = members.isNotEmpty; });
    } catch (e) { setState(() { _houseMembers = []; _showMembers = false; }); }
  }

  void _selectMember(Map<String, dynamic> m) { setState(() { _nameController.text = m['name'] ?? ''; _showMembers = false; }); }

  Future<void> _pickPaymentDate() async {
    final picked = await showDatePicker(context: context, initialDate: _paymentDate ?? DateTime.now().add(const Duration(days: 7)), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: AppTheme.goldPrimary)), child: child!));
    if (picked != null) setState(() => _paymentDate = picked);
  }

  Future<void> _submitPayment() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final house = _houseController.text.trim().toUpperCase();
      final payerName = _nameController.text.trim();
      final results = await DatabaseHelper.query('SELECT id FROM users WHERE house_number = @house', substitutionValues: {'house': house});
      int userId;
      if (results.isEmpty) {
        userId = await DatabaseHelper.registerUser(houseNumber: house, name: payerName.isNotEmpty ? payerName : 'House $house', mobileNumber: '0000000000', userType: 'user');
      } else {
        userId = results.first['id'] as int;
      }
      final status = _paymentStatus == 'pay_later' ? 'pending' : 'paid';
      final paidDate = _paymentStatus == 'pay_later' ? _paymentDate : DateTime.now();
      await DatabaseHelper.addPayment(userId: userId, houseNumber: house, amount: double.parse(_amountController.text), paymentMethod: _paymentMethod, paymentStatus: status, payerName: payerName.isNotEmpty ? payerName : null, paidDate: paidDate);
      widget.onPaymentAdded();
      if (mounted) Navigator.pop(context);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(status == 'pending' ? 'Payment recorded (Pay Later)' : AppLocalizations.t('payment_added')), backgroundColor: Colors.green));
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
              Text(AppLocalizations.t('add_payment'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.goldPrimary)),
              const SizedBox(height: 16),
              _buildField(_houseController, AppLocalizations.t('house_number'), Icons.home, onChanged: _loadHouseMembers, textCapitalization: TextCapitalization.characters),
              if (_showMembers && _houseMembers.isNotEmpty) ...[
                const SizedBox(height: 6),
                Container(
                  constraints: const BoxConstraints(maxHeight: 120),
                  decoration: BoxDecoration(color: AppTheme.purpleDark, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.goldPrimary.withOpacity(0.3))),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: _houseMembers.map((m) {
                        return Material(
                          color: Colors.transparent,
                          child: ListTile(
                            dense: true,
                            leading: CircleAvatar(backgroundColor: AppTheme.goldPrimary, radius: 12, child: Text((m['name'] ?? '?').toString().isNotEmpty ? (m['name'] ?? '?')[0].toString().toUpperCase() : '?', style: const TextStyle(fontSize: 10, color: AppTheme.purpleDark))),
                            title: Text(m['name'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 12)),
                            onTap: () => _selectMember(m),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              _buildField(_nameController, AppLocalizations.t('payer_name'), Icons.person),
              const SizedBox(height: 10),
              _buildField(_amountController, AppLocalizations.t('amount_rs'), Icons.attach_money, keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              Row(
                children: [
                  _methodChip(AppLocalizations.t('cash'), 'cash', Icons.money), const SizedBox(width: 6),
                  _methodChip(AppLocalizations.t('upi'), 'online', Icons.qr_code), const SizedBox(width: 6),
                  _methodChip(AppLocalizations.t('pay_later'), 'pay_later', Icons.schedule),
                ],
              ),
              if (_paymentStatus == 'pay_later') ...[
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _pickPaymentDate,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppTheme.purpleDark.withOpacity(0.5), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppTheme.goldPrimary.withOpacity(0.3))),
                    child: Row(children: [
                      const Icon(Icons.calendar_today, color: AppTheme.goldPrimary, size: 18),
                      const SizedBox(width: 10),
                      Text(_paymentDate != null ? 'Due: ${_paymentDate!.day}/${_paymentDate!.month}/${_paymentDate!.year}' : 'Select payment date', style: TextStyle(color: _paymentDate != null ? Colors.white : AppTheme.textMuted, fontSize: 13)),
                    ]),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitPayment,
                style: ElevatedButton.styleFrom(backgroundColor: _paymentStatus == 'pay_later' ? Colors.orange : AppTheme.goldPrimary, foregroundColor: AppTheme.purpleDark, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: _isLoading ? const CircularProgressIndicator(color: AppTheme.purpleDark) : Text(_paymentStatus == 'pay_later' ? 'SAVE PAY LATER' : AppLocalizations.t('add_payment_btn'), style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, IconData icon, {TextInputType? keyboardType, ValueChanged<String>? onChanged, TextCapitalization? textCapitalization}) {
    return TextFormField(
      controller: ctrl, keyboardType: keyboardType, style: const TextStyle(color: Colors.white), onChanged: onChanged, textCapitalization: textCapitalization ?? TextCapitalization.none,
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

  Widget _methodChip(String label, String value, IconData icon) {
    final isPayLater = value == 'pay_later';
    final active = isPayLater ? _paymentStatus == 'pay_later' : _paymentMethod == value && _paymentStatus != 'pay_later';
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() { if (isPayLater) { _paymentStatus = 'pay_later'; _paymentMethod = 'pending'; } else { _paymentStatus = 'paid'; _paymentMethod = value; } }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(color: active ? (isPayLater ? Colors.orange : AppTheme.goldPrimary) : Colors.transparent, borderRadius: BorderRadius.circular(8), border: Border.all(color: active ? (isPayLater ? Colors.orange : AppTheme.goldPrimary) : Colors.white24)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 14, color: active ? AppTheme.purpleDark : Colors.white54),
            const SizedBox(width: 3),
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: active ? AppTheme.purpleDark : Colors.white54)),
          ]),
        ),
      ),
    );
  }
}
