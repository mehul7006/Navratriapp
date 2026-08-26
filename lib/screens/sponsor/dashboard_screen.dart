import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../database/database_helper.dart';

class SponsorDashboardScreen extends StatefulWidget {
  const SponsorDashboardScreen({super.key});

  @override
  State<SponsorDashboardScreen> createState() => _SponsorDashboardScreenState();
}

class _SponsorDashboardScreenState extends State<SponsorDashboardScreen> {
  Map<String, dynamic>? _sponsorData;
  List<Map<String, dynamic>> _gifts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final authProvider = context.read<AuthProvider>();
    final houseNumber = authProvider.houseNumber ?? '';
    try {
      final sponsors = await DatabaseHelper.getAllSponsors();
      final match = sponsors.where((s) => s['house_number'] == houseNumber).toList();
      final gifts = await DatabaseHelper.getMyGifts(houseNumber);
      setState(() {
        _sponsorData = match.isNotEmpty ? match.first : null;
        _gifts = gifts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.purpleDark,
      appBar: AppBar(
        title: const Text('Sponsor Dashboard'),
        backgroundColor: AppTheme.purpleDeep,
        foregroundColor: AppTheme.goldPrimary,
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: AppTheme.goldPrimary), onPressed: _loadData),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              authProvider.logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.goldPrimary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileCard(user),
                  const SizedBox(height: 16),
                  _buildSponsorInfo(),
                  const SizedBox(height: 16),
                  const Text('Quick Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 12),
                  _buildActionCard(
                    icon: Icons.upload,
                    title: 'My Advertisement',
                    subtitle: _sponsorData?['advertisement_image']?.toString().isNotEmpty == true
                        ? 'Image uploaded - tap to change'
                        : (_sponsorData?['advertisement_text']?.toString().isNotEmpty == true
                            ? _sponsorData!['advertisement_text']
                            : 'No advertisement uploaded'),
                    onTap: () => _showAdDialog(),
                  ),
                  _buildActionCard(
                    icon: Icons.card_giftcard,
                    title: 'My Gift Contributions',
                    subtitle: '${_gifts.length} gifts distributed',
                    onTap: () {},
                  ),
                  _buildActionCard(
                    icon: Icons.payment,
                    title: 'Payment Status',
                    subtitle: 'Status: ${(_sponsorData?['payment_status'] ?? 'pending').toString().toUpperCase()}',
                    onTap: () {},
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileCard(Map<String, dynamic>? user) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.redAccent.withValues(alpha: 0.8), AppTheme.purpleCard.withValues(alpha: 0.95)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.goldPrimary),
      ),
      child: Row(
        children: [
          Container(
            width: 60, height: 60,
            decoration: const BoxDecoration(gradient: AppTheme.goldGradient, shape: BoxShape.circle),
            child: const Center(child: Icon(Icons.business, size: 28, color: AppTheme.purpleDark)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user?['name'] ?? 'Sponsor', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 4),
                Text('House: ${user?['house_number'] ?? 'N/A'}', style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
                if (_sponsorData?['company_name']?.toString().isNotEmpty == true)
                  Text('Company: ${_sponsorData!['company_name']}', style: const TextStyle(fontSize: 13, color: AppTheme.goldPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSponsorInfo() {
    final status = _sponsorData?['payment_status'] ?? 'pending';
    final statusColor = status == 'paid' ? Colors.green : Colors.orange;
    final amount = _sponsorData?['sponsorship_amount'] ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.hubItemDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Your Sponsorship', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.goldPrimary)),
          const SizedBox(height: 12),
          _buildInfoRow('Status', status.toString().toUpperCase(), statusColor),
          _buildInfoRow('Amount', '₹$amount', AppTheme.goldPrimary),
          _buildInfoRow('Company', _sponsorData?['company_name'] ?? 'N/A', Colors.white),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textMuted)),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildActionCard({required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Container(
          width: 44, height: 44,
          decoration: const BoxDecoration(gradient: AppTheme.goldGradient, borderRadius: BorderRadius.all(Radius.circular(12))),
          child: Icon(icon, color: AppTheme.purpleDark),
        ),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: const Icon(Icons.arrow_forward_ios, color: AppTheme.goldPrimary, size: 16),
        onTap: onTap,
        tileColor: AppTheme.purpleCard.withValues(alpha: 0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showAdDialog() {
    final adText = _sponsorData?['advertisement_text'] ?? '';
    final existingImage = _sponsorData?['advertisement_image'] ?? '';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.purpleCard,
        title: const Text('My Advertisement', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (existingImage.toString().isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(base64Decode(existingImage), height: 120, width: double.infinity, fit: BoxFit.cover),
                ),
                const SizedBox(height: 12),
              ],
              Text(adText.isNotEmpty ? adText : 'No advertisement uploaded yet.', style: const TextStyle(color: Colors.white70)),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              await _pickAndUploadImage();
            },
            icon: const Icon(Icons.camera_alt, color: AppTheme.goldPrimary, size: 18),
            label: const Text('Upload Image', style: TextStyle(color: AppTheme.goldPrimary)),
          ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close', style: TextStyle(color: AppTheme.goldPrimary))),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked == null) return;
    final bytes = await File(picked.path).readAsBytes();
    final base64Image = base64Encode(bytes);
    final auth = context.read<AuthProvider>();
    final userId = auth.userId ?? 0;
    try {
      await DatabaseHelper.updateSponsorImage(userId, base64Image);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image uploaded successfully'), backgroundColor: Colors.green));
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
      }
    }
  }
}
