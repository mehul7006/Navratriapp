import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../providers/notification_provider.dart';
import '../providers/auth_provider.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final notifProvider = context.read<NotificationProvider>();
      if (auth.currentUser != null) {
        notifProvider.loadNotifications(
          auth.currentUser!['id'] as int,
          auth.currentUser!['user_type'] as String,
        );
      }
    });
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'aarti_booking': return Icons.temple_hindu;
      case 'snack_booking': return Icons.restaurant;
      case 'gift_booking': return Icons.card_giftcard;
      case 'lucky_draw': return Icons.emoji_events;
      case 'payment': return Icons.payments;
      case 'expense': return Icons.receipt_long;
      case 'sponsor_ad': return Icons.campaign;
      case 'song_request': return Icons.music_note;
      case 'day_end': return Icons.wb_twilight;
      case 'ad_confirmed': return Icons.check_circle;
      case 'ad_rejected': return Icons.cancel;
      case 'ticket_assigned': return Icons.confirmation_number;
      default: return Icons.notifications;
    }
  }

  Color _getColor(String type) {
    switch (type) {
      case 'aarti_booking': return AppTheme.goldPrimary;
      case 'snack_booking': return Colors.orange;
      case 'gift_booking': return Colors.pinkAccent;
      case 'lucky_draw': return Colors.amber;
      case 'payment': return Colors.green;
      case 'expense': return Colors.redAccent;
      case 'sponsor_ad': return AppTheme.cyanAccent;
      case 'song_request': return Colors.purpleAccent;
      case 'day_end': return Colors.blueGrey;
      case 'ad_confirmed': return Colors.green;
      case 'ad_rejected': return Colors.red;
      case 'ticket_assigned': return Colors.teal;
      default: return AppTheme.goldPrimary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifProvider = context.watch<NotificationProvider>();
    final notifications = notifProvider.notifications;

    return Scaffold(
      backgroundColor: AppTheme.purpleDark,
      appBar: AppBar(
        backgroundColor: AppTheme.purpleDeep,
        title: const Text('Notifications', style: TextStyle(color: AppTheme.goldPrimary)),
        iconTheme: const IconThemeData(color: AppTheme.goldPrimary),
        actions: [
          if (notifications.any((n) => n['is_read'] == false))
            TextButton(
              onPressed: () {
                final auth = context.read<AuthProvider>();
                notifProvider.markAllAsRead(
                  auth.currentUser!['id'] as int,
                  auth.currentUser!['user_type'] as String,
                );
              },
              child: const Text('Mark all read', style: TextStyle(color: AppTheme.goldPrimary, fontSize: 12)),
            ),
        ],
      ),
      body: notifProvider.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.goldPrimary))
          : notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none, color: Colors.white24, size: 80),
                      const SizedBox(height: 16),
                      Text('No notifications yet', style: TextStyle(color: Colors.white38, fontSize: 16)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notif = notifications[index];
                    final isRead = notif['is_read'] == true;
                    final type = notif['type'] ?? 'general';
                    final created = notif['created_at'] ?? '';

                    return Dismissible(
                      key: Key('notif_${notif['id']}'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: AppTheme.redAccent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) {
                        final auth = context.read<AuthProvider>();
                        notifProvider.deleteNotification(
                          notif['id'] as int,
                          auth.currentUser!['id'] as int,
                          auth.currentUser!['user_type'] as String,
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        decoration: BoxDecoration(
                          color: isRead
                              ? AppTheme.purpleCard.withOpacity(0.5)
                              : AppTheme.purpleCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isRead ? Colors.white12 : AppTheme.goldPrimary.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: _getColor(type).withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(_getIcon(type), color: _getColor(type), size: 22),
                          ),
                          title: Text(
                            notif['title'] ?? '',
                            style: TextStyle(
                              color: AppTheme.textMain,
                              fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                notif['message'] ?? '',
                                style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatTime(created),
                                style: TextStyle(color: Colors.white38, fontSize: 10),
                              ),
                            ],
                          ),
                          trailing: !isRead
                              ? Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppTheme.goldPrimary,
                                    shape: BoxShape.circle,
                                  ),
                                )
                              : null,
                          onTap: () {
                            if (!isRead) {
                              final auth = context.read<AuthProvider>();
                              notifProvider.markAsRead(
                                notif['id'] as int,
                                auth.currentUser!['id'] as int,
                                auth.currentUser!['user_type'] as String,
                              );
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  String _formatTime(String isoString) {
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return DateFormat('dd MMM, hh:mm a').format(dt);
    } catch (_) {
      return '';
    }
  }
}
