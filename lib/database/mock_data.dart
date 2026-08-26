class MockData {
  static final List<Map<String, dynamic>> users = [
    {'id': 1, 'house_number': 'ADMIN-001', 'name': 'Organizer Admin', 'mobile_number': '9999999999', 'user_type': 'organizer', 'password': 'admin123', 'is_active': true},
    {'id': 2, 'house_number': 'A-402', 'name': 'Rajesh Kumar', 'mobile_number': '9876543210', 'user_type': 'user', 'is_active': true},
    {'id': 3, 'house_number': 'A-101', 'name': 'Priya Sharma', 'mobile_number': '9876543211', 'user_type': 'user', 'is_active': true},
    {'id': 4, 'house_number': 'B-205', 'name': 'Amit Patel', 'mobile_number': '9876543212', 'user_type': 'user', 'is_active': true},
    {'id': 5, 'house_number': 'C-303', 'name': 'Sneha Gupta', 'mobile_number': '9876543213', 'user_type': 'user', 'is_active': true},
    {'id': 6, 'house_number': 'SP-001', 'name': 'Sharma Electronics', 'mobile_number': '9876543214', 'user_type': 'sponsor', 'is_active': true, 'company_name': 'Sharma Electronics', 'advertisement_text': 'Best deals on electronics'},
    {'id': 7, 'house_number': 'B-102', 'name': 'Vikram Singh', 'mobile_number': '9876543215', 'user_type': 'user', 'is_active': true},
    {'id': 8, 'house_number': 'A-301', 'name': 'Meena Devi', 'mobile_number': '9876543216', 'user_type': 'user', 'is_active': true},
    {'id': 9, 'house_number': 'C-201', 'name': 'Ravi Verma', 'mobile_number': '9876543217', 'user_type': 'user', 'is_active': true},
    {'id': 10, 'house_number': 'SP-002', 'name': 'Patel Traders', 'mobile_number': '9876543218', 'user_type': 'sponsor', 'is_active': true, 'company_name': 'Patel Traders', 'advertisement_text': 'Wholesale grocery'},
  ];

  static final List<Map<String, dynamic>> payments = [
    {'id': 1, 'user_id': 2, 'house_number': 'A-402', 'user_name': 'Rajesh Kumar', 'amount': 2000.0, 'payment_method': 'cash', 'payment_status': 'paid', 'created_at': '2026-10-01'},
    {'id': 2, 'user_id': 3, 'house_number': 'A-101', 'user_name': 'Priya Sharma', 'amount': 2000.0, 'payment_method': 'online', 'payment_status': 'paid', 'created_at': '2026-10-02'},
    {'id': 3, 'user_id': 4, 'house_number': 'B-205', 'user_name': 'Amit Patel', 'amount': 1000.0, 'payment_method': 'cash', 'payment_status': 'pending', 'created_at': '2026-10-03'},
    {'id': 4, 'user_id': 5, 'house_number': 'C-303', 'user_name': 'Sneha Gupta', 'amount': 2000.0, 'payment_method': 'online', 'payment_status': 'paid', 'created_at': '2026-10-04'},
    {'id': 5, 'user_id': 7, 'house_number': 'B-102', 'user_name': 'Vikram Singh', 'amount': 1500.0, 'payment_method': 'cash', 'payment_status': 'tentative', 'tentative_date': '2026-10-10', 'created_at': '2026-10-05'},
  ];

  static final List<Map<String, dynamic>> expenses = [
    {'id': 1, 'category_id': 1, 'category_name': 'Light', 'item_name': 'LED String Lights', 'amount': 5000.0, 'expense_date': '2026-10-01', 'paid_to': 'Electric Mart'},
    {'id': 2, 'category_id': 2, 'category_name': 'Sound', 'item_name': 'Speaker Rental', 'amount': 8000.0, 'expense_date': '2026-10-02', 'paid_to': 'Sound Systems Inc'},
    {'id': 3, 'category_id': 3, 'category_name': 'Decoration', 'item_name': 'Flower Garlands', 'amount': 3000.0, 'expense_date': '2026-10-03', 'paid_to': 'Fresh Flowers Shop'},
    {'id': 4, 'category_id': 4, 'category_name': 'Food & Drinks', 'item_name': 'Prasad Items', 'amount': 2000.0, 'expense_date': '2026-10-04', 'paid_to': 'Puja Store'},
  ];

  static final List<Map<String, dynamic>> expenseCategories = [
    {'id': 1, 'name': 'Light', 'description': 'Lighting and electrical expenses', 'is_active': true},
    {'id': 2, 'name': 'Sound', 'description': 'Sound system and music expenses', 'is_active': true},
    {'id': 3, 'name': 'Decoration', 'description': 'Decoration and setup expenses', 'is_active': true},
    {'id': 4, 'name': 'Food & Drinks', 'description': 'Food and beverages', 'is_active': true},
    {'id': 5, 'name': 'Prizes & Gifts', 'description': 'Prizes for winners and gifts', 'is_active': true},
    {'id': 6, 'name': 'Miscellaneous', 'description': 'Other expenses', 'is_active': true},
  ];

  static final List<Map<String, dynamic>> navratriDays = [
    {'id': 1, 'day_number': 1, 'date': '2026-10-15', 'goddess_name': 'Shailputri', 'dress_code': 'Royal Blue & Bandhani', 'is_active': true},
    {'id': 2, 'day_number': 2, 'date': '2026-10-16', 'goddess_name': 'Brahmacharini', 'dress_code': 'White & Silver', 'is_active': false},
    {'id': 3, 'day_number': 3, 'date': '2026-10-17', 'goddess_name': 'Chandraghanta', 'dress_code': 'Red & Gold', 'is_active': false},
    {'id': 4, 'day_number': 4, 'date': '2026-10-18', 'goddess_name': 'Kushmanda', 'dress_code': 'Green & Yellow', 'is_active': false},
    {'id': 5, 'day_number': 5, 'date': '2026-10-19', 'goddess_name': 'Skandamata', 'dress_code': 'Orange & Pink', 'is_active': false},
    {'id': 6, 'day_number': 6, 'date': '2026-10-20', 'goddess_name': 'Katyayani', 'dress_code': 'Purple & Magenta', 'is_active': false},
    {'id': 7, 'day_number': 7, 'date': '2026-10-21', 'goddess_name': 'Kalaratri', 'dress_code': 'Black & Red', 'is_active': false},
    {'id': 8, 'day_number': 8, 'date': '2026-10-22', 'goddess_name': 'Mahagauri', 'dress_code': 'Peacock Blue', 'is_active': false},
    {'id': 9, 'day_number': 9, 'date': '2026-10-23', 'goddess_name': 'Siddhidatri', 'dress_code': 'Multi-color', 'is_active': false},
  ];

  static final List<Map<String, dynamic>> aartiSlots = [
    {'id': 1, 'day_number': 1, 'slot_time': '19:00', 'slot_label': 'Maha Aarti - Slot 1', 'max_participants': 5, 'current_participants': 3, 'is_active': true},
    {'id': 2, 'day_number': 1, 'slot_time': '19:30', 'slot_label': 'Maha Aarti - Slot 2', 'max_participants': 5, 'current_participants': 2, 'is_active': true},
    {'id': 3, 'day_number': 1, 'slot_time': '20:00', 'slot_label': 'Aarti - Slot 3', 'max_participants': 10, 'current_participants': 5, 'is_active': true},
    {'id': 4, 'day_number': 2, 'slot_time': '19:00', 'slot_label': 'Maha Aarti - Slot 1', 'max_participants': 5, 'current_participants': 0, 'is_active': true},
    {'id': 5, 'day_number': 2, 'slot_time': '19:30', 'slot_label': 'Maha Aarti - Slot 2', 'max_participants': 5, 'current_participants': 1, 'is_active': true},
  ];

  static final List<Map<String, dynamic>> aartiBookings = [
    {'id': 1, 'user_id': 2, 'house_number': 'A-402', 'user_name': 'Rajesh Kumar', 'day_number': 1, 'slot_id': 1, 'slot_time': '19:00', 'status': 'approved', 'created_at': '2026-10-10'},
    {'id': 2, 'user_id': 3, 'house_number': 'A-101', 'user_name': 'Priya Sharma', 'day_number': 1, 'slot_id': 1, 'slot_time': '19:00', 'status': 'pending', 'created_at': '2026-10-11'},
    {'id': 3, 'user_id': 4, 'house_number': 'B-205', 'user_name': 'Amit Patel', 'day_number': 1, 'slot_id': 2, 'slot_time': '19:30', 'status': 'approved', 'created_at': '2026-10-11'},
    {'id': 4, 'user_id': 5, 'house_number': 'C-303', 'user_name': 'Sneha Gupta', 'day_number': 1, 'slot_id': 3, 'slot_time': '20:00', 'status': 'pending', 'created_at': '2026-10-12'},
  ];

  static final List<Map<String, dynamic>> snacks = [
    {'id': 1, 'name': 'Samosa (2 pcs)', 'description': 'Crispy samosas with mint chutney', 'price': 30.0, 'quantity_available': 100, 'quantity_sold': 25, 'is_vegetarian': true, 'is_active': true},
    {'id': 2, 'name': 'Dahi Vada', 'description': 'Soft vadas in spiced yogurt', 'price': 40.0, 'quantity_available': 50, 'quantity_sold': 12, 'is_vegetarian': true, 'is_active': true},
    {'id': 3, 'name': 'Chaat', 'description': 'Tangy street food mix', 'price': 35.0, 'quantity_available': 60, 'quantity_sold': 18, 'is_vegetarian': true, 'is_active': true},
    {'id': 4, 'name': 'Jalebi', 'description': 'Hot crispy jalebis', 'price': 25.0, 'quantity_available': 80, 'quantity_sold': 30, 'is_vegetarian': true, 'is_active': true},
    {'id': 5, 'name': 'Masala Chai', 'description': 'Hot spiced tea', 'price': 15.0, 'quantity_available': 200, 'quantity_sold': 55, 'is_vegetarian': true, 'is_active': true},
    {'id': 6, 'name': 'Cold Drink', 'description': 'Packaged cold drinks', 'price': 20.0, 'quantity_available': 150, 'quantity_sold': 40, 'is_vegetarian': true, 'is_active': true},
  ];

  static final List<Map<String, dynamic>> snackOrders = [
    {'id': 1, 'user_id': 2, 'house_number': 'A-402', 'user_name': 'Rajesh Kumar', 'snack_id': 1, 'snack_name': 'Samosa (2 pcs)', 'day_number': 1, 'quantity': 2, 'total_price': 60.0, 'status': 'delivered', 'created_at': '2026-10-15 19:30'},
    {'id': 2, 'user_id': 3, 'house_number': 'A-101', 'user_name': 'Priya Sharma', 'snack_id': 4, 'snack_name': 'Jalebi', 'day_number': 1, 'quantity': 3, 'total_price': 75.0, 'status': 'preparing', 'created_at': '2026-10-15 20:00'},
    {'id': 3, 'user_id': 5, 'house_number': 'C-303', 'user_name': 'Sneha Gupta', 'snack_id': 5, 'snack_name': 'Masala Chai', 'day_number': 1, 'quantity': 1, 'total_price': 15.0, 'status': 'pending', 'created_at': '2026-10-15 20:15'},
  ];

  static final List<Map<String, dynamic>> gifts = [
    {'id': 1, 'name': 'Brass Diya Set', 'description': 'Traditional brass diya set', 'gift_type': 'daily', 'day_number': 1, 'quantity': 3, 'quantity_assigned': 2, 'sponsor_id': null, 'is_active': true},
    {'id': 2, 'name': 'Dry Fruit Box', 'description': 'Premium dry fruit collection', 'gift_type': 'daily', 'day_number': 1, 'quantity': 5, 'quantity_assigned': 3, 'sponsor_id': null, 'is_active': true},
    {'id': 3, 'name': 'Silver Coin', 'description': '5gm silver coin', 'gift_type': 'sponsor', 'day_number': 1, 'quantity': 2, 'quantity_assigned': 1, 'sponsor_id': 1, 'sponsor_name': 'Sharma Electronics', 'is_active': true},
    {'id': 4, 'name': 'Bamboo Basket', 'description': 'Handcrafted bamboo basket', 'gift_type': 'daily', 'day_number': 2, 'quantity': 3, 'quantity_assigned': 0, 'sponsor_id': null, 'is_active': true},
    {'id': 5, 'name': 'Idol of Goddess', 'description': 'Small goddess idol', 'gift_type': 'daily', 'day_number': 3, 'quantity': 2, 'quantity_assigned': 0, 'sponsor_id': null, 'is_active': true},
    {'id': 6, 'name': 'Smart Watch', 'description': 'Fitness smartwatch', 'gift_type': 'sponsor', 'day_number': 3, 'quantity': 1, 'quantity_assigned': 0, 'sponsor_id': 2, 'sponsor_name': 'Patel Traders', 'is_active': true},
  ];

  static final List<Map<String, dynamic>> giftAssignments = [
    {'id': 1, 'gift_id': 1, 'gift_name': 'Brass Diya Set', 'user_id': 2, 'house_number': 'A-402', 'user_name': 'Rajesh Kumar', 'day_number': 1, 'assigned_at': '2026-10-15 21:00'},
    {'id': 2, 'gift_id': 1, 'gift_name': 'Brass Diya Set', 'user_id': 4, 'house_number': 'B-205', 'user_name': 'Amit Patel', 'day_number': 1, 'assigned_at': '2026-10-15 21:05'},
    {'id': 3, 'gift_id': 2, 'gift_name': 'Dry Fruit Box', 'user_id': 3, 'house_number': 'A-101', 'user_name': 'Priya Sharma', 'day_number': 1, 'assigned_at': '2026-10-15 21:10'},
    {'id': 4, 'gift_id': 2, 'gift_name': 'Dry Fruit Box', 'user_id': 5, 'house_number': 'C-303', 'user_name': 'Sneha Gupta', 'day_number': 1, 'assigned_at': '2026-10-15 21:15'},
    {'id': 5, 'gift_id': 3, 'gift_name': 'Silver Coin', 'user_id': 7, 'house_number': 'B-102', 'user_name': 'Vikram Singh', 'day_number': 1, 'assigned_at': '2026-10-15 21:20'},
  ];

  static final List<Map<String, dynamic>> announcements = [
    {'id': 1, 'title': 'Welcome to Navratri 2026!', 'message': 'Nine nights of celebration begin today. Join us for Maha Aarti at 7 PM.', 'announcement_type': 'general', 'priority': 1, 'is_active': true},
    {'id': 2, 'title': 'Dress Code Reminder', 'message': 'Tonight\'s dress code is Royal Blue & Bandhani. Look your best!', 'announcement_type': 'reminder', 'priority': 2, 'is_active': true},
    {'id': 3, 'title': 'Snack Counter Open', 'message': 'Snack counter is now open. Enjoy samosas, jalebi, and chai!', 'announcement_type': 'info', 'priority': 1, 'is_active': true},
  ];

  static int _nextId = 100;
  static int get nextId => _nextId++;
}
