import 'dart:convert';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../database/database_helper.dart';
import 'package:navratri_app/widgets/background_scaffold.dart';

class AdConfirmationScreen extends StatefulWidget {
  const AdConfirmationScreen({super.key});

  @override
  State<AdConfirmationScreen> createState() => _AdConfirmationScreenState();
}

class _AdConfirmationScreenState extends State<AdConfirmationScreen> {
  List<Map<String, dynamic>> _allAds = [];
  bool _isLoading = true;
  String _selectedTab = 'pending';

  @override
  void initState() {
    super.initState();
    _loadAds();
  }

  Future<void> _loadAds() async {
    setState(() => _isLoading = true);
    try {
      final ads = await DatabaseHelper.getAllSponsorAdsForOrganizer();
      if (mounted) setState(() { _allAds = ads; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredAds => _allAds.where((a) => a['status'] == _selectedTab).toList();

  Future<void> _confirmAd(int id) async {
    try {
      await DatabaseHelper.confirmSponsorAd(id);
      _loadAds();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _rejectAd(int id) async {
    try {
      await DatabaseHelper.rejectSponsorAd(id);
      _loadAds();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = _allAds.where((a) => a['status'] == 'pending').length;
    final confirmedCount = _allAds.where((a) => a['status'] == 'confirmed').length;
    final rejectedCount = _allAds.where((a) => a['status'] == 'rejected').length;
    final cancelledCount = _allAds.where((a) => a['status'] == 'cancelled').length;

    return BackgroundScaffold(
      backgroundImage: 'assets/images/BGIMAGE.jpg',
      backgroundColor: const Color(0xA60C0117),
      appBar: AppBar(
        title: const Text('Ad Confirmation', style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.purpleDeep,
        iconTheme: const IconThemeData(color: AppTheme.goldPrimary),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _loadAds),
        ],
      ),
      child: Column(
        children: [
          _buildTabBar(pendingCount, confirmedCount, rejectedCount, cancelledCount),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.goldPrimary))
                : _filteredAds.isEmpty
                    ? Center(child: Text('No ${_selectedTab} ads', style: TextStyle(color: Colors.white54, fontSize: 16)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredAds.length,
                        itemBuilder: (context, index) => _buildAdCard(_filteredAds[index]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(int pending, int confirmed, int rejected, int cancelled) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.purpleCard.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildTab('pending', 'Pending', pending, Colors.orange),
          _buildTab('confirmed', 'Confirmed', confirmed, Colors.green),
          _buildTab('rejected', 'Rejected', rejected, Colors.red),
          _buildTab('cancelled', 'Cancelled', cancelled, Colors.grey),
        ],
      ),
    );
  }

  Widget _buildTab(String tab, String label, int count, Color color) {
    final isActive = _selectedTab == tab;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = tab),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? color.withValues(alpha: 0.3) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(label, style: TextStyle(
                color: isActive ? color : Colors.white54,
                fontWeight: FontWeight.bold, fontSize: 13,
              )),
              const SizedBox(height: 2),
              Text('$count', style: TextStyle(
                color: isActive ? color : Colors.white38,
                fontSize: 18, fontWeight: FontWeight.bold,
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdCard(Map<String, dynamic> ad) {
    final status = ad['status'] ?? 'pending';
    final dayNum = ad['day_number'];
    final sponsorName = ad['sponsor_name'] ?? '';
    final sponsorHouse = ad['sponsor_house'] ?? '';
    final isPending = status == 'pending';
    final isConfirmed = status == 'confirmed';
    final isRejected = status == 'rejected';
    final isCancelled = status == 'cancelled';

    Color statusColor;
    String statusLabel;
    if (isPending) { statusColor = Colors.orange; statusLabel = 'Pending Review'; }
    else if (isConfirmed) { statusColor = Colors.green; statusLabel = 'Confirmed'; }
    else if (isCancelled) { statusColor = Colors.grey; statusLabel = 'Cancelled'; }
    else { statusColor = Colors.red; statusLabel = 'Rejected'; }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.purpleCard.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusColor.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 80,
                    height: 60,
                    child: Image.memory(
                      base64Decode(ad['image_data'] ?? ''),
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppTheme.purpleDark,
                        child: const Center(child: Icon(Icons.broken_image, color: Colors.white24, size: 24)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(sponsorName, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text('House: $sponsorHouse', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: dayNum == null ? Colors.blue.withValues(alpha: 0.2) : AppTheme.goldPrimary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(dayNum == null ? 'All Days' : 'Day $dayNum',
                              style: TextStyle(color: dayNum == null ? Colors.blue : AppTheme.goldPrimary, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(statusLabel,
                              style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isPending)
            Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () => _confirmAd(ad['id']),
                      icon: const Icon(Icons.check_circle, color: Colors.green, size: 20),
                      label: Text('Confirm', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.1)),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () => _rejectAd(ad['id']),
                      icon: const Icon(Icons.cancel, color: Colors.red, size: 20),
                      label: Text('Reject', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          if (isConfirmed || isRejected)
            Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
              ),
              child: Row(
                children: [
                  if (isPending || isConfirmed)
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () => _rejectAd(ad['id']),
                        icon: const Icon(Icons.cancel, color: Colors.red, size: 20),
                        label: Text('Cancel', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
