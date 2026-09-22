import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../theme/app_theme.dart';
import '../../database/database_helper.dart';
import '../../l10n/app_localizations.dart';
import 'package:navratri_app/widgets/background_scaffold.dart';

class SponsorReportsScreen extends StatefulWidget {
  const SponsorReportsScreen({super.key});

  @override
  State<SponsorReportsScreen> createState() => _SponsorReportsScreenState();
}

class _SponsorReportsScreenState extends State<SponsorReportsScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _paymentReport;
  Map<String, dynamic>? _expenseReport;
  Map<String, dynamic>? _activityReport;
  Map<String, dynamic>? _summary;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        DatabaseHelper.getPaymentsByHouseReport(),
        DatabaseHelper.getExpensesByDateReport(),
        DatabaseHelper.getDailyActivityReport(),
        DatabaseHelper.getReportSummary(),
      ]);
      setState(() {
        _paymentReport = results[0];
        _expenseReport = results[1];
        _activityReport = results[2];
        _summary = results[3];
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.t('reports_analytics_title'), style: const TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.purpleDeep,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: const Icon(Icons.picture_as_pdf, color: Colors.white), onPressed: _exportPDF, tooltip: AppLocalizations.t('export_pdf')),
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _loadData),
        ],
      ),
      body: BackgroundBody(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.goldPrimary))
            : RefreshIndicator(
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle('1. Income Report (by House)'),
                      _buildIncomeByHouse(),
                      const SizedBox(height: 16),
                      _sectionTitle('2. Expense Report (by Date)'),
                      _buildExpensesByDate(),
                      const SizedBox(height: 16),
                      _sectionTitle('3. Balance Sheet'),
                      _buildBalanceSheet(),
                      const SizedBox(height: 16),
                      _sectionTitle('4. Daily Activity (Day 1-10)'),
                      _buildDailyActivity(),
                      const SizedBox(height: 16),
                      _sectionTitle('5. Charts'),
                      _buildCharts(),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.goldPrimary)),
    );
  }

  // ========== INCOME BY HOUSE ==========
  Widget _buildIncomeByHouse() {
    final payments = _paymentReport?['payments'] as List? ?? [];
    final fundTotal = _parseAmount(_paymentReport?['fund_total']);
    final sponsorTotal = _parseAmount(_paymentReport?['sponsor_total']);
    final grandTotal = fundTotal + sponsorTotal;

    if (payments.isEmpty) return _emptyCard(AppLocalizations.t('no_payment_data'));

    final sortedPayments = List<Map<String, dynamic>>.from(payments)
      ..sort((a, b) => (a['house_number'] ?? '').toString().compareTo((b['house_number'] ?? '').toString()));

    return Column(
      children: [
        _card(
          child: Column(
            children: [
              _tableHeader(['#', 'House', 'Owner Name', 'Amount', 'Status']),
              ...sortedPayments.asMap().entries.map((entry) {
                final p = entry.value;
                final amount = _parseAmount(p['total_amount']);
                final status = (p['payment_status'] ?? 'unpaid').toString();
                final isPaid = status == 'paid';
                return _tableRow([
                  '${entry.key + 1}',
                  '${p['house_number'] ?? ''}',
                  '${p['owner_name'] ?? ''}',
                  '₹${amount.toStringAsFixed(0)}',
                  isPaid ? 'Paid' : 'Unpaid',
                ]);
              }),
              _divider(),
              _tableRow(['', 'Subtotal (Fund Collection)', '', '₹${fundTotal.toStringAsFixed(0)}'], bold: true),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _card(
          child: Column(
            children: [
              _tableRow(['', 'Sponsor Income', '', '₹${sponsorTotal.toStringAsFixed(0)}'], bold: true),
              _divider(),
              _tableRow(['', 'TOTAL INCOME', '', '₹${grandTotal.toStringAsFixed(0)}'], bold: true, color: Colors.green),
            ],
          ),
        ),
      ],
    );
  }

  // ========== EXPENSES BY DATE ==========
  Widget _buildExpensesByDate() {
    final expenses = _expenseReport?['expenses'] as List? ?? [];
    final totalExpense = _parseAmount(_expenseReport?['total']);

    if (expenses.isEmpty) return _emptyCard(AppLocalizations.t('no_expense_data'));

    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final e in expenses) {
      final date = (e['expense_date'] ?? 'Unknown').toString().split('T').first;
      grouped.putIfAbsent(date, () => []).add(e);
    }

    final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return Column(
      children: [
        ...sortedDates.map((date) {
          final dayExpenses = grouped[date]!;
          dayExpenses.sort((a, b) => (a['category_name'] ?? '').toString().compareTo((b['category_name'] ?? '').toString()));
          double dayTotal = 0;
          for (final e in dayExpenses) dayTotal += _parseAmount(e['amount']);

          return _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppTheme.goldPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(date, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.goldPrimary)),
                ),
                const SizedBox(height: 8),
                _tableHeader(['Category', 'Item', 'Notes', 'Paid To', 'Amount']),
                ...dayExpenses.map((e) => _tableRow([
                  '${e['category_name'] ?? ''}',
                  '${e['item_name'] ?? ''}',
                  '${e['notes'] ?? ''}',
                  '${e['paid_to'] ?? ''}',
                  '₹${_parseAmount(e['amount']).toStringAsFixed(0)}',
                ])),
                _divider(),
                _tableRow(['', 'Day Total', '', '', '₹${dayTotal.toStringAsFixed(0)}'], bold: true),
              ],
            ),
          );
        }),
        const SizedBox(height: 8),
        _card(
          child: _tableRow(['', 'TOTAL EXPENSES', '', '', '₹${totalExpense.toStringAsFixed(0)}'], bold: true, color: Colors.red),
        ),
      ],
    );
  }

  // ========== BALANCE SHEET ==========
  Widget _buildBalanceSheet() {
    final fundTotal = _parseAmount(_paymentReport?['fund_total']);
    final sponsorTotal = _parseAmount(_paymentReport?['sponsor_total']);
    final totalIncome = fundTotal + sponsorTotal;
    final totalExpense = _parseAmount(_expenseReport?['total']);
    final balance = totalIncome - totalExpense;

    return _card(
      child: Column(
        children: [
          _tableRow(['Total Fund Collection', '₹${fundTotal.toStringAsFixed(0)}']),
          _tableRow(['Total Sponsor Income', '₹${sponsorTotal.toStringAsFixed(0)}']),
          _divider(),
          _tableRow(['TOTAL INCOME', '₹${totalIncome.toStringAsFixed(0)}'], bold: true, color: Colors.green),
          _divider(),
          _tableRow(['TOTAL EXPENSES', '₹${totalExpense.toStringAsFixed(0)}'], bold: true, color: Colors.red),
          _divider(),
          _tableRow(['REMAINING BALANCE', '₹${balance.toStringAsFixed(0)}'], bold: true, color: balance >= 0 ? Colors.green : Colors.red),
        ],
      ),
    );
  }

  // ========== DAILY ACTIVITY ==========
  Widget _buildDailyActivity() {
    final days = _activityReport?['days'] as List? ?? [];
    if (days.isEmpty) return _emptyCard(AppLocalizations.t('no_activity_data'));

    return Column(
      children: days.map((day) {
        final dayNum = day['day_number'];
        final goddess = day['goddess_name'] ?? '';
        final date = (day['date'] ?? '').toString().split('T').first;
        final aarti = day['aarti_bookings'] as List? ?? [];
        final foods = day['food_orders'] as List? ?? [];
        final gifts = day['gift_assignments'] as List? ?? [];

        return _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppTheme.goldPrimary.withOpacity(0.2), AppTheme.purpleCard]),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('DAY $dayNum : $goddess', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.goldPrimary)),
                    if (date.isNotEmpty) Text(date, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                  ],
                ),
              ),

              if (aarti.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Text('Aarti Bookings', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange)),
                const SizedBox(height: 4),
                ...aarti.map((a) {
                  final name = a['name'] ?? '';
                  final house = a['house_number'] ?? '';
                  final slot = '${a['slot_time'] ?? ''} ${a['slot_label'] ?? ''}'.trim();
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text('$name ($house) - $slot', style: const TextStyle(fontSize: 11, color: Colors.white70), overflow: TextOverflow.ellipsis),
                        ),
                        _approvalBadge(true),
                      ],
                    ),
                  );
                }),
              ],

              if (foods.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Text('Snack Distribution', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue)),
                const SizedBox(height: 4),
                ...foods.map((f) {
                  final name = f['name'] ?? '';
                  final house = f['house_number'] ?? '';
                  final item = f['snack_name'] ?? '';
                  final paidBy = (f['paid_by'] ?? 'organizer').toString();
                  final isSponsor = paidBy == 'sponsor';
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text('$name ($house) - $item', style: const TextStyle(fontSize: 11, color: Colors.white70), overflow: TextOverflow.ellipsis),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isSponsor ? Colors.purple.withOpacity(0.3) : Colors.green.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(isSponsor ? 'Sponsor' : 'Organizer', style: TextStyle(fontSize: 9, color: isSponsor ? Colors.purpleAccent : Colors.greenAccent, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  );
                }),
              ],

              if (gifts.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Text('Gift Distribution', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.purple)),
                const SizedBox(height: 4),
                ...gifts.map((g) {
                  final name = g['name'] ?? '';
                  final house = g['house_number'] ?? '';
                  final gift = g['gift_name'] ?? '';
                  final paidBy = (g['paid_by'] ?? 'organizer').toString();
                  final isSponsor = paidBy == 'sponsor';
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text('$name ($house) - $gift', style: const TextStyle(fontSize: 11, color: Colors.white70), overflow: TextOverflow.ellipsis),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isSponsor ? Colors.purple.withOpacity(0.3) : Colors.green.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(isSponsor ? 'Sponsor' : 'Organizer', style: TextStyle(fontSize: 9, color: isSponsor ? Colors.purpleAccent : Colors.greenAccent, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  );
                }),
              ],

              if (aarti.isEmpty && foods.isEmpty && gifts.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(AppLocalizations.t('no_activity_day'), style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _approvalBadge(bool isApproved) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isApproved ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isApproved ? AppLocalizations.t('approved') : 'Pending',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: isApproved ? Colors.green : Colors.orange,
        ),
      ),
    );
  }

  // ========== CHARTS ==========
  Widget _buildCharts() {
    final catExpenses = _summary?['category_expenses'] as List? ?? [];
    final expenseTotal = catExpenses.fold<double>(0, (sum, e) => sum + _parseAmount(e['total']));
    final fundTotal = _parseAmount(_paymentReport?['fund_total']);
    final sponsorTotal = _parseAmount(_paymentReport?['sponsor_total']);
    final totalIncome = fundTotal + sponsorTotal;
    final totalExpense = _parseAmount(_expenseReport?['total']);

    return Column(
      children: [
        if (totalIncome > 0 || totalExpense > 0) _buildIncomeExpenseChart(totalIncome, totalExpense),
        const SizedBox(height: 12),
        if (expenseTotal > 0 && catExpenses.isNotEmpty) _buildExpensePieChart(catExpenses, expenseTotal),
      ],
    );
  }

  Widget _buildIncomeExpenseChart(double income, double expense) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Income vs Expense', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: (income > expense ? income : expense) * 1.2,
                barGroups: [
                  BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: income, color: Colors.green, width: 40, borderRadius: const BorderRadius.vertical(top: Radius.circular(6)))]),
                  BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: expense, color: Colors.red, width: 40, borderRadius: const BorderRadius.vertical(top: Radius.circular(6)))]),
                ],
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) => Text(v == 0 ? 'Income' : 'Expense', style: const TextStyle(color: Colors.white70, fontSize: 11)))),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 50, getTitlesWidget: (v, _) => Text('₹${(v / 1000).toStringAsFixed(0)}k', style: const TextStyle(color: Colors.white54, fontSize: 10)))),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpensePieChart(List catExpenses, double total) {
    const colors = [Colors.blue, Colors.red, Colors.green, Colors.orange, Colors.purple, Colors.teal, Colors.amber, Colors.pink, Colors.cyan];
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Expense Breakdown', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: catExpenses.asMap().entries.map((entry) {
                  final amount = _parseAmount(entry.value['total']);
                  final pct = total > 0 ? (amount / total * 100) : 0.0;
                  return PieChartSectionData(value: amount, title: '${pct.toStringAsFixed(0)}%', color: colors[entry.key % colors.length], radius: 80, titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white));
                }).toList(),
                sectionsSpace: 2,
                centerSpaceRadius: 30,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: catExpenses.asMap().entries.map((entry) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 10, height: 10, color: colors[entry.key % colors.length]),
                  const SizedBox(width: 4),
                  Text('${entry.value['category_name']} ₹${_parseAmount(entry.value['total']).toStringAsFixed(0)}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ========== HELPER WIDGETS ==========
  double _parseAmount(dynamic value) {
    if (value == null) return 0;
    return double.tryParse(value.toString()) ?? 0;
  }

  Widget _card({required Widget child}) {
    return Card(
      color: AppTheme.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(padding: const EdgeInsets.all(12), child: child),
    );
  }

  Widget _emptyCard(String msg) {
    return _card(child: Center(child: Padding(padding: const EdgeInsets.all(16), child: Text(msg, style: const TextStyle(color: AppTheme.textMuted)))));
  }

  Widget _tableHeader(List<String> cols) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(color: AppTheme.goldPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Row(
        children: cols.map((c) => Expanded(child: Text(c, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.goldPrimary)))).toList(),
      ),
    );
  }

  Widget _tableRow(List<String> cols, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: cols.map((c) => Expanded(child: Text(c, style: TextStyle(fontSize: 11, fontWeight: bold ? FontWeight.bold : FontWeight.normal, color: color ?? Colors.white70), overflow: TextOverflow.ellipsis))).toList(),
      ),
    );
  }

  Widget _divider() => const Divider(color: Colors.white12, height: 8);

  // ========== PDF EXPORT ==========
  Future<void> _exportPDF() async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.notoSansRegular();
    final fontBold = await PdfGoogleFonts.notoSansBold();

    final fundTotal = _parseAmount(_paymentReport?['fund_total']);
    final sponsorTotal = _parseAmount(_paymentReport?['sponsor_total']);
    final totalIncome = fundTotal + sponsorTotal;
    final totalExpense = _parseAmount(_expenseReport?['total']);
    final balance = totalIncome - totalExpense;

    final payments = _paymentReport?['payments'] as List? ?? [];
    final sortedPayments = List<Map<String, dynamic>>.from(payments)
      ..sort((a, b) => (a['house_number'] ?? '').toString().compareTo((b['house_number'] ?? '').toString()));

    final expenses = _expenseReport?['expenses'] as List? ?? [];
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final e in expenses) {
      final date = (e['expense_date'] ?? 'Unknown').toString().split('T').first;
      grouped.putIfAbsent(date, () => []).add(e);
    }
    final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    final days = _activityReport?['days'] as List? ?? [];
    final catExpenses = _summary?['category_expenses'] as List? ?? [];
    final expenseTotal = catExpenses.fold<double>(0, (sum, e) => sum + _parseAmount(e['total']));

    // ===== PAGE 1: Income + Expense =====
    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(20),
      build: (ctx) => [
        pw.Header(level: 0, child: pw.Text('Navratri 2026 - Reports & Analytics', style: pw.TextStyle(font: fontBold, fontSize: 18))),
        pw.SizedBox(height: 12),
        pw.Text('INCOME REPORT (by House)', style: pw.TextStyle(font: fontBold, fontSize: 14)),
        pw.SizedBox(height: 8),
        if (sortedPayments.isNotEmpty) ...[
          pw.Table.fromTextArray(
            context: ctx,
            headers: ['#', 'House', 'Owner', 'Amount', 'Status'],
            headerStyle: pw.TextStyle(font: fontBold, fontSize: 10),
            cellStyle: pw.TextStyle(font: font, fontSize: 10),
            data: sortedPayments.asMap().entries.map((entry) {
              final p = entry.value;
              final amount = _parseAmount(p['total_amount']);
              final isPaid = (p['payment_status'] ?? 'unpaid') == 'paid';
              return ['${entry.key + 1}', '${p['house_number'] ?? ''}', '${p['owner_name'] ?? ''}', '₹${amount.toStringAsFixed(0)}', isPaid ? 'Paid' : 'Unpaid'];
            }).toList(),
          ),
          pw.SizedBox(height: 6),
          pw.Text('Subtotal (Fund): ₹${fundTotal.toStringAsFixed(0)}', style: pw.TextStyle(font: fontBold, fontSize: 11)),
          pw.Text('Sponsor Income: ₹${sponsorTotal.toStringAsFixed(0)}', style: pw.TextStyle(font: fontBold, fontSize: 11)),
          pw.Text('TOTAL INCOME: ₹${totalIncome.toStringAsFixed(0)}', style: pw.TextStyle(font: fontBold, fontSize: 12, color: PdfColors.green)),
        ] else ...[
          pw.Text('No payment data', style: pw.TextStyle(font: font, fontSize: 11, color: PdfColors.grey)),
        ],
        pw.SizedBox(height: 16),
        pw.Text('EXPENSE REPORT (by Date)', style: pw.TextStyle(font: fontBold, fontSize: 14)),
        pw.SizedBox(height: 8),
        if (sortedDates.isNotEmpty) ...[
          ...sortedDates.map((date) {
            final dayExpenses = grouped[date]!;
            dayExpenses.sort((a, b) => (a['category_name'] ?? '').toString().compareTo((b['category_name'] ?? '').toString()));
            double dayTotal = 0;
            for (final e in dayExpenses) dayTotal += _parseAmount(e['amount']);
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(date, style: pw.TextStyle(font: fontBold, fontSize: 11)),
                pw.SizedBox(height: 4),
                pw.Table.fromTextArray(
                  context: ctx,
                  headers: ['Category', 'Item', 'Notes', 'Paid To', 'Amount'],
                  headerStyle: pw.TextStyle(font: fontBold, fontSize: 9),
                  cellStyle: pw.TextStyle(font: font, fontSize: 9),
                  data: dayExpenses.map((e) => [
                    '${e['category_name'] ?? ''}', '${e['item_name'] ?? ''}',
                    '${(e['notes'] ?? '').toString().length > 20 ? (e['notes'] ?? '').toString().substring(0, 20) + '...' : e['notes'] ?? ''}',
                    '${e['paid_to'] ?? ''}', '₹${_parseAmount(e['amount']).toStringAsFixed(0)}',
                  ]).toList(),
                ),
                pw.Text('Day Total: ₹${dayTotal.toStringAsFixed(0)}', style: pw.TextStyle(font: fontBold, fontSize: 10)),
                pw.SizedBox(height: 8),
              ],
            );
          }),
          pw.Text('TOTAL EXPENSES: ₹${totalExpense.toStringAsFixed(0)}', style: pw.TextStyle(font: fontBold, fontSize: 12, color: PdfColors.red)),
        ] else ...[
          pw.Text('No expense data', style: pw.TextStyle(font: font, fontSize: 11, color: PdfColors.grey)),
        ],
      ],
    ));

    // ===== PAGE 2: Balance Sheet + Summary =====
    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(20),
      build: (ctx) => [
        pw.Header(level: 0, child: pw.Text('Balance Sheet', style: pw.TextStyle(font: fontBold, fontSize: 18))),
        pw.SizedBox(height: 12),
        pw.Table.fromTextArray(
          context: ctx,
          headers: ['Item', 'Amount'],
          headerStyle: pw.TextStyle(font: fontBold, fontSize: 12),
          cellStyle: pw.TextStyle(font: font, fontSize: 12),
          data: [
            ['Total Fund Collection', '₹${fundTotal.toStringAsFixed(0)}'],
            ['Total Sponsor Income', '₹${sponsorTotal.toStringAsFixed(0)}'],
            ['TOTAL INCOME', '₹${totalIncome.toStringAsFixed(0)}'],
            ['TOTAL EXPENSES', '₹${totalExpense.toStringAsFixed(0)}'],
            ['REMAINING BALANCE', '₹${balance.toStringAsFixed(0)}'],
          ],
        ),
        pw.SizedBox(height: 20),
        pw.Text('Summary Statistics', style: pw.TextStyle(font: fontBold, fontSize: 18)),
        pw.SizedBox(height: 12),
        pw.Table.fromTextArray(
          context: ctx,
          headers: ['Metric', 'Value'],
          headerStyle: pw.TextStyle(font: fontBold, fontSize: 12),
          cellStyle: pw.TextStyle(font: font, fontSize: 12),
          data: [
            ['Total Members', '${_summary?['members'] ?? 0}'],
            ['Tickets Assigned', '${_summary?['ticket_assigned'] ?? 0}'],
            ['Winners', '${_summary?['ticket_winners'] ?? 0}'],
            ['Total Income', '₹${totalIncome.toStringAsFixed(0)}'],
            ['Total Expenses', '₹${totalExpense.toStringAsFixed(0)}'],
            ['Net Balance', '₹${balance.toStringAsFixed(0)}'],
          ],
        ),
        if (catExpenses.isNotEmpty) ...[
          pw.SizedBox(height: 16),
          pw.Text('Expense Breakdown', style: pw.TextStyle(font: fontBold, fontSize: 14)),
          pw.SizedBox(height: 8),
          pw.Table.fromTextArray(
            context: ctx,
            headers: ['Category', 'Amount', '%'],
            headerStyle: pw.TextStyle(font: fontBold, fontSize: 11),
            cellStyle: pw.TextStyle(font: font, fontSize: 11),
            data: catExpenses.map((e) {
              final amt = _parseAmount(e['total']);
              final pct = expenseTotal > 0 ? (amt / expenseTotal * 100) : 0.0;
              return ['${e['category_name'] ?? ''}', '₹${amt.toStringAsFixed(0)}', '${pct.toStringAsFixed(0)}%'];
            }).toList(),
          ),
        ],
      ],
    ));

    // ===== PAGES 3+: Daily Activity =====
    for (int i = 0; i < days.length; i += 5) {
      final chunk = days.sublist(i, (i + 5 < days.length ? i + 5 : days.length));
      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (ctx) => [
          pw.Header(level: 0, child: pw.Text('Daily Activity (Days ${i + 1}-${i + chunk.length})', style: pw.TextStyle(font: fontBold, fontSize: 16))),
          pw.SizedBox(height: 10),
          ...chunk.map((day) {
            final dayNum = day['day_number'];
            final goddess = day['goddess_name'] ?? '';
            final date = (day['date'] ?? '').toString().split('T').first;
            final aarti = day['aarti_bookings'] as List? ?? [];
            final foods = day['food_orders'] as List? ?? [];
            final gifts = day['gift_assignments'] as List? ?? [];
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(6),
                  decoration: pw.BoxDecoration(color: PdfColor.fromHex('#FFD700'), borderRadius: pw.BorderRadius.circular(4)),
                  child: pw.Text('DAY $dayNum : $goddess ($date)', style: pw.TextStyle(font: fontBold, fontSize: 14)),
                ),
                pw.SizedBox(height: 4),
                if (aarti.isNotEmpty) ...[
                  pw.Text('Aarti Bookings:', style: pw.TextStyle(font: fontBold, fontSize: 12)),
                  pw.Table.fromTextArray(
                    context: ctx,
                    headers: ['House', 'Name', 'Slot', 'Status'],
                    headerStyle: pw.TextStyle(font: fontBold, fontSize: 10),
                    cellStyle: pw.TextStyle(font: font, fontSize: 10),
                    data: aarti.map((a) => [
                      '${a['house_number'] ?? ''}', '${a['name'] ?? ''}',
                      '${a['slot_time'] ?? ''} ${a['slot_label'] ?? ''}', 'Approved',
                    ]).toList(),
                  ),
                  pw.SizedBox(height: 4),
                ],
                if (foods.isNotEmpty) ...[
                  pw.Text('Snack Distribution:', style: pw.TextStyle(font: fontBold, fontSize: 12)),
                  pw.Table.fromTextArray(
                    context: ctx,
                    headers: ['House', 'Name', 'Item', 'Paid By'],
                    headerStyle: pw.TextStyle(font: fontBold, fontSize: 10),
                    cellStyle: pw.TextStyle(font: font, fontSize: 10),
                    data: foods.map((f) => [
                      '${f['house_number'] ?? ''}', '${f['name'] ?? ''}',
                      '${f['snack_name'] ?? ''}', '${f['paid_by'] ?? 'organizer'}',
                    ]).toList(),
                  ),
                  pw.SizedBox(height: 4),
                ],
                if (gifts.isNotEmpty) ...[
                  pw.Text('Gift Distribution:', style: pw.TextStyle(font: fontBold, fontSize: 12)),
                  pw.Table.fromTextArray(
                    context: ctx,
                    headers: ['House', 'Name', 'Gift', 'Paid By'],
                    headerStyle: pw.TextStyle(font: fontBold, fontSize: 10),
                    cellStyle: pw.TextStyle(font: font, fontSize: 10),
                    data: gifts.map((g) => [
                      '${g['house_number'] ?? ''}', '${g['name'] ?? ''}',
                      '${g['gift_name'] ?? ''}', '${g['paid_by'] ?? 'organizer'}',
                    ]).toList(),
                  ),
                  pw.SizedBox(height: 4),
                ],
                if (aarti.isEmpty && foods.isEmpty && gifts.isEmpty)
                  pw.Text('No activity', style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey)),
                pw.SizedBox(height: 10),
              ],
            );
          }),
        ],
      ));
    }

    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }
}
