import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../database/database_helper.dart';
import 'package:navratri_app/widgets/background_scaffold.dart';

class SponsorAdvertisementScreen extends StatefulWidget {
  const SponsorAdvertisementScreen({super.key});

  @override
  State<SponsorAdvertisementScreen> createState() => _SponsorAdvertisementScreenState();
}

class _SponsorAdvertisementScreenState extends State<SponsorAdvertisementScreen> {
  List<Map<String, dynamic>> _allAds = [];
  bool _isLoading = true;
  int _selectedDay = 0;
  String _activeTab = 'pending';

  @override
  void initState() {
    super.initState();
    _loadAds();
  }

  int get _userId {
    final auth = context.read<AuthProvider>();
    return auth.currentUser?['id'] ?? 0;
  }

  Future<void> _loadAds() async {
    setState(() => _isLoading = true);
    try {
      final ads = await DatabaseHelper.getSponsorAds(_userId);
      if (mounted) setState(() { _allAds = ads; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredAds {
    var list = _allAds.where((a) => a['status'] == _activeTab).toList();
    if (_selectedDay > 0) {
      list = list.where((a) => a['day_number'] == _selectedDay || a['day_number'] == null).toList();
    }
    return list;
  }

  void _showAddAdDialog() {
    int? selectedDay;
    bool allDays = true;
    XFile? pickedFile;
    String? base64Image;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.purpleCard.withValues(alpha: 0.6),
          title: const Text('Add Advertisement', style: TextStyle(color: Colors.white, fontSize: 18)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  title: Text(allDays ? 'All 10 Days' : 'Specific Day Only',
                      style: const TextStyle(color: Colors.white, fontSize: 14)),
                  subtitle: Text(allDays ? 'Ad shows on every day' : 'Ad shows only on selected day',
                      style: const TextStyle(color: Colors.white54, fontSize: 11)),
                  value: allDays,
                  onChanged: (v) => setDialogState(() => allDays = v),
                  activeColor: AppTheme.goldPrimary,
                  contentPadding: EdgeInsets.zero,
                ),
                if (!allDays) ...[
                  const SizedBox(height: 8),
                  const Text('Select Day:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: List.generate(10, (i) {
                      final day = i + 1;
                      final isSelected = selectedDay == day;
                      return GestureDetector(
                        onTap: () => setDialogState(() => selectedDay = day),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.goldPrimary : AppTheme.purpleDark,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: isSelected ? AppTheme.goldPrimary : Colors.white24),
                          ),
                          child: Text('D$day', style: TextStyle(
                            color: isSelected ? AppTheme.purpleDark : Colors.white,
                            fontWeight: FontWeight.bold, fontSize: 12,
                          )),
                        ),
                      );
                    }),
                  ),
                ],
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () async {
                    try {
                      final picker = ImagePicker();
                      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                      if (picked != null) {
                        final bytes = await picked.readAsBytes();
                        setDialogState(() {
                          pickedFile = picked;
                          base64Image = base64Encode(bytes);
                        });
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Image picker error: $e'), backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppTheme.purpleDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.goldPrimary.withOpacity(0.4), style: BorderStyle.solid),
                    ),
                    child: base64Image != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.memory(base64Decode(base64Image!), fit: BoxFit.cover),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate, color: Colors.white38, size: 40),
                              const SizedBox(height: 8),
                              Text('Tap to upload image', style: TextStyle(color: Colors.white38, fontSize: 13)),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              onPressed: (base64Image != null && (allDays || selectedDay != null))
                  ? () async {
                      Navigator.pop(ctx);
                      await _createAd(base64Image!, allDays ? null : selectedDay);
                    }
                  : null,
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.goldPrimary),
              child: const Text('Add', style: TextStyle(color: AppTheme.purpleDark, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createAd(String imageData, int? dayNumber) async {
    try {
      await DatabaseHelper.createSponsorAd(userId: _userId, imageData: imageData, dayNumber: dayNumber);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Advertisement added!'), backgroundColor: Colors.green),
        );
        _loadAds();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _toggleAd(int id, bool currentStatus) async {
    try {
      await DatabaseHelper.toggleSponsorAd(id, !currentStatus);
      _loadAds();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteAd(int id) async {
    try {
      await DatabaseHelper.deleteSponsorAd(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Advertisement deleted'), backgroundColor: Colors.orange),
        );
        _loadAds();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundScaffold(
      backgroundImage: 'assets/images/LOGIN_BG.jpg',
      backgroundColor: const Color(0xA60C0117),
      appBar: AppBar(
        title: const Text('My Advertisements', style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.purpleDeep,
        iconTheme: const IconThemeData(color: AppTheme.goldPrimary),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _loadAds),
        ],
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.goldPrimary))
          : Column(
              children: [
                _buildDaySelector(),
                _buildTabBar(),
                Expanded(child: _buildAdList()),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddAdDialog,
        backgroundColor: AppTheme.goldPrimary,
        child: const Icon(Icons.add, color: AppTheme.purpleDark, size: 28),
      ),
    );
  }

  Widget _buildDaySelector() {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: 11,
        itemBuilder: (context, index) {
          final day = index;
          final isSelected = day == _selectedDay;
          return GestureDetector(
            onTap: () => setState(() => _selectedDay = day),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.goldPrimary : AppTheme.purpleCard.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isSelected ? AppTheme.goldPrimary : AppTheme.cardBorder),
              ),
              child: Center(
                child: Text(day == 0 ? 'All' : 'D$day', style: TextStyle(
                  color: isSelected ? AppTheme.purpleDark : Colors.white,
                  fontWeight: FontWeight.bold, fontSize: 12,
                )),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabBar() {
    final pendingCount = _allAds.where((a) => a['status'] == 'pending').length;
    final confirmedCount = _allAds.where((a) => a['status'] == 'confirmed').length;
    final rejectedCount = _allAds.where((a) => a['status'] == 'rejected').length;
    final cancelledCount = _allAds.where((a) => a['status'] == 'cancelled').length;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.purpleCard.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(child: _buildTab('pending', 'Pending')),
          Expanded(child: _buildTab('confirmed', 'Confirmed')),
          Expanded(child: _buildTab('rejected', 'Rejected')),
          Expanded(child: _buildTab('cancelled', 'Cancelled')),
        ],
      ),
    );
  }

  Widget _buildTab(String tab, String label) {
    final isActive = _activeTab == tab;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = tab),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.goldPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(label, textAlign: TextAlign.center, style: TextStyle(
          color: isActive ? AppTheme.purpleDark : Colors.white70,
          fontWeight: FontWeight.bold, fontSize: 13,
        )),
      ),
    );
  }

  Widget _buildAdList() {
    final ads = _filteredAds;
    if (ads.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.ad_units, size: 48, color: Colors.white24),
            const SizedBox(height: 12),
            Text(
              'No $_activeTab advertisements',
              style: const TextStyle(color: Colors.white38, fontSize: 16),
            ),
            const SizedBox(height: 4),
            const Text('Tap + to add your first ad', style: TextStyle(color: Colors.white24, fontSize: 12)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: ads.length,
      itemBuilder: (context, index) {
        final ad = ads[index];
        final dayNum = ad['day_number'];
        final isVisible = ad['is_visible'] == true;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppTheme.purpleCard.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isVisible ? AppTheme.goldPrimary.withValues(alpha: 0.4) : Colors.red.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 240,
                      height: 180,
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
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: dayNum == null ? Colors.blue.withValues(alpha: 0.2) : AppTheme.goldPrimary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        dayNum == null ? 'All Days' : 'Day $dayNum',
                        style: TextStyle(
                          color: dayNum == null ? Colors.blue : AppTheme.goldPrimary,
                          fontSize: 11, fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _statusColor(ad['status']).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _statusLabel(ad['status']),
                        style: TextStyle(
                          color: _statusColor(ad['status']),
                          fontSize: 11, fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (isVisible) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('Visible Now',
                          style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                    const Spacer(),
                    if (ad['status'] == 'pending' || ad['status'] == 'confirmed')
                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.orange, size: 20),
                        onPressed: () => _cancelAd(ad['id']),
                        tooltip: 'Cancel Ad',
                      ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                      onPressed: () => _deleteAd(ad['id']),
                      tooltip: 'Delete',
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'confirmed': return Colors.green;
      case 'rejected': return Colors.red;
      case 'cancelled': return Colors.grey;
      default: return Colors.orange;
    }
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'confirmed': return 'Confirmed';
      case 'rejected': return 'Rejected';
      case 'cancelled': return 'Cancelled';
      default: return 'Pending';
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

  Future<void> _cancelAd(int id) async {
    try {
      await DatabaseHelper.cancelSponsorAd(id);
      _loadAds();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
