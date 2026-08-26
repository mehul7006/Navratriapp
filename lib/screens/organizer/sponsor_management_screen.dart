import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_theme.dart';
import '../../database/database_helper.dart';

class SponsorManagementScreen extends StatefulWidget {
  const SponsorManagementScreen({super.key});

  @override
  State<SponsorManagementScreen> createState() => _SponsorManagementScreenState();
}

class _SponsorManagementScreenState extends State<SponsorManagementScreen> {
  List<Map<String, dynamic>> _sponsors = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final sponsors = await DatabaseHelper.getAllSponsors();
      setState(() {
        _sponsors = sponsors;
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
        title: const Text('Sponsors', style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.purpleDeep,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _loadData),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.goldPrimary))
          : _sponsors.isEmpty
              ? _buildEmptyState()
              : _buildSponsorList(),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.goldPrimary,
        onPressed: _showAddSponsorDialog,
        icon: const Icon(Icons.add, color: Colors.black),
        label: const Text('Add Sponsor', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.business, size: 64, color: Colors.white24),
          SizedBox(height: 16),
          Text('No sponsors yet', style: TextStyle(color: Colors.white54, fontSize: 16)),
          SizedBox(height: 8),
          Text('Add sponsors to manage their profiles', style: TextStyle(color: Colors.white38, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildSponsorList() {
    final totalAmount = _sponsors.fold<double>(0, (sum, s) => sum + (double.tryParse(s['sponsorship_amount'].toString()) ?? 0));
    final paid = _sponsors.where((s) => s['payment_status'] == 'paid').length;
    final pending = _sponsors.where((s) => s['payment_status'] == 'pending').length;

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [AppTheme.purpleDeep, AppTheme.purpleDeep.withValues(alpha: 0.7)]),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statItem('Total', '${_sponsors.length}', Colors.white),
              _statItem('Amount', '₹${totalAmount.toStringAsFixed(0)}', AppTheme.goldPrimary),
              _statItem('Paid', '$paid', Colors.green),
              _statItem('Pending', '$pending', Colors.orange),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _sponsors.length,
            itemBuilder: (context, index) => _buildSponsorCard(_sponsors[index]),
          ),
        ),
      ],
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.white70)),
      ],
    );
  }

  Widget _buildSponsorCard(Map<String, dynamic> sponsor) {
    final paymentStatus = sponsor['payment_status'] ?? 'pending';
    final statusColor = paymentStatus == 'paid' ? Colors.green : Colors.orange;
    final imageBase64 = sponsor['advertisement_image']?.toString();
    return Card(
      color: AppTheme.cardBg,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppTheme.goldPrimary,
                      backgroundImage: imageBase64 != null && imageBase64.isNotEmpty
                          ? MemoryImage(base64Decode(imageBase64))
                          : null,
                      child: imageBase64 == null || imageBase64.isEmpty
                          ? Text(
                              (sponsor['name'] ?? 'S')[0].toString().toUpperCase(),
                              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0, right: 0,
                      child: GestureDetector(
                        onTap: () => _uploadImage(sponsor),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(color: AppTheme.goldPrimary, shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt, size: 12, color: Colors.black),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(sponsor['name'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      Text('House: ${sponsor['house_number']}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white70),
                  onSelected: (v) => _handleAction(v, sponsor),
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(
                      value: 'toggle',
                      child: Text(paymentStatus == 'paid' ? 'Mark Pending' : 'Mark Paid'),
                    ),
                    const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                  ],
                ),
              ],
            ),
            const Divider(color: Colors.white24),
            _detailRow(Icons.business, 'Company', sponsor['company_name'] ?? 'N/A'),
            _detailRow(Icons.phone, 'Mobile', sponsor['mobile_number'] ?? 'N/A'),
            _detailRow(Icons.attach_money, 'Amount', '₹${sponsor['sponsorship_amount'] ?? 0}'),
            Row(
              children: [
                Icon(Icons.circle, size: 10, color: statusColor),
                const SizedBox(width: 8),
                Text('Status: ', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                Text(paymentStatus.toString().toUpperCase(),
                    style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
            if (sponsor['advertisement_text']?.toString().isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('${sponsor['advertisement_text'] ?? ''}', style: const TextStyle(color: Colors.white70, fontSize: 11, fontStyle: FontStyle.italic)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.white38),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(color: Colors.white54, fontSize: 12)),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 12))),
        ],
      ),
    );
  }

  Future<void> _handleAction(String action, Map<String, dynamic> sponsor) async {
    if (action == 'toggle') {
      final newStatus = sponsor['payment_status'] == 'paid' ? 'pending' : 'paid';
      await DatabaseHelper.updateSponsor(sponsor['id'], paymentStatus: newStatus);
      _loadData();
    } else if (action == 'edit') {
      _showEditSponsorDialog(sponsor);
    } else if (action == 'delete') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete Sponsor?'),
          content: Text('Delete ${sponsor['name']}? This cannot be undone.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
          ],
        ),
      );
      if (confirm == true) {
        await DatabaseHelper.deleteSponsor(sponsor['id']);
        _loadData();
      }
    }
  }

  Future<void> _uploadImage(Map<String, dynamic> sponsor) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 512, maxHeight: 512, imageQuality: 75);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      final base64Image = base64Encode(bytes);
      await DatabaseHelper.updateSponsorImage(sponsor['id'], base64Image);
      _loadData();
    }
  }

  void _showAddSponsorDialog() {
    final houseController = TextEditingController();
    final nameController = TextEditingController();
    final mobileController = TextEditingController();
    final companyController = TextEditingController();
    final adController = TextEditingController();
    final amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: const Text('Add Sponsor', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(houseController, 'House Number'),
              _field(nameController, 'Contact Name'),
              _field(mobileController, 'Mobile Number'),
              _field(companyController, 'Company Name'),
              _field(adController, 'Advertisement Text'),
              _field(amountController, 'Sponsorship Amount', isNumber: true),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              if (houseController.text.isNotEmpty && nameController.text.isNotEmpty) {
                await DatabaseHelper.addSponsor(
                  houseNumber: houseController.text,
                  name: nameController.text,
                  mobile: mobileController.text,
                  companyName: companyController.text,
                  adText: adController.text,
                  amount: double.tryParse(amountController.text),
                );
                Navigator.pop(ctx);
                _loadData();
              }
            },
            child: const Text('Add', style: TextStyle(color: AppTheme.goldPrimary)),
          ),
        ],
      ),
    );
  }

  void _showEditSponsorDialog(Map<String, dynamic> sponsor) {
    final companyController = TextEditingController(text: sponsor['company_name'] ?? '');
    final adController = TextEditingController(text: sponsor['advertisement_text'] ?? '');
    final amountController = TextEditingController(text: sponsor['sponsorship_amount']?.toString() ?? '0');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: Text('Edit ${sponsor['name']}', style: const TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(companyController, 'Company Name'),
              _field(adController, 'Advertisement Text'),
              _field(amountController, 'Amount', isNumber: true),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await DatabaseHelper.updateSponsor(
                sponsor['id'],
                companyName: companyController.text,
                adText: adController.text,
                amount: double.tryParse(amountController.text),
              );
              Navigator.pop(ctx);
              _loadData();
            },
            child: const Text('Save', style: TextStyle(color: AppTheme.goldPrimary)),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController controller, String label, {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          border: const OutlineInputBorder(),
          enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
        ),
      ),
    );
  }
}
