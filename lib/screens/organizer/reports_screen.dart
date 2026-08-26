import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../theme/app_theme.dart';
import '../../database/database_helper.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _summary = {};
  List<Map<String, dynamic>> _categoryExpenses = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final report = await DatabaseHelper.getReportSummary();
      setState(() {
        _summary = report ?? {};
        final catList = _summary['category_expenses'];
        _categoryExpenses = catList != null
            ? (catList as List).map((e) => Map<String, dynamic>.from(e)).toList()
            : [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _exportPDF() async {
    final pdf = pw.Document();
    final income = double.tryParse(_summary['income'].toString()) ?? 0;
    final expense = double.tryParse(_summary['expense'].toString()) ?? 0;

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (context) => [
        pw.Header(level: 0, child: pw.Text('Navratri 2026 - Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold))),
        pw.SizedBox(height: 20),
        pw.Header(level: 1, child: pw.Text('Financial Summary')),
        pw.Table.fromTextArray(
          headers: ['Item', 'Amount'],
          data: [
            ['Fund Collection', '₹${income.toStringAsFixed(0)}'],
            ['Sponsorship', '₹${(_summary['sponsors'] ?? 0)}'],
            ['Total Expenses', '₹${expense.toStringAsFixed(0)}'],
            ['Net Balance', '₹${(income - expense).toStringAsFixed(0)}'],
          ],
        ),
        pw.SizedBox(height: 20),
        pw.Header(level: 1, child: pw.Text('Category-wise Expenses')),
        pw.Table.fromTextArray(
          headers: ['Category', 'Amount'],
          data: _categoryExpenses.map((e) => [e['category_name'] ?? '', '₹${e['total']}']).toList(),
        ),
        pw.SizedBox(height: 20),
        pw.Header(level: 1, child: pw.Text('Event Statistics')),
        pw.Table.fromTextArray(
          headers: ['Metric', 'Count'],
          data: [
            ['Members', '${_summary['members'] ?? 0}'],
            ['Tickets Assigned', '${_summary['ticket_assigned'] ?? 0}'],
            ['Winners', '${_summary['ticket_winners'] ?? 0}'],
          ],
        ),
      ],
    ));

    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.purpleDark,
      appBar: AppBar(
        title: const Text('Reports & Analytics', style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.purpleDeep,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: const Icon(Icons.picture_as_pdf, color: Colors.white), onPressed: _exportPDF, tooltip: 'Export PDF'),
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _loadData),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.goldPrimary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('Financial Summary'),
                  _buildFinanceCard(),
                  const SizedBox(height: 20),
                  if (_categoryExpenses.isNotEmpty) ...[
                    _sectionTitle('Expense Breakdown'),
                    _buildPieChart(),
                    const SizedBox(height: 20),
                  ],
                  _sectionTitle('Event Activity'),
                  _buildActivityGrid(),
                  const SizedBox(height: 20),
                  _sectionTitle('Participation'),
                  _buildParticipationCard(),
                ],
              ),
            ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.goldPrimary)),
    );
  }

  Widget _buildFinanceCard() {
    final income = double.tryParse(_summary['income'].toString()) ?? 0;
    final expense = double.tryParse(_summary['expense'].toString()) ?? 0;
    final net = income - expense;
    return Card(
      color: AppTheme.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _financeRow(Icons.attach_money, 'Total Income', '₹${income.toStringAsFixed(0)}', Colors.green),
            _financeRow(Icons.receipt, 'Total Expenses', '₹${expense.toStringAsFixed(0)}', Colors.red),
            const Divider(color: Colors.white24),
            _financeRow(
              Icons.account_balance_wallet,
              'Net Balance',
              '₹${net.toStringAsFixed(0)}',
              net >= 0 ? Colors.green : Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _financeRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(color: Colors.white70))),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  static const List<Color> _chartColors = [
    Colors.blue, Colors.red, Colors.green, Colors.orange, Colors.purple,
    Colors.teal, Colors.amber, Colors.pink, Colors.cyan,
  ];

  Widget _buildPieChart() {
    final total = _categoryExpenses.fold<double>(0, (sum, e) => sum + (double.tryParse(e['total'].toString()) ?? 0));
    if (total == 0) return const SizedBox.shrink();

    return Card(
      color: AppTheme.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: _categoryExpenses.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final e = entry.value;
                    final amount = double.tryParse(e['total'].toString()) ?? 0;
                    final percentage = total > 0 ? (amount / total * 100) : 0.0;
                    return PieChartSectionData(
                      value: amount,
                      title: '${percentage.toStringAsFixed(0)}%',
                      color: _chartColors[idx % _chartColors.length],
                      radius: 80,
                      titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                    );
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
              children: _categoryExpenses.asMap().entries.map((entry) {
                final idx = entry.key;
                final e = entry.value;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 10, height: 10, color: _chartColors[idx % _chartColors.length]),
                    const SizedBox(width: 4),
                    Text('${e['category_name'] ?? ''} ₹${e['total']}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityGrid() {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: [
        _activityCard(Icons.people, 'Members', '${_summary['members'] ?? 0}', Colors.blue),
        _activityCard(Icons.business, 'Sponsors', '${_summary['sponsors'] ?? 0}', Colors.purple),
        _activityCard(Icons.confirmation_number, 'Tickets', '${_summary['ticket_assigned'] ?? 0}', Colors.amber),
        _activityCard(Icons.emoji_events, 'Winners', '${_summary['ticket_winners'] ?? 0}', Colors.green),
        _activityCard(Icons.receipt, 'Expenses', '₹${(_summary['expense'] ?? 0).toStringAsFixed(0)}', Colors.red),
        _activityCard(Icons.attach_money, 'Income', '₹${(_summary['income'] ?? 0).toStringAsFixed(0)}', Colors.teal),
      ],
    );
  }

  Widget _activityCard(IconData icon, String label, String value, Color color) {
    return Card(
      color: AppTheme.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipationCard() {
    final assigned = _summary['ticket_assigned'] ?? 0;
    final winners = _summary['ticket_winners'] ?? 0;
    final members = _summary['members'] ?? 1;
    return Card(
      color: AppTheme.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _participationBar('Tickets Assigned', assigned, assigned + 50, Colors.green),
            const SizedBox(height: 12),
            _participationBar('Winners', winners, assigned > 0 ? assigned : 1, Colors.amber),
            const SizedBox(height: 12),
            _participationBar('Active Members', members, members + 10, Colors.blue),
          ],
        ),
      ),
    );
  }

  Widget _participationBar(String label, int current, int total, Color color) {
    final progress = total > 0 ? current / total : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
            Text('$current / $total', style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress.clamp(0.0, 1.0),
          backgroundColor: Colors.white12,
          valueColor: AlwaysStoppedAnimation(color),
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
      ],
    );
  }
}
