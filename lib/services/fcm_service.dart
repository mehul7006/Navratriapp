import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_messaging/firebase_messaging.dart';
import '../database/database_helper.dart';

class FcmService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static String? _currentToken;
  static int? _boundUserId;
  static String? _boundUserType;
  static final Completer<void> _initCompleter = Completer<void>();
  static Future<void> get ready => _initCompleter.future;

  static Future<void> init() async {
    if (kIsWeb) {
      if (!_initCompleter.isCompleted) _initCompleter.complete();
      return;
    }
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      print('FCM: Permission status = ${settings.authorizationStatus}');
      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        _currentToken = await _messaging.getToken();
        print('FCM: Token = ${_currentToken?.substring(0, 20)}...');
        if (_currentToken != null) {
          await DatabaseHelper.saveFcmToken(_currentToken!);
          print('FCM: Token saved to server');
          if (_boundUserId != null && _boundUserType != null) {
            await DatabaseHelper.bindFcmToken(_boundUserId!, _boundUserType!, _currentToken!);
            print('FCM: Token bound to user $_boundUserId');
          }
        }
        _messaging.onTokenRefresh.listen((token) async {
          _currentToken = token;
          await DatabaseHelper.saveFcmToken(token);
          if (_boundUserId != null && _boundUserType != null) {
            await DatabaseHelper.bindFcmToken(_boundUserId!, _boundUserType!, token);
          }
        });
      } else {
        print('FCM: Permission denied');
      }
      FirebaseMessaging.onMessage.listen((message) {
        print('FCM: Foreground message = ${message.notification?.title}');
      });
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        print('FCM: Notification tapped');
      });
    } catch (e) {
      print('FCM: Init error = $e');
    }
    if (!_initCompleter.isCompleted) _initCompleter.complete();
  }

  static Future<void> bindToUser(int userId, String userType) async {
    _boundUserId = userId;
    _boundUserType = userType;
    await ready;
    if (_currentToken != null) {
      await DatabaseHelper.bindFcmToken(userId, userType, _currentToken!);
      print('FCM: Token bound to user $userId ($userType)');
    } else {
      print('FCM: No token available to bind');
    }
  }

  static String? get currentToken => _currentToken;
}
