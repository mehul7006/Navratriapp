import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../database/database_helper.dart';
import '../../l10n/app_localizations.dart';
import 'package:navratri_app/widgets/background_scaffold.dart';

class UserShoutoutWallScreen extends StatefulWidget {
  const UserShoutoutWallScreen({super.key});

  @override
  State<UserShoutoutWallScreen> createState() => _UserShoutoutWallScreenState();
}

class _UserShoutoutWallScreenState extends State<UserShoutoutWallScreen> {
  final _messageController = TextEditingController();
  List<Map<String, dynamic>> _shoutouts = [];
  List<Map<String, dynamic>> _members = [];
  int _selectedDay = 1;
  bool _isLoading = true;
  bool _isSubmitting = false;
  Timer? _refreshTimer;
  int? _selectedToUser;
  String _selectedEmoji = '*';

  final _emojis = ['*', '+', '!', '#', '1', '<3', '>>', '~'];

  @override
  void initState() {
    super.initState();
    _loadData();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) => _loadData());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final shoutouts = await DatabaseHelper.getShoutouts(day: _selectedDay);
      final members = await DatabaseHelper.getAllMembers();
      if (mounted) {
        setState(() {
          _shoutouts = shoutouts;
          _members = members;
          _isLoading = false;
        });
      }
    } catch (_) {}
  }

  Future<void> _submitShoutout() async {
    if (_messageController.text.trim().isEmpty) return;
    final auth = context.read<AuthProvider>();
    final userId = auth.currentUser?['id'];
    if (userId == null) return;

    setState(() => _isSubmitting = true);
    try {
      await DatabaseHelper.createShoutout(
        fromUserId: userId,
        toUserId: _selectedToUser,
        message: _messageController.text.trim(),
        emoji: _selectedEmoji,
        dayNumber: _selectedDay,
      );
      _messageController.clear();
      _selectedToUser = null;
      _loadData();
    } catch (_) {}
    setState(() => _isSubmitting = false);
  }

  Future<void> _react(int shoutoutId, String reaction) async {
    final auth = context.read<AuthProvider>();
    final userId = auth.currentUser?['id'];
    if (userId == null) return;
    await DatabaseHelper.reactShoutout(shoutoutId, userId, reaction);
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundScaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.t('shoutout_wall'), style: const TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.purpleDeep,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _loadData),
        ],
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.goldPrimary))
          : Column(
              children: [
                _buildDaySelector(),
                _buildInputSection(),
                Expanded(
                  child: _shoutouts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('🎉', style: TextStyle(fontSize: 48)),
                              const SizedBox(height: 12),
                              Text(AppLocalizations.t('no_shoutouts'), style: const TextStyle(color: Colors.white38, fontSize: 16)),
                              Text(AppLocalizations.t('be_first_congratulate'), style: const TextStyle(color: Colors.white24, fontSize: 12)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _shoutouts.length,
                          itemBuilder: (context, index) => _buildShoutoutCard(_shoutouts[index]),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildDaySelector() {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: 9,
        itemBuilder: (context, index) {
          final day = index + 1;
          final isSelected = day == _selectedDay;
          return GestureDetector(
            onTap: () => setState(() => _selectedDay = day),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.goldPrimary : AppTheme.purpleCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isSelected ? AppTheme.goldPrimary : AppTheme.cardBorder),
              ),
              child: Center(
                child: Text('D$day', style: TextStyle(
                  color: isSelected ? AppTheme.purpleDark : Colors.white,
                  fontWeight: FontWeight.bold,
                )),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppTheme.purpleDeep,
        border: Border(bottom: BorderSide(color: AppTheme.cardBorder)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _emojis.length,
              itemBuilder: (context, index) {
                final emoji = _emojis[index];
                final isSelected = emoji == _selectedEmoji;
                return GestureDetector(
                  onTap: () => setState(() => _selectedEmoji = emoji),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.goldPrimary.withOpacity(0.3) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: isSelected ? Border.all(color: AppTheme.goldPrimary) : null,
                    ),
                    child: Center(child: Text(emoji, style: const TextStyle(fontSize: 20))),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppTheme.purpleCard,
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                isExpanded: true,
                value: _selectedToUser,
                hint: Text(AppLocalizations.t('hint_tag_someone'), style: const TextStyle(color: Colors.white38)),
                dropdownColor: AppTheme.purpleCard,
                style: const TextStyle(color: Colors.white),
                items: _members.map((m) => DropdownMenuItem<int>(
                  value: m['id'],
                  child: Text('${m['name']} (${m['house_number']})', style: const TextStyle(fontSize: 13)),
                )).toList(),
                onChanged: (val) => setState(() => _selectedToUser = val),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.t('hint_write_shoutout'),
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: AppTheme.purpleCard,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitShoutout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.goldPrimary,
                    foregroundColor: AppTheme.purpleDark,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.send, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShoutoutCard(Map<String, dynamic> shoutout) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.purpleCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: const BoxDecoration(gradient: AppTheme.goldGradient, shape: BoxShape.circle),
                child: Center(
                  child: Text(shoutout['emoji'] ?? '🎉', style: const TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(shoutout['from_user_name'] ?? 'Someone', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                        if (shoutout['to_user_name'] != null && (shoutout['to_user_name'] as String).isNotEmpty) ...[
                          const Text(' → ', style: TextStyle(color: AppTheme.textMuted)),
                          Text(shoutout['to_user_name'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.goldPrimary)),
                        ],
                      ],
                    ),
                    Text(shoutout['from_house'] ?? '', style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(shoutout['message'] ?? '', style: const TextStyle(fontSize: 14, color: Colors.white, height: 1.4)),
          const SizedBox(height: 10),
          Row(
            children: ['❤️', '👏', '🔥', '💪'].map((r) {
              return GestureDetector(
                onTap: () => _react(shoutout['id'], r),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.purpleDark,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(r, style: const TextStyle(fontSize: 14)),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
