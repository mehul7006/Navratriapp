import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../database/database_helper.dart';
import '../../l10n/app_localizations.dart';
import 'package:navratri_app/widgets/background_scaffold.dart';

class DjConsoleScreen extends StatefulWidget {
  const DjConsoleScreen({super.key});

  @override
  State<DjConsoleScreen> createState() => _DjConsoleScreenState();
}

class _DjConsoleScreenState extends State<DjConsoleScreen> {
  List<Map<String, dynamic>> _requests = [];
  List<Map<String, dynamic>> _suggestions = [];
  int _selectedDay = 1;
  bool _isLoading = true;
  Timer? _refreshTimer;
  String _activeTab = 'queue';

  @override
  void initState() {
    super.initState();
    _loadData();
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (_) => _loadData());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
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

  Future<void> _playSong(int id) async {
    await DatabaseHelper.playSongRequest(id);
    _loadData();
  }

  Future<void> _skipSong(int id) async {
    await DatabaseHelper.skipSongRequest(id);
    _loadData();
  }

  Future<void> _deleteSong(int id) async {
    await DatabaseHelper.deleteSongRequest(id);
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
    return BackgroundScaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.t('dj_console'), style: const TextStyle(color: Colors.white)),
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
                _buildNowPlaying(),
                _buildDaySelector(),
                _buildTabBar(),
                Expanded(
                  child: _activeTab == 'queue' ? _buildQueueTab() : _buildSuggestionsTab(),
                ),
              ],
            ),
    );
  }

  Widget _buildNowPlaying() {
    final playing = _requests.where((r) => r['status'] == 'playing').toList();
    if (playing.isEmpty) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Colors.grey.shade800, Colors.grey.shade900]),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          children: [
            const Icon(Icons.music_off, size: 36, color: Colors.white38),
            const SizedBox(height: 8),
            Text(AppLocalizations.t('no_song_playing'), style: const TextStyle(color: Colors.white38, fontSize: 16)),
            Text(AppLocalizations.t('tap_play_start'), style: const TextStyle(color: Colors.white24, fontSize: 12)),
          ],
        ),
      );
    }
    final current = playing.first;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1a5c1a), Color(0xFF0d3d0d)]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withOpacity(0.5), width: 2),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.volume_up, color: Colors.green, size: 18),
              const SizedBox(width: 8),
              Text(AppLocalizations.t('now_playing'), style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 10),
          Text(current['song_name'] ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text('Requested by: ${current['user_name'] ?? 'Unknown'} (${current['house_number'] ?? ''})',
              style: const TextStyle(fontSize: 13, color: Colors.white70)),
          if (current['youtube_link'] != null && (current['youtube_link'] as String).isNotEmpty) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _launchYoutube(current['youtube_link']),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: Colors.red.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.play_circle, color: Colors.red, size: 18),
                    const SizedBox(width: 6),
                    Text(AppLocalizations.t('open_youtube'), style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDaySelector() {
    return SizedBox(
      height: 46,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: 9,
        itemBuilder: (context, index) {
          final day = index + 1;
          final isSelected = day == _selectedDay;
          return GestureDetector(
            onTap: () => setState(() => _selectedDay = day),
            child: Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.goldPrimary : AppTheme.purpleCard,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text('D$day', style: TextStyle(
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(color: AppTheme.purpleCard, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Expanded(child: _buildTab('queue', AppLocalizations.t('request_queue'))),
          Expanded(child: _buildTab('suggest', AppLocalizations.t('tomorrows_suggestions'))),
        ],
      ),
    );
  }

  Widget _buildTab(String tab, String label) {
    final isActive = _activeTab == tab;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = tab),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.goldPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(label, textAlign: TextAlign.center, style: TextStyle(
          color: isActive ? AppTheme.purpleDark : Colors.white70,
          fontWeight: FontWeight.bold, fontSize: 12,
        )),
      ),
    );
  }

  Widget _buildQueueTab() {
    final pending = _requests.where((r) => r['status'] == 'pending').toList();
    final playing = _requests.where((r) => r['status'] == 'playing').toList();
    final skipped = _requests.where((r) => r['status'] == 'skipped').toList();

    if (_requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.queue_music, size: 48, color: Colors.white24),
            const SizedBox(height: 12),
            Text(AppLocalizations.t('no_requests_yet'), style: const TextStyle(color: Colors.white38, fontSize: 16)),
            Text(AppLocalizations.t('waiting_requests'), style: const TextStyle(color: Colors.white24, fontSize: 12)),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (playing.isNotEmpty) ...[
          const Text('▶ NOW PLAYING', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          ...playing.map((r) => _buildRequestCard(r, isPlaying: true)),
          const SizedBox(height: 16),
        ],
        if (pending.isNotEmpty) ...[
          Text('⏳ PENDING (${pending.length})', style: const TextStyle(color: AppTheme.goldPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          ...pending.map((r) => _buildRequestCard(r)),
        ],
        if (skipped.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('⏭ SKIPPED (${skipped.length})', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          ...skipped.map((r) => _buildRequestCard(r, isSkipped: true)),
        ],
      ],
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> req, {bool isPlaying = false, bool isSkipped = false}) {
    final color = isPlaying ? Colors.green : isSkipped ? Colors.red : AppTheme.goldPrimary;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.purpleCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.4), width: isPlaying ? 2 : 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(req['song_name'] ?? '', style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.bold,
                  color: isPlaying ? Colors.green : Colors.white,
                )),
                const SizedBox(height: 2),
                Text('${req['user_name'] ?? 'Unknown'} • ${req['house_number'] ?? ''}',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                Text('Votes: ${req['request_count'] ?? 0}', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                if (req['youtube_link'] != null && (req['youtube_link'] as String).isNotEmpty)
                  GestureDetector(
                    onTap: () => _launchYoutube(req['youtube_link']),
                    child: const Text('🔗 YouTube link', style: TextStyle(fontSize: 10, color: Colors.blue)),
                  ),
              ],
            ),
          ),
          if (!isPlaying && !isSkipped) ...[
            IconButton(
              icon: const Icon(Icons.play_circle, color: Colors.green, size: 32),
              onPressed: () => _playSong(req['id']),
              tooltip: 'Play',
            ),
            IconButton(
              icon: const Icon(Icons.skip_next, color: Colors.orange, size: 28),
              onPressed: () => _skipSong(req['id']),
              tooltip: 'Skip',
            ),
          ],
          if (isPlaying) ...[
            IconButton(
              icon: const Icon(Icons.stop_circle, color: Colors.red, size: 32),
              onPressed: () => _skipSong(req['id']),
              tooltip: 'Stop',
            ),
          ],
        ],
      ),
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
            Text(AppLocalizations.t('no_suggestions_tomorrow'), style: const TextStyle(color: Colors.white38, fontSize: 16)),
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
            border: Border.all(color: Colors.purpleAccent.withOpacity(0.4)),
          ),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: Colors.purpleAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.lightbulb, color: Colors.purpleAccent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(sug['song_name'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 2),
                    Text('by ${sug['user_name'] ?? 'Unknown'}', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: Colors.purpleAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.thumb_up, color: Colors.purpleAccent, size: 14),
                    const SizedBox(width: 4),
                    Text('${sug['upvotes'] ?? 0}', style: const TextStyle(fontSize: 13, color: Colors.purpleAccent, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
