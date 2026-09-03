import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../theme/app_theme.dart';
import '../../database/database_helper.dart';
import '../../l10n/app_localizations.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
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
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.purpleDark,
      appBar: AppBar(
        title: Text(AppLocalizations.t('reports_analytics_title'), style: const TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.purpleDeep,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: const Icon(Icons.picture_as_pdf, color: Colors.white), onPressed: _exportPDF, tooltip: AppLocalizations.t('export_pdf')),
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _loadData),
        ],
      ),
      body: _isLoading
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
                    _sectionTitle('4. Daily Activity (Day 1-9)'),
                    _buildDailyActivity(),
                    const SizedBox(height: 16),
                    _sectionTitle('5. Charts'),
                    _buildCharts(),
                  ],
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
                final status = (p['payment_status'] ?? '').toString();
                final amount = _parseAmount(p['total_amount']);
                return _tableRow([
                  '${entry.key + 1}',
                  '${p['house_number'] ?? ''}',
                  '${p['owner_name'] ?? ''}',
                  amount > 0 ? '₹${amount.toStringAsFixed(0)}' : '-',
                  status == 'paid' ? 'Paid' : 'Pending',
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
        final dressCode = day['dress_code'] ?? '';
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
              if (dressCode.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text('Dress Code: $dressCode', style: const TextStyle(fontSize: 11, color: Colors.white70)),
              ],

              if (aarti.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Text('Aarti Bookings', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange)),
                const SizedBox(height: 4),
                ...aarti.map((a) {
                  final status = (a['status'] ?? '').toString();
                  final isApproved = status == 'approved';
                  final name = a['name'] ?? '';
                  final slot = '${a['slot_time'] ?? ''} ${a['slot_label'] ?? ''}'.trim();
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text('Aarti: $name ($slot)', style: const TextStyle(fontSize: 11, color: Colors.white70), overflow: TextOverflow.ellipsis),
                        ),
                        _approvalBadge(isApproved),
                      ],
                    ),
                  );
                }),
              ],

              if (foods.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Text('Food Orders', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue)),
                const SizedBox(height: 4),
                ...foods.map((f) {
                  final status = (f['status'] ?? '').toString();
                  final isApproved = status == 'approved' || status == 'delivered';
                  final name = f['name'] ?? '';
                  final item = f['snack_name'] ?? '';
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text('Food Provider: $name ($item)', style: const TextStyle(fontSize: 11, color: Colors.white70), overflow: TextOverflow.ellipsis),
                        ),
                        _approvalBadge(isApproved),
                      ],
                    ),
                  );
                }),
              ],

              if (gifts.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Text('Gifts Provided', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.purple)),
                const SizedBox(height: 4),
                ...gifts.map((g) {
                  final status = (g['status'] ?? '').toString();
                  final isApproved = status == 'approved' || status == 'delivered';
                  final name = g['name'] ?? '';
                  final gift = g['gift_name'] ?? '';
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text('Gift Provider: $name ($gift)', style: const TextStyle(fontSize: 11, color: Colors.white70), overflow: TextOverflow.ellipsis),
                        ),
                        _approvalBadge(isApproved),
                      ],
                    ),
                  );
                }),
              ],

              if (aarti.isEmpty && foods.isEmpty && gifts.isEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
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
          const Text('📊 Income vs Expense', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
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
          const Text('🥧 Expense Breakdown', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
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

    // PAGE 1: Cover + Income Summary
    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (ctx) => [
        pw.Header(level: 0, child: pw.Text('🪔 Navratri 2026 - Nishitpark Society', style: pw.TextStyle(font: fontBold, fontSize: 22))),
        pw.Header(level: 1, child: pw.Text('📊 Financial Report', style: pw.TextStyle(font: font, fontSize: 16))),
        pw.SizedBox(height: 20),
        pw.Text('💰 INCOME REPORT', style: pw.TextStyle(font: fontBold, fontSize: 14)),
        pw.SizedBox(height: 10),
        pw.Table.fromTextArray(
          context: ctx,
          headers: ['#', 'House', 'Owner Name', 'Amount (₹)', 'Status'],
          data: _buildIncomeTableRows(),
          cellAlignment: pw.Alignment.centerLeft,
        ),
        pw.SizedBox(height: 10),
        pw.Table.fromTextArray(
          context: ctx,
          headers: ['', 'Item', 'Amount (₹)'],
          data: [
            ['', 'Subtotal (Fund Collection)', '₹${fundTotal.toStringAsFixed(0)}'],
            ['', 'Sponsor Income', '₹${sponsorTotal.toStringAsFixed(0)}'],
            ['', 'TOTAL INCOME', '₹${totalIncome.toStringAsFixed(0)}'],
          ],
          cellAlignment: pw.Alignment.centerLeft,
        ),
      ],
    ));

    // PAGE 2: Expenses by Date
    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (ctx) => [
        pw.Text('💸 EXPENSE REPORT (Date-wise)', style: pw.TextStyle(font: fontBold, fontSize: 16)),
        pw.SizedBox(height: 10),
        ..._buildExpensePdfSections(font, fontBold),
        pw.SizedBox(height: 10),
        pw.Table.fromTextArray(
          context: ctx,
          data: [
            ['', 'TOTAL EXPENSES', '₹${totalExpense.toStringAsFixed(0)}'],
          ],
          cellAlignment: pw.Alignment.centerLeft,
        ),
        pw.SizedBox(height: 20),
        pw.Text('📋 BALANCE SHEET', style: pw.TextStyle(font: fontBold, fontSize: 16)),
        pw.SizedBox(height: 10),
        pw.Table.fromTextArray(
          context: ctx,
          headers: ['Item', 'Amount (₹)'],
          data: [
            ['Total Fund Collection', '₹${fundTotal.toStringAsFixed(0)}'],
            ['Total Sponsor Income', '₹${sponsorTotal.toStringAsFixed(0)}'],
            ['Total Income', '₹${totalIncome.toStringAsFixed(0)}'],
            ['Total Expenses', '₹${totalExpense.toStringAsFixed(0)}'],
            ['REMAINING BALANCE', '₹${balance.toStringAsFixed(0)}'],
          ],
        ),
      ],
    ));

    // PAGES 3-5: Daily Activity (3 days per page)
    final days = _activityReport?['days'] as List? ?? [];
    for (int i = 0; i < days.length; i += 3) {
      final chunk = days.sublist(i, (i + 3 < days.length ? i + 3 : days.length));
      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (ctx) => [
          pw.Text('📅 DAILY ACTIVITY (Days ${i + 1}-${i + chunk.length})', style: pw.TextStyle(font: fontBold, fontSize: 16)),
          pw.SizedBox(height: 10),
          ...chunk.map((day) => _buildDayActivityPdf(day, font, fontBold)),
        ],
      ));
    }

    // LAST PAGE: Summary Stats
    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (ctx) => [
        pw.Text('📈 SUMMARY STATISTICS', style: pw.TextStyle(font: fontBold, fontSize: 16)),
        pw.SizedBox(height: 10),
        pw.Table.fromTextArray(
          context: ctx,
          headers: ['Metric', 'Value'],
          data: [
            ['Total Members', '${_summary?['members'] ?? 0}'],
            ['Tickets Assigned', '${_summary?['ticket_assigned'] ?? 0}'],
            ['Winners', '${_summary?['ticket_winners'] ?? 0}'],
            ['Total Income', '₹${totalIncome.toStringAsFixed(0)}'],
            ['Total Expenses', '₹${totalExpense.toStringAsFixed(0)}'],
            ['Net Balance', '₹${balance.toStringAsFixed(0)}'],
          ],
        ),
        pw.SizedBox(height: 20),
        pw.Text('Generated on: ${DateTime.now().toString().split('.')[0]}', style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey)),
      ],
    ));

    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  List<List<String>> _buildIncomeTableRows() {
    final payments = _paymentReport?['payments'] as List? ?? [];
    final sortedPayments = List<Map<String, dynamic>>.from(payments)
      ..sort((a, b) => (a['house_number'] ?? '').toString().compareTo((b['house_number'] ?? '').toString()));
    final rows = <List<String>>[];
    int idx = 1;
    for (final p in sortedPayments) {
      final status = (p['payment_status'] ?? '').toString();
      final amount = _parseAmount(p['total_amount']);
      rows.add([
        '${idx++}',
        '${p['house_number'] ?? ''}',
        '${p['owner_name'] ?? ''}',
        amount > 0 ? '₹${amount.toStringAsFixed(0)}' : '-',
        status == 'paid' ? 'Paid' : 'Pending',
      ]);
    }
    return rows;
  }

  List<pw.Widget> _buildExpensePdfSections(pw.Font font, pw.Font fontBold) {
    final expenses = _expenseReport?['expenses'] as List? ?? [];
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final e in expenses) {
      final date = (e['expense_date'] ?? 'Unknown').toString().split('T').first;
      grouped.putIfAbsent(date, () => []).add(e);
    }
    final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return sortedDates.map((date) {
      final dayExpenses = grouped[date]!;
      dayExpenses.sort((a, b) => (a['category_name'] ?? '').toString().compareTo((b['category_name'] ?? '').toString()));
      double dayTotal = 0;
      for (final e in dayExpenses) dayTotal += _parseAmount(e['amount']);
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(date, style: pw.TextStyle(font: fontBold, fontSize: 12)),
          pw.SizedBox(height: 4),
          pw.Table.fromTextArray(
            context: null,
            headers: ['Category', 'Item', 'Notes', 'Paid To', 'Amount'],
            data: dayExpenses.map((e) => [
              '${e['category_name'] ?? ''}',
              '${e['item_name'] ?? ''}',
              '${e['notes'] ?? ''}',
              '${e['paid_to'] ?? ''}',
              '₹${_parseAmount(e['amount']).toStringAsFixed(0)}',
            ]).toList(),
          ),
          pw.Text('Day Total: ₹${dayTotal.toStringAsFixed(0)}', style: pw.TextStyle(font: fontBold, fontSize: 10)),
          pw.SizedBox(height: 10),
        ],
      );
    }).toList();
  }

  pw.Widget _buildDayActivityPdf(Map<String, dynamic> day, pw.Font font, pw.Font fontBold) {
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
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(color: PdfColor.fromHex('#FFD700'), borderRadius: pw.BorderRadius.circular(4)),
          child: pw.Text('DAY $dayNum : $goddess ($date)', style: pw.TextStyle(font: fontBold, fontSize: 12)),
        ),
        pw.SizedBox(height: 6),
        if (aarti.isNotEmpty) ...[
          pw.Text('Aarti Bookings:', style: pw.TextStyle(font: fontBold, fontSize: 10)),
          pw.Table.fromTextArray(context: null, headers: ['House', 'Name', 'Slot', 'Status'],
            data: aarti.map((a) => ['${a['house_number']}', '${a['name']}', '${a['slot_time']} ${a['slot_label']}', '${(a['status'] ?? '').toString().toUpperCase()}']).toList()),
          pw.SizedBox(height: 4),
        ],
        if (foods.isNotEmpty) ...[
          pw.Text('Food Orders:', style: pw.TextStyle(font: fontBold, fontSize: 10)),
          pw.Table.fromTextArray(context: null, headers: ['House', 'Name', 'Item', 'Qty', 'Amt'],
            data: foods.map((f) => ['${f['house_number']}', '${f['name']}', '${f['snack_name']}', '${f['quantity']}', '₹${_parseAmount(f['total_price']).toStringAsFixed(0)}']).toList()),
          pw.SizedBox(height: 4),
        ],
        if (gifts.isNotEmpty) ...[
          pw.Text('Gifts Provided:', style: pw.TextStyle(font: fontBold, fontSize: 10)),
          pw.Table.fromTextArray(context: null, headers: ['House', 'Name', 'Gift'],
            data: gifts.map((g) => ['${g['house_number']}', '${g['name']}', '${g['gift_name']}']).toList()),
          pw.SizedBox(height: 4),
        ],
        if (aarti.isEmpty && foods.isEmpty && gifts.isEmpty)
          pw.Text('No activity', style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey)),
        pw.SizedBox(height: 10),
      ],
    );
  }
}
