# Navratri 2026 App — Future Features Roadmap

## Status: Planning Phase
## Last Updated: 2026-08-28

---

## Phase 1: Engagement Features (Quick Wins)

### 1.1 Garba Song Demand Tab 🎵
**Priority: HIGH | Effort: Medium | Impact: 🔥🔥🔥**

Users request songs by uploading song name + YouTube link. DJ sees queue on organizer display and plays the next requested song. Also allows suggesting songs for tomorrow.

#### Database Tables
```sql
CREATE TABLE song_requests (
  id SERIAL PRIMARY KEY,
  user_id INT REFERENCES users(id),
  song_name VARCHAR NOT NULL,
  youtube_link VARCHAR,
  day_number INT NOT NULL,
  request_type VARCHAR DEFAULT 'live',  -- live, suggestion
  status VARCHAR DEFAULT 'pending',     -- pending, playing, completed, skipped
  request_count INT DEFAULT 1,
  played_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE song_suggestions (
  id SERIAL PRIMARY KEY,
  user_id INT REFERENCES users(id),
  song_name VARCHAR NOT NULL,
  youtube_link VARCHAR,
  target_day INT NOT NULL,
  upvotes INT DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE song_upvotes (
  id SERIAL PRIMARY KEY,
  song_suggestion_id INT REFERENCES song_suggestions(id),
  user_id INT REFERENCES users(id),
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(song_suggestion_id, user_id)
);
```

#### API Endpoints
```
POST   /api/song-requests          — Request a song (user)
GET    /api/song-requests?day=N    — Get requests for day (organizer)
PUT    /api/song-requests/<id>/play — Mark as playing (organizer)
PUT    /api/song-requests/<id>/skip — Skip song (organizer)
DELETE /api/song-requests/<id>      — Remove request

POST   /api/song-suggestions       — Suggest for tomorrow (user)
GET    /api/song-suggestions?day=N — Get suggestions for day
POST   /api/song-suggestions/<id>/upvote — Upvote suggestion
DELETE /api/song-suggestions/<id>/upvote — Remove upvote
```

#### User Screens
- **Song Request Tab** (new screen in user dashboard)
  - Search bar: "Type song name..."
  - YouTube link input: "Paste YouTube link (optional)"
  - [REQUEST] button
  - Live queue showing current requests with vote counts
  - "Suggest for Tomorrow" section

#### Organizer/DJ Display
- **DJ Console Screen** (new screen accessible from organizer dashboard)
  - Now Playing card with song name + requester
  - Request Queue (sorted by votes/time)
  - [PLAY NEXT] [SKIP] [CLEAR ALL] buttons
  - Tomorrow's Suggestions section with upvote counts
  - Quick play buttons: Dhol, Dandiya, Bhajan, Modern

#### Flutter Files
- `lib/screens/user/user_song_request_screen.dart` — User request screen
- `lib/screens/organizer/dj_console_screen.dart` — DJ display screen
- `lib/database/database_helper.dart` — Add API methods

---

### 1.2 Shoutout Wall 🎉
**Priority: MEDIUM | Effort: Low | Impact: 🔥🔥**

Social feed where residents post congratulatory messages to winners.

#### Database Tables
```sql
CREATE TABLE shoutouts (
  id SERIAL PRIMARY KEY,
  from_user_id INT REFERENCES users(id),
  to_user_id INT REFERENCES users(id),
  message TEXT NOT NULL,
  emoji VARCHAR(10) DEFAULT '🎉',
  day_number INT NOT NULL,
  shoutout_type VARCHAR DEFAULT 'general', -- winner, birthday, thank_you, general
  is_approved BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE shoutout_reactions (
  id SERIAL PRIMARY KEY,
  shoutout_id INT REFERENCES shoutouts(id),
  user_id INT REFERENCES users(id),
  reaction VARCHAR(5) NOT NULL,  -- ❤️ 👏 🎉 🔥
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(shoutout_id, user_id, reaction)
);
```

#### API Endpoints
```
POST   /api/shoutouts              — Post shoutout
GET    /api/shoutouts?day=N        — Get shoutouts for day
POST   /api/shoutouts/<id>/react   — Add reaction
DELETE /api/shoutouts/<id>/react   — Remove reaction
DELETE /api/shoutouts/<id>         — Delete own shoutout
```

#### User Screen
- **Shoutout Wall Screen** (new in user dashboard)
  - Post form: "Write a shoutout..." + emoji picker + tag user
  - Feed: newest first, shows reactions
  - Tap ❤️ 👏 🎉 to react

#### Auto-Shoutout
- When someone wins a draw → system auto-posts: "🎉 Congrats to [Name] from [House] for winning [Prize]!"

---

### 1.3 Confetti Animation on Winner 🎊
**Priority: HIGH | Effort: 5 minutes | Impact: 🔥**

Add confetti burst animation when a winner is announced in the lucky draw.

#### Implementation
- Add `confetti` package to `pubspec.yaml`
- Trigger confetti in `_showWinnerDialog()` and `_showAllPrizeWinnersDialog()`
- Use `ConfettiWidget` with gold/green/purple colors

---

## Phase 2: Smart Features (Medium Effort)

### 2.1 Smart Coupon QR Code 📱
**Priority: HIGH | Effort: Medium | Impact: 🔥🔥🔥**

Physical coupon with QR code → organizer scans → auto-assigns ticket to participant.

#### QR Code Data Format
```json
{
  "v": 1,
  "app": "navratri2026",
  "ticket": "2026100045",
  "day": 3,
  "goddess": "Chandraghanta"
}
```

#### API Endpoints
```
POST /api/coupon/scan              — Scan QR, return ticket info
GET  /api/coupon/generate/<day>   — Generate QR data for tickets
POST /api/coupon/bulk-generate    — Generate all QR codes for a day
```

#### Screens
- **QR Scanner Screen** (organizer)
  - Camera view with overlay
  - Scan result: ticket code, day, status
  - House number search → member select → Assign
  
- **QR Print Screen** (organizer)
  - Select day → show all tickets as printable QR cards
  - Print button → generate PDF with QR codes
  - Format: 3 columns x 5 rows on A4

#### Packages
- `qr_flutter` — Generate QR codes
- `mobile_scanner` — Scan QR codes
- `pdf` + `printing` — Print QR sheets

---

### 2.2 Auto-Reminders 🔔
**Priority: MEDIUM | Effort: Medium | Impact: 🔥🔥**

Scheduled push notifications for daily events.

#### Architecture
```
┌─────────────────────────────────────┐
│         Reminder Scheduler          │
│  ┌────────┐  ┌────────┐  ┌───────┐ │
│  │ Aarti  │  │ Food   │  │ Draw  │ │
│  │ -30min │  │ -15min │  │ -10min│ │
│  └───┬────┘  └───┬────┘  └───┬───┘ │
│      └───────────┴───────────┘     │
│              │                     │
│     ┌────────▼────────┐            │
│     │ Web Push (FCM)  │            │
│     └─────────────────┘            │
└─────────────────────────────────────┘
```

#### Implementation Options
1. **In-App Timer** — Show banner 30min/15min/5min before events (works always)
2. **Web Push** — FCM notifications (needs browser permission, works when closed)
3. **Hybrid** — In-app banners + optional web push

#### Database Tables
```sql
CREATE TABLE reminder_settings (
  id SERIAL PRIMARY KEY,
  event_type VARCHAR NOT NULL,     -- aarti, food, draw, announcement
  minutes_before INT NOT NULL,     -- 30, 15, 5
  message_template VARCHAR NOT NULL,
  is_enabled BOOLEAN DEFAULT TRUE
);

CREATE TABLE reminder_logs (
  id SERIAL PRIMARY KEY,
  user_id INT REFERENCES users(id),
  event_type VARCHAR NOT NULL,
  sent_at TIMESTAMP DEFAULT NOW(),
  status VARCHAR DEFAULT 'sent'    -- sent, delivered, failed
);
```

#### API Endpoints
```
GET  /api/reminders/settings      — Get reminder config (organizer)
PUT  /api/reminders/settings      — Update reminder config
POST /api/reminders/test          — Send test reminder
GET  /api/reminders/logs          — View sent reminders
```

---

### 2.3 Multi-Language Support 🌐
**Priority: MEDIUM | Effort: Medium | Impact: 🔥🔥**

Hindi, Gujarati, and English toggle.

#### Architecture
```
lib/
├── l10n/
│   ├── en.json
│   ├── hi.json
│   └── gu.json
├── providers/
│   └── locale_provider.dart
└── widgets/
    └── language_toggle.dart
```

#### Priority Strings (translate first)
```
Navigation: Home, Members, Aarti, Food, Gifts, Reports
Actions: Login, Book, Order, Assign, Save, Cancel
Status: Active, Pending, Approved, Completed
Festival: Day, Goddess, Dress Code, Lucky Draw
Messages: Success, Error, Loading, No Data
```

#### Implementation
- Store language preference in SharedPreferences
- Provider-based locale state management
- Toggle widget in settings/profile screen
- All strings go through `AppLocalizations.translate(key)`

---

## Phase 3: Advanced Features (High Effort)

### 3.1 Live Polling 📊
**Priority: HIGH | Effort: High | Impact: 🔥🔥🔥**

Real-time voting on next garba song. Results shown on organizer display (not separate DJ display).

#### Database Tables
```sql
CREATE TABLE polls (
  id SERIAL PRIMARY KEY,
  question VARCHAR NOT NULL,
  day_number INT NOT NULL,
  is_active BOOLEAN DEFAULT TRUE,
  created_by INT REFERENCES users(id),
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE poll_options (
  id SERIAL PRIMARY KEY,
  poll_id INT REFERENCES polls(id),
  song_name VARCHAR NOT NULL,
  youtube_link VARCHAR,
  vote_count INT DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE poll_votes (
  id SERIAL PRIMARY KEY,
  poll_id INT REFERENCES polls(id),
  option_id INT REFERENCES poll_options(id),
  user_id INT REFERENCES users(id),
  voted_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(poll_id, user_id)
);
```

#### API Endpoints
```
POST   /api/polls                  — Create poll (organizer)
GET    /api/polls?day=N            — Get active poll
POST   /api/polls/<id>/vote        — Cast vote (user)
PUT    /api/polls/<id>/close       — Close poll (organizer)
GET    /api/polls/<id>/results     — Get live results
DELETE /api/polls/<id>             — Delete poll
```

#### User Screen
- **Poll Screen** (user dashboard)
  - Active poll with options
  - Tap to vote (can change until poll closes)
  - Live vote counts (auto-refresh every 3s)

#### Organizer Display
- **Poll Results Widget** (shown on organizer dashboard)
  - Bar chart of votes
  - Auto-refresh every 5s
  - [CLOSE POLL] button

---

### 3.2 Garba Marathon — Dance Streak Tracker 💃
**Priority: MEDIUM | Effort: High | Impact: 🔥🔥**

Track continuous garba participation. Longest streak wins!

#### Database Tables
```sql
CREATE TABLE garba_checkins (
  id SERIAL PRIMARY KEY,
  user_id INT REFERENCES users(id),
  day_number INT NOT NULL,
  check_in_time TIMESTAMP DEFAULT NOW(),
  check_out_time TIMESTAMP,
  duration_minutes INT,
  venue_verified BOOLEAN DEFAULT FALSE,
  UNIQUE(user_id, day_number)
);

CREATE TABLE garba_streaks (
  id SERIAL PRIMARY KEY,
  user_id INT REFERENCES users(id) UNIQUE,
  current_streak INT DEFAULT 0,
  longest_streak INT DEFAULT 0,
  total_days INT DEFAULT 0,
  total_hours DECIMAL(5,1) DEFAULT 0,
  last_checkin_date DATE,
  updated_at TIMESTAMP DEFAULT NOW()
);
```

#### API Endpoints
```
POST /api/garba/checkin           — Check in (user)
POST /api/garba/checkout          — Check out (user)
GET  /api/garba/status            — Get user's today status
GET  /api/garba/leaderboard       — Get streak leaderboard
GET  /api/garba/history?user_id=N — Get user's history
```

#### User Screen
- **Garba Check-in Card** (in user dashboard)
  - [CHECK IN] / [CHECK OUT] toggle button
  - Today's duration timer
  - Current streak: "🔥 5 days"
  - Total hours: "23.5 hours"

#### Organizer Screen
- **Leaderboard Screen** (accessible from organizer dashboard)
  - Top 10 by streak
  - Top 10 by total hours
  - Per-day attendance chart

---

### 3.3 Offline Mode 📶
**Priority: LOW | Effort: High | Impact: 🔥🔥**

Cache data for areas with poor signal.

#### Architecture
```
┌─────────────────────────────────────────┐
│            Offline Strategy             │
├─────────────────────────────────────────┤
│ 1. Cache API responses in SQLite        │
│ 2. Queue write operations when offline  │
│ 3. Sync when connection restored        │
│ 4. Show cached data with "offline" badge│
└─────────────────────────────────────────┘
```

#### Cache Strategy
```
Data Type          Cache Time    Sync Priority
─────────────────  ────────────  ─────────────
User Profile       24 hours      Low
Day Schedule       12 hours      Medium
Snack Menu         6 hours       Low
Tickets            1 hour        High
Aarti Bookings     Real-time     Critical
Song Requests      5 minutes     Medium
```

#### Implementation
- `connectivity_plus` package for network detection
- SQLite local cache via `sqflite`
- Background sync service
- Offline banner widget

---

## Implementation Order

```
Week 1: Phase 1 — Quick Wins
├── Day 1: Confetti animation (5 min)
├── Day 2-3: Garba Song Demand Tab
└── Day 4-5: Shoutout Wall

Week 2: Phase 2 — Smart Features
├── Day 1-2: Smart Coupon QR
├── Day 3-4: Auto-Reminders (in-app)
└── Day 5: Multi-Language (Hindi + English)

Week 3: Phase 3 — Advanced
├── Day 1-2: Live Polling
├── Day 3-4: Garba Marathon
└── Day 5: Gujarati language + Offline basics
```

---

## Database Migration Summary

All new tables to create:
1. `song_requests` — Song request queue
2. `song_suggestions` — Tomorrow's song suggestions
3. `song_upvotes` — Upvotes on suggestions
4. `shoutouts` — Shoutout messages
5. `shoutout_reactions` — Reactions on shoutouts
6. `reminder_settings` — Reminder configuration
7. `reminder_logs` — Sent reminder history
8. `polls` — Live polls
9. `poll_options` — Poll options
10. `poll_votes` — User votes
11. `garba_checkins` — Check-in/check-out records
12. `garba_streaks` — Streak tracking

---

## New Screens Summary

| Screen | Location | Access |
|--------|----------|--------|
| Song Request | User Dashboard tab | All users |
| DJ Console | Organizer push screen | Organizer |
| Shoutout Wall | User Dashboard tab | All users |
| QR Scanner | Organizer push screen | Organizer |
| QR Print | Organizer push screen | Organizer |
| Poll Results | Organizer Dashboard widget | Organizer |
| Poll Vote | User Dashboard tab | All users |
| Garba Check-in | User Dashboard card | All users |
| Leaderboard | Organizer push screen | Organizer |
| Language Toggle | Settings / Profile | All users |

---

## Risk Assessment

| Feature | Risk | Mitigation |
|---------|------|------------|
| QR Scanner | Camera permissions | Fallback to manual entry |
| Web Push | Browser support | In-app reminders as backup |
| Offline | Data conflicts | Queue writes, merge on sync |
| Multi-Language | Translation accuracy | Community review |
| Live Polling | High traffic | Rate limiting, caching |

---

## Success Metrics

- **Song Demand Tab**: 50+ song requests per day
- **Shoutout Wall**: 20+ shoutouts per day
- **QR Coupon**: 90% scan success rate
- **Reminders**: 80% delivery rate
- **Multi-Language**: 30% users switch language
- **Garba Marathon**: 60% daily check-in rate
- **Live Polling**: 100+ votes per poll
