# ============================================
# NAVRATRI 2026 - ORGANIZER MODE
# Complete Implementation Roadmap (Updated)
# ============================================

## TABLE OF CONTENTS
1. Requirements Analysis
2. User Types & Login System
3. Database Schema (PostgreSQL Compatible)
4. Flutter Architecture
5. Implementation Phases (12 Weeks)
6. Auto-Testing After Each Phase
7. Screen Flow & Navigation

---

## 1. REQUIREMENTS ANALYSIS

### 1.1 User Types & Login System
┌─────────────────────────────────────────────────────────────────────┐
│ USER TYPE    │ LOGIN ID         │ PASSWORD        │ PERMISSIONS     │
├─────────────────────────────────────────────────────────────────────┤
│ User         │ House Number     │ Mobile Number   │ View + Tickets  │
│              │ (A-402, B-101)   │ (9876543210)   │                 │
├─────────────────────────────────────────────────────────────────────┤
│ Organizer    │ Username         │ Password        │ Full Access     │
├─────────────────────────────────────────────────────────────────────┤
│ Sponsor      │ House Number     │ Password        │ Ads + View      │
└─────────────────────────────────────────────────────────────────────┘

### 1.2 Core Features
A. Member Registration (Organizer) - House No, Name, Mobile
B. Fund Collection (Cash/Online + Tentative Date) - Linked to House No
C. Sponsor Management (Ads Upload) - Linked to House No
D. Expense Management (Categories: Light, Sound, Decoration, etc.)
E. Income vs Expense Dashboard
F. Draw Ticket System (Barcode Scan) - Linked to House No
G. Daily Draw Management (Start/Stop Day, N draws, no repeat winners)
H. Broadcast & Announcements

---

## 2. DATABASE SCHEMA (PostgreSQL)

### 2.1 Key Tables
```sql
-- USERS (House Number = User ID)
users (
  id, house_number (UNIQUE), name, mobile_number,
  user_type, password, is_active
)

-- FUND COLLECTIONS (Linked to House Number)
fund_collections (
  id, user_id, house_number, amount,
  payment_method (cash/online),
  payment_status (paid/pending/tentative),
  tentative_date, paid_date
)

-- SPONSORS (Linked to House Number)
sponsors (
  id, user_id, company_name,
  advertisement_text, advertisement_image,
  sponsorship_amount, payment_status
)

-- DRAW TICKETS (Linked to House Number)
draw_tickets (
  id, ticket_code, user_id, house_number,
  day_number, is_assigned, is_winner
)

-- Other tables: expense_categories, expenses,
-- navratri_days, daily_draws, announcements,
-- daily_schedules, broadcasts
```

---

## 3. FLUTTER ARCHITECTURE

### 3.1 Project Structure
```
lib/
├── main.dart
├── config/
├── database/
├── models/ (6 files)
├── providers/
├── screens/
│   ├── auth/
│   ├── organizer/
│   ├── user/
│   └── sponsor/
├── widgets/
└── services/
```

---

## 4. IMPLEMENTATION PHASES (12 Weeks)

### PHASE 1: Foundation (Week 1-2) ✅ COMPLETED
```
Week 1: Project Setup & Database
├── Day 1-2: Flutter project, folder structure     ✅ Done
├── Day 3-4: PostgreSQL schema, database_helper    ✅ Done
├── Day 5-7: Models for all entities               ✅ Done
│
Week 2: Authentication & User Management
├── Day 1-2: Auth provider, login logic            ✅ Done
├── Day 3-4: Login screen (3 user types)           ✅ Done
├── Day 5-7: User registration screen              ✅ Done
│
✅ PHASE 1 AUTO-TEST PASSED
```

### PHASE 2: Core Features (Week 3-5) 🔄 IN PROGRESS
```
Week 3: Member Registration & Fund Collection
├── Day 1-3: Member registration screen (Organizer)
├── Day 4-5: Payment collection screen             ✅ Done
├── Day 6-7: Payment tracking (Cash/Online/Tentative)
│
Week 4: Sponsor Management
├── Day 1-3: Sponsor registration screen
├── Day 4-5: Ad upload functionality
├── Day 6-7: Sponsor dashboard
│
Week 5: Expense Management
├── Day 1-3: Category management (Light, Sound, etc.)
├── Day 4-5: Expense entry screen
├── Day 6-7: Expense list with filters
│
✅ PHASE 2 AUTO-TEST (After Week 5)
```

### PHASE 3: Draw System (Week 6-8)
```
Week 6: Ticket Distribution
├── Day 1-3: Barcode/QR generation for tickets
├── Day 4-5: Barcode scanner for organizer
├── Day 6-7: Ticket-user mapping (by house number)
│
Week 7: Day Control & Daily Draws
├── Day 1-3: Start/Stop Navratri day
├── Day 4-5: Daily draw mechanism (N times)
├── Day 6-7: Winner selection (no repeat for day)
│
Week 8: Draw History & Winner Display
├── Day 1-3: User coupon view screen              ✅ Done
├── Day 4-5: Winner announcements
├── Day 6-7: Draw history screen
│
✅ PHASE 3 AUTO-TEST (After Week 8)
```

### PHASE 4: Communication (Week 9-10)
```
Week 9: Announcements & Broadcasts
├── Day 1-3: Announcement CRUD
├── Day 4-5: Broadcast system
├── Day 6-7: Push notification setup
│
Week 10: Schedule & Gifts
├── Day 1-3: Daily schedule management
├── Day 4-5: Gift addition (last day)
├── Day 6-7: Schedule display for users
│
✅ PHASE 4 AUTO-TEST (After Week 10)
```

### PHASE 5: Reports & Dashboard (Week 11)
```
Week 11: Analytics & Reports
├── Day 1-2: Income vs Expense dashboard
├── Day 3-4: Category-wise expense breakdown
├── Day 5-6: PDF report generation
├── Day 7: Export functionality
│
✅ PHASE 5 AUTO-TEST (After Week 11)
```

### PHASE 6: Polish & Testing (Week 12)
```
Week 12: Testing & Deployment
├── Day 1-2: Unit tests
├── Day 3-4: UI testing
├── Day 5-6: Performance optimization
├── Day 7: Build for Web, Android, iOS
│
✅ PHASE 6 FINAL TEST
```

---

## 5. AUTO-TESTING AFTER EACH PHASE

### 5.1 Test Script Location
```
navratri_app/test/
├── phase1_test.dart   ✅ Passed
├── phase2_test.dart   ⏳ Pending
├── phase3_test.dart   ⏳ Pending
├── phase4_test.dart   ⏳ Pending
├── phase5_test.dart   ⏳ Pending
└── phase6_test.dart   ⏳ Pending
```

### 5.2 Phase 1 Tests ✅ PASSED
```dart
// phase1_test.dart
test('Database connection', () async {
  await DatabaseHelper.connect();
  expect(DatabaseHelper.isConnected, true);
});

test('Create tables', () async {
  await DatabaseHelper.createAllTables();
  final result = await DatabaseHelper.query('SELECT COUNT(*) FROM users');
  expect(result.isNotEmpty, true);
});

test('User login with house number', () async {
  final user = await DatabaseHelper.loginUser(
    houseNumber: 'A-402',
    mobileNumber: '9876543210',
  );
  expect(user, isNotNull);
  expect(user!['house_number'], 'A-402');
});

test('Register new user', () async {
  final userId = await DatabaseHelper.registerUser(
    houseNumber: 'TEST-001',
    name: 'Test User',
    mobileNumber: '1234567890',
  );
  expect(userId > 0, true);
});
```

### 5.3 Phase 2 Tests (After Week 5)
```dart
// phase2_test.dart
test('Add payment linked to house number', () async {
  final paymentId = await DatabaseHelper.addPayment(
    userId: 1,
    houseNumber: 'A-402',
    amount: 1000,
    paymentMethod: 'cash',
  );
  expect(paymentId > 0, true);
});

test('Get payments by house number', () async {
  final payments = await DatabaseHelper.getPaymentsByHouse('A-402');
  expect(payments.isNotEmpty, true);
});

test('Register sponsor', () async {
  final sponsorId = await DatabaseHelper.registerSponsor(
    houseNumber: 'SP-002',
    name: 'Test Sponsor',
    mobileNumber: '9999999999',
    companyName: 'Test Company',
    password: 'test123',
  );
  expect(sponsorId > 0, true);
});

test('Add expense', () async {
  final expenseId = await DatabaseHelper.addExpense(
    categoryId: 1,
    itemName: 'LED Lights',
    amount: 5000,
  );
  expect(expenseId > 0, true);
});
```

### 5.4 Phase 3 Tests (After Week 8)
```dart
// phase3_test.dart
test('Generate tickets for day', () async {
  await DatabaseHelper.generateTickets(dayNumber: 1, count: 100);
  final count = await DatabaseHelper.getTicketCount(1);
  expect(count, 100);
});

test('Assign ticket to user', () async {
  await DatabaseHelper.assignTicket(
    ticketCode: 'NR2026-D1-001',
    userId: 1,
    houseNumber: 'A-402',
  );
  final tickets = await DatabaseHelper.getMyTickets('A-402');
  expect(tickets.isNotEmpty, true);
});

test('Get user tickets by house number', () async {
  final tickets = await DatabaseHelper.getTicketsByHouse('A-402');
  expect(tickets.isNotEmpty, true);
});
```

### 5.5 Phase 4 Tests (After Week 10)
```dart
// phase4_test.dart
test('Create announcement', () async {
  final announcementId = await DatabaseHelper.createAnnouncement(
    title: 'Test Announcement',
    message: 'Test message',
  );
  expect(announcementId > 0, true);
});

test('Get active announcements', () async {
  final announcements = await DatabaseHelper.getActiveAnnouncements();
  expect(announcements.isNotEmpty, true);
});

test('Create schedule', () async {
  final scheduleId = await DatabaseHelper.createSchedule(
    dayNumber: 1,
    eventName: 'Maha Aarti',
    eventTime: '19:30',
  );
  expect(scheduleId > 0, true);
});
```

### 5.6 Phase 5 Tests (After Week 11)
```dart
// phase5_test.dart
test('Get income summary', () async {
  final summary = await DatabaseHelper.getIncomeSummary();
  expect(summary.containsKey('fund_collection'), true);
  expect(summary.containsKey('sponsorship'), true);
});

test('Get expense summary by category', () async {
  final summary = await DatabaseHelper.getExpenseSummaryByCategory();
  expect(summary.isNotEmpty, true);
});

test('Generate PDF report', () async {
  final pdfBytes = await PDFService.generateReport();
  expect(pdfBytes.isNotEmpty, true);
});
```

### 5.7 Test Commands
```bash
# Run all tests
flutter test

# Run phase-specific tests
flutter test test/phase1_test.dart
flutter test test/phase2_test.dart

# Run with coverage
flutter test --coverage
```

### 5.8 Test Checklist Per Phase
```
Phase Completion Checklist:
□ All features implemented
□ All tests passing
□ No regression in previous phases
□ UI responsive on all screen sizes
□ Database queries optimized
□ Error handling in place
□ Loading states implemented
□ Edge cases handled
```

---

## 6. SCREEN FLOW & NAVIGATION

### 6.1 App Navigation
```
App
├── Splash Screen
├── Login Screen
│   ├── User Login (House + Mobile) → User Home
│   ├── Organizer Login → Organizer Dashboard
│   └── Sponsor Login → Sponsor Dashboard
│
└── Registration (Organizer Only)
    ├── Register Member
    └── Register Sponsor
```

### 6.2 Organizer Dashboard Tabs
```
Organizer Dashboard
├── Tab 1: Home (Summary)
├── Tab 2: Members
├── Tab 3: Sponsors
├── Tab 4: Expenses
├── Tab 5: Draws
└── Tab 6: More
```

### 6.3 User Home Screen
```
User Home
├── Profile Card (House No, Name)
├── My Tickets (by house number)
├── Current Day Schedule
├── Announcements
├── Payment History
└── Gate Pass (QR)
```

---

## 7. FILES CREATED SO FAR

### Documentation
- ROADMAP.md

### Database
- database/schema.sql
- database/database_helper.dart
- database/app_database.dart

### Config
- config/database_config.dart
- .env
- docker-compose.yml

### Models (6 files)
- user.dart, fund_collection.dart, sponsor.dart
- expense.dart, draw_ticket.dart, announcement.dart

### Screens
- auth/login_screen.dart, auth/register_screen.dart
- organizer/dashboard_screen.dart, organizer/payment_collection_screen.dart
- user/home_screen.dart, user/user_coupon_screen.dart
- sponsor/dashboard_screen.dart

### Providers
- auth_provider.dart

---

**Target: Full app ready in 12 weeks (3 months)**
**Current Progress: Phase 1 Complete, Starting Phase 2**
