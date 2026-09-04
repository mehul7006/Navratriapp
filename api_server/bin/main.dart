import 'dart:io';
import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:postgres/postgres.dart';

const Duration istOffset = Duration(hours: 5, minutes: 30);

String _toIST(DateTime dt) {
  final ist = dt.isUtc ? dt.add(istOffset) : dt.add(istOffset);
  return '${ist.year.toString().padLeft(4, '0')}-${ist.month.toString().padLeft(2, '0')}-${ist.day.toString().padLeft(2, '0')}T${ist.hour.toString().padLeft(2, '0')}:${ist.minute.toString().padLeft(2, '0')}:${ist.second.toString().padLeft(2, '0')}.${ist.millisecond.toString().padLeft(3, '0')}';
}

String _nowIST() {
  return _toIST(DateTime.now().toUtc());
}

Connection? _db;

Future<Connection> get db async {
  if (_db != null) return _db!;
  _db = await Connection.open(
    Endpoint(
      host: 'localhost',
      port: 5432,
      database: 'navratri_2026',
      username: 'postgres',
      password: 'postgres',
    ),
    settings: const ConnectionSettings(
      sslMode: SslMode.disable,
      connectTimeout: Duration(seconds: 5),
      queryTimeout: Duration(seconds: 10),
    ),
  );
  // Set session timezone to IST (Asia/Kolkata)
  try {
    await _db!.execute("SET timezone = 'Asia/Kolkata'");
  } catch (_) {}
  // Add soft delete columns if missing
  try {
    await _db!.execute(
        "ALTER TABLE fund_collections ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN DEFAULT FALSE");
    await _db!.execute(
        "ALTER TABLE fund_collections ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP");
    await _db!.execute(
        "ALTER TABLE fund_collections ADD COLUMN IF NOT EXISTS deleted_reason TEXT");
    await _db!.execute(
        "ALTER TABLE expenses ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN DEFAULT FALSE");
    await _db!.execute(
        "ALTER TABLE expenses ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP");
    await _db!.execute(
        "ALTER TABLE expenses ADD COLUMN IF NOT EXISTS deleted_reason TEXT");
    // Fix paid_by column type - must be varchar, not integer
    await _db!.execute("ALTER TABLE expenses DROP COLUMN IF EXISTS paid_by");
    await _db!.execute(
        "ALTER TABLE expenses ADD COLUMN paid_by VARCHAR DEFAULT 'organizer'");
    // Daily draws table for lucky draw spin
    await _db!.execute('''CREATE TABLE IF NOT EXISTS daily_draws (
      id SERIAL PRIMARY KEY, day_number INT NOT NULL, ticket_id INT,
      ticket_code VARCHAR, winner_id INT, house_number VARCHAR,
      draw_number INT DEFAULT 1, drawn_by INT, drawn_at TIMESTAMP DEFAULT NOW()
    )''');
    await _db!.execute(
        "ALTER TABLE daily_draws ADD COLUMN IF NOT EXISTS draw_date DATE DEFAULT CURRENT_DATE");
    await _db!.execute(
        "UPDATE daily_draws SET draw_date = DATE(drawn_at) WHERE draw_date IS NULL");
    await _db!.execute(
        "ALTER TABLE daily_draws ADD COLUMN IF NOT EXISTS winner_id INT");
    await _db!.execute(
        "ALTER TABLE daily_draws ADD COLUMN IF NOT EXISTS ticket_id INT");
    await _db!.execute(
        "ALTER TABLE daily_draws ADD COLUMN IF NOT EXISTS draw_number INT DEFAULT 1");
    await _db!.execute(
        "ALTER TABLE daily_draws ADD COLUMN IF NOT EXISTS drawn_by INT");
    await _db!.execute(
        "ALTER TABLE daily_draws ADD COLUMN IF NOT EXISTS ticket_code VARCHAR");
    await _db!.execute(
        "ALTER TABLE daily_draws ADD COLUMN IF NOT EXISTS house_number VARCHAR");
    await _db!.execute(
        "ALTER TABLE daily_draws ADD COLUMN IF NOT EXISTS prize_level INT");
    await _db!.execute(
        "ALTER TABLE daily_draws ADD COLUMN IF NOT EXISTS status VARCHAR DEFAULT 'drawn'");
    await _db!.execute(
        "ALTER TABLE daily_draws ADD COLUMN IF NOT EXISTS is_available BOOLEAN");
    await _db!.execute(
        "ALTER TABLE daily_draws ADD COLUMN IF NOT EXISTS rescheduled_to_day INT");
    await _db!.execute(
        "ALTER TABLE daily_draws ADD COLUMN IF NOT EXISTS cancelled_reason TEXT");
    await _db!.execute(
        "ALTER TABLE daily_draws ADD COLUMN IF NOT EXISTS cancelled_at TIMESTAMP");
    // Member type column - main = paid member, sub = garba participant
    await _db!.execute(
        "ALTER TABLE users ADD COLUMN IF NOT EXISTS member_type VARCHAR DEFAULT 'main'");
    // Fix existing users that have NULL member_type - set to 'main'
    await _db!.execute(
        "UPDATE users SET member_type = 'main' WHERE member_type IS NULL AND user_type != 'organizer'");
    // Gift assignments status column
    await _db!.execute(
        "ALTER TABLE gift_assignments ADD COLUMN IF NOT EXISTS status VARCHAR DEFAULT 'assigned'");
    // Allow multiple members per house - drop unique constraint with CASCADE
    try {
      await _db!.execute(
          'ALTER TABLE users DROP CONSTRAINT IF EXISTS users_house_number_key CASCADE');
    } catch (_) {}
    // ========== SONG REQUESTS ==========
    await _db!.execute('''CREATE TABLE IF NOT EXISTS song_requests (
      id SERIAL PRIMARY KEY, user_id INT, song_name VARCHAR NOT NULL,
      youtube_link VARCHAR, day_number INT NOT NULL,
      request_type VARCHAR DEFAULT 'live', status VARCHAR DEFAULT 'pending',
      request_count INT DEFAULT 1, played_at TIMESTAMP, created_at TIMESTAMP DEFAULT NOW()
    )''');
    await _db!.execute('''CREATE TABLE IF NOT EXISTS song_suggestions (
      id SERIAL PRIMARY KEY, user_id INT, song_name VARCHAR NOT NULL,
      youtube_link VARCHAR, target_day INT NOT NULL, upvotes INT DEFAULT 0,
      created_at TIMESTAMP DEFAULT NOW()
    )''');
    await _db!.execute('''CREATE TABLE IF NOT EXISTS song_upvotes (
      id SERIAL PRIMARY KEY, song_suggestion_id INT, user_id INT,
      created_at TIMESTAMP DEFAULT NOW(), UNIQUE(song_suggestion_id, user_id)
    )''');
    // ========== SHOUTOUTS ==========
    await _db!.execute('''CREATE TABLE IF NOT EXISTS shoutouts (
      id SERIAL PRIMARY KEY, from_user_id INT, to_user_id INT,
      message TEXT NOT NULL, emoji VARCHAR(10) DEFAULT '🎉',
      day_number INT NOT NULL, shoutout_type VARCHAR DEFAULT 'general',
      is_approved BOOLEAN DEFAULT TRUE, created_at TIMESTAMP DEFAULT NOW()
    )''');
    await _db!.execute('''CREATE TABLE IF NOT EXISTS shoutout_reactions (
      id SERIAL PRIMARY KEY, shoutout_id INT, user_id INT,
      reaction VARCHAR(5) NOT NULL, created_at TIMESTAMP DEFAULT NOW(),
      UNIQUE(shoutout_id, user_id, reaction)
    )''');
  } catch (_) {}
  return _db!;
}

final router = Router()
  ..post('/api/auth/login-user', _loginUser)
  ..post('/api/auth/login-organizer', _loginOrganizer)
  ..post('/api/auth/login-sponsor', _loginSponsor)
  ..post('/api/auth/register', _register)
  ..get('/api/members', _getAllMembers)
  ..get('/api/members/house/<house>', _getMembersByHouse)
  ..put('/api/members/<id>/status', _updateMemberStatus)
  ..put('/api/members/<id>', _updateMember)
  ..delete('/api/members/<id>', _deleteMember)
  ..get('/api/garba/houses', _getGarbaHouses)
  ..get('/api/garba/members/<house>', _getGarbaMembersByHouse)
  ..post('/api/garba/members', _addGarbaMember)
  ..put('/api/garba/members/<id>/move', _moveGarbaMember)
  ..delete('/api/garba/members/<id>', _deleteGarbaMember)
  ..get('/api/garba/member/<id>/details', _getGarbaMemberDetails)
  ..get('/api/payments', _getAllPayments)
  ..get('/api/payments/house/<house>', _getPaymentsByHouse)
  ..post('/api/payments', _addPayment)
  ..put('/api/payments/<id>', _updatePayment)
  ..put('/api/payments/<id>/status', _updatePaymentStatus)
  ..get('/api/expenses', _getExpenses)
  ..put('/api/expenses/<id>', _updateExpense)
  ..delete('/api/expenses/<id>', _deleteExpense)
  ..get('/api/expenses/deleted', _getDeletedExpenses)
  ..delete('/api/payments/<id>', _deletePayment)
  ..get('/api/payments/deleted', _getDeletedPayments)
  ..post('/api/tickets/batch-delete', _batchDeleteTickets)
  ..get('/api/aarti-slots/<day>', _getAartiSlots)
  ..get('/api/aarti-slots', _getAllAartiSlots)
  ..post('/api/aarti-slots', _addAartiSlot)
  ..put('/api/aarti-slots/<id>', _updateAartiSlot)
  ..get('/api/aarti-bookings', _getAartiBookings)
  ..get('/api/aarti-bookings/my/<house>', _getMyAartiBookings)
  ..post('/api/aarti-bookings', _bookAartiSlot)
  ..put('/api/aarti-bookings/<id>/status', _updateBookingStatus)
  ..put('/api/aarti-bookings/<id>/cancel', _cancelAartiBooking)
  ..get('/api/snacks', _getSnacks)
  ..get('/api/snacks/all', _getAllSnacks)
  ..post('/api/snacks', _addSnack)
  ..put('/api/snacks/<id>', _updateSnack)
  ..get('/api/snack-orders', _getSnackOrders)
  ..get('/api/snack-orders/my/<house>', _getMySnackOrders)
  ..post('/api/snack-orders', _orderSnack)
  ..put('/api/snack-orders/<id>/status', _updateSnackOrderStatus)
  ..put('/api/snack-orders/<id>/cancel', _cancelSnackOrder)
  ..get('/api/gifts', _getGifts)
  ..post('/api/gifts', _addGift)
  ..put('/api/gifts/<id>', _updateGift)
  ..get('/api/gift-assignments', _getGiftAssignments)
  ..post('/api/gift-assignments', _assignGift)
  ..put('/api/gift-assignments/<id>/cancel', _cancelGiftAssignment)
  ..get('/api/gifts/my/<house>', _getMyGifts)
  ..get('/api/announcements', _getAnnouncements)
  ..post('/api/announcements', _createAnnouncement)
  ..delete('/api/announcements/<id>', _deleteAnnouncement)
  ..get('/api/tickets/my/<house>', _getMyTickets)
  ..get('/api/tickets', _getAllTickets)
  ..post('/api/tickets/generate', _generateTickets)
  ..put('/api/tickets/assign', _assignTicket)
  ..put('/api/tickets/<id>/winner', _markWinner)
  ..delete('/api/tickets/<id>', _deleteTicket)
  ..get('/api/navratri-days', _getNavratriDays)
  ..put('/api/navratri-days/<day>', _updateNavratriDay)
  ..get('/api/daily-schedules/<day>', _getDailySchedule)
  ..post('/api/daily-schedules', _addScheduleEvent)
  ..delete('/api/daily-schedules/<id>', _deleteScheduleEvent)
  ..get('/api/sponsors', _getAllSponsors)
  ..post('/api/sponsors', _addSponsor)
  ..put('/api/sponsors/<id>', _updateSponsor)
  ..put('/api/sponsors/<id>/image', _updateSponsorImage)
  ..get('/api/sponsors/active', _getActiveSponsors)
  ..delete('/api/sponsors/<id>', _deleteSponsor)
  ..put('/api/profile/<id>', _updateProfile)
  ..get('/api/winners', _getWinners)
  ..get('/api/winners/history', _getDrawHistory)
  ..post('/api/daily-draws/spin-prize', _spinPrizeDraw)
  ..post('/api/daily-draws/spin', _spinDraw)
  ..get('/api/daily-draws/history', _getDailyDrawHistory)
  ..get('/api/daily-draws/count', _getDailyDrawCount)
  ..get('/api/daily-draws/tickets/<day>', _getDrawTicketsForDay)
  ..post('/api/daily-draws/confirm', _confirmDraw)
  ..post('/api/daily-draws/disqualify', _disqualifyDraw)
  ..post('/api/daily-draws/create', _createDraw)
  ..post('/api/daily-draws/cancel', _cancelDraw)
  ..get('/api/daily-info', _getDailyInfo)
  ..put('/api/navratri-days/<day>/start', _startDay)
  ..put('/api/navratri-days/<day>/end', _endDay)
  ..put('/api/navratri-days/<day>/reopen', _reopenDay)
  ..post('/api/broadcasts', _createBroadcast)
  ..get('/api/broadcasts', _getBroadcasts)
  ..delete('/api/broadcasts/<id>', _deleteBroadcast)
  // ========== SONG REQUESTS ==========
  ..post('/api/song-requests', _createSongRequest)
  ..get('/api/song-requests', _getSongRequests)
  ..put('/api/song-requests/<id>/play', _playSongRequest)
  ..put('/api/song-requests/<id>/skip', _skipSongRequest)
  ..delete('/api/song-requests/<id>', _deleteSongRequest)
  ..post('/api/song-requests/<id>/upvote', _upvoteSongRequest)
  // ========== SONG SUGGESTIONS ==========
  ..post('/api/song-suggestions', _createSongSuggestion)
  ..get('/api/song-suggestions', _getSongSuggestions)
  ..post('/api/song-suggestions/<id>/upvote', _upvoteSongSuggestion)
  ..delete('/api/song-suggestions/<id>/upvote', _removeUpvoteSuggestion)
  // ========== SHOUTOUTS ==========
  ..post('/api/shoutouts', _createShoutout)
  ..get('/api/shoutouts', _getShoutouts)
  ..post('/api/shoutouts/<id>/react', _reactShoutout)
  ..delete('/api/shoutouts/<id>/react', _removeShoutoutReaction)
  ..delete('/api/shoutouts/<id>', _deleteShoutout)
  ..get('/api/reports/summary', _getReportSummary)
  ..get('/api/reports/payments-by-house', _getPaymentsByHouseReport)
  ..get('/api/reports/expenses-by-date', _getExpensesByDateReport)
  ..get('/api/reports/daily-activity', _getDailyActivityReport)
  ..post('/api/query', _genericQuery)
  ..post('/api/execute', _genericExecute);

Map<String, dynamic> _parseRow(ResultRow row) {
  final map = row.toColumnMap();
  for (final key in map.keys) {
    if (map[key] is DateTime) {
      map[key] = _toIST(map[key] as DateTime);
    } else if (map[key] is String) {
      final val = map[key] as String;
      if (val.isNotEmpty) {
        if (val.contains('T') &&
            (val.endsWith('Z') ||
                RegExp(r'\d{4}-\d{2}-\d{2}T\d{2}:\d{2}').hasMatch(val))) {
          try {
            final dt = DateTime.parse(val);
            map[key] = _toIST(dt.isUtc ? dt : dt.toUtc());
          } catch (_) {}
        }
      }
    }
  }
  return map;
}

List<Map<String, dynamic>> _parseResults(Result results) {
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

Future<bool> _isDayBookable(Connection conn, int dayNumber) async {
  final result = await conn.execute(
    Sql.named('SELECT is_active, is_completed FROM navratri_days WHERE day_number = @day'),
    parameters: {'day': dayNumber},
  );
  if (result.isEmpty) return false;
  final row = result.first.toColumnMap();
  if (row['is_completed'] == true) return false;
  if (row['is_active'] == true) return true;
  final activeResult = await conn.execute(
    Sql.named('SELECT day_number FROM navratri_days WHERE is_active = TRUE'),
  );
  if (activeResult.isEmpty) return false;
  final activeDay = activeResult.first.toColumnMap()['day_number'] as int;
  return dayNumber > activeDay;
}

// ========== AUTH ==========

Future<Response> _loginUser(Request request) async {
  try {
    final body = await _getBody(request);
    final conn = await db;
    final results = await conn.execute(
      Sql.named('''
        SELECT id, house_number, name, mobile_number, user_type, profile_image
        FROM users 
        WHERE UPPER(house_number) = UPPER(@house) AND mobile_number = @mobile AND is_active = TRUE
      '''),
      parameters: {
        'house': body['house_number'],
        'mobile': body['mobile_number']
      },
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
      Sql.named('''
        SELECT id, house_number, name, user_type
        FROM users 
        WHERE UPPER(house_number) = UPPER(@username) AND password = @password 
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
      Sql.named('''
        SELECT u.id, u.house_number, u.name, u.mobile_number, u.user_type,
               s.company_name, s.advertisement_text, s.sponsorship_amount, s.payment_status
        FROM users u
        LEFT JOIN sponsors s ON u.id = s.user_id
        WHERE UPPER(u.house_number) = UPPER(@house) AND u.password = @password 
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
      Sql.named('''
        INSERT INTO users (house_number, name, mobile_number, user_type, member_type)
        VALUES (@house, @name, @mobile, @type, @member_type) RETURNING id
      '''),
      parameters: {
        'house': body['house_number'],
        'name': body['name'],
        'mobile': body['mobile_number'],
        'type': body['user_type'] ?? 'user',
        'member_type': body['member_type'] ?? 'main',
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
      Sql.named(
          "SELECT u.*, COALESCE(SUM(fc.amount), 0) as total_paid FROM users u LEFT JOIN fund_collections fc ON fc.user_id = u.id AND fc.payment_status = 'paid' AND fc.is_deleted IS NOT TRUE WHERE u.user_type != 'organizer' AND u.member_type = 'main' GROUP BY u.id HAVING COALESCE(SUM(fc.amount), 0) > 0 ORDER BY u.house_number"),
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
      Sql.named('UPDATE users SET is_active = @active WHERE id = @id'),
      parameters: {'active': body['is_active'], 'id': int.parse(id)},
    );
    return _jsonResponse({'ok': true});
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

Future<Response> _updateMember(Request request, String id) async {
  try {
    final body = await _getBody(request);
    final conn = await db;
    final updates = <String>[];
    final params = <String, dynamic>{'id': int.parse(id)};
    if (body.containsKey('name')) {
      updates.add('name = @name');
      params['name'] = body['name'];
    }
    if (body.containsKey('house_number')) {
      updates.add('house_number = @house');
      params['house'] = body['house_number'];
    }
    if (body.containsKey('mobile_number')) {
      updates.add('mobile_number = @mobile');
      params['mobile'] = body['mobile_number'];
    }
    if (updates.isEmpty) return _jsonResponse({'ok': true});
    await conn.execute(
        Sql.named('UPDATE users SET ${updates.join(', ')} WHERE id = @id'),
        parameters: params);
    return _jsonResponse({'ok': true});
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

Future<Response> _deleteMember(Request request, String id) async {
  try {
    final conn = await db;
    await conn.execute(
      Sql.named('DELETE FROM users WHERE id = @id'),
      parameters: {'id': int.parse(id)},
    );
    return _jsonResponse({'ok': true});
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

Future<Response> _getMembersByHouse(Request request, String house) async {
  try {
    final conn = await db;
    final results = await conn.execute(
      Sql.named(
          'SELECT * FROM users WHERE house_number = @house AND is_active = true ORDER BY name'),
      parameters: {'house': house},
    );
    return _jsonResponse(_parseResults(results));
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

// ========== GARBA PARTICIPATION ==========

Future<Response> _getGarbaHouses(Request request) async {
  try {
    final conn = await db;
    final results = await conn.execute(Sql.named('''
      SELECT house_number, COUNT(*) as member_count,
             array_agg(name ORDER BY name) as member_names
      FROM users 
      WHERE user_type != 'organizer' AND house_number IS NOT NULL
      GROUP BY house_number 
      ORDER BY house_number
    '''));
    return _jsonResponse(_parseResults(results));
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

Future<Response> _getGarbaMembersByHouse(Request request, String house) async {
  try {
    final conn = await db;
    final results = await conn.execute(Sql.named('''
      SELECT u.id, u.name, u.house_number, u.user_type, u.member_type, u.is_active,
             (SELECT COUNT(*) FROM draw_tickets dt WHERE dt.user_id = u.id) as total_tickets,
             (SELECT COUNT(*) FROM draw_tickets dt WHERE dt.user_id = u.id AND dt.is_winner = TRUE) as winning_tickets,
             (SELECT dd.prize_level FROM daily_draws dd WHERE dd.winner_id = u.id AND dd.status = 'confirmed' ORDER BY dd.drawn_at DESC LIMIT 1) as last_prize_level
      FROM users u
      WHERE u.house_number = @house AND u.user_type != 'organizer'
      ORDER BY u.member_type, u.name
    '''), parameters: {'house': house});
    return _jsonResponse(_parseResults(results));
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

Future<Response> _addGarbaMember(Request request) async {
  try {
    final body = await _getBody(request);
    final conn = await db;
    final name = body['name'] as String;
    final houseNumber = body['house_number'] as String;
    final memberType = body['member_type'] as String? ?? 'sub';
    
    final result = await conn.execute(Sql.named(
      'INSERT INTO users (name, house_number, user_type, member_type, is_active) VALUES (@name, @house, @userType, @memberType, true) RETURNING id'),
      parameters: {'name': name, 'house': houseNumber, 'userType': 'user', 'memberType': memberType});
    
    return _jsonResponse({'ok': true, 'id': result.first.toColumnMap()['id']});
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

Future<Response> _moveGarbaMember(Request request, String id) async {
  try {
    final body = await _getBody(request);
    final conn = await db;
    final newHouse = body['new_house_number'] as String;
    
    await conn.execute(Sql.named(
      'UPDATE users SET house_number = @house WHERE id = @id'),
      parameters: {'house': newHouse, 'id': int.parse(id)});
    
    return _jsonResponse({'ok': true});
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

Future<Response> _deleteGarbaMember(Request request, String id) async {
  try {
    final conn = await db;
    await conn.execute(
      Sql.named('DELETE FROM users WHERE id = @id'),
      parameters: {'id': int.parse(id)});
    return _jsonResponse({'ok': true});
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

Future<Response> _getGarbaMemberDetails(Request request, String id) async {
  try {
    final conn = await db;
    final userId = int.parse(id);
    
    // Get user info
    final userResult = await conn.execute(
      Sql.named('SELECT * FROM users WHERE id = @id'),
      parameters: {'id': userId});
    if (userResult.isEmpty) return _errorResponse('Member not found');
    final user = userResult.first.toColumnMap();
    
    // Get tickets with day info
    final ticketsResult = await conn.execute(Sql.named('''
      SELECT dt.*, nd.goddess_name, nd.date as event_date,
             dd.status as draw_status, dd.prize_level
      FROM draw_tickets dt
      LEFT JOIN navratri_days nd ON dt.day_number = nd.day_number
      LEFT JOIN daily_draws dd ON dd.ticket_code = dt.ticket_code AND dd.day_number = dt.day_number
      WHERE dt.user_id = @userId
      ORDER BY dt.day_number, dt.ticket_code
    '''), parameters: {'userId': userId});
    
    // Get lucky draw wins
    final winsResult = await conn.execute(Sql.named('''
      SELECT dd.*, nd.goddess_name, nd.date as event_date
      FROM daily_draws dd
      LEFT JOIN navratri_days nd ON dd.day_number = nd.day_number
      WHERE dd.winner_id = @userId AND dd.status = 'confirmed'
      ORDER BY dd.drawn_at DESC
    '''), parameters: {'userId': userId});
    
    return _jsonResponse({
      'user': user,
      'tickets': _parseResults(ticketsResult),
      'wins': _parseResults(winsResult),
    });
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

// ========== PAYMENTS ==========

Future<Response> _getAllPayments(Request request) async {
  try {
    final conn = await db;
    final results = await conn.execute(Sql.named('''
      SELECT fc.*, u.name as user_name, u.house_number,
             ru.name as receiver_name
      FROM fund_collections fc
      JOIN users u ON fc.user_id = u.id
      LEFT JOIN users ru ON fc.received_by = ru.id
      WHERE fc.is_deleted IS NOT TRUE
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
      Sql.named('''
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
      Sql.named('''
        INSERT INTO fund_collections 
          (user_id, house_number, amount, payment_method, payment_status, tentative_date, paid_date, received_by, notes, payer_name)
        VALUES (@userId, @house, @amount, @method, @status, @tentative, @paidDate, @receivedBy, @notes, @payerName)
        RETURNING id
      '''),
      parameters: {
        'userId': body['user_id'],
        'house': body['house_number'],
        'amount': body['amount'],
        'method': body['payment_method'],
        'status': body['payment_status'] ?? 'paid',
        'tentative': body['tentative_date'],
        'paidDate': body['paid_date'],
        'receivedBy': body['received_by'],
        'notes': body['notes'],
        'payerName': body['payer_name'],
      },
    );
    return _jsonResponse({'id': results.first.toColumnMap()['id']});
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

Future<Response> _updatePayment(Request request, String id) async {
  try {
    final body = await _getBody(request);
    final conn = await db;
    final sets = <String>[];
    final params = <String, dynamic>{'id': int.parse(id)};
    if (body.containsKey('amount')) {
      sets.add('amount = @amount');
      params['amount'] = body['amount'];
    }
    if (body.containsKey('payment_method')) {
      sets.add('payment_method = @method');
      params['method'] = body['payment_method'];
    }
    if (body.containsKey('payer_name')) {
      sets.add('payer_name = @payer');
      params['payer'] = body['payer_name'];
    }
    if (body.containsKey('notes')) {
      sets.add('notes = @notes');
      params['notes'] = body['notes'];
    }
    if (sets.isEmpty) return _jsonResponse({'ok': true});
    await conn.execute(
        Sql.named(
            'UPDATE fund_collections SET ${sets.join(", ")} WHERE id = @id'),
        parameters: params);
    return _jsonResponse({'ok': true});
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

Future<Response> _updatePaymentStatus(Request request, String id) async {
  try {
    final body = await _getBody(request);
    final conn = await db;
    final status = body['payment_status'];
    final sets = <String>['payment_status = @status'];
    final params = <String, dynamic>{'status': status, 'id': int.parse(id)};
    if (body.containsKey('paid_date') && body['paid_date'] != null) {
      sets.add('paid_date = @paidDate');
      params['paidDate'] = DateTime.tryParse(body['paid_date']);
    }
    if (body.containsKey('payment_method') && body['payment_method'] != null) {
      sets.add('payment_method = @method');
      params['method'] = body['payment_method'];
    }
    await conn.execute(
      Sql.named(
          'UPDATE fund_collections SET ${sets.join(", ")} WHERE id = @id'),
      parameters: params,
    );
    return _jsonResponse({'ok': true});
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

Future<Response> _getExpenses(Request request) async {
  try {
    final conn = await db;
    final results = await conn.execute(Sql.named('''
      SELECT e.*, c.name as category_name
      FROM expenses e
      JOIN expense_categories c ON e.category_id = c.id
      WHERE e.is_deleted IS NOT TRUE
      ORDER BY e.created_at DESC
    '''));
    return _jsonResponse(_parseResults(results));
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

Future<Response> _updateExpense(Request request, String id) async {
  try {
    final body = await _getBody(request);
    final conn = await db;
    final sets = <String>[];
    final params = <String, dynamic>{'id': int.parse(id)};
    if (body.containsKey('category_id')) {
      sets.add('category_id = @catId');
      params['catId'] = body['category_id'];
    }
    if (body.containsKey('item_name')) {
      sets.add('item_name = @item');
      params['item'] = body['item_name'];
    }
    if (body.containsKey('amount')) {
      sets.add('amount = @amount');
      params['amount'] = body['amount'];
    }
    if (body.containsKey('paid_to')) {
      sets.add('paid_to = @paidTo');
      params['paidTo'] = body['paid_to'];
    }
    if (body.containsKey('expense_date')) {
      sets.add('expense_date = @date');
      params['date'] = body['expense_date'];
    }
    if (body.containsKey('notes')) {
      sets.add('notes = @notes');
      params['notes'] = body['notes'];
    }
    if (body.containsKey('paid_by')) {
      sets.add('paid_by = @paidBy');
      params['paidBy'] = body['paid_by'];
    }
    if (sets.isEmpty) return _jsonResponse({'ok': true});
    await conn.execute(
        Sql.named('UPDATE expenses SET ${sets.join(", ")} WHERE id = @id'),
        parameters: params);
    return _jsonResponse({'ok': true});
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

Future<Response> _deletePayment(Request request, String id) async {
  try {
    final body = await _getBody(request);
    final reason = body['reason'] ?? '';
    if (reason.toString().trim().isEmpty) {
      return _errorResponse('Reason is required to delete');
    }
    final conn = await db;
    await conn.execute(
      Sql.named(
          'UPDATE fund_collections SET is_deleted = TRUE, deleted_at = @now, deleted_reason = @reason WHERE id = @id'),
      parameters: {
        'id': int.parse(id),
        'reason': reason,
        'now': DateTime.now().toUtc()
      },
    );
    return _jsonResponse({'ok': true});
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

Future<Response> _getDeletedPayments(Request request) async {
  try {
    final conn = await db;
    final results = await conn.execute(
      Sql.named(
          'SELECT * FROM fund_collections WHERE is_deleted = TRUE ORDER BY deleted_at DESC'),
    );
    return _jsonResponse(_parseResults(results));
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

Future<Response> _deleteExpense(Request request, String id) async {
  try {
    final body = await _getBody(request);
    final reason = body['reason'] ?? '';
    if (reason.toString().trim().isEmpty) {
      return _errorResponse('Reason is required to delete');
    }
    final conn = await db;
    await conn.execute(
      Sql.named(
          'UPDATE expenses SET is_deleted = TRUE, deleted_at = @now, deleted_reason = @reason WHERE id = @id'),
      parameters: {
        'id': int.parse(id),
        'reason': reason,
        'now': DateTime.now().toUtc()
      },
    );
    return _jsonResponse({'ok': true});
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

Future<Response> _getDeletedExpenses(Request request) async {
  try {
    final conn = await db;
    final results = await conn.execute(Sql.named('''
      SELECT e.*, c.name as category_name
      FROM expenses e
      JOIN expense_categories c ON e.category_id = c.id
      WHERE e.is_deleted = TRUE
      ORDER BY e.deleted_at DESC
    '''));
    return _jsonResponse(_parseResults(results));
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

Future<Response> _batchDeleteTickets(Request request) async {
  try {
    final body = await _getBody(request);
    final ids = body['ids'];
    final reason = body['reason'] ?? '';
    if (reason.toString().trim().isEmpty) {
      return _errorResponse('Reason is required to delete');
    }
    if (ids == null || ids is! List || ids.isEmpty) {
      return _errorResponse('No tickets selected');
    }
    final conn = await db;
    final idList = ids.map((e) => int.parse(e.toString())).toList();
    await conn.execute(
      Sql.named('DELETE FROM draw_tickets WHERE id = ANY(@ids)'),
      parameters: {'ids': idList},
    );
    return _jsonResponse({'ok': true, 'deleted': idList.length});
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

// ========== AARTI SLOTS ==========

Future<Response> _getAartiSlots(Request request, String day) async {
  try {
    final conn = await db;
    final results = await conn.execute(
      Sql.named(
          'SELECT * FROM aarti_slots WHERE day_number = @day ORDER BY slot_time'),
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
      Sql.named('SELECT * FROM aarti_slots ORDER BY day_number, slot_time'),
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
      Sql.named('''
        INSERT INTO aarti_slots (day_number, slot_time, slot_label, max_participants)
        VALUES (@day, @time, @label, @max) RETURNING id
      '''),
      parameters: {
        'day': body['day_number'],
        'time': body['slot_time'],
        'label': body['slot_label'],
        'max': body['max_participants'],
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
    if (body.containsKey('slot_time')) {
      updates.add('slot_time = @time');
      params['time'] = body['slot_time'];
    }
    if (body.containsKey('slot_label')) {
      updates.add('slot_label = @label');
      params['label'] = body['slot_label'];
    }
    if (body.containsKey('max_participants')) {
      updates.add('max_participants = @max');
      params['max'] = body['max_participants'];
    }
    if (body.containsKey('is_active')) {
      updates.add('is_active = @active');
      params['active'] = body['is_active'];
    }
    if (updates.isNotEmpty) {
      await conn.execute(
          Sql.named(
              'UPDATE aarti_slots SET ${updates.join(', ')} WHERE id = @id'),
          parameters: params);
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
    if (day != null) {
      conditions.add('ab.day_number = @day');
      params['day'] = int.parse(day);
    }
    if (status != null) {
      conditions.add('ab.status = @status');
      params['status'] = status;
    }
    if (conditions.isNotEmpty) sql += ' WHERE ${conditions.join(' AND ')}';
    sql += ' ORDER BY ab.created_at DESC';
    final results = await conn.execute(Sql.named(sql), parameters: params);
    return _jsonResponse(_parseResults(results));
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

Future<Response> _getMyAartiBookings(Request request, String house) async {
  try {
    final conn = await db;
    final results = await conn.execute(
      Sql.named('''
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
    final dayNumber = body['day_number'] as int;
    if (!await _isDayBookable(conn, dayNumber)) {
      return _errorResponse('Bookings are closed for Day $dayNumber', status: 403);
    }
    final results = await conn.execute(
      Sql.named('''
        INSERT INTO aarti_bookings (user_id, house_number, day_number, slot_id)
        VALUES (@userId, @house, @day, @slot) RETURNING id
      '''),
      parameters: {
        'userId': body['user_id'],
        'house': body['house_number'],
        'day': body['day_number'],
        'slot': body['slot_id'],
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
      Sql.named('''
        UPDATE aarti_bookings SET status = @status, approved_by = @by, approved_at = @now
        WHERE id = @id
      '''),
      parameters: {
        'status': body['status'],
        'by': body['approved_by'],
        'id': int.parse(id),
        'now': DateTime.now().toUtc()
      },
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
    final results = await conn.execute(
        Sql.named('SELECT * FROM snacks WHERE is_active = TRUE ORDER BY name'));
    return _jsonResponse(_parseResults(results));
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

Future<Response> _getAllSnacks(Request request) async {
  try {
    final conn = await db;
    final results =
        await conn.execute(Sql.named('SELECT * FROM snacks ORDER BY name'));
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
      Sql.named('''
        INSERT INTO snacks (name, description, price, quantity_available, is_vegetarian)
        VALUES (@name, @desc, @price, @qty, @veg) RETURNING id
      '''),
      parameters: {
        'name': body['name'],
        'desc': body['description'],
        'price': body['price'],
        'qty': body['quantity_available'],
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
    if (body.containsKey('name')) {
      updates.add('name = @name');
      params['name'] = body['name'];
    }
    if (body.containsKey('price')) {
      updates.add('price = @price');
      params['price'] = body['price'];
    }
    if (body.containsKey('quantity_available')) {
      updates.add('quantity_available = @qty');
      params['qty'] = body['quantity_available'];
    }
    if (body.containsKey('is_active')) {
      updates.add('is_active = @active');
      params['active'] = body['is_active'];
    }
    if (updates.isNotEmpty) {
      await conn.execute(
          Sql.named('UPDATE snacks SET ${updates.join(', ')} WHERE id = @id'),
          parameters: params);
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
    if (day != null) {
      conditions.add('so.day_number = @day');
      params['day'] = int.parse(day);
    }
    if (status != null) {
      conditions.add('so.status = @status');
      params['status'] = status;
    }
    if (conditions.isNotEmpty) sql += ' WHERE ${conditions.join(' AND ')}';
    sql += ' ORDER BY so.created_at DESC';
    final results = await conn.execute(Sql.named(sql), parameters: params);
    return _jsonResponse(_parseResults(results));
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

Future<Response> _getMySnackOrders(Request request, String house) async {
  try {
    final conn = await db;
    final results = await conn.execute(
      Sql.named('''
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
    final dayNumber = body['day_number'] as int;
    if (!await _isDayBookable(conn, dayNumber)) {
      return _errorResponse('Bookings are closed for Day $dayNumber', status: 403);
    }
    final results = await conn.execute(
      Sql.named('''
        INSERT INTO snack_orders (user_id, house_number, snack_id, day_number, quantity, notes)
        VALUES (@userId, @house, @snackId, @day, @qty, @notes) RETURNING id
      '''),
      parameters: {
        'userId': body['user_id'],
        'house': body['house_number'],
        'snackId': body['snack_id'],
        'day': body['day_number'],
        'qty': body['quantity'],
        'notes': body['notes'],
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
      Sql.named('UPDATE snack_orders SET status = @status WHERE id = @id'),
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
    var sql =
        'SELECT g.*, s.company_name as sponsor_name FROM gifts g LEFT JOIN sponsors s ON g.sponsor_id = s.id';
    final conditions = <String>[];
    final params = <String, dynamic>{};
    if (day != null) {
      conditions.add('g.day_number = @day');
      params['day'] = int.parse(day);
    }
    if (type != null) {
      conditions.add('g.gift_type = @type');
      params['type'] = type;
    }
    if (conditions.isNotEmpty) sql += ' WHERE ${conditions.join(' AND ')}';
    sql += ' ORDER BY g.day_number, g.name';
    final results = await conn.execute(Sql.named(sql), parameters: params);
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
      Sql.named('''
        INSERT INTO gifts (name, description, sponsor_id, gift_type, day_number, quantity)
        VALUES (@name, @desc, @sponsor, @type, @day, @qty) RETURNING id
      '''),
      parameters: {
        'name': body['name'],
        'desc': body['description'],
        'sponsor': body['sponsor_id'],
        'type': body['gift_type'],
        'day': body['day_number'],
        'qty': body['quantity'],
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
    if (body.containsKey('name')) {
      updates.add('name = @name');
      params['name'] = body['name'];
    }
    if (body.containsKey('quantity')) {
      updates.add('quantity = @qty');
      params['qty'] = body['quantity'];
    }
    if (body.containsKey('is_active')) {
      updates.add('is_active = @active');
      params['active'] = body['is_active'];
    }
    if (updates.isNotEmpty) {
      await conn.execute(
          Sql.named('UPDATE gifts SET ${updates.join(', ')} WHERE id = @id'),
          parameters: params);
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
    final results = await conn.execute(Sql.named(sql), parameters: params);
    return _jsonResponse(_parseResults(results));
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

Future<Response> _assignGift(Request request) async {
  try {
    final body = await _getBody(request);
    final conn = await db;
    final dayNumber = body['day_number'] as int;
    if (!await _isDayBookable(conn, dayNumber)) {
      return _errorResponse('Bookings are closed for Day $dayNumber', status: 403);
    }
    final results = await conn.execute(
      Sql.named('''
        INSERT INTO gift_assignments (gift_id, user_id, house_number, day_number, assigned_by, notes)
        VALUES (@gift, @user, @house, @day, @by, @notes) RETURNING id
      '''),
      parameters: {
        'gift': body['gift_id'],
        'user': body['user_id'],
        'house': body['house_number'],
        'day': body['day_number'],
        'by': body['assigned_by'],
        'notes': body['notes'],
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
      Sql.named('''
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
    final results = await conn.execute(Sql.named(
        'SELECT * FROM announcements WHERE is_active = TRUE ORDER BY created_at DESC'));
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
      Sql.named('''
        INSERT INTO announcements (title, message, announcement_type, priority)
        VALUES (@title, @msg, @type, @pri) RETURNING id
      '''),
      parameters: {
        'title': body['title'],
        'msg': body['message'],
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
      Sql.named('UPDATE announcements SET is_active = FALSE WHERE id = @id'),
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
      Sql.named('''
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

    // Get the next sequential number
    final maxResult = await conn.execute(Sql.named(
        "SELECT ticket_code FROM draw_tickets ORDER BY id DESC LIMIT 1"));
    int nextNum = 2026100001;
    if (maxResult.isNotEmpty) {
      final lastCode =
          maxResult.first.toColumnMap()['ticket_code']?.toString() ?? '';
      final parsed = int.tryParse(lastCode);
      if (parsed != null && parsed >= 2026100001) {
        nextNum = parsed + 1;
      }
    }

    for (int i = 0; i < count; i++) {
      final ticketCode = (nextNum + i).toString();
      await conn.execute(
        Sql.named(
            'INSERT INTO draw_tickets (ticket_code, day_number) VALUES (@code, @day)'),
        parameters: {'code': ticketCode, 'day': dayNumber},
      );
    }
    return _jsonResponse({
      'ok': true,
      'from': (nextNum).toString(),
      'to': (nextNum + count - 1).toString()
    });
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

Future<Response> _assignTicket(Request request) async {
  try {
    final body = await _getBody(request);
    final conn = await db;
    await conn.execute(
      Sql.named('''
        UPDATE draw_tickets SET user_id = @userId, house_number = @house, 
            is_assigned = TRUE, assigned_at = @now
        WHERE ticket_code = @code
      '''),
      parameters: {
        'code': body['ticket_code'],
        'userId': body['user_id'],
        'house': body['house_number'],
        'now': DateTime.now().toUtc(),
      },
    );
    return _jsonResponse({'ok': true});
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

// ========== TICKETS (ORGANIZER) ==========

Future<Response> _getAllTickets(Request request) async {
  try {
    final conn = await db;
    final day = request.url.queryParameters['day'];
    final assigned = request.url.queryParameters['assigned'];
    String sql = '''
      SELECT dt.*, nd.goddess_name, nd.date as event_date, 
             u.name as user_name, u.house_number as assigned_house,
             (SELECT prize_level FROM daily_draws WHERE ticket_code = dt.ticket_code AND day_number = dt.day_number AND status = 'confirmed' ORDER BY drawn_at DESC LIMIT 1) as prize_level,
             (SELECT status FROM daily_draws WHERE ticket_code = dt.ticket_code AND day_number = dt.day_number ORDER BY drawn_at DESC LIMIT 1) as draw_status,
             (SELECT cancelled_reason FROM daily_draws WHERE ticket_code = dt.ticket_code AND day_number = dt.day_number AND status = 'cancelled' ORDER BY drawn_at DESC LIMIT 1) as cancelled_reason,
             CASE WHEN EXISTS(SELECT 1 FROM daily_draws WHERE ticket_code = dt.ticket_code AND day_number = dt.day_number AND status = 'confirmed') THEN TRUE ELSE FALSE END as is_winner
      FROM draw_tickets dt
      LEFT JOIN navratri_days nd ON dt.day_number = nd.day_number
      LEFT JOIN users u ON dt.user_id = u.id
    ''';
    final conditions = <String>[];
    final params = <String, dynamic>{};
    if (day != null) {
      conditions.add('dt.day_number = @day');
      params['day'] = int.parse(day);
    }
    if (assigned == 'true') conditions.add('dt.is_assigned = TRUE');
    if (assigned == 'false') conditions.add('dt.is_assigned = FALSE');
    if (conditions.isNotEmpty) sql += ' WHERE ${conditions.join(' AND ')}';
    sql += ' ORDER BY dt.day_number, dt.ticket_code';
    final results = await conn.execute(Sql.named(sql), parameters: params);
    return _jsonResponse(_parseResults(results));
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

Future<Response> _markWinner(Request request, String id) async {
  try {
    final conn = await db;
    await conn.execute(
      Sql.named('UPDATE draw_tickets SET is_winner = TRUE WHERE id = @id'),
      parameters: {'id': int.parse(id)},
    );
    return _jsonResponse({'ok': true});
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

Future<Response> _deleteTicket(Request request, String id) async {
  try {
    final conn = await db;
    await conn.execute(
      Sql.named('DELETE FROM draw_tickets WHERE id = @id'),
      parameters: {'id': int.parse(id)},
    );
    return _jsonResponse({'ok': true});
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

// ========== NAVRATRI DAYS ==========

Future<Response> _getNavratriDays(Request request) async {
  try {
    final conn = await db;
    final results = await conn.execute(
      Sql.named('SELECT * FROM navratri_days ORDER BY day_number'),
    );
    return _jsonResponse(_parseResults(results));
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

Future<Response> _updateNavratriDay(Request request, String day) async {
  try {
    final body = await _getBody(request);
    final conn = await db;
    final updates = <String>[];
    final params = <String, dynamic>{'day': int.parse(day)};
    if (body.containsKey('goddess_name')) {
      updates.add('goddess_name = @goddess');
      params['goddess'] = body['goddess_name'];
    }
    if (body.containsKey('dress_code')) {
      updates.add('dress_code = @dress');
      params['dress'] = body['dress_code'];
    }
    if (body.containsKey('is_active')) {
      updates.add('is_active = @active');
      params['active'] = body['is_active'];
    }
    if (body.containsKey('is_completed')) {
      updates.add('is_completed = @completed');
      params['completed'] = body['is_completed'];
    }
    if (updates.isEmpty) return _errorResponse('No fields to update');
    await conn.execute(
        Sql.named(
            'UPDATE navratri_days SET ${updates.join(', ')} WHERE day_number = @day'),
        parameters: params);
    return _jsonResponse({'ok': true});
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

// ========== DAILY SCHEDULES ==========

Future<Response> _getDailySchedule(Request request, String day) async {
  try {
    final conn = await db;
    final results = await conn.execute(
      Sql.named(
          'SELECT * FROM daily_schedules WHERE day_number = @day ORDER BY event_time'),
      parameters: {'day': int.parse(day)},
    );
    return _jsonResponse(_parseResults(results));
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

Future<Response> _addScheduleEvent(Request request) async {
  try {
    final body = await _getBody(request);
    final conn = await db;
    await conn.execute(
      Sql.named('''
        INSERT INTO daily_schedules (day_number, event_time, event_name, event_description, location)
        VALUES (@day, @time, @name, @desc, @location)
      '''),
      parameters: {
        'day': body['day_number'],
        'time': body['event_time'],
        'name': body['event_name'],
        'desc': body['event_description'] ?? '',
        'location': body['location'] ?? '',
      },
    );
    return _jsonResponse({'ok': true});
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

Future<Response> _deleteScheduleEvent(Request request, String id) async {
  try {
    final conn = await db;
    await conn.execute(
      Sql.named('DELETE FROM daily_schedules WHERE id = @id'),
      parameters: {'id': int.parse(id)},
    );
    return _jsonResponse({'ok': true});
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

// ========== SPONSORS ==========

Future<Response> _getAllSponsors(Request request) async {
  try {
    final conn = await db;
    final results = await conn.execute(
      Sql.named('''
        SELECT u.id, u.house_number, u.name, u.mobile_number, u.is_active,
               s.company_name, s.advertisement_text, s.sponsorship_amount, s.payment_status,
               s.advertisement_image
        FROM users u
        LEFT JOIN sponsors s ON u.id = s.user_id
        WHERE u.user_type = 'sponsor'
        ORDER BY u.house_number
      '''),
    );
    return _jsonResponse(_parseResults(results));
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

Future<Response> _addSponsor(Request request) async {
  try {
    final body = await _getBody(request);
    final conn = await db;
    final userResult = await conn.execute(
      Sql.named('''
        INSERT INTO users (house_number, name, mobile_number, user_type, password)
        VALUES (@house, @name, @mobile, 'sponsor', @password) RETURNING id
      '''),
      parameters: {
        'house': body['house_number'],
        'name': body['name'],
        'mobile': body['mobile_number'],
        'password': body['password'] ?? body['house_number'],
      },
    );
    final userId = userResult.first.toColumnMap()['id'];
    await conn.execute(
      Sql.named('''
        INSERT INTO sponsors (user_id, company_name, advertisement_text, sponsorship_amount, payment_status)
        VALUES (@userId, @company, @ad, @amount, 'pending')
      '''),
      parameters: {
        'userId': userId,
        'company': body['company_name'] ?? '',
        'ad': body['advertisement_text'] ?? '',
        'amount': body['sponsorship_amount'] ?? 0,
      },
    );
    return _jsonResponse({'ok': true, 'id': userId});
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

Future<Response> _updateSponsor(Request request, String id) async {
  try {
    final body = await _getBody(request);
    final conn = await db;
    if (body.containsKey('company_name') ||
        body.containsKey('sponsorship_amount') ||
        body.containsKey('payment_status')) {
      final updates = <String>[];
      final params = <String, dynamic>{'userId': int.parse(id)};
      if (body.containsKey('company_name')) {
        updates.add('company_name = @company');
        params['company'] = body['company_name'];
      }
      if (body.containsKey('advertisement_text')) {
        updates.add('advertisement_text = @ad');
        params['ad'] = body['advertisement_text'];
      }
      if (body.containsKey('sponsorship_amount')) {
        updates.add('sponsorship_amount = @amount');
        params['amount'] = body['sponsorship_amount'];
      }
      if (body.containsKey('payment_status')) {
        updates.add('payment_status = @status');
        params['status'] = body['payment_status'];
      }
      if (updates.isNotEmpty) {
        await conn.execute(
            Sql.named(
                'UPDATE sponsors SET ${updates.join(', ')} WHERE user_id = @userId'),
            parameters: params);
      }
    }
    return _jsonResponse({'ok': true});
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

// ========== USER PROFILE ==========

Future<Response> _updateProfile(Request request, String id) async {
  try {
    final body = await _getBody(request);
    final conn = await db;
    final updates = <String>[];
    final params = <String, dynamic>{'id': int.parse(id)};
    if (body.containsKey('name')) {
      updates.add('name = @name');
      params['name'] = body['name'];
    }
    if (body.containsKey('mobile_number')) {
      updates.add('mobile_number = @mobile');
      params['mobile'] = body['mobile_number'];
    }
    if (body.containsKey('password')) {
      updates.add('password = @password');
      params['password'] = body['password'];
    }
    if (updates.isEmpty) return _errorResponse('No fields to update');
    await conn.execute(
        Sql.named('UPDATE users SET ${updates.join(', ')} WHERE id = @id'),
        parameters: params);
    final result = await conn.execute(
      Sql.named(
          'SELECT id, house_number, name, mobile_number, user_type FROM users WHERE id = @id'),
      parameters: {'id': int.parse(id)},
    );
    if (result.isNotEmpty) return _jsonResponse(_parseRow(result.first));
    return _jsonResponse({'ok': true});
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

// ========== WINNERS ==========

Future<Response> _getWinners(Request request) async {
  try {
    final day = request.url.queryParameters['day'];
    final conn = await db;
    String sql = '''
      SELECT dt.ticket_code, dt.day_number, dt.is_winner,
             u.name as user_name, u.house_number,
             nd.goddess_name, nd.date as event_date,
             dd.prize_level, dd.status as draw_status
      FROM draw_tickets dt
      LEFT JOIN users u ON dt.user_id = u.id
      LEFT JOIN navratri_days nd ON dt.day_number = nd.day_number
      LEFT JOIN daily_draws dd ON dd.ticket_code = dt.ticket_code AND dd.day_number = dt.day_number AND dd.status = 'confirmed'
      WHERE dt.is_winner = TRUE
    ''';
    final params = <String, dynamic>{};
    if (day != null) {
      sql += ' AND dt.day_number = @day';
      params['day'] = int.parse(day);
    }
    sql += ' ORDER BY dt.day_number DESC';
    final results = await conn.execute(Sql.named(sql), parameters: params);
    return _jsonResponse(_parseResults(results));
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

Future<Response> _getDrawHistory(Request request) async {
  try {
    final conn = await db;
    final results = await conn.execute(Sql.named('''
      SELECT dt.ticket_code, dt.day_number, dt.is_winner, dt.is_assigned,
             u.name as user_name, u.house_number,
             nd.goddess_name, nd.date as event_date
      FROM draw_tickets dt
      LEFT JOIN users u ON dt.user_id = u.id
      LEFT JOIN navratri_days nd ON dt.day_number = nd.day_number
      WHERE dt.is_winner = TRUE OR dt.is_assigned = TRUE
      ORDER BY dt.day_number DESC, dt.ticket_code
    '''));
    return _jsonResponse(_parseResults(results));
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

// ========== SPONSOR IMAGE ==========

Future<Response> _updateSponsorImage(Request request, String id) async {
  try {
    final body = await _getBody(request);
    final conn = await db;
    await conn.execute(
      Sql.named(
          'UPDATE sponsors SET advertisement_image = @image WHERE user_id = @userId'),
      parameters: {
        'userId': int.parse(id),
        'image': body['advertisement_image'] ?? ''
      },
    );
    return _jsonResponse({'ok': true});
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

Future<Response> _getActiveSponsors(Request request) async {
  try {
    final conn = await db;
    final results = await conn.execute(Sql.named('''
      SELECT s.company_name, s.advertisement_text, s.advertisement_image,
             s.sponsorship_amount, u.name as contact_name, u.house_number
      FROM sponsors s
      JOIN users u ON s.user_id = u.id
      WHERE s.is_active = TRUE AND u.is_active = TRUE
      ORDER BY s.sponsorship_amount DESC
    '''));
    return _jsonResponse(_parseResults(results));
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

Future<Response> _deleteSponsor(Request request, String id) async {
  try {
    final conn = await db;
    await conn.execute(
      Sql.named('DELETE FROM sponsors WHERE user_id = @userId'),
      parameters: {'userId': int.parse(id)},
    );
    await conn.execute(
      Sql.named('DELETE FROM users WHERE id = @id'),
      parameters: {'id': int.parse(id)},
    );
    return _jsonResponse({'ok': true});
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

// ========== BROADCASTS ==========

Future<Response> _createBroadcast(Request request) async {
  try {
    final body = await _getBody(request);
    final conn = await db;
    final prio = body['priority'] ?? 'normal';
    int priorityNum;
    switch (prio.toString()) {
      case 'urgent':
        priorityNum = 3;
        break;
      case 'high':
        priorityNum = 2;
        break;
      case 'normal':
        priorityNum = 1;
        break;
      default:
        priorityNum = 0;
        break;
    }
    await conn.execute(
      Sql.named(
          'INSERT INTO announcements (title, message, announcement_type, priority, is_active) VALUES (@title, @message, @type, @priority, TRUE)'),
      parameters: {
        'title': body['title'] ?? 'Broadcast',
        'message': body['message'] ?? '',
        'type': body['announcement_type'] ?? 'broadcast',
        'priority': priorityNum,
      },
    );
    return _jsonResponse({'ok': true});
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

Future<Response> _getBroadcasts(Request request) async {
  try {
    final conn = await db;
    final results = await conn.execute(
      Sql.named(
          'SELECT * FROM announcements WHERE announcement_type = \'broadcast\' ORDER BY created_at DESC'),
    );
    return _jsonResponse(_parseResults(results));
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

Future<Response> _deleteBroadcast(Request request, String id) async {
  try {
    final conn = await db;
    await conn.execute(Sql.named('DELETE FROM announcements WHERE id = @id'),
        parameters: {'id': int.parse(id)});
    return _jsonResponse({'ok': true});
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

// ========== CANCEL ENDPOINTS ==========

Future<Response> _cancelAartiBooking(Request request, String id) async {
  try {
    final conn = await db;
    await conn.execute(
      Sql.named(
          "UPDATE aarti_bookings SET status = 'cancelled' WHERE id = @id"),
      parameters: {'id': int.parse(id)},
    );
    return _jsonResponse({'ok': true});
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

Future<Response> _cancelSnackOrder(Request request, String id) async {
  try {
    final conn = await db;
    await conn.execute(
      Sql.named("UPDATE snack_orders SET status = 'cancelled' WHERE id = @id"),
      parameters: {'id': int.parse(id)},
    );
    return _jsonResponse({'ok': true});
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

Future<Response> _cancelGiftAssignment(Request request, String id) async {
  try {
    final conn = await db;
    await conn.execute(
      Sql.named(
          "UPDATE gift_assignments SET status = 'cancelled' WHERE id = @id"),
      parameters: {'id': int.parse(id)},
    );
    return _jsonResponse({'ok': true});
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

// ========== 3-PRIZE LUCKY DRAW ==========

Future<Response> _spinPrizeDraw(Request request) async {
  try {
    final body = await _getBody(request);
    final conn = await db;
    final dayNumber = body['day_number'] as int;
    final drawnBy = body['drawn_by'] as int;
    final prizeLevel = body['prize_level'] as int;

    if (!await _isDayBookable(conn, dayNumber)) {
      return _errorResponse('Lucky Draw is closed for Day $dayNumber', status: 403);
    }

    if (prizeLevel < 1 || prizeLevel > 3)
      return _errorResponse('prize_level must be 1, 2, or 3');

    // Max 3 prize draws per day (count rows where prize_level IS NOT NULL)
    final countResult = await conn.execute(
      Sql.named(
          "SELECT COUNT(*) as cnt FROM daily_draws WHERE day_number = @day AND draw_date = CURRENT_DATE AND prize_level IS NOT NULL"),
      parameters: {'day': dayNumber},
    );
    final prizeSpinsToday = countResult.first.toColumnMap()['cnt'] ?? 0;
    if (prizeSpinsToday >= 3)
      return _errorResponse('Maximum 3 prize draws per day reached');

    // Pick random assigned ticket for this day, excluding users who won any prize in last 3 days
    final ticketResult = await conn.execute(
      Sql.named('''
        SELECT dt.id, dt.ticket_code, dt.user_id, dt.house_number, u.name as user_name
        FROM draw_tickets dt
        JOIN users u ON dt.user_id = u.id
        WHERE dt.day_number = @day AND dt.is_assigned = TRUE
        AND dt.user_id NOT IN (
          SELECT winner_id FROM daily_draws 
          WHERE winner_id IS NOT NULL 
          AND drawn_at > NOW() - INTERVAL '3 days'
        )
        ORDER BY RANDOM() LIMIT 1
      '''),
      parameters: {'day': dayNumber},
    );

    if (ticketResult.isEmpty)
      return _errorResponse('No more tickets to draw for this day');

    final ticket = _parseRow(ticketResult.first);
    await conn.execute(
      Sql.named('''
        INSERT INTO daily_draws (day_number, ticket_id, ticket_code, winner_id, house_number, draw_number, drawn_by, drawn_at, prize_level)
        VALUES (@day, @ticketId, @ticketCode, @winnerId, @house, @drawNum, @drawnBy, NOW(), @prizeLevel)
      '''),
      parameters: {
        'day': dayNumber,
        'ticketId': ticket['id'],
        'ticketCode': ticket['ticket_code'],
        'winnerId': ticket['user_id'],
        'house': ticket['house_number'],
        'drawNum': prizeSpinsToday + 1,
        'drawnBy': drawnBy,
        'prizeLevel': prizeLevel,
      },
    );

    return _jsonResponse({
      'ticket_code': ticket['ticket_code'],
      'user_name': ticket['user_name'],
      'house_number': ticket['house_number'],
      'prize_level': prizeLevel,
    });
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

// ========== LUCKY DRAW / SPIN ==========

Future<Response> _spinDraw(Request request) async {
  try {
    final body = await _getBody(request);
    final conn = await db;
    final dayNumber = body['day_number'] as int;

    final countResult = await conn.execute(
      Sql.named(
          "SELECT COUNT(*) as cnt FROM daily_draws WHERE day_number = @day AND draw_date = CURRENT_DATE"),
      parameters: {'day': dayNumber},
    );
    final spinsToday = countResult.first.toColumnMap()['cnt'] ?? 0;
    if (spinsToday >= 6)
      return _errorResponse('Maximum 6 draws per day reached');

    // Pick random assigned ticket for this day, excluding users who won in last 3 days
    final ticketResult = await conn.execute(
      Sql.named('''
        SELECT dt.id, dt.ticket_code, dt.user_id, dt.house_number, u.name as user_name
        FROM draw_tickets dt
        JOIN users u ON dt.user_id = u.id
        WHERE dt.day_number = @day AND dt.is_assigned = TRUE
        AND dt.user_id NOT IN (
          SELECT winner_id FROM daily_draws 
          WHERE winner_id IS NOT NULL 
          AND drawn_at > NOW() - INTERVAL '3 days'
        )
        ORDER BY RANDOM() LIMIT 1
      '''),
      parameters: {'day': dayNumber},
    );

    if (ticketResult.isEmpty)
      return _errorResponse('No more tickets to draw for this day');

    final ticket = _parseRow(ticketResult.first);
    await conn.execute(
      Sql.named('''
        INSERT INTO daily_draws (day_number, ticket_id, ticket_code, winner_id, house_number, draw_number, drawn_by, drawn_at)
        VALUES (@day, @ticketId, @ticketCode, @winnerId, @house, @drawNum, @drawnBy, NOW())
      '''),
      parameters: {
        'day': dayNumber,
        'ticketId': ticket['id'],
        'ticketCode': ticket['ticket_code'],
        'winnerId': ticket['user_id'],
        'house': ticket['house_number'],
        'drawNum': spinsToday + 1,
        'drawnBy': body['drawn_by'],
      },
    );

    return _jsonResponse({
      'ticket_code': ticket['ticket_code'],
      'user_name': ticket['user_name'],
      'house_number': ticket['house_number'],
      'draw_number': spinsToday + 1,
    });
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

Future<Response> _getDailyDrawHistory(Request request) async {
  try {
    final day = request.url.queryParameters['day'];
    final conn = await db;
    var sql = '''
      SELECT dd.*, u.name as winner_name, u.house_number, nd.goddess_name, nd.date as event_date
      FROM daily_draws dd
      LEFT JOIN users u ON dd.winner_id = u.id
      LEFT JOIN navratri_days nd ON dd.day_number = nd.day_number
    ''';
    final params = <String, dynamic>{};
    if (day != null) {
      sql += ' WHERE dd.day_number = @day';
      params['day'] = int.parse(day);
    }
    sql += ' ORDER BY dd.drawn_at DESC';
    final results = await conn.execute(Sql.named(sql), parameters: params);
    return _jsonResponse(_parseResults(results));
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

Future<Response> _getDailyDrawCount(Request request) async {
  try {
    final day = request.url.queryParameters['day'] ?? '1';
    final conn = await db;
    final results = await conn.execute(
      Sql.named(
          "SELECT COUNT(*) as cnt FROM daily_draws WHERE day_number = @day AND draw_date = CURRENT_DATE"),
      parameters: {'day': int.parse(day)},
    );
    return _jsonResponse(
        {'count': results.first.toColumnMap()['cnt'] ?? 0, 'max': 6});
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

Future<Response> _getDrawTicketsForDay(Request request, String day) async {
  try {
    final conn = await db;
    final results = await conn.execute(
      Sql.named('''
        SELECT dt.id, dt.ticket_code, dt.user_id, dt.house_number, u.name as user_name
        FROM draw_tickets dt
        JOIN users u ON dt.user_id = u.id
        WHERE dt.day_number = @day AND dt.is_assigned = TRUE
        AND dt.user_id NOT IN (
          SELECT winner_id FROM daily_draws 
          WHERE winner_id IS NOT NULL 
          AND drawn_at > NOW() - INTERVAL '3 days'
        )
        ORDER BY dt.id
      '''),
      parameters: {'day': int.parse(day)},
    );
    return _jsonResponse(_parseResults(results));
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

// ========== CREATE DRAW ==========

Future<Response> _createDraw(Request request) async {
  try {
    final body = await _getBody(request);
    final conn = await db;
    final dayNumber = body['day_number'] as int;
    final ticketId = body['ticket_id'] as int;
    final ticketCode = body['ticket_code'] as String;
    final winnerId = body['winner_id'] as int;
    final houseNumber = body['house_number'] as String;
    final drawnBy = body['drawn_by'] as int;

    final countResult = await conn.execute(
      Sql.named(
          "SELECT COUNT(*) as cnt FROM daily_draws WHERE day_number = @day AND draw_date = CURRENT_DATE"),
      parameters: {'day': dayNumber},
    );
    final drawsToday = countResult.first.toColumnMap()['cnt'] ?? 0;

    final result = await conn.execute(
      Sql.named('''
        INSERT INTO daily_draws (day_number, ticket_id, ticket_code, winner_id, house_number, draw_number, drawn_by, drawn_at, status)
        VALUES (@day, @ticketId, @ticketCode, @winnerId, @house, @drawNum, @drawnBy, NOW(), 'drawn')
        RETURNING id
      '''),
      parameters: {
        'day': dayNumber,
        'ticketId': ticketId,
        'ticketCode': ticketCode,
        'winnerId': winnerId,
        'house': houseNumber,
        'drawNum': drawsToday + 1,
        'drawnBy': drawnBy,
      },
    );

    return _jsonResponse({'id': result.first.toColumnMap()['id']});
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

// ========== CONFIRM / DISQUALIFY DRAW ==========

Future<Response> _confirmDraw(Request request) async {
  try {
    final body = await _getBody(request);
    final conn = await db;
    final drawId = body['draw_id'] as int;
    final dayNumber = body['day_number'] as int;

    // Count existing confirmed prize winners for this day to determine prize level
    final countResult = await conn.execute(
      Sql.named(
          "SELECT COUNT(*) as cnt FROM daily_draws WHERE day_number = @day AND status = 'confirmed' AND prize_level IS NOT NULL"),
      parameters: {'day': dayNumber},
    );
    final confirmedCount = countResult.first.toColumnMap()['cnt'] ?? 0;

    int prizeLevel;
    if (confirmedCount == 0) {
      prizeLevel = 3; // First available = 3rd prize
    } else if (confirmedCount == 1) {
      prizeLevel = 2; // Second available = 2nd prize
    } else if (confirmedCount == 2) {
      prizeLevel = 1; // Third available = 1st prize
    } else {
      prizeLevel = 0; // No more prizes, just a general winner
    }

    // Update the daily_draws record
    await conn.execute(
      Sql.named('''
        UPDATE daily_draws SET status = 'confirmed', is_available = TRUE, prize_level = @prizeLevel
        WHERE id = @id
      '''),
      parameters: {'id': drawId, 'prizeLevel': prizeLevel > 0 ? prizeLevel : null},
    );

    // Also mark the ticket as winner in draw_tickets
    await conn.execute(
      Sql.named('UPDATE draw_tickets SET is_winner = TRUE WHERE ticket_code = (SELECT ticket_code FROM daily_draws WHERE id = @id)'),
      parameters: {'id': drawId},
    );

    return _jsonResponse({'ok': true, 'prize_level': prizeLevel});
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

Future<Response> _disqualifyDraw(Request request) async {
  try {
    final body = await _getBody(request);
    final conn = await db;
    final drawId = body['draw_id'] as int;
    final currentDay = body['day_number'] as int;
    final nextDay = currentDay + 1;

    // Get the ticket_code and winner_id from this draw
    final drawResult = await conn.execute(
      Sql.named('SELECT ticket_code, winner_id FROM daily_draws WHERE id = @id'),
      parameters: {'id': drawId},
    );
    if (drawResult.isEmpty) return _errorResponse('Draw not found');

    final drawData = drawResult.first.toColumnMap();
    final ticketCode = drawData['ticket_code'];

    // Update the daily_draws record as disqualified
    await conn.execute(
      Sql.named('''
        UPDATE daily_draws SET status = 'disqualified', is_available = FALSE, rescheduled_to_day = @nextDay
        WHERE id = @id
      '''),
      parameters: {'id': drawId, 'nextDay': nextDay <= 9 ? nextDay : null},
    );

    // Move the ticket to the next day if within 9 days
    if (nextDay <= 9) {
      await conn.execute(
        Sql.named('UPDATE draw_tickets SET day_number = @nextDay WHERE ticket_code = @code'),
        parameters: {'nextDay': nextDay, 'code': ticketCode},
      );
    }

    return _jsonResponse({'ok': true, 'rescheduled_to_day': nextDay <= 9 ? nextDay : null});
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

// ========== CANCEL DRAW ==========

Future<Response> _cancelDraw(Request request) async {
  try {
    final body = await _getBody(request);
    final conn = await db;
    final drawId = body['draw_id'] as int;
    final reason = body['reason'] as String;

    if (reason.isEmpty) {
      return _errorResponse('Cancellation reason is required');
    }

    // Check if draw exists and is confirmed
    final drawResult = await conn.execute(
      Sql.named('SELECT id, status, prize_level, ticket_code FROM daily_draws WHERE id = @id'),
      parameters: {'id': drawId},
    );
    if (drawResult.isEmpty) return _errorResponse('Draw not found');

    final drawData = drawResult.first.toColumnMap();
    if (drawData['status'] != 'confirmed') {
      return _errorResponse('Only confirmed draws can be cancelled');
    }

    // Update the daily_draws record as cancelled
    await conn.execute(
      Sql.named('''
        UPDATE daily_draws 
        SET status = 'cancelled', 
            cancelled_reason = @reason, 
            cancelled_at = NOW()
        WHERE id = @id
      '''),
      parameters: {'id': drawId, 'reason': reason},
    );

    // Reset the is_winner flag in draw_tickets so ticket becomes eligible again
    final ticketCode = drawData['ticket_code'];
    if (ticketCode != null) {
      await conn.execute(
        Sql.named('UPDATE draw_tickets SET is_winner = FALSE WHERE ticket_code = @code'),
        parameters: {'code': ticketCode},
      );
    }

    return _jsonResponse({
      'ok': true, 
      'draw_id': drawId,
      'prize_level': drawData['prize_level'],
      'cancelled_reason': reason
    });
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

// ========== DAILY INFO (for login marquee) ==========

Future<Response> _getDailyInfo(Request request) async {
  try {
    final conn = await db;
    final dayParam = request.url.queryParameters['day'];
    int dayNumber = 1;
    if (dayParam != null) {
      dayNumber = int.parse(dayParam);
    } else {
      final activeDay = await conn.execute(Sql.named(
          "SELECT day_number FROM navratri_days WHERE is_active = TRUE LIMIT 1"));
      if (activeDay.isNotEmpty)
        dayNumber = activeDay.first.toColumnMap()['day_number'] ?? 1;
    }

    final dayData = await conn.execute(
      Sql.named('SELECT * FROM navratri_days WHERE day_number = @day'),
      parameters: {'day': dayNumber},
    );

    // Aarti bookings with user names (approved or pending)
    final aartiBookings = await conn.execute(
      Sql.named('''
        SELECT ab.house_number, u.name, a.slot_time, a.slot_label, ab.status
        FROM aarti_bookings ab
        JOIN users u ON ab.user_id = u.id
        JOIN aarti_slots a ON ab.slot_id = a.id
        WHERE ab.day_number = @day
        ORDER BY a.slot_time
      '''),
      parameters: {'day': dayNumber},
    );

    // Gift assignments with donor names
    final giftAssignments = await conn.execute(
      Sql.named('''
        SELECT g.name as gift_name, u.name as donor_name, u.house_number, ga.status
        FROM gift_assignments ga
        JOIN gifts g ON ga.gift_id = g.id
        JOIN users u ON ga.user_id = u.id
        WHERE ga.day_number = @day
      '''),
      parameters: {'day': dayNumber},
    );

    // Snack orders with buyer names
    final snackOrders = await conn.execute(
      Sql.named('''
        SELECT s.name as snack_name, u.name as buyer_name, u.house_number, so.quantity, so.status
        FROM snack_orders so
        JOIN users u ON so.user_id = u.id
        JOIN snacks s ON so.snack_id = s.id
        WHERE so.day_number = @day
      '''),
      parameters: {'day': dayNumber},
    );

    // Active sponsors
    final sponsors = await conn.execute(
      Sql.named('''
        SELECT s.company_name
        FROM sponsors s
        JOIN users u ON s.user_id = u.id
        WHERE s.is_active = TRUE AND u.is_active = TRUE AND s.company_name IS NOT NULL AND s.company_name != ''
        ORDER BY s.sponsorship_amount DESC LIMIT 5
      '''),
    );

    // Yesterday's prize winners
    final yesterdayWinners = await conn.execute(
      Sql.named('''
        SELECT dd.*, u.name as user_name, nd.goddess_name
        FROM daily_draws dd
        LEFT JOIN users u ON dd.winner_id = u.id
        LEFT JOIN navratri_days nd ON dd.day_number = nd.day_number
        WHERE dd.status = 'confirmed' AND dd.day_number = @yesterdayDay
        ORDER BY dd.prize_level ASC
      '''),
      parameters: {'yesterdayDay': dayNumber > 1 ? dayNumber - 1 : 1},
    );

    return _jsonResponse({
      'day_number': dayNumber,
      'day_info': dayData.isNotEmpty ? _parseRow(dayData.first) : null,
      'aarti_bookings': _parseResults(aartiBookings),
      'gift_assignments': _parseResults(giftAssignments),
      'snack_orders': _parseResults(snackOrders),
      'sponsors': _parseResults(sponsors),
      'yesterday_prize_winners': _parseResults(yesterdayWinners),
    });
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

// ========== START / END DAY ==========

Future<Response> _startDay(Request request, String day) async {
  try {
    final conn = await db;
    await conn.execute(Sql.named("UPDATE navratri_days SET is_active = FALSE"));
    await conn.execute(
      Sql.named(
          "UPDATE navratri_days SET is_active = TRUE WHERE day_number = @day"),
      parameters: {'day': int.parse(day)},
    );
    return _jsonResponse({'ok': true});
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

Future<Response> _endDay(Request request, String day) async {
  try {
    final conn = await db;
    await conn.execute(
      Sql.named(
          "UPDATE navratri_days SET is_active = FALSE, is_completed = TRUE WHERE day_number = @day"),
      parameters: {'day': int.parse(day)},
    );
    final nextDay = int.parse(day) + 1;
    if (nextDay <= 9) {
      await conn.execute(
        Sql.named(
            "UPDATE navratri_days SET is_active = TRUE WHERE day_number = @day"),
        parameters: {'day': nextDay},
      );
    }
    return _jsonResponse(
        {'ok': true, 'next_day': nextDay <= 9 ? nextDay : null});
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

Future<Response> _reopenDay(Request request, String day) async {
  try {
    final conn = await db;
    await conn.execute(
      Sql.named(
          "UPDATE navratri_days SET is_completed = FALSE, is_active = TRUE WHERE day_number = @day"),
      parameters: {'day': int.parse(day)},
    );
    return _jsonResponse({'ok': true});
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

// ========== REPORTS ==========

Future<Response> _getReportSummary(Request request) async {
  try {
    final conn = await db;
    final income = await conn.execute(Sql.named(
        "SELECT COALESCE(SUM(amount), 0) as total FROM fund_collections WHERE payment_status = 'paid' AND is_deleted IS NOT TRUE"));
    final expense = await conn.execute(Sql.named(
        "SELECT COALESCE(SUM(amount), 0) as total FROM expenses WHERE paid_by = 'organizer' AND is_deleted IS NOT TRUE"));
    final members = await conn.execute(Sql.named(
        "SELECT COUNT(*) as total FROM users WHERE user_type != 'organizer' AND is_active = TRUE"));
    final sponsors = await conn.execute(Sql.named(
        "SELECT COALESCE(SUM(sponsorship_amount), 0) as total FROM sponsors WHERE is_active = TRUE"));
    final ticketWinners = await conn.execute(Sql.named(
        "SELECT COUNT(*) as total FROM draw_tickets WHERE is_winner = TRUE"));
    final ticketAssigned = await conn.execute(Sql.named(
        "SELECT COUNT(*) as total FROM draw_tickets WHERE is_assigned = TRUE"));

    final catExpenses = await conn.execute(Sql.named('''
      SELECT c.name as category_name, COALESCE(SUM(e.amount), 0) as total
      FROM expense_categories c
      LEFT JOIN expenses e ON c.id = e.category_id AND e.is_deleted IS NOT TRUE
      WHERE c.is_active = TRUE
      GROUP BY c.name ORDER BY total DESC
    '''));

    return _jsonResponse({
      'income': _parseRow(income.first)['total'],
      'expense': _parseRow(expense.first)['total'],
      'members': _parseRow(members.first)['total'],
      'sponsors': _parseRow(sponsors.first)['total'],
      'ticket_winners': _parseRow(ticketWinners.first)['total'],
      'ticket_assigned': _parseRow(ticketAssigned.first)['total'],
      'category_expenses': _parseResults(catExpenses),
    });
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

// ========== DETAILED REPORTS ==========

Future<Response> _getPaymentsByHouseReport(Request request) async {
  try {
    final conn = await db;
    final results = await conn.execute(Sql.named('''
      SELECT u.house_number, u.name as owner_name, 
             COALESCE(SUM(fc.amount), 0) as total_amount,
             MAX(fc.payment_method) as payment_method,
             CASE WHEN SUM(fc.amount) > 0 THEN 'paid' ELSE 'pending' END as payment_status,
             COUNT(fc.id) as payment_count
      FROM users u
      LEFT JOIN fund_collections fc ON fc.user_id = u.id AND fc.payment_status = 'paid' AND fc.is_deleted IS NOT TRUE
      WHERE u.member_type = 'main' AND u.user_type != 'organizer'
      GROUP BY u.id, u.house_number, u.name
      ORDER BY u.house_number ASC
    '''));
    final total = await conn.execute(Sql.named(
        "SELECT COALESCE(SUM(amount), 0) as total FROM fund_collections WHERE payment_status = 'paid' AND is_deleted IS NOT TRUE"));
    final sponsorTotal = await conn.execute(Sql.named(
        "SELECT COALESCE(SUM(sponsorship_amount), 0) as total FROM sponsors WHERE is_active = TRUE"));
    return _jsonResponse({
      'payments': _parseResults(results),
      'fund_total': _parseRow(total.first)['total'],
      'sponsor_total': _parseRow(sponsorTotal.first)['total'],
    });
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

Future<Response> _getExpensesByDateReport(Request request) async {
  try {
    final conn = await db;
    final results = await conn.execute(Sql.named('''
      SELECT e.expense_date, c.name as category_name, e.item_name,
             e.amount, e.paid_to, e.paid_by, e.notes
      FROM expenses e
      JOIN expense_categories c ON e.category_id = c.id
      WHERE e.is_deleted IS NOT TRUE
      ORDER BY e.expense_date DESC, c.name
    '''));
    final byDate = await conn.execute(Sql.named('''
      SELECT e.expense_date, COALESCE(SUM(e.amount), 0) as total
      FROM expenses e WHERE e.is_deleted IS NOT TRUE
      GROUP BY e.expense_date ORDER BY e.expense_date DESC
    '''));
    final total = await conn.execute(Sql.named(
        "SELECT COALESCE(SUM(amount), 0) as total FROM expenses WHERE is_deleted IS NOT TRUE"));
    return _jsonResponse({
      'expenses': _parseResults(results),
      'by_date': _parseResults(byDate),
      'total': _parseRow(total.first)['total'],
    });
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

Future<Response> _getDailyActivityReport(Request request) async {
  try {
    final conn = await db;
    final days = await conn.execute(Sql.named('''
      SELECT nd.day_number, nd.goddess_name, nd.date, nd.dress_code, nd.is_active, nd.is_completed
      FROM navratri_days nd ORDER BY nd.day_number
    '''));

    final activity = <Map<String, dynamic>>[];
    for (final dayRow in days) {
      final dayMap = dayRow.toColumnMap();
      final dayNum = dayMap['day_number'];

      final aarti = await conn.execute(Sql.named('''
        SELECT ab.house_number, u.name, a.slot_time, a.slot_label, ab.status
        FROM aarti_bookings ab
        JOIN users u ON ab.user_id = u.id
        JOIN aarti_slots a ON ab.slot_id = a.id
        WHERE ab.day_number = @day AND ab.status != 'cancelled'
        ORDER BY a.slot_time
      '''), parameters: {'day': dayNum});

      final foods = await conn.execute(Sql.named('''
        SELECT so.house_number, u.name, s.name as snack_name, so.quantity, so.total_price, so.status
        FROM snack_orders so
        JOIN users u ON so.user_id = u.id
        JOIN snacks s ON so.snack_id = s.id
        WHERE so.day_number = @day AND so.status != 'cancelled'
        ORDER BY u.house_number
      '''), parameters: {'day': dayNum});

      final gifts = await conn.execute(Sql.named('''
        SELECT ga.house_number, u.name, g.name as gift_name, ga.status
        FROM gift_assignments ga
        JOIN users u ON ga.user_id = u.id
        JOIN gifts g ON ga.gift_id = g.id
        WHERE ga.day_number = @day AND ga.status != 'cancelled'
        ORDER BY u.house_number
      '''), parameters: {'day': dayNum});

      activity.add({
        'day_number': dayNum,
        'goddess_name': dayMap['goddess_name'],
        'date': dayMap['date'],
        'dress_code': dayMap['dress_code'],
        'is_active': dayMap['is_active'],
        'is_completed': dayMap['is_completed'],
        'aarti_bookings': _parseResults(aarti),
        'food_orders': _parseResults(foods),
        'gift_assignments': _parseResults(gifts),
      });
    }

    return _jsonResponse({'days': activity});
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

// ========== SONG REQUESTS ==========

Future<Response> _createSongRequest(Request request) async {
  try {
    final body = await _getBody(request);
    final conn = await db;
    final result = await conn.execute(Sql.named('''
      INSERT INTO song_requests (user_id, song_name, youtube_link, day_number, request_type)
      VALUES (@userId, @songName, @youtubeLink, @dayNumber, @requestType)
      RETURNING id, song_name, youtube_link, day_number, request_type, status, created_at
    '''), parameters: {
      'userId': body['user_id'],
      'songName': body['song_name'],
      'youtubeLink': body['youtube_link'] ?? '',
      'dayNumber': body['day_number'] ?? 1,
      'requestType': body['request_type'] ?? 'live',
    });
    return _jsonResponse(_parseRow(result.first));
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

Future<Response> _getSongRequests(Request request) async {
  try {
    final conn = await db;
    final dayParam = request.url.queryParameters['day'];
    final statusParam = request.url.queryParameters['status'];

    String sql = '''
      SELECT sr.*, u.name as user_name, u.house_number,
        (SELECT COUNT(*) FROM song_upvotes su WHERE su.song_suggestion_id = sr.id) as vote_count
      FROM song_requests sr
      LEFT JOIN users u ON sr.user_id = u.id
      WHERE 1=1
    ''';
    final params = <String, dynamic>{};

    if (dayParam != null) {
      sql += ' AND sr.day_number = @day';
      params['day'] = int.parse(dayParam);
    }
    if (statusParam != null) {
      sql += ' AND sr.status = @status';
      params['status'] = statusParam;
    }
    sql += ' ORDER BY sr.request_count DESC, sr.created_at ASC';

    final results = await conn.execute(Sql.named(sql), parameters: params);
    return _jsonResponse(_parseResults(results));
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

Future<Response> _playSongRequest(Request request, String id) async {
  try {
    final conn = await db;
    await conn.execute(Sql.named('''
      UPDATE song_requests SET status = 'playing', played_at = NOW() WHERE id = @id
    '''), parameters: {'id': int.parse(id)});
    return _jsonResponse({'ok': true});
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

Future<Response> _skipSongRequest(Request request, String id) async {
  try {
    final conn = await db;
    await conn.execute(Sql.named('''
      UPDATE song_requests SET status = 'skipped' WHERE id = @id
    '''), parameters: {'id': int.parse(id)});
    return _jsonResponse({'ok': true});
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

Future<Response> _deleteSongRequest(Request request, String id) async {
  try {
    final conn = await db;
    await conn.execute(Sql.named('DELETE FROM song_requests WHERE id = @id'),
        parameters: {'id': int.parse(id)});
    return _jsonResponse({'ok': true});
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

Future<Response> _upvoteSongRequest(Request request, String id) async {
  try {
    final conn = await db;
    await conn.execute(Sql.named('''
      UPDATE song_requests SET request_count = request_count + 1 WHERE id = @id
    '''), parameters: {'id': int.parse(id)});
    return _jsonResponse({'ok': true});
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

// ========== SONG SUGGESTIONS ==========

Future<Response> _createSongSuggestion(Request request) async {
  try {
    final body = await _getBody(request);
    final conn = await db;
    final result = await conn.execute(Sql.named('''
      INSERT INTO song_suggestions (user_id, song_name, youtube_link, target_day)
      VALUES (@userId, @songName, @youtubeLink, @targetDay)
      RETURNING id, song_name, youtube_link, target_day, upvotes, created_at
    '''), parameters: {
      'userId': body['user_id'],
      'songName': body['song_name'],
      'youtubeLink': body['youtube_link'] ?? '',
      'targetDay': body['target_day'] ?? 1,
    });
    return _jsonResponse(_parseRow(result.first));
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

Future<Response> _getSongSuggestions(Request request) async {
  try {
    final conn = await db;
    final dayParam = request.url.queryParameters['day'];

    String sql = '''
      SELECT ss.*, u.name as user_name, u.house_number,
        (SELECT COUNT(*) FROM song_upvotes su WHERE su.song_suggestion_id = ss.id) as vote_count
      FROM song_suggestions ss
      LEFT JOIN users u ON ss.user_id = u.id
      WHERE 1=1
    ''';
    final params = <String, dynamic>{};

    if (dayParam != null) {
      sql += ' AND ss.target_day = @day';
      params['day'] = int.parse(dayParam);
    }
    sql += ' ORDER BY vote_count DESC, ss.created_at DESC';

    final results = await conn.execute(Sql.named(sql), parameters: params);
    return _jsonResponse(_parseResults(results));
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

Future<Response> _upvoteSongSuggestion(Request request, String id) async {
  try {
    final body = await _getBody(request);
    final conn = await db;
    await conn.execute(Sql.named('''
      INSERT INTO song_upvotes (song_suggestion_id, user_id)
      VALUES (@suggestionId, @userId)
      ON CONFLICT (song_suggestion_id, user_id) DO NOTHING
    '''), parameters: {'suggestionId': int.parse(id), 'userId': body['user_id']});
    await conn.execute(Sql.named('''
      UPDATE song_suggestions SET upvotes = (
        SELECT COUNT(*) FROM song_upvotes WHERE song_suggestion_id = @id
      ) WHERE id = @id
    '''), parameters: {'id': int.parse(id)});
    return _jsonResponse({'ok': true});
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

Future<Response> _removeUpvoteSuggestion(Request request, String id) async {
  try {
    final body = await _getBody(request);
    final conn = await db;
    await conn.execute(Sql.named('''
      DELETE FROM song_upvotes WHERE song_suggestion_id = @suggestionId AND user_id = @userId
    '''), parameters: {'suggestionId': int.parse(id), 'userId': body['user_id']});
    await conn.execute(Sql.named('''
      UPDATE song_suggestions SET upvotes = (
        SELECT COUNT(*) FROM song_upvotes WHERE song_suggestion_id = @id
      ) WHERE id = @id
    '''), parameters: {'id': int.parse(id)});
    return _jsonResponse({'ok': true});
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

// ========== SHOUTOUTS ==========

Future<Response> _createShoutout(Request request) async {
  try {
    final body = await _getBody(request);
    final conn = await db;
    final result = await conn.execute(Sql.named('''
      INSERT INTO shoutouts (from_user_id, to_user_id, message, emoji, day_number, shoutout_type)
      VALUES (@fromUserId, @toUserId, @message, @emoji, @dayNumber, @shoutoutType)
      RETURNING id, message, emoji, day_number, shoutout_type, created_at
    '''), parameters: {
      'fromUserId': body['from_user_id'],
      'toUserId': body['to_user_id'] ?? body['from_user_id'],
      'message': body['message'],
      'emoji': body['emoji'] ?? '🎉',
      'dayNumber': body['day_number'] ?? 1,
      'shoutoutType': body['shoutout_type'] ?? 'general',
    });
    final shoutout = _parseRow(result.first);
    // Get user names
    final fromUser = await conn.execute(Sql.named('SELECT name FROM users WHERE id = @id'),
        parameters: {'id': body['from_user_id']});
    shoutout['from_user_name'] = fromUser.isNotEmpty ? fromUser.first.toColumnMap()['name'] : '';
    if (body['to_user_id'] != null && body['to_user_id'] != body['from_user_id']) {
      final toUser = await conn.execute(Sql.named('SELECT name FROM users WHERE id = @id'),
          parameters: {'id': body['to_user_id']});
      shoutout['to_user_name'] = toUser.isNotEmpty ? toUser.first.toColumnMap()['name'] : '';
    }
    return _jsonResponse(shoutout);
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

Future<Response> _getShoutouts(Request request) async {
  try {
    final conn = await db;
    final dayParam = request.url.queryParameters['day'];

    String sql = '''
      SELECT s.*, fu.name as from_user_name, fu.house_number as from_house,
        tu.name as to_user_name, tu.house_number as to_house,
        (SELECT COUNT(*) FROM shoutout_reactions sr WHERE sr.shoutout_id = s.id) as reaction_count
      FROM shoutouts s
      LEFT JOIN users fu ON s.from_user_id = fu.id
      LEFT JOIN users tu ON s.to_user_id = tu.id
      WHERE s.is_approved = TRUE
    ''';
    final params = <String, dynamic>{};

    if (dayParam != null) {
      sql += ' AND s.day_number = @day';
      params['day'] = int.parse(dayParam);
    }
    sql += ' ORDER BY s.created_at DESC';

    final results = await conn.execute(Sql.named(sql), parameters: params);
    return _jsonResponse(_parseResults(results));
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

Future<Response> _reactShoutout(Request request, String id) async {
  try {
    final body = await _getBody(request);
    final conn = await db;
    await conn.execute(Sql.named('''
      INSERT INTO shoutout_reactions (shoutout_id, user_id, reaction)
      VALUES (@shoutoutId, @userId, @reaction)
      ON CONFLICT (shoutout_id, user_id, reaction) DO NOTHING
    '''), parameters: {
      'shoutoutId': int.parse(id),
      'userId': body['user_id'],
      'reaction': body['reaction'],
    });
    return _jsonResponse({'ok': true});
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

Future<Response> _removeShoutoutReaction(Request request, String id) async {
  try {
    final body = await _getBody(request);
    final conn = await db;
    await conn.execute(Sql.named('''
      DELETE FROM shoutout_reactions WHERE shoutout_id = @shoutoutId AND user_id = @userId AND reaction = @reaction
    '''), parameters: {
      'shoutoutId': int.parse(id),
      'userId': body['user_id'],
      'reaction': body['reaction'],
    });
    return _jsonResponse({'ok': true});
  } catch (e) {
    return _errorResponse(e.toString(), status: 500);
  }
}

Future<Response> _deleteShoutout(Request request, String id) async {
  try {
    final conn = await db;
    await conn.execute(Sql.named('DELETE FROM shoutout_reactions WHERE shoutout_id = @id'),
        parameters: {'id': int.parse(id)});
    await conn.execute(Sql.named('DELETE FROM shoutouts WHERE id = @id'),
        parameters: {'id': int.parse(id)});
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
      Sql.named(body['sql'] as String),
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
      Sql.named(body['sql'] as String),
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

  final server = await io.serve(handler, ip, port);
  print(
      'Navratri API Server running on http://${server.address.host}:${server.port}');
}
