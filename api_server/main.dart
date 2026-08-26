import 'dart:io';
import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:postgres/postgres.dart';

Connection? _db;

Future<Connection> get db async {
  if (_db != null) return _db!;
  _db = await Connection.open(
    Endpoint(
      host: 'localhost',
      port: 5432,
      database: 'navratri_2026',
      username: 'postgres',
      password: 'your_local_password',
    ),
    settings: const ConnectionSettings(
      sslMode: SslMode.disable,
      connectTimeout: Duration(seconds: 5),
      queryTimeout: Duration(seconds: 10),
    ),
  );
  return _db!;
}

final router = Router()
  ..post('/api/auth/login-user', _loginUser)
  ..post('/api/auth/login-organizer', _loginOrganizer)
  ..post('/api/auth/login-sponsor', _loginSponsor)
  ..post('/api/auth/register', _register)
  ..get('/api/members', _getAllMembers)
  ..put('/api/members/<id>/status', _updateMemberStatus)
  ..get('/api/payments', _getAllPayments)
  ..get('/api/payments/house/<house>', _getPaymentsByHouse)
  ..post('/api/payments', _addPayment)
  ..get('/api/aarti-slots/<day>', _getAartiSlots)
  ..get('/api/aarti-slots', _getAllAartiSlots)
  ..post('/api/aarti-slots', _addAartiSlot)
  ..put('/api/aarti-slots/<id>', _updateAartiSlot)
  ..get('/api/aarti-bookings', _getAartiBookings)
  ..get('/api/aarti-bookings/my/<house>', _getMyAartiBookings)
  ..post('/api/aarti-bookings', _bookAartiSlot)
  ..put('/api/aarti-bookings/<id>/status', _updateBookingStatus)
  ..get('/api/snacks', _getSnacks)
  ..get('/api/snacks/all', _getAllSnacks)
  ..post('/api/snacks', _addSnack)
  ..put('/api/snacks/<id>', _updateSnack)
  ..get('/api/snack-orders', _getSnackOrders)
  ..get('/api/snack-orders/my/<house>', _getMySnackOrders)
  ..post('/api/snack-orders', _orderSnack)
  ..put('/api/snack-orders/<id>/status', _updateSnackOrderStatus)
  ..get('/api/gifts', _getGifts)
  ..post('/api/gifts', _addGift)
  ..put('/api/gifts/<id>', _updateGift)
  ..get('/api/gift-assignments', _getGiftAssignments)
  ..post('/api/gift-assignments', _assignGift)
  ..get('/api/gifts/my/<house>', _getMyGifts)
  ..get('/api/announcements', _getAnnouncements)
  ..post('/api/announcements', _createAnnouncement)
  ..delete('/api/announcements/<id>', _deleteAnnouncement)
  ..get('/api/tickets/my/<house>', _getMyTickets)
  ..post('/api/tickets/generate', _generateTickets)
  ..put('/api/tickets/assign', _assignTicket)
  ..post('/api/query', _genericQuery)
  ..post('/api/execute', _genericExecute);

Map<String, dynamic> _parseRow(PostgreSQLResultRow row) {
  final map = <String, dynamic>{};
  for (var i = 0; i < row.length; i++) {
    map[row.columnDescriptions[i].columnName] = row[i];
  }
  return map;
}

List<Map<String, dynamic>> _parseResults(PostgreSQLResult results) {
  return results.map((row) => _parseRow(row)).toList();
}

Response _jsonResponse(dynamic data, {int status = 200}) {
  return Response.ok(
    jsonEncode(data),
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type',
    },
  );
}

Response _errorResponse(String message, {int status = 400}) {
  return Response(
    status,
    body: jsonEncode({'error': message}),
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*',
    },
  );
}

Future<Request> _readBody(Request request) async => request;

Future<Map<String, dynamic>> _getBody(Request request) async {
  final body = await request.readAsString();
  return body.isEmpty ? {} : jsonDecode(body) as Map<String, dynamic>;
}

// ========== AUTH ==========

Future<Response> _loginUser(Request request) async {
  try {
    final body = await _getBody(request);
    final conn = await db;
    final results = await conn.execute(
      Sql.indexed('''
        SELECT id, house_number, name, mobile_number, user_type, profile_image
        FROM users 
        WHERE house_number = @house AND mobile_number = @mobile AND is_active = TRUE
      '''),
      parameters: {'house': body['house_number'], 'mobile': body['mobile_number']},
    );
    if (results.isNotEmpty) return _jsonResponse(_parseRow(results.first));
    return _jsonResponse(null);
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

Future<Response> _loginOrganizer(Request request) async {
  try {
    final body = await _getBody(request);
    final conn = await db;
    final results = await conn.execute(
      Sql.indexed('''
        SELECT id, house_number, name, user_type
        FROM users 
        WHERE house_number = @username AND password = @password 
        AND user_type = 'organizer' AND is_active = TRUE
      '''),
      parameters: {'username': body['username'], 'password': body['password']},
    );
    if (results.isNotEmpty) return _jsonResponse(_parseRow(results.first));
    return _jsonResponse(null);
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

Future<Response> _loginSponsor(Request request) async {
  try {
    final body = await _getBody(request);
    final conn = await db;
    final results = await conn.execute(
      Sql.indexed('''
        SELECT u.id, u.house_number, u.name, u.mobile_number, u.user_type,
               s.company_name, s.advertisement_text
        FROM users u
        LEFT JOIN sponsors s ON u.id = s.user_id
        WHERE u.house_number = @house AND u.password = @password 
        AND u.user_type = 'sponsor' AND u.is_active = TRUE
      '''),
      parameters: {'house': body['house_number'], 'password': body['password']},
    );
    if (results.isNotEmpty) return _jsonResponse(_parseRow(results.first));
    return _jsonResponse(null);
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

Future<Response> _register(Request request) async {
  try {
    final body = await _getBody(request);
    final conn = await db;
    final results = await conn.execute(
      Sql.indexed('''
        INSERT INTO users (house_number, name, mobile_number, user_type)
        VALUES (@house, @name, @mobile, @type) RETURNING id
      '''),
      parameters: {
        'house': body['house_number'],
        'name': body['name'],
        'mobile': body['mobile_number'],
        'type': body['user_type'] ?? 'user',
      },
    );
    return _jsonResponse({'id': results.first.toColumnMap()['id']});
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

// ========== MEMBERS ==========

Future<Response> _getAllMembers(Request request) async {
  try {
    final conn = await db;
    final results = await conn.execute(
      Sql.indexed("SELECT * FROM users WHERE user_type != 'organizer' ORDER BY house_number"),
    );
    return _jsonResponse(_parseResults(results));
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

Future<Response> _updateMemberStatus(Request request, String id) async {
  try {
    final body = await _getBody(request);
    final conn = await db;
    await conn.execute(
      Sql.indexed('UPDATE users SET is_active = @active WHERE id = @id'),
      parameters: {'active': body['is_active'], 'id': int.parse(id)},
    );
    return _jsonResponse({'ok': true});
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

// ========== PAYMENTS ==========

Future<Response> _getAllPayments(Request request) async {
  try {
    final conn = await db;
    final results = await conn.execute(Sql.indexed('''
      SELECT fc.*, u.name as user_name, u.house_number,
             ru.name as receiver_name
      FROM fund_collections fc
      JOIN users u ON fc.user_id = u.id
      LEFT JOIN users ru ON fc.received_by = ru.id
      ORDER BY fc.created_at DESC
    '''));
    return _jsonResponse(_parseResults(results));
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

Future<Response> _getPaymentsByHouse(Request request, String house) async {
  try {
    final conn = await db;
    final results = await conn.execute(
      Sql.indexed('''
        SELECT fc.*, u.name as user_name
        FROM fund_collections fc
        JOIN users u ON fc.user_id = u.id
        WHERE fc.house_number = @house
        ORDER BY fc.created_at DESC
      '''),
      parameters: {'house': house},
    );
    return _jsonResponse(_parseResults(results));
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

Future<Response> _addPayment(Request request) async {
  try {
    final body = await _getBody(request);
    final conn = await db;
    final results = await conn.execute(
      Sql.indexed('''
        INSERT INTO fund_collections 
          (user_id, house_number, amount, payment_method, payment_status, tentative_date, received_by, notes)
        VALUES (@userId, @house, @amount, @method, @status, @tentative, @receivedBy, @notes)
        RETURNING id
      '''),
      parameters: {
        'userId': body['user_id'], 'house': body['house_number'],
        'amount': body['amount'], 'method': body['payment_method'],
        'status': body['payment_status'] ?? 'paid',
        'tentative': body['tentative_date'],
        'receivedBy': body['received_by'],
        'notes': body['notes'],
      },
    );
    return _jsonResponse({'id': results.first.toColumnMap()['id']});
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

// ========== AARTI SLOTS ==========

Future<Response> _getAartiSlots(Request request, String day) async {
  try {
    final conn = await db;
    final results = await conn.execute(
      Sql.indexed('SELECT * FROM aarti_slots WHERE day_number = @day ORDER BY slot_time'),
      parameters: {'day': int.parse(day)},
    );
    return _jsonResponse(_parseResults(results));
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

Future<Response> _getAllAartiSlots(Request request) async {
  try {
    final conn = await db;
    final results = await conn.execute(
      Sql.indexed('SELECT * FROM aarti_slots ORDER BY day_number, slot_time'),
    );
    return _jsonResponse(_parseResults(results));
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

Future<Response> _addAartiSlot(Request request) async {
  try {
    final body = await _getBody(request);
    final conn = await db;
    final results = await conn.execute(
      Sql.indexed('''
        INSERT INTO aarti_slots (day_number, slot_time, slot_label, max_participants)
        VALUES (@day, @time, @label, @max) RETURNING id
      '''),
      parameters: {
        'day': body['day_number'], 'time': body['slot_time'],
        'label': body['slot_label'], 'max': body['max_participants'],
      },
    );
    return _jsonResponse({'id': results.first.toColumnMap()['id']});
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

Future<Response> _updateAartiSlot(Request request, String id) async {
  try {
    final body = await _getBody(request);
    final conn = await db;
    final updates = <String>[];
    final params = <String, dynamic>{'id': int.parse(id)};
    if (body.containsKey('slot_time')) { updates.add('slot_time = @time'); params['time'] = body['slot_time']; }
    if (body.containsKey('slot_label')) { updates.add('slot_label = @label'); params['label'] = body['slot_label']; }
    if (body.containsKey('max_participants')) { updates.add('max_participants = @max'); params['max'] = body['max_participants']; }
    if (body.containsKey('is_active')) { updates.add('is_active = @active'); params['active'] = body['is_active']; }
    if (updates.isNotEmpty) {
      await conn.execute(Sql.indexed('UPDATE aarti_slots SET ${updates.join(', ')} WHERE id = @id'), parameters: params);
    }
    return _jsonResponse({'ok': true});
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

// ========== AARTI BOOKINGS ==========

Future<Response> _getAartiBookings(Request request) async {
  try {
    final day = request.url.queryParameters['day'];
    final status = request.url.queryParameters['status'];
    final conn = await db;
    var sql = '''
      SELECT ab.*, u.name as user_name, a.slot_time, a.slot_label
      FROM aarti_bookings ab
      JOIN users u ON ab.user_id = u.id
      JOIN aarti_slots a ON ab.slot_id = a.id
    ''';
    final conditions = <String>[];
    final params = <String, dynamic>{};
    if (day != null) { conditions.add('ab.day_number = @day'); params['day'] = int.parse(day); }
    if (status != null) { conditions.add('ab.status = @status'); params['status'] = status; }
    if (conditions.isNotEmpty) sql += ' WHERE ${conditions.join(' AND ')}';
    sql += ' ORDER BY ab.created_at DESC';
    final results = await conn.execute(Sql.indexed(sql), parameters: params);
    return _jsonResponse(_parseResults(results));
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

Future<Response> _getMyAartiBookings(Request request, String house) async {
  try {
    final conn = await db;
    final results = await conn.execute(
      Sql.indexed('''
        SELECT ab.*, a.slot_time, a.slot_label
        FROM aarti_bookings ab
        JOIN aarti_slots a ON ab.slot_id = a.id
        WHERE ab.house_number = @house
        ORDER BY ab.day_number, a.slot_time
      '''),
      parameters: {'house': house},
    );
    return _jsonResponse(_parseResults(results));
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

Future<Response> _bookAartiSlot(Request request) async {
  try {
    final body = await _getBody(request);
    final conn = await db;
    final results = await conn.execute(
      Sql.indexed('''
        INSERT INTO aarti_bookings (user_id, house_number, day_number, slot_id)
        VALUES (@userId, @house, @day, @slot) RETURNING id
      '''),
      parameters: {
        'userId': body['user_id'], 'house': body['house_number'],
        'day': body['day_number'], 'slot': body['slot_id'],
      },
    );
    return _jsonResponse({'id': results.first.toColumnMap()['id']});
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

Future<Response> _updateBookingStatus(Request request, String id) async {
  try {
    final body = await _getBody(request);
    final conn = await db;
    await conn.execute(
      Sql.indexed('''
        UPDATE aarti_bookings SET status = @status, approved_by = @by, approved_at = CURRENT_TIMESTAMP
        WHERE id = @id
      '''),
      parameters: {'status': body['status'], 'by': body['approved_by'], 'id': int.parse(id)},
    );
    return _jsonResponse({'ok': true});
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

// ========== SNACKS ==========

Future<Response> _getSnacks(Request request) async {
  try {
    final conn = await db;
    final results = await conn.execute(Sql.indexed('SELECT * FROM snacks WHERE is_active = TRUE ORDER BY name'));
    return _jsonResponse(_parseResults(results));
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

Future<Response> _getAllSnacks(Request request) async {
  try {
    final conn = await db;
    final results = await conn.execute(Sql.indexed('SELECT * FROM snacks ORDER BY name'));
    return _jsonResponse(_parseResults(results));
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

Future<Response> _addSnack(Request request) async {
  try {
    final body = await _getBody(request);
    final conn = await db;
    final results = await conn.execute(
      Sql.indexed('''
        INSERT INTO snacks (name, description, price, quantity_available, is_vegetarian)
        VALUES (@name, @desc, @price, @qty, @veg) RETURNING id
      '''),
      parameters: {
        'name': body['name'], 'desc': body['description'],
        'price': body['price'], 'qty': body['quantity_available'],
        'veg': body['is_vegetarian'] ?? true,
      },
    );
    return _jsonResponse({'id': results.first.toColumnMap()['id']});
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

Future<Response> _updateSnack(Request request, String id) async {
  try {
    final body = await _getBody(request);
    final conn = await db;
    final updates = <String>[];
    final params = <String, dynamic>{'id': int.parse(id)};
    if (body.containsKey('name')) { updates.add('name = @name'); params['name'] = body['name']; }
    if (body.containsKey('price')) { updates.add('price = @price'); params['price'] = body['price']; }
    if (body.containsKey('quantity_available')) { updates.add('quantity_available = @qty'); params['qty'] = body['quantity_available']; }
    if (body.containsKey('is_active')) { updates.add('is_active = @active'); params['active'] = body['is_active']; }
    if (updates.isNotEmpty) {
      await conn.execute(Sql.indexed('UPDATE snacks SET ${updates.join(', ')} WHERE id = @id'), parameters: params);
    }
    return _jsonResponse({'ok': true});
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

// ========== SNACK ORDERS ==========

Future<Response> _getSnackOrders(Request request) async {
  try {
    final day = request.url.queryParameters['day'];
    final status = request.url.queryParameters['status'];
    final conn = await db;
    var sql = '''
      SELECT so.*, u.name as user_name, s.name as snack_name
      FROM snack_orders so
      JOIN users u ON so.user_id = u.id
      JOIN snacks s ON so.snack_id = s.id
    ''';
    final conditions = <String>[];
    final params = <String, dynamic>{};
    if (day != null) { conditions.add('so.day_number = @day'); params['day'] = int.parse(day); }
    if (status != null) { conditions.add('so.status = @status'); params['status'] = status; }
    if (conditions.isNotEmpty) sql += ' WHERE ${conditions.join(' AND ')}';
    sql += ' ORDER BY so.created_at DESC';
    final results = await conn.execute(Sql.indexed(sql), parameters: params);
    return _jsonResponse(_parseResults(results));
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

Future<Response> _getMySnackOrders(Request request, String house) async {
  try {
    final conn = await db;
    final results = await conn.execute(
      Sql.indexed('''
        SELECT so.*, s.name as snack_name
        FROM snack_orders so
        JOIN snacks s ON so.snack_id = s.id
        WHERE so.house_number = @house
        ORDER BY so.created_at DESC
      '''),
      parameters: {'house': house},
    );
    return _jsonResponse(_parseResults(results));
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

Future<Response> _orderSnack(Request request) async {
  try {
    final body = await _getBody(request);
    final conn = await db;
    final results = await conn.execute(
      Sql.indexed('''
        INSERT INTO snack_orders (user_id, house_number, snack_id, day_number, quantity, notes)
        VALUES (@userId, @house, @snackId, @day, @qty, @notes) RETURNING id
      '''),
      parameters: {
        'userId': body['user_id'], 'house': body['house_number'],
        'snackId': body['snack_id'], 'day': body['day_number'],
        'qty': body['quantity'], 'notes': body['notes'],
      },
    );
    return _jsonResponse({'id': results.first.toColumnMap()['id']});
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

Future<Response> _updateSnackOrderStatus(Request request, String id) async {
  try {
    final body = await _getBody(request);
    final conn = await db;
    await conn.execute(
      Sql.indexed('UPDATE snack_orders SET status = @status WHERE id = @id'),
      parameters: {'status': body['status'], 'id': int.parse(id)},
    );
    return _jsonResponse({'ok': true});
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

// ========== GIFTS ==========

Future<Response> _getGifts(Request request) async {
  try {
    final day = request.url.queryParameters['day'];
    final type = request.url.queryParameters['type'];
    final conn = await db;
    var sql = 'SELECT g.*, s.company_name as sponsor_name FROM gifts g LEFT JOIN sponsors s ON g.sponsor_id = s.id';
    final conditions = <String>[];
    final params = <String, dynamic>{};
    if (day != null) { conditions.add('g.day_number = @day'); params['day'] = int.parse(day); }
    if (type != null) { conditions.add('g.gift_type = @type'); params['type'] = type; }
    if (conditions.isNotEmpty) sql += ' WHERE ${conditions.join(' AND ')}';
    sql += ' ORDER BY g.day_number, g.name';
    final results = await conn.execute(Sql.indexed(sql), parameters: params);
    return _jsonResponse(_parseResults(results));
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

Future<Response> _addGift(Request request) async {
  try {
    final body = await _getBody(request);
    final conn = await db;
    final results = await conn.execute(
      Sql.indexed('''
        INSERT INTO gifts (name, description, sponsor_id, gift_type, day_number, quantity)
        VALUES (@name, @desc, @sponsor, @type, @day, @qty) RETURNING id
      '''),
      parameters: {
        'name': body['name'], 'desc': body['description'],
        'sponsor': body['sponsor_id'], 'type': body['gift_type'],
        'day': body['day_number'], 'qty': body['quantity'],
      },
    );
    return _jsonResponse({'id': results.first.toColumnMap()['id']});
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

Future<Response> _updateGift(Request request, String id) async {
  try {
    final body = await _getBody(request);
    final conn = await db;
    final updates = <String>[];
    final params = <String, dynamic>{'id': int.parse(id)};
    if (body.containsKey('name')) { updates.add('name = @name'); params['name'] = body['name']; }
    if (body.containsKey('quantity')) { updates.add('quantity = @qty'); params['qty'] = body['quantity']; }
    if (body.containsKey('is_active')) { updates.add('is_active = @active'); params['active'] = body['is_active']; }
    if (updates.isNotEmpty) {
      await conn.execute(Sql.indexed('UPDATE gifts SET ${updates.join(', ')} WHERE id = @id'), parameters: params);
    }
    return _jsonResponse({'ok': true});
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

// ========== GIFT ASSIGNMENTS ==========

Future<Response> _getGiftAssignments(Request request) async {
  try {
    final day = request.url.queryParameters['day'];
    final conn = await db;
    var sql = '''
      SELECT ga.*, g.name as gift_name, u.name as user_name
      FROM gift_assignments ga
      JOIN gifts g ON ga.gift_id = g.id
      JOIN users u ON ga.user_id = u.id
    ''';
    final params = <String, dynamic>{};
    if (day != null) {
      sql += ' WHERE ga.day_number = @day';
      params['day'] = int.parse(day);
    }
    sql += ' ORDER BY ga.assigned_at DESC';
    final results = await conn.execute(Sql.indexed(sql), parameters: params);
    return _jsonResponse(_parseResults(results));
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

Future<Response> _assignGift(Request request) async {
  try {
    final body = await _getBody(request);
    final conn = await db;
    final results = await conn.execute(
      Sql.indexed('''
        INSERT INTO gift_assignments (gift_id, user_id, house_number, day_number, assigned_by, notes)
        VALUES (@gift, @user, @house, @day, @by, @notes) RETURNING id
      '''),
      parameters: {
        'gift': body['gift_id'], 'user': body['user_id'],
        'house': body['house_number'], 'day': body['day_number'],
        'by': body['assigned_by'], 'notes': body['notes'],
      },
    );
    return _jsonResponse({'id': results.first.toColumnMap()['id']});
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

Future<Response> _getMyGifts(Request request, String house) async {
  try {
    final conn = await db;
    final results = await conn.execute(
      Sql.indexed('''
        SELECT ga.*, g.name as gift_name, g.gift_type
        FROM gift_assignments ga
        JOIN gifts g ON ga.gift_id = g.id
        WHERE ga.house_number = @house
        ORDER BY ga.assigned_at DESC
      '''),
      parameters: {'house': house},
    );
    return _jsonResponse(_parseResults(results));
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

// ========== ANNOUNCEMENTS ==========

Future<Response> _getAnnouncements(Request request) async {
  try {
    final conn = await db;
    final results = await conn.execute(Sql.indexed('SELECT * FROM announcements WHERE is_active = TRUE ORDER BY created_at DESC'));
    return _jsonResponse(_parseResults(results));
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

Future<Response> _createAnnouncement(Request request) async {
  try {
    final body = await _getBody(request);
    final conn = await db;
    final results = await conn.execute(
      Sql.indexed('''
        INSERT INTO announcements (title, message, announcement_type, priority)
        VALUES (@title, @msg, @type, @pri) RETURNING id
      '''),
      parameters: {
        'title': body['title'], 'msg': body['message'],
        'type': body['announcement_type'] ?? 'general',
        'pri': body['priority'] ?? 1,
      },
    );
    return _jsonResponse({'id': results.first.toColumnMap()['id']});
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

Future<Response> _deleteAnnouncement(Request request, String id) async {
  try {
    final conn = await db;
    await conn.execute(
      Sql.indexed('UPDATE announcements SET is_active = FALSE WHERE id = @id'),
      parameters: {'id': int.parse(id)},
    );
    return _jsonResponse({'ok': true});
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

// ========== TICKETS ==========

Future<Response> _getMyTickets(Request request, String house) async {
  try {
    final conn = await db;
    final results = await conn.execute(
      Sql.indexed('''
        SELECT dt.*, nd.goddess_name, nd.date as event_date, nd.dress_code, u.name as user_name
        FROM draw_tickets dt
        JOIN navratri_days nd ON dt.day_number = nd.day_number
        JOIN users u ON dt.user_id = u.id
        WHERE dt.house_number = @house AND dt.is_assigned = TRUE
        ORDER BY dt.day_number
      '''),
      parameters: {'house': house},
    );
    return _jsonResponse(_parseResults(results));
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

Future<Response> _generateTickets(Request request) async {
  try {
    final body = await _getBody(request);
    final conn = await db;
    final dayNumber = body['day_number'] as int;
    final count = body['count'] as int;
    for (int i = 0; i < count; i++) {
      final ticketCode = 'NR2026-D$dayNumber-${DateTime.now().millisecondsSinceEpoch}-$i';
      await conn.execute(
        Sql.indexed('INSERT INTO draw_tickets (ticket_code, day_number) VALUES (@code, @day)'),
        parameters: {'code': ticketCode, 'day': dayNumber},
      );
    }
    return _jsonResponse({'ok': true});
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

Future<Response> _assignTicket(Request request) async {
  try {
    final body = await _getBody(request);
    final conn = await db;
    await conn.execute(
      Sql.indexed('''
        UPDATE draw_tickets SET user_id = @userId, house_number = @house, 
            is_assigned = TRUE, assigned_at = CURRENT_TIMESTAMP
        WHERE ticket_code = @code
      '''),
      parameters: {
        'code': body['ticket_code'],
        'userId': body['user_id'],
        'house': body['house_number'],
      },
    );
    return _jsonResponse({'ok': true});
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

// ========== GENERIC ==========

Future<Response> _genericQuery(Request request) async {
  try {
    final body = await _getBody(request);
    final conn = await db;
    final results = await conn.execute(
      Sql.indexed(body['sql'] as String),
      parameters: body['parameters'] != null
          ? Map<String, dynamic>.from(body['parameters'] as Map)
          : null,
    );
    return _jsonResponse(_parseResults(results));
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

Future<Response> _genericExecute(Request request) async {
  try {
    final body = await _getBody(request);
    final conn = await db;
    await conn.execute(
      Sql.indexed(body['sql'] as String),
      parameters: body['parameters'] != null
          ? Map<String, dynamic>.from(body['parameters'] as Map)
          : null,
    );
    return _jsonResponse({'ok': true});
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

// ========== CORS ==========

Future<Response> _optionsHandler(Request request) async {
  return Response.ok('', headers: {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
  });
}

// ========== MAIN ==========

void main(List<String> args) async {
  final ip = InternetAddress.anyIPv4;
  final port = int.parse(args.isNotEmpty ? args[0] : '8080');

  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware((innerHandler) {
    return (request) async {
      if (request.method == 'OPTIONS') {
        return _optionsHandler(request);
      }
      return innerHandler(request);
    };
  }).addHandler(router.call);

  final server = await serve(handler, ip, port);
  print('Navratri API Server running on http://${server.address.host}:${server.port}');
}
