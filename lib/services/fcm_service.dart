import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_messaging/firebase_messaging.dart';
import '../database/database_helper.dart';

class FcmService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static String? _currentToken;
  static int? _boundUserId;
  static String? _boundUserType;

  static Future<void> init() async {
    if (kIsWeb) return;
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        _currentToken = await _messaging.getToken();
        if (_currentToken != null) {
          await DatabaseHelper.saveFcmToken(_currentToken!);
          if (_boundUserId != null && _boundUserType != null) {
            await DatabaseHelper.bindFcmToken(_boundUserId!, _boundUserType!, _currentToken!);
          }
        }
        _messaging.onTokenRefresh.listen((token) {
          _currentToken = token;
          DatabaseHelper.saveFcmToken(token);
          if (_boundUserId != null && _boundUserType != null) {
            DatabaseHelper.bindFcmToken(_boundUserId!, _boundUserType!, token);
          }
        });
      }
      FirebaseMessaging.onMessage.listen(_onForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);
    } catch (_) {}
  }

  static Future<void> bindToUser(int userId, String userType) async {
    _boundUserId = userId;
    _boundUserType = userType;
    if (_currentToken != null) {
      await DatabaseHelper.bindFcmToken(userId, userType, _currentToken!);
    }
  }

  static void _onForegroundMessage(RemoteMessage message) {}

  static void _onMessageOpenedApp(RemoteMessage message) {}

  static String? get currentToken => _currentToken;
}
