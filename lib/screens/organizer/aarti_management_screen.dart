import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../database/database_helper.dart';
import '../../l10n/app_localizations.dart';
import 'package:navratri_app/widgets/background_scaffold.dart';

class AartiManagementScreen extends StatefulWidget {
  const AartiManagementScreen({super.key});

  @override
  State<AartiManagementScreen> createState() => _AartiManagementScreenState();
}

class _AartiManagementScreenState extends State<AartiManagementScreen> {
  List<Map<String, dynamic>> _bookings = [];
  bool _isLoading = true;
  int _selectedDay = 1;
  int _selectedTab = 0; // 0=Book, 1=Pending, 2=Confirmed

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    _bookings = await DatabaseHelper.getAartiBookings(dayNumber: _selectedDay);
    if (mounted) setState(() => _isLoading = false);
  }

  List<Map<String, dynamic>> get _pendingBookings =>
      _bookings.where((b) => b['status'] == 'pending').toList();

  List<Map<String, dynamic>> get _confirmedBookings =>
      _bookings.where((b) => b['status'] == 'approved').toList();

  @override
  Widget build(BuildContext context) {
    return BackgroundBody(
      child: Stack(
        children: [
          Column(
            children: [
              _buildDaySelector(),
              _buildTabBar(),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _selectedTab == 0
                        ? _buildBookAartiTab()
                        : _selectedTab == 1
                            ? _buildPendingTab()
                            : _buildConfirmedTab(),
              ),
            ],
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              backgroundColor: AppTheme.goldPrimary,
              onPressed: () => _showAddBookingDialog(),
              child: const Icon(Icons.add, color: AppTheme.purpleDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySelector() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 9,
        itemBuilder: (context, index) {
          final day = index + 1;
          final isSelected = _selectedDay == day;
          return GestureDetector(
            onTap: () { setState(() => _selectedDay = day); _loadData(); },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.goldPrimary : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.goldPrimary.withOpacity(0.5)),
              ),
              child: Text('Day $day', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isSelected ? AppTheme.purpleDark : AppTheme.textMuted)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          _buildTab('Book Aarti', 0),
          const SizedBox(width: 6),
          _buildTab('Pending (${_pendingBookings.length})', 1),
          const SizedBox(width: 6),
          _buildTab('Confirmed (${_confirmedBookings.length})', 2),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.goldPrimary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.goldPrimary.withOpacity(0.5)),
          ),
          child: Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isSelected ? AppTheme.purpleDark : AppTheme.textMuted)),
        ),
      ),
    );
  }

  Widget _buildBookAartiTab() {
    if (_bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wb_sunny_outlined, size: 48, color: AppTheme.goldPrimary.withOpacity(0.3)),
            const SizedBox(height: 12),
            Text('No bookings for Day $_selectedDay', style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
            const SizedBox(height: 8),
            Text('Tap + to book aarti', style: TextStyle(color: AppTheme.goldPrimary.withOpacity(0.5), fontSize: 12)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: _bookings.length,
      itemBuilder: (context, index) => _buildBookingCard(_bookings[index]),
    );
  }

  Widget _buildPendingTab() {
    if (_pendingBookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pending_actions, size: 48, color: AppTheme.goldPrimary.withOpacity(0.3)),
            const SizedBox(height: 12),
            Text('No pending bookings', style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: _pendingBookings.length,
      itemBuilder: (context, index) => _buildBookingCard(_pendingBookings[index], showActions: true),
    );
  }

  Widget _buildConfirmedTab() {
    if (_confirmedBookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 48, color: AppTheme.goldPrimary.withOpacity(0.3)),
            const SizedBox(height: 12),
            Text('No confirmed bookings', style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: _confirmedBookings.length,
      itemBuilder: (context, index) => _buildBookingCard(_confirmedBookings[index], showActions: true),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking, {bool showActions = false}) {
    final status = booking['status'] ?? 'pending';
    final statusColor = status == 'approved' ? Colors.green : (status == 'rejected' ? Colors.red : Colors.orange);
    final name = booking['user_name']?.toString() ?? '';
    final house = booking['house_number']?.toString() ?? '';
    final bookingId = booking['id']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.hubItemDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50, height: 50,
                decoration: const BoxDecoration(gradient: AppTheme.goldGradient, borderRadius: BorderRadius.all(Radius.circular(12))),
                child: Center(
                  child: Text(house.length >= 3 ? house.substring(0, 3) : house, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.purpleDark)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name.isNotEmpty ? name : house, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                    const SizedBox(height: 2),
                    Text('House: $house', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                    const SizedBox(height: 2),
                    Text('Booking #$bookingId', style: TextStyle(fontSize: 11, color: AppTheme.goldPrimary.withOpacity(0.7))),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.2), borderRadius: BorderRadius.circular(20), border: Border.all(color: statusColor)),
                child: Text(status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor)),
              ),
            ],
          ),
          if (showActions && status == 'pending') ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await DatabaseHelper.updateBookingStatus(booking['id'], 'approved');
                      _loadData();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Booking confirmed'), backgroundColor: Colors.green),
                        );
                      }
                    },
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Confirm', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 10)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await DatabaseHelper.updateBookingStatus(booking['id'], 'rejected');
                      _loadData();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Booking rejected'), backgroundColor: Colors.red),
                        );
                      }
                    },
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Reject', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.redAccent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 10)),
                  ),
                ),
              ],
            ),
          ],
          if (showActions && status == 'approved') ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await DatabaseHelper.cancelAartiBooking(booking['id']);
                  _loadData();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Booking cancelled'), backgroundColor: Colors.orange),
                    );
                  }
                },
                icon: const Icon(Icons.cancel, size: 16),
                label: const Text('Cancel Booking', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 10)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showAddBookingDialog() {
    final houseController = TextEditingController();
    final nameController = TextEditingController();
    int formDay = _selectedDay;
    List<Map<String, dynamic>> members = [];
    bool isSearching = false;
    void Function(VoidCallback)? sheetSetState;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.purpleCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          sheetSetState = setSheetState;
          return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Book Aarti Slot', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.goldPrimary)),
                const SizedBox(height: 16),
                Text('Select Day', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.goldPrimary)),
                const SizedBox(height: 8),
                Container(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 9,
                    itemBuilder: (ctx, index) {
                      final day = index + 1;
                      final isFormSelected = formDay == day;
                      return GestureDetector(
                        onTap: () => setSheetState(() => formDay = day),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isFormSelected ? AppTheme.goldPrimary : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.goldPrimary.withOpacity(0.5)),
                          ),
                          child: Text('Day $day', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isFormSelected ? AppTheme.purpleDark : AppTheme.textMuted)),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                _buildField(controller: houseController, label: 'House Number (e.g. B437)', icon: Icons.home, textCapitalization: TextCapitalization.characters, autoCapitalize: true),
                const SizedBox(height: 4),
                if (isSearching)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Text('Searching...', style: TextStyle(color: AppTheme.goldPrimary, fontSize: 12)),
                  ),
                if (members.isNotEmpty)
                  Container(
                    constraints: const BoxConstraints(maxHeight: 150),
                    decoration: BoxDecoration(
                      color: AppTheme.purpleDark,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.goldPrimary.withOpacity(0.3)),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: members.length,
                      itemBuilder: (ctx, i) {
                        final m = members[i];
                        return ListTile(
                          dense: true,
                          title: Text(m['name'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 14)),
                          subtitle: Text(m['house_number'] ?? '', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                          onTap: () {
                            setSheetState(() {
                              nameController.text = m['name'] ?? '';
                              houseController.text = m['house_number'] ?? '';
                              members = [];
                            });
                          },
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 12),
                _buildField(controller: nameController, label: 'Name', icon: Icons.person),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    if (houseController.text.isEmpty || nameController.text.isEmpty) return;
                    try {
                      final users = await DatabaseHelper.getMembersByHouse(houseController.text.trim().toUpperCase());
                      int userId = 0;
                      for (final u in users) {
                        if ((u['name'] ?? '').toString().toLowerCase() == nameController.text.trim().toLowerCase()) {
                          userId = u['id'] as int;
                          break;
                        }
                      }
                      await DatabaseHelper.bookAartiSlot(
                        userId: userId,
                        houseNumber: houseController.text.trim().toUpperCase(),
                        dayNumber: formDay,
                        slotId: 0,
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                      _loadData();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Booking created for Day $formDay'), backgroundColor: Colors.green),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.goldPrimary, foregroundColor: AppTheme.purpleDark, padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: const Text('BOOK SLOT', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
        },
      ),
    );

    houseController.addListener(() async {
      final text = houseController.text.trim();
      if (text.length < 2) {
        sheetSetState?.call(() { members = []; isSearching = false; });
        return;
      }
      sheetSetState?.call(() => isSearching = true);
      try {
        final results = await DatabaseHelper.getMembersByHouse(text);
        sheetSetState?.call(() { members = results; isSearching = false; });
      } catch (_) {
        sheetSetState?.call(() => isSearching = false);
      }
    });
  }

  Widget _buildField({required TextEditingController controller, required String label, required IconData icon, TextInputType keyboardType = TextInputType.text, TextCapitalization textCapitalization = TextCapitalization.none, bool autoCapitalize = false}) {
    return TextFormField(
      controller: controller, keyboardType: keyboardType, textCapitalization: textCapitalization, style: const TextStyle(color: Colors.white),
      onChanged: autoCapitalize ? (v) { final upper = v.toUpperCase(); if (v != upper) { controller.value = controller.value.copyWith(text: upper, selection: TextSelection.collapsed(offset: upper.length)); } } : null,
      decoration: InputDecoration(
        labelText: label, prefixIcon: Icon(icon, color: AppTheme.goldPrimary),
        labelStyle: const TextStyle(color: AppTheme.textMuted), filled: true,
        fillColor: AppTheme.purpleDark.withOpacity(0.5),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.goldPrimary.withOpacity(0.3))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.goldPrimary.withOpacity(0.3))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.goldPrimary)),
      ),
    );
  }
}
