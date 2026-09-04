import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../database/database_helper.dart';
import '../../l10n/app_localizations.dart';
import 'package:navratri_app/widgets/background_scaffold.dart';

class AnnouncementManagementScreen extends StatefulWidget {
  const AnnouncementManagementScreen({super.key});

  @override
  State<AnnouncementManagementScreen> createState() => _AnnouncementManagementScreenState();
}

class _AnnouncementManagementScreenState extends State<AnnouncementManagementScreen> {
  List<Map<String, dynamic>> _announcements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    setState(() => _isLoading = true);
    _announcements = await DatabaseHelper.getAnnouncements();
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.t('announcements')),
        backgroundColor: AppTheme.purpleDeep,
        foregroundColor: AppTheme.goldPrimary,
        iconTheme: const IconThemeData(color: AppTheme.goldPrimary),
      ),
      body: BackgroundBody(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _announcements.isEmpty
                ? Center(child: Text(AppLocalizations.t('no_announcements'), style: const TextStyle(color: AppTheme.textMuted)))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _announcements.length,
                    itemBuilder: (context, index) => _buildAnnouncementCard(_announcements[index]),
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.goldPrimary,
        onPressed: () => _showAddAnnouncementDialog(),
        child: const Icon(Icons.add, color: AppTheme.purpleDark),
      ),
    );
  }

  Widget _buildAnnouncementCard(Map<String, dynamic> announcement) {
    final type = announcement['announcement_type'] ?? 'general';
    Color typeColor;
    switch (type) {
      case 'reminder': typeColor = Colors.orange; break;
      case 'info': typeColor = Colors.blue; break;
      default: typeColor = AppTheme.goldPrimary;
    }

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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: typeColor.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                child: Text(type.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: typeColor)),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.delete, color: AppTheme.redAccent, size: 20),
                onPressed: () async {
                  await DatabaseHelper.deleteAnnouncement(announcement['id']);
                  _loadAnnouncements();
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(announcement['title'] ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 4),
          Text(announcement['message'] ?? '', style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
        ],
      ),
    );
  }

  void _showAddAnnouncementDialog() {
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    String type = 'general';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.purpleCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(AppLocalizations.t('new_announcement'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.goldPrimary)),
              const SizedBox(height: 16),
              Row(
                children: ['general', 'reminder', 'info'].map((t) {
                  final isSelected = type == t;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setModalState(() => type = t),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.goldPrimary : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.goldPrimary.withOpacity(0.5)),
                        ),
                        child: Text(t.toUpperCase(), textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isSelected ? AppTheme.purpleDark : AppTheme.textMuted)),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              _buildField(controller: titleController, label: AppLocalizations.t('title'), icon: Icons.title),
              const SizedBox(height: 12),
              _buildField(controller: messageController, label: AppLocalizations.t('message'), icon: Icons.message, maxLines: 3),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (titleController.text.isEmpty || messageController.text.isEmpty) return;
                  await DatabaseHelper.createAnnouncement(
                    title: titleController.text.trim(),
                    message: messageController.text.trim(),
                    type: type,
                  );
                  Navigator.pop(ctx);
                  _loadAnnouncements();
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.goldPrimary, foregroundColor: AppTheme.purpleDark, padding: const EdgeInsets.symmetric(vertical: 16)),
                child: Text(AppLocalizations.t('post_announcement'), style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({required TextEditingController controller, required String label, required IconData icon, int maxLines = 1}) {
    return TextFormField(
      controller: controller, maxLines: maxLines, style: const TextStyle(color: Colors.white),
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
