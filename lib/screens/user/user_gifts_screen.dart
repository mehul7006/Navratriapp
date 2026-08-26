import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../database/database_helper.dart';

class UserGiftsScreen extends StatefulWidget {
  const UserGiftsScreen({super.key});

  @override
  State<UserGiftsScreen> createState() => _UserGiftsScreenState();
}

class _UserGiftsScreenState extends State<UserGiftsScreen> {
  List<Map<String, dynamic>> _myGifts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGifts();
  }

  Future<void> _loadGifts() async {
    setState(() => _isLoading = true);
    final authProvider = context.read<AuthProvider>();
    _myGifts = await DatabaseHelper.getMyGifts(authProvider.houseNumber ?? '');
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.purpleDark,
      appBar: AppBar(
        title: const Text('My Gifts'),
        backgroundColor: AppTheme.purpleDeep,
        foregroundColor: AppTheme.goldPrimary,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadGifts),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _myGifts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.card_giftcard_outlined, size: 80, color: AppTheme.textMuted.withOpacity(0.3)),
                      const SizedBox(height: 16),
                      const Text('No gifts received yet', style: TextStyle(fontSize: 18, color: AppTheme.textMuted)),
                      const SizedBox(height: 8),
                      const Text('Gifts will appear here when assigned by the organizer', style: TextStyle(fontSize: 13, color: AppTheme.textMuted), textAlign: TextAlign.center),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.all(12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [AppTheme.goldPrimary.withOpacity(0.2), AppTheme.purpleCard]),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.goldPrimary.withOpacity(0.5)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.card_giftcard, color: AppTheme.goldPrimary, size: 28),
                          const SizedBox(width: 12),
                          Text('${_myGifts.length} Gift${_myGifts.length != 1 ? 's' : ''} Received', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.goldPrimary)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: _myGifts.length,
                        itemBuilder: (context, index) => _buildGiftCard(_myGifts[index]),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildGiftCard(Map<String, dynamic> gift) {
    final type = gift['gift_type'] ?? 'daily';
    final typeColor = type == 'sponsor' ? Colors.orange : Colors.purple;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTheme.hubItemDecoration,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [typeColor.withOpacity(0.3), AppTheme.purpleCard]),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Icon(Icons.card_giftcard, color: typeColor, size: 18),
                const SizedBox(width: 8),
                Text(type == 'sponsor' ? 'Sponsor Gift' : 'Daily Gift', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: typeColor)),
                const Spacer(),
                Text('Day ${gift['day_number'] ?? ''}', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 60, height: 60,
                  decoration: const BoxDecoration(gradient: AppTheme.goldGradient, borderRadius: BorderRadius.all(Radius.circular(14))),
                  child: const Center(child: Icon(Icons.card_giftcard, color: AppTheme.purpleDark, size: 30)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(gift['gift_name'] ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 4),
                      Text('Assigned on ${gift['assigned_at'] ?? ''}', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                    ],
                  ),
                ),
                const Icon(Icons.check_circle, color: Colors.green, size: 28),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
