import 'dart:convert';
import 'package:http/http.dart' as http;

const String _apiBase = 'http://localhost:8080';

class DatabaseHelper {
  static Future<void> connect() async {
    try {
      await http.get(Uri.parse('$_apiBase/api/announcements')).timeout(
        const Duration(seconds: 3),
      );
    } catch (_) {}
  }

  static bool get isConnected => true;

  // ========== HTTP HELPERS ==========

  static Future<List<Map<String, dynamic>>> _get(String path, {Map<String, String>? queryParams}) async {
    final uri = Uri.parse('$_apiBase$path').replace(queryParameters: queryParams);
    final response = await http.get(uri).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) throw Exception('API error: ${response.statusCode}');
    final data = jsonDecode(response.body);
    if (data == null) return [];
    return (data as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static Future<Map<String, dynamic>?> _post(String path, Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('$_apiBase$path'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) throw Exception('API error: ${response.statusCode}');
    final data = jsonDecode(response.body);
    return data is Map ? Map<String, dynamic>.from(data) : null;
  }

  static Future<List<Map<String, dynamic>>> _postList(String path, Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('$_apiBase$path'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) throw Exception('API error: ${response.statusCode}');
    final data = jsonDecode(response.body);
    if (data is List) return data.map((e) => Map<String, dynamic>.from(e)).toList();
    return [];
  }

  static Future<void> _put(String path, Map<String, dynamic> body) async {
    final response = await http.put(
      Uri.parse('$_apiBase$path'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) throw Exception('API error: ${response.statusCode}');
  }

  static Future<Map<String, dynamic>?> _putJson(String path, Map<String, dynamic> body) async {
    final response = await http.put(
      Uri.parse('$_apiBase$path'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) return null;
    final data = jsonDecode(response.body);
    return data is Map<String, dynamic> ? data : null;
  }

  static Future<void> _delete(String path) async {
    final response = await http.delete(Uri.parse('$_apiBase$path'))
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) throw Exception('API error: ${response.statusCode}');
  }

  // ========== AUTHENTICATION ==========

  static Future<Map<String, dynamic>?> loginUser({
    required String houseNumber,
    required String mobileNumber,
  }) async {
    return _post('/api/auth/login-user', {
      'house_number': houseNumber,
      'mobile_number': mobileNumber,
    });
  }

  static Future<Map<String, dynamic>?> loginSponsor({
    required String houseNumber,
    required String password,
  }) async {
    return _post('/api/auth/login-sponsor', {
      'house_number': houseNumber,
      'password': password,
    });
  }

  static Future<Map<String, dynamic>?> loginOrganizer({
    required String username,
    required String password,
  }) async {
    return _post('/api/auth/login-organizer', {
      'username': username,
      'password': password,
    });
  }

  static Future<int> registerUser({
    required String houseNumber,
    required String name,
    required String mobileNumber,
    String userType = 'user',
  }) async {
    final result = await _post('/api/auth/register', {
      'house_number': houseNumber,
      'name': name,
      'mobile_number': mobileNumber,
      'user_type': userType,
    });
    return result?['id'] ?? 0;
  }

  // ========== MEMBERS ==========

  static Future<List<Map<String, dynamic>>> getAllMembers() async {
    return _get('/api/members');
  }

  static Future<void> updateUserStatus(int userId, bool isActive) async {
    await _put('/api/members/$userId/status', {'is_active': isActive});
  }

  static Future<void> updateMember(int userId, {String? name, String? houseNumber, String? mobileNumber}) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (houseNumber != null) body['house_number'] = houseNumber;
    if (mobileNumber != null) body['mobile_number'] = mobileNumber;
    await _put('/api/members/$userId', body);
  }

  static Future<void> deleteMember(int userId) async {
    await _delete('/api/members/$userId');
  }

  static Future<List<Map<String, dynamic>>> getMembersByHouse(String houseNumber) async {
    return _get('/api/members/house/$houseNumber');
  }

  // ========== PAYMENTS ==========

  static Future<List<Map<String, dynamic>>> getAllPayments() async {
    return _get('/api/payments');
  }

  static Future<List<Map<String, dynamic>>> getPaymentsByHouse(String houseNumber) async {
    return _get('/api/payments/house/$houseNumber');
  }

  static Future<int> addPayment({
    required int userId,
    required String houseNumber,
    required double amount,
    required String paymentMethod,
    String paymentStatus = 'paid',
    String? payerName,
    DateTime? tentativeDate,
    DateTime? paidDate,
    int? receivedBy,
    String? notes,
  }) async {
    final result = await _post('/api/payments', {
      'user_id': userId,
      'house_number': houseNumber,
      'amount': amount,
      'payment_method': paymentMethod,
      'payment_status': paymentStatus,
      'payer_name': payerName,
      'tentative_date': tentativeDate?.toIso8601String(),
      'paid_date': paidDate?.toIso8601String(),
      'received_by': receivedBy,
      'notes': notes,
    });
    return result?['id'] ?? 0;
  }

  static Future<void> updatePayment(int paymentId, {double? amount, String? paymentMethod, String? payerName, String? notes}) async {
    final body = <String, dynamic>{};
    if (amount != null) body['amount'] = amount;
    if (paymentMethod != null) body['payment_method'] = paymentMethod;
    if (payerName != null) body['payer_name'] = payerName;
    if (notes != null) body['notes'] = notes;
    if (body.isNotEmpty) await _put('/api/payments/$paymentId', body);
  }

  static Future<void> updatePaymentStatus(int paymentId, {required String status, String? paidDate, String? paymentMethod}) async {
    await _put('/api/payments/$paymentId/status', {
      'payment_status': status,
      'paid_date': paidDate,
      'payment_method': paymentMethod,
    });
  }

  static Future<void> deletePayment(int paymentId, String reason) async {
    final response = await http.delete(
      Uri.parse('$_apiBase/api/payments/$paymentId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'reason': reason}),
    ).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) throw Exception('API error: ${response.statusCode}');
  }

  static Future<List<Map<String, dynamic>>> getDeletedPayments() async {
    return _get('/api/payments/deleted');
  }

  static Future<List<Map<String, dynamic>>> getExpenses() async {
    return _get('/api/expenses');
  }

  static Future<List<Map<String, dynamic>>> getDeletedExpenses() async {
    return _get('/api/expenses/deleted');
  }

  static Future<void> deleteExpense(int expenseId, String reason) async {
    final response = await http.delete(
      Uri.parse('$_apiBase/api/expenses/$expenseId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'reason': reason}),
    ).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) throw Exception('API error: ${response.statusCode}');
  }

  static Future<void> updateExpense(int expenseId, {int? categoryId, String? itemName, double? amount, String? paidTo, String? expenseDate, String? notes, String? paidBy}) async {
    final body = <String, dynamic>{};
    if (categoryId != null) body['category_id'] = categoryId;
    if (itemName != null) body['item_name'] = itemName;
    if (amount != null) body['amount'] = amount;
    if (paidTo != null) body['paid_to'] = paidTo;
    if (expenseDate != null) body['expense_date'] = expenseDate;
    if (notes != null) body['notes'] = notes;
    if (paidBy != null) body['paid_by'] = paidBy;
    if (body.isNotEmpty) await _put('/api/expenses/$expenseId', body);
  }

  // ========== TICKETS ==========

  static Future<List<Map<String, dynamic>>> getMyTickets(String houseNumber) async {
    return _get('/api/tickets/my/$houseNumber');
  }

  static Future<void> generateTickets({required int dayNumber, required int count}) async {
    await _post('/api/tickets/generate', {'day_number': dayNumber, 'count': count});
  }

  static Future<void> assignTicket({required String ticketCode, required int userId, required String houseNumber}) async {
    await _put('/api/tickets/assign', {
      'ticket_code': ticketCode,
      'user_id': userId,
      'house_number': houseNumber,
    });
  }

  // ========== AARTI SLOTS ==========

  static Future<List<Map<String, dynamic>>> getAartiSlots(int dayNumber) async {
    return _get('/api/aarti-slots/$dayNumber');
  }

  static Future<List<Map<String, dynamic>>> getAllAartiSlots() async {
    return _get('/api/aarti-slots');
  }

  static Future<int> addAartiSlot({required int dayNumber, required String slotTime, required String slotLabel, required int maxParticipants}) async {
    final result = await _post('/api/aarti-slots', {
      'day_number': dayNumber,
      'slot_time': slotTime,
      'slot_label': slotLabel,
      'max_participants': maxParticipants,
    });
    return result?['id'] ?? 0;
  }

  static Future<void> updateAartiSlot(int slotId, {String? slotTime, String? slotLabel, int? maxParticipants, bool? isActive}) async {
    final body = <String, dynamic>{};
    if (slotTime != null) body['slot_time'] = slotTime;
    if (slotLabel != null) body['slot_label'] = slotLabel;
    if (maxParticipants != null) body['max_participants'] = maxParticipants;
    if (isActive != null) body['is_active'] = isActive;
    await _put('/api/aarti-slots/$slotId', body);
  }

  // ========== AARTI BOOKINGS ==========

  static Future<List<Map<String, dynamic>>> getAartiBookings({int? dayNumber, String? status}) async {
    final params = <String, String>{};
    if (dayNumber != null) params['day'] = dayNumber.toString();
    if (status != null) params['status'] = status;
    return _get('/api/aarti-bookings', queryParams: params.isNotEmpty ? params : null);
  }

  static Future<List<Map<String, dynamic>>> getMyAartiBookings(String houseNumber) async {
    return _get('/api/aarti-bookings/my/$houseNumber');
  }

  static Future<int> bookAartiSlot({required int userId, required String houseNumber, required int dayNumber, required int slotId}) async {
    final result = await _post('/api/aarti-bookings', {
      'user_id': userId,
      'house_number': houseNumber,
      'day_number': dayNumber,
      'slot_id': slotId,
    });
    return result?['id'] ?? 0;
  }

  static Future<void> updateBookingStatus(int bookingId, String status, {int? approvedBy}) async {
    await _put('/api/aarti-bookings/$bookingId/status', {
      'status': status,
      'approved_by': approvedBy,
    });
  }

  static Future<void> cancelAartiBooking(int bookingId) async {
    await _put('/api/aarti-bookings/$bookingId/cancel', {});
  }

  // ========== SNACKS ==========

  static Future<List<Map<String, dynamic>>> getSnacks() async {
    return _get('/api/snacks');
  }

  static Future<List<Map<String, dynamic>>> getAllSnacks() async {
    return _get('/api/snacks/all');
  }

  static Future<int> addSnack({required String name, String? description, required double price, required int quantity, bool isVegetarian = true}) async {
    final result = await _post('/api/snacks', {
      'name': name,
      'description': description,
      'price': price,
      'quantity_available': quantity,
      'is_vegetarian': isVegetarian,
    });
    return result?['id'] ?? 0;
  }

  static Future<void> updateSnack(int snackId, {String? name, double? price, int? quantity, bool? isActive}) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (price != null) body['price'] = price;
    if (quantity != null) body['quantity_available'] = quantity;
    if (isActive != null) body['is_active'] = isActive;
    await _put('/api/snacks/$snackId', body);
  }

  // ========== SNACK ORDERS ==========

  static Future<List<Map<String, dynamic>>> getSnackOrders({int? dayNumber, String? status}) async {
    final params = <String, String>{};
    if (dayNumber != null) params['day'] = dayNumber.toString();
    if (status != null) params['status'] = status;
    return _get('/api/snack-orders', queryParams: params.isNotEmpty ? params : null);
  }

  static Future<List<Map<String, dynamic>>> getMySnackOrders(String houseNumber) async {
    return _get('/api/snack-orders/my/$houseNumber');
  }

  static Future<int> orderSnack({required int userId, required String houseNumber, required int snackId, required int dayNumber, required int quantity, String? notes}) async {
    final result = await _post('/api/snack-orders', {
      'user_id': userId,
      'house_number': houseNumber,
      'snack_id': snackId,
      'day_number': dayNumber,
      'quantity': quantity,
      'notes': notes,
    });
    return result?['id'] ?? 0;
  }

  static Future<void> updateSnackOrderStatus(int orderId, String status) async {
    await _put('/api/snack-orders/$orderId/status', {'status': status});
  }

  static Future<void> cancelSnackOrder(int orderId) async {
    await _put('/api/snack-orders/$orderId/cancel', {});
  }

  // ========== GIFTS ==========

  static Future<List<Map<String, dynamic>>> getGifts({int? dayNumber, String? giftType}) async {
    final params = <String, String>{};
    if (dayNumber != null) params['day'] = dayNumber.toString();
    if (giftType != null) params['type'] = giftType;
    return _get('/api/gifts', queryParams: params.isNotEmpty ? params : null);
  }

  static Future<int> addGift({required String name, String? description, int? sponsorId, required String giftType, int? dayNumber, required int quantity}) async {
    final result = await _post('/api/gifts', {
      'name': name,
      'description': description,
      'sponsor_id': sponsorId,
      'gift_type': giftType,
      'day_number': dayNumber,
      'quantity': quantity,
    });
    return result?['id'] ?? 0;
  }

  static Future<void> updateGift(int giftId, {String? name, int? quantity, bool? isActive}) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (quantity != null) body['quantity'] = quantity;
    if (isActive != null) body['is_active'] = isActive;
    await _put('/api/gifts/$giftId', body);
  }

  // ========== GIFT ASSIGNMENTS ==========

  static Future<List<Map<String, dynamic>>> getGiftAssignments({int? dayNumber}) async {
    final params = <String, String>{};
    if (dayNumber != null) params['day'] = dayNumber.toString();
    return _get('/api/gift-assignments', queryParams: params.isNotEmpty ? params : null);
  }

  static Future<int> assignGift({required int giftId, required int userId, required String houseNumber, int? dayNumber, int? assignedBy, String? notes}) async {
    final result = await _post('/api/gift-assignments', {
      'gift_id': giftId,
      'user_id': userId,
      'house_number': houseNumber,
      'day_number': dayNumber,
      'assigned_by': assignedBy,
      'notes': notes,
    });
    return result?['id'] ?? 0;
  }

  static Future<List<Map<String, dynamic>>> getMyGifts(String houseNumber) async {
    return _get('/api/gifts/my/$houseNumber');
  }

  static Future<void> cancelGiftAssignment(int assignmentId) async {
    await _put('/api/gift-assignments/$assignmentId/cancel', {});
  }

  // ========== ANNOUNCEMENTS ==========

  static Future<List<Map<String, dynamic>>> getAnnouncements() async {
    return _get('/api/announcements');
  }

  static Future<int> createAnnouncement({required String title, required String message, String type = 'general', int priority = 1}) async {
    final result = await _post('/api/announcements', {
      'title': title,
      'message': message,
      'announcement_type': type,
      'priority': priority,
    });
    return result?['id'] ?? 0;
  }

  static Future<void> deleteAnnouncement(int id) async {
    await _delete('/api/announcements/$id');
  }

  // ========== TICKETS ==========

  static Future<List<Map<String, dynamic>>> getAllTickets({String? day, String? assigned}) async {
    final params = <String, String>{};
    if (day != null) params['day'] = day;
    if (assigned != null) params['assigned'] = assigned;
    return _get('/api/tickets', queryParams: params.isNotEmpty ? params : null);
  }

  static Future<void> markWinner(int id) async {
    await _put('/api/tickets/$id/winner', {});
  }

  static Future<void> deleteTicket(int id) async {
    await _delete('/api/tickets/$id');
  }

  static Future<void> batchDeleteTickets(List<int> ids, String reason) async {
    final response = await http.post(
      Uri.parse('$_apiBase/api/tickets/batch-delete'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'ids': ids, 'reason': reason}),
    ).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) throw Exception('API error: ${response.statusCode}');
  }

  // ========== NAVRATRI DAYS ==========

  static Future<List<Map<String, dynamic>>> getNavratriDays() async {
    return _get('/api/navratri-days');
  }

  static Future<int?> getCurrentActiveDay() async {
    final days = await getNavratriDays();
    for (final d in days) {
      if (d['is_active'] == true) return d['day_number'] as int;
    }
    return null;
  }

  static Future<bool> isDayBookable(int dayNumber) async {
    final days = await getNavratriDays();
    final day = days.firstWhere(
      (d) => d['day_number'] == dayNumber,
      orElse: () => {},
    );
    if (day.isEmpty) return false;
    if (day['is_completed'] == true) return false;
    if (day['is_active'] == true) return true;
    final activeDay = await getCurrentActiveDay();
    if (activeDay == null) return false;
    return dayNumber > activeDay;
  }

  static Future<void> updateNavratriDay(int day, {String? goddessName, String? dressCode, bool? isActive, bool? isCompleted}) async {
    final body = <String, dynamic>{};
    if (goddessName != null) body['goddess_name'] = goddessName;
    if (dressCode != null) body['dress_code'] = dressCode;
    if (isActive != null) body['is_active'] = isActive;
    if (isCompleted != null) body['is_completed'] = isCompleted;
    await _put('/api/navratri-days/$day', body);
  }

  // ========== DAILY SCHEDULES ==========

  static Future<List<Map<String, dynamic>>> getDailySchedule(int day) async {
    return _get('/api/daily-schedules/$day');
  }

  static Future<void> addScheduleEvent({required int dayNumber, required String time, required String name, String? description, String? location}) async {
    await _post('/api/daily-schedules', {
      'day_number': dayNumber,
      'event_time': time,
      'event_name': name,
      'event_description': description ?? '',
      'location': location ?? '',
    });
  }

  static Future<void> deleteScheduleEvent(int id) async {
    await _delete('/api/daily-schedules/$id');
  }

  // ========== SPONSORS ==========

  static Future<List<Map<String, dynamic>>> getAllSponsors() async {
    return _get('/api/sponsors');
  }

  static Future<void> addSponsor({required String houseNumber, required String name, required String mobile, String? companyName, String? adText, double? amount, String? remarks}) async {
    await _post('/api/sponsors', {
      'house_number': houseNumber,
      'name': name,
      'mobile_number': mobile,
      'company_name': companyName ?? '',
      'advertisement_text': adText ?? '',
      'sponsorship_amount': amount ?? 0,
      'remarks': remarks ?? '',
    });
  }

  static Future<void> updateSponsor(int userId, {String? companyName, String? adText, double? amount, String? paymentStatus, String? adminRemarks}) async {
    final body = <String, dynamic>{};
    if (companyName != null) body['company_name'] = companyName;
    if (adText != null) body['advertisement_text'] = adText;
    if (amount != null) body['sponsorship_amount'] = amount;
    if (paymentStatus != null) body['payment_status'] = paymentStatus;
    if (adminRemarks != null) body['admin_remarks'] = adminRemarks;
    if (body.isNotEmpty) await _put('/api/sponsors/$userId', body);
  }

  static Future<void> updateSponsorImage(int userId, String imageBase64) async {
    await _put('/api/sponsors/$userId/image', {'advertisement_image': imageBase64});
  }

  static Future<List<Map<String, dynamic>>> getActiveSponsors() async {
    return _get('/api/sponsors/active');
  }

  static Future<void> deleteSponsor(int userId) async {
    await _delete('/api/sponsors/$userId');
  }

  // ========== DRAWS / WINNERS ==========

  static Future<List<Map<String, dynamic>>> getDrawHistory() async {
    return _get('/api/winners/history');
  }

  // ========== BROADCASTS ==========

  static Future<void> createBroadcast({required String title, required String message, String priority = 'normal'}) async {
    await _post('/api/broadcasts', {'title': title, 'message': message, 'priority': priority});
  }

  static Future<List<Map<String, dynamic>>> getBroadcasts() async {
    return _get('/api/broadcasts');
  }

  static Future<void> deleteBroadcast(int id) async {
    await _delete('/api/broadcasts/$id');
  }

  // ========== REPORTS ==========

  static Future<Map<String, dynamic>?> getReportSummary() async {
    final response = await http.get(Uri.parse('$_apiBase/api/reports/summary')).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) return null;
    final data = jsonDecode(response.body);
    return data is Map ? Map<String, dynamic>.from(data) : null;
  }

  static Future<Map<String, dynamic>?> getPaymentsByHouseReport() async {
    final response = await http.get(Uri.parse('$_apiBase/api/reports/payments-by-house')).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) return null;
    final data = jsonDecode(response.body);
    return data is Map ? Map<String, dynamic>.from(data) : null;
  }

  static Future<Map<String, dynamic>?> getExpensesByDateReport() async {
    final response = await http.get(Uri.parse('$_apiBase/api/reports/expenses-by-date')).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) return null;
    final data = jsonDecode(response.body);
    return data is Map ? Map<String, dynamic>.from(data) : null;
  }

  static Future<Map<String, dynamic>?> getDailyActivityReport() async {
    final response = await http.get(Uri.parse('$_apiBase/api/reports/daily-activity')).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) return null;
    final data = jsonDecode(response.body);
    return data is Map ? Map<String, dynamic>.from(data) : null;
  }

  // ========== GENERIC QUERY ==========

  static Future<List<Map<String, dynamic>>> query(String sql, {Map<String, dynamic>? substitutionValues}) async {
    return _postList('/api/query', {
      'sql': sql,
      'parameters': substitutionValues,
    });
  }

  static Future<void> execute(String sql, {Map<String, dynamic>? substitutionValues}) async {
    await _post('/api/execute', {
      'sql': sql,
      'parameters': substitutionValues,
    });
  }

  // ========== USER PROFILE ==========

  static Future<Map<String, dynamic>?> updateProfile(int userId, {String? name, String? mobile, String? password}) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (mobile != null) body['mobile_number'] = mobile;
    if (password != null) body['password'] = password;
    if (body.isEmpty) return null;
    return _putJson('/api/profile/$userId', body);
  }

  // ========== WINNERS ==========

  static Future<List<Map<String, dynamic>>> getWinners({int? day}) async {
    final params = <String, String>{};
    if (day != null) params['day'] = day.toString();
    return _get('/api/winners', queryParams: params.isNotEmpty ? params : null);
  }

  // ========== LUCKY DRAW ==========

  static Future<Map<String, dynamic>?> spinDraw({required int dayNumber, required int drawnBy}) async {
    try {
      final result = await _post('/api/daily-draws/spin', {
        'day_number': dayNumber,
        'drawn_by': drawnBy,
      });
      return result;
    } catch (e) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> spinDrawPrize({required int dayNumber, required int drawnBy, required int prizeLevel}) async {
    try {
      final result = await _post('/api/daily-draws/spin-prize', {
        'day_number': dayNumber,
        'drawn_by': drawnBy,
        'prize_level': prizeLevel,
      });
      return result;
    } catch (e) {
      return null;
    }
  }

  static Future<Map<String, dynamic>> getDailyDrawCount(int dayNumber) async {
    final response = await http.get(Uri.parse('$_apiBase/api/daily-draws/count?day=$dayNumber')).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) return {'count': 0, 'max': 6};
    return jsonDecode(response.body);
  }

  static Future<List<Map<String, dynamic>>> getDailyDrawHistory({int? dayNumber}) async {
    final params = dayNumber != null ? '?day=$dayNumber' : '';
    return _get('/api/daily-draws/history$params');
  }

  static Future<Map<String, dynamic>?> getDailyInfo({int? dayNumber}) async {
    final params = dayNumber != null ? '?day=$dayNumber' : '';
    final response = await http.get(Uri.parse('$_apiBase/api/daily-info$params')).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) return null;
    final data = jsonDecode(response.body);
    return data is Map ? Map<String, dynamic>.from(data) : null;
  }

  // ========== START / END DAY ==========

  static Future<void> startDay(int dayNumber) async {
    await _put('/api/navratri-days/$dayNumber/start', {});
  }

  static Future<void> endDay(int dayNumber) async {
    await _put('/api/navratri-days/$dayNumber/end', {});
  }

  static Future<void> reopenDay(int dayNumber) async {
    await _put('/api/navratri-days/$dayNumber/reopen', {});
  }

  // ========== SONG REQUESTS ==========

  static Future<Map<String, dynamic>?> createSongRequest({
    required int userId,
    required String songName,
    String? youtubeLink,
    required int dayNumber,
    String requestType = 'live',
  }) async {
    return _post('/api/song-requests', {
      'user_id': userId,
      'song_name': songName,
      'youtube_link': youtubeLink ?? '',
      'day_number': dayNumber,
      'request_type': requestType,
    });
  }

  static Future<List<Map<String, dynamic>>> getSongRequests({int? day, String? status}) async {
    final params = <String, String>{};
    if (day != null) params['day'] = day.toString();
    if (status != null) params['status'] = status;
    return _get('/api/song-requests', queryParams: params.isNotEmpty ? params : null);
  }

  static Future<void> playSongRequest(int id) async {
    await _put('/api/song-requests/$id/play', {});
  }

  static Future<void> skipSongRequest(int id) async {
    await _put('/api/song-requests/$id/skip', {});
  }

  static Future<void> deleteSongRequest(int id) async {
    await _delete('/api/song-requests/$id');
  }

  static Future<void> upvoteSongRequest(int id) async {
    await _post('/api/song-requests/$id/upvote', {});
  }

  // ========== SONG SUGGESTIONS ==========

  static Future<Map<String, dynamic>?> createSongSuggestion({
    required int userId,
    required String songName,
    String? youtubeLink,
    required int targetDay,
  }) async {
    return _post('/api/song-suggestions', {
      'user_id': userId,
      'song_name': songName,
      'youtube_link': youtubeLink ?? '',
      'target_day': targetDay,
    });
  }

  static Future<List<Map<String, dynamic>>> getSongSuggestions({int? day}) async {
    final params = day != null ? '?day=$day' : '';
    return _get('/api/song-suggestions$params');
  }

  static Future<void> upvoteSongSuggestion(int id, int userId) async {
    await _post('/api/song-suggestions/$id/upvote', {'user_id': userId});
  }

  static Future<void> removeUpvoteSuggestion(int id, int userId) async {
    await _delete('/api/song-suggestions/$id/upvote');
  }

  // ========== SHOUTOUTS ==========

  static Future<Map<String, dynamic>?> createShoutout({
    required int fromUserId,
    int? toUserId,
    required String message,
    String emoji = '🎉',
    required int dayNumber,
    String shoutoutType = 'general',
  }) async {
    return _post('/api/shoutouts', {
      'from_user_id': fromUserId,
      'to_user_id': toUserId ?? fromUserId,
      'message': message,
      'emoji': emoji,
      'day_number': dayNumber,
      'shoutout_type': shoutoutType,
    });
  }

  static Future<List<Map<String, dynamic>>> getShoutouts({int? day}) async {
    final params = day != null ? '?day=$day' : '';
    return _get('/api/shoutouts$params');
  }

  static Future<void> reactShoutout(int id, int userId, String reaction) async {
    await _post('/api/shoutouts/$id/react', {'user_id': userId, 'reaction': reaction});
  }

  static Future<void> removeShoutoutReaction(int id, int userId, String reaction) async {
    await _delete('/api/shoutouts/$id/react');
  }

  static Future<void> deleteShoutout(int id) async {
    await _delete('/api/shoutouts/$id');
  }
}
