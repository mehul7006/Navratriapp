import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';

void main() async {
  final sa = jsonDecode(await File('service_account.json').readAsString()) as Map<String, dynamic>;
  final now = DateTime.now().toUtc();
  final header = base64UrlEncode(utf8.encode(jsonEncode({'alg': 'RS256', 'typ': 'JWT'})));
  final payload = base64UrlEncode(utf8.encode(jsonEncode({'iss': sa['client_email'], 'scope': 'https://www.googleapis.com/auth/firebase.messaging', 'aud': 'https://oauth2.googleapis.com/token', 'iat': now.millisecondsSinceEpoch ~/ 1000, 'exp': now.add(Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000})));
  final signingInput = '\.\';
  final key = _parseKey(sa['private_key'] as String);
  final signer = Signer('SHA-256/RSA')..init(true, PrivateKeyParameter<RSAPrivateKey>(key));
  final sig = signer.generateSignature(Uint8List.fromList(utf8.encode(signingInput)));
  final jwt = '\.\';
  final req = await HttpClient().postUrl(Uri.parse('https://oauth2.googleapis.com/token'));
  req.headers.set('Content-Type', 'application/x-www-form-urlencoded');
  req.write('grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=\');
  final resp = await req.close();
  final data = jsonDecode(await resp.transform(utf8.decoder).join()) as Map<String, dynamic>;
  final accessToken = data['access_token'] as String;
  final pushReq = await HttpClient().postUrl(Uri.parse('https://fcm.googleapis.com/v1/projects/navratriapp-2026/messages:send'));
  pushReq.headers.set('Authorization', 'Bearer \');
  pushReq.headers.set('Content-Type', 'application/json');
  pushReq.write(jsonEncode({'message': {'token': 'ehX2iF1cSH64k4sg7u8Y7H:APA91bFHu27ypGXG48zjqPN8LX0ocatvapB3V5LZsMt0mHNLtUwcdKmwckDXWIIznQlniddJW7En_KevNkkye3BLWrSTkMUUYrk1Oni_f8iaPwENcP-e610', 'notification': {'title': 'Test Push (App Closed)', 'body': 'This should appear on lock screen!'}, 'android': {'priority': 'high', 'notification': {'channel_id': 'navratri_notifications', 'sound': 'default'}}}}));
  final pushResp = await pushReq.close();
  print('Status: \');
  print('Body: \');
}
RSAPrivateKey _parseKey(String pem) { final lines = pem.split('\n').where((l) => !l.startsWith('-----') && l.trim().isNotEmpty).join(); final der = base64Decode(lines); int o = 0; int rl() { int l = der[o++]; if ((l & 0x80) != 0) { int n = l & 0x7F; l = 0; for (int i = 0; i < n; i++) l = (l << 8) | der[o++]; } return l; } void rt(int e) { if (der[o++] != e) throw Exception('bad tag'); } void se() { int l = rl(); o += l; } BigInt ri() { rt(0x02); int l = rl(); var b = der.sublist(o, o + l); o += l; return b.fold(BigInt.from(0), (a, c) => (a << 8) | BigInt.from(c)); } o = 0; rt(0x30); rl(); rt(0x02); rl(); o++; rt(0x30); se(); rt(0x04); rl(); rt(0x30); rl(); rt(0x02); rl(); o++; final n = ri(); final e = ri(); final d = ri(); final p = ri(); final q = ri(); return RSAPrivateKey(n, d, p, q); }
