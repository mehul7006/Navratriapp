import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../database/database_helper.dart';
import '../../l10n/app_localizations.dart';

class UserSongRequestScreen extends StatefulWidget {
  const UserSongRequestScreen({super.key});

  @override
  State<UserSongRequestScreen> createState() => _UserSongRequestScreenState();
}

class _UserSongRequestScreenState extends State<UserSongRequestScreen> {
  final _songNameController = TextEditingController();
  final _youtubeController = TextEditingController();
  List<Map<String, dynamic>> _requests = [];
  List<Map<String, dynamic>> _suggestions = [];
  int _selectedDay = 1;
  bool _isLoading = true;
  bool _isSubmitting = false;
  Timer? _refreshTimer;
  String _activeTab = 'live';

  @override
  void initState() {
    super.initState();
    _loadData();
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) => _loadData());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _songNameController.dispose();
    _youtubeController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final requests = await DatabaseHelper.getSongRequests(day: _selectedDay);
      final suggestions = await DatabaseHelper.getSongSuggestions(day: _selectedDay);
      if (mounted) {
        setState(() {
          _requests = requests;
          _suggestions = suggestions;
          _isLoading = false;
        });
      }
    } catch (_) {}
  }

  Future<void> _submitRequest() async {
    if (_songNameController.text.trim().isEmpty) return;
    final auth = context.read<AuthProvider>();
    final userId = auth.currentUser?['id'];
    if (userId == null) return;

    setState(() => _isSubmitting = true);
    try {
      await DatabaseHelper.createSongRequest(
        userId: userId,
        songName: _songNameController.text.trim(),
        youtubeLink: _youtubeController.text.trim().isNotEmpty ? _youtubeController.text.trim() : null,
        dayNumber: _selectedDay,
      );
      _songNameController.clear();
      _youtubeController.clear();
      _loadData();
    } catch (_) {}
    setState(() => _isSubmitting = false);
  }

  Future<void> _submitSuggestion() async {
    if (_songNameController.text.trim().isEmpty) return;
    final auth = context.read<AuthProvider>();
    final userId = auth.currentUser?['id'];
    if (userId == null) return;

    setState(() => _isSubmitting = true);
    try {
      await DatabaseHelper.createSongSuggestion(
        userId: userId,
        songName: _songNameController.text.trim(),
        youtubeLink: _youtubeController.text.trim().isNotEmpty ? _youtubeController.text.trim() : null,
        targetDay: _selectedDay + 1 > 9 ? 9 : _selectedDay + 1,
      );
      _songNameController.clear();
      _youtubeController.clear();
      _loadData();
    } catch (_) {}
    setState(() => _isSubmitting = false);
  }

  Future<void> _upvoteRequest(int id) async {
    final auth = context.read<AuthProvider>();
    final userId = auth.currentUser?['id'];
    if (userId == null) return;
    await DatabaseHelper.upvoteSongRequest(id);
    _loadData();
  }

  Future<void> _upvoteSuggestion(int id) async {
    final auth = context.read<AuthProvider>();
    final userId = auth.currentUser?['id'];
    if (userId == null) return;
    await DatabaseHelper.upvoteSongSuggestion(id, userId);
    _loadData();
  }

  Future<void> _launchYoutube(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.purpleDark,
      appBar: AppBar(
        title: Text(AppLocalizations.t('song_requests'), style: const TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.purpleDeep,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _loadData),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.goldPrimary))
          : Column(
              children: [
                _buildDaySelector(),
                _buildTabBar(),
                Expanded(
                  child: _activeTab == 'live' ? _buildLiveTab() : _buildSuggestionsTab(),
                ),
                _buildInputSection(),
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

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.purpleCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(child: _buildTab('live', AppLocalizations.t('live_requests'))),
          Expanded(child: _buildTab('suggest', AppLocalizations.t('tomorrows_picks'))),
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
          fontWeight: FontWeight.bold,
          fontSize: 13,
        )),
      ),
    );
  }

  Widget _buildLiveTab() {
    if (_requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.music_note, size: 48, color: Colors.white24),
            const SizedBox(height: 12),
            Text(AppLocalizations.t('no_song_requests'), style: const TextStyle(color: Colors.white38, fontSize: 16)),
            Text(AppLocalizations.t('be_first_song'), style: const TextStyle(color: Colors.white24, fontSize: 12)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _requests.length,
      itemBuilder: (context, index) {
        final req = _requests[index];
        final status = req['status'] ?? 'pending';
        final statusColor = status == 'playing' ? Colors.green :
            status == 'skipped' ? Colors.red : Colors.orange;
        final statusIcon = status == 'playing' ? Icons.play_circle :
            status == 'skipped' ? Icons.skip_next : Icons.hourglass_empty;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.purpleCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: statusColor.withOpacity(0.4)),
          ),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: statusColor.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                child: Icon(statusIcon, color: statusColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(req['song_name'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 2),
                    Text('by ${req['user_name'] ?? 'Unknown'} • ${req['house_number'] ?? ''}',
                        style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                    if (req['youtube_link'] != null && (req['youtube_link'] as String).isNotEmpty)
                      GestureDetector(
                        onTap: () => _launchYoutube(req['youtube_link']),
                        child: Text(req['youtube_link'], style: const TextStyle(fontSize: 10, color: Colors.blue, decoration: TextDecoration.underline)),
                      ),
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.thumb_up, color: AppTheme.goldPrimary, size: 20),
                    onPressed: () => _upvoteRequest(req['id']),
                  ),
                  Text('${req['request_count'] ?? 0}', style: const TextStyle(fontSize: 12, color: AppTheme.goldPrimary)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSuggestionsTab() {
    if (_suggestions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lightbulb_outline, size: 48, color: Colors.white24),
            const SizedBox(height: 12),
            Text(AppLocalizations.t('no_suggestions'), style: const TextStyle(color: Colors.white38, fontSize: 16)),
            Text(AppLocalizations.t('suggest_songs_tomorrow'), style: const TextStyle(color: Colors.white24, fontSize: 12)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _suggestions.length,
      itemBuilder: (context, index) {
        final sug = _suggestions[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.purpleCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: Colors.purple.withOpacity(0.3), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.lightbulb, color: Colors.purpleAccent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(sug['song_name'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 2),
                    Text('by ${sug['user_name'] ?? 'Unknown'}',
                        style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.thumb_up, color: Colors.purpleAccent, size: 20),
                    onPressed: () => _upvoteSuggestion(sug['id']),
                  ),
                  Text('${sug['upvotes'] ?? 0}', style: const TextStyle(fontSize: 12, color: Colors.purpleAccent)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInputSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppTheme.purpleDeep,
        border: Border(top: BorderSide(color: AppTheme.cardBorder)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _songNameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: AppLocalizations.t('hint_song_name'),
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
                width: 100,
                child: TextField(
                  controller: _youtubeController,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  decoration: InputDecoration(
                    hintText: AppLocalizations.t('hint_youtube_link'),
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: AppTheme.purpleCard,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitRequest,
                  icon: _isSubmitting ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.music_note, size: 16),
                  label: Text(_activeTab == 'live' ? AppLocalizations.t('request') : AppLocalizations.t('suggest')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.goldPrimary,
                    foregroundColor: AppTheme.purpleDark,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
