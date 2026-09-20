import 'dart:async';
import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class NotificationProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  Timer? _pollTimer;

  List<Map<String, dynamic>> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;

  void startPolling(int userId, String userType) {
    _pollTimer?.cancel();
    _refresh(userId, userType);
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _refresh(userId, userType);
    });
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _refresh(int userId, String userType) async {
    try {
      final notifs = await DatabaseHelper.getNotifications(userId, userType);
      final count = await DatabaseHelper.getUnreadCount(userId, userType);
      if (_notifications.length != notifs.length || _unreadCount != count) {
        _notifications = notifs;
        _unreadCount = count;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> loadNotifications(int userId, String userType) async {
    _isLoading = true;
    notifyListeners();
    try {
      _notifications = await DatabaseHelper.getNotifications(userId, userType);
      _unreadCount = await DatabaseHelper.getUnreadCount(userId, userType);
    } catch (_) {}
    _isLoading = false;
    notifyListeners();
  }

  Future<void> markAsRead(int id, int userId, String userType) async {
    await DatabaseHelper.markNotificationAsRead(id);
    final index = _notifications.indexWhere((n) => n['id'] == id);
    if (index != -1) {
      _notifications[index]['is_read'] = true;
      _unreadCount = (_unreadCount - 1).clamp(0, 999);
      notifyListeners();
    }
  }

  Future<void> markAllAsRead(int userId, String userType) async {
    await DatabaseHelper.markAllNotificationsAsRead(userId, userType);
    for (final n in _notifications) {
      n['is_read'] = true;
    }
    _unreadCount = 0;
    notifyListeners();
  }

  Future<void> deleteNotification(int id, int userId, String userType) async {
    await DatabaseHelper.deleteNotification(id);
    _notifications.removeWhere((n) => n['id'] == id);
    _unreadCount = (_unreadCount - 1).clamp(0, 999);
    notifyListeners();
  }

  static Future<void> send({
    required int userId,
    required String userType,
    required String title,
    required String message,
    required String type,
  }) async {
    await DatabaseHelper.createNotification(
      userId: userId,
      userType: userType,
      title: title,
      message: message,
      type: type,
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}
