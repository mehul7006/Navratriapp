import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../database/database_helper.dart';
import '../../l10n/app_localizations.dart';

class BroadcastManagementScreen extends StatefulWidget {
  const BroadcastManagementScreen({super.key});

  @override
  State<BroadcastManagementScreen> createState() => _BroadcastManagementScreenState();
}

class _BroadcastManagementScreenState extends State<BroadcastManagementScreen> {
  List<Map<String, dynamic>> _broadcasts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBroadcasts();
  }

  Future<void> _loadBroadcasts() async {
    setState(() => _isLoading = true);
    try {
      final broadcasts = await DatabaseHelper.getBroadcasts();
      setState(() { _broadcasts = broadcasts; _isLoading = false; });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _showCreateDialog() {
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    String priority = 'normal';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.cardBg,
          title: Text(AppLocalizations.t('new_broadcast'), style: const TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: AppLocalizations.t('title'),
                    labelStyle: const TextStyle(color: AppTheme.textMuted),
                    filled: true,
                    fillColor: AppTheme.purpleDark,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: messageController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.t('message'),
                    labelStyle: const TextStyle(color: AppTheme.textMuted),
                    filled: true,
                    fillColor: AppTheme.purpleDark,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: priority,
                  dropdownColor: AppTheme.purpleDeep,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(labelText: AppLocalizations.t('priority'), labelStyle: const TextStyle(color: AppTheme.textMuted)),
                  items: [
                    DropdownMenuItem(value: 'low', child: Text(AppLocalizations.t('low'))),
                    DropdownMenuItem(value: 'normal', child: Text(AppLocalizations.t('normal'))),
                    DropdownMenuItem(value: 'high', child: Text(AppLocalizations.t('high'))),
                    DropdownMenuItem(value: 'urgent', child: Text(AppLocalizations.t('urgent'))),
                  ],
                  onChanged: (v) => setDialogState(() => priority = v ?? 'normal'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocalizations.t('cancel'), style: const TextStyle(color: Colors.white70))),
            TextButton(
              onPressed: () async {
                if (titleController.text.isNotEmpty && messageController.text.isNotEmpty) {
                  await DatabaseHelper.createBroadcast(
                    title: titleController.text.trim(),
                    message: messageController.text.trim(),
                    priority: priority,
                  );
                  Navigator.pop(ctx);
                  _loadBroadcasts();
                }
              },
              child: Text(AppLocalizations.t('send'), style: const TextStyle(color: AppTheme.goldPrimary)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.purpleDark,
      appBar: AppBar(
        title: Text(AppLocalizations.t('broadcasts')),
        backgroundColor: AppTheme.purpleDeep,
        foregroundColor: AppTheme.goldPrimary,
        iconTheme: const IconThemeData(color: AppTheme.goldPrimary),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _loadBroadcasts),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.goldPrimary,
        onPressed: _showCreateDialog,
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.goldPrimary))
          : _broadcasts.isEmpty
              ? Center(child: Text(AppLocalizations.t('no_broadcasts'), style: const TextStyle(color: AppTheme.textMuted)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _broadcasts.length,
                  itemBuilder: (context, index) {
                    final b = _broadcasts[index];
                    final priority = b['priority'] ?? 'normal';
                    final Color priorityColor;
                    switch (priority) {
                      case 'urgent': priorityColor = Colors.red; break;
                      case 'high': priorityColor = Colors.orange; break;
                      case 'normal': priorityColor = Colors.blue; break;
                      default: priorityColor = Colors.grey; break;
                    }
                    String dateStr = '';
                    try {
                      dateStr = DateFormat('dd MMM yyyy HH:mm').format(DateTime.parse(b['created_at'] ?? ''));
                    } catch (_) {}

                    return Card(
                      color: AppTheme.cardBg,
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: priorityColor,
                          child: const Icon(Icons.broadcast_on_home, color: Colors.white, size: 18),
                        ),
                        title: Text(b['title'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(b['message'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: priorityColor.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                                  child: Text(priority.toUpperCase(), style: TextStyle(color: priorityColor, fontSize: 9, fontWeight: FontWeight.bold)),
                                ),
                                if (dateStr.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  Text(dateStr, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                                ],
                              ],
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text(AppLocalizations.t('delete_broadcast')),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppLocalizations.t('cancel'))),
                                  TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(AppLocalizations.t('delete'), style: const TextStyle(color: Colors.red))),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await DatabaseHelper.deleteBroadcast(b['id']);
                              _loadBroadcasts();
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
