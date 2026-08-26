-- ============================================
-- NAVRATRI 2026 - PostgreSQL Schema
-- House Number = User ID (linked everywhere)
-- ============================================

-- ============================================
-- USERS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    house_number VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    mobile_number VARCHAR(15) NOT NULL,
    user_type VARCHAR(20) DEFAULT 'user',
    password VARCHAR(255),
    profile_image TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_users_house ON users(house_number);
CREATE INDEX idx_users_mobile ON users(mobile_number);

-- ============================================
-- FUND COLLECTIONS TABLE (Linked to House Number)
-- ============================================
CREATE TABLE IF NOT EXISTS fund_collections (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    house_number VARCHAR(50) NOT NULL REFERENCES users(house_number),
    amount DECIMAL(10,2) NOT NULL,
    payment_method VARCHAR(20) NOT NULL,
    payment_status VARCHAR(20) DEFAULT 'pending',
    payer_name VARCHAR(100),
    tentative_date DATE,
    paid_date DATE,
    received_by INTEGER REFERENCES users(id),
    receipt_number VARCHAR(100),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_funds_user ON fund_collections(user_id);
CREATE INDEX idx_funds_house ON fund_collections(house_number);
CREATE INDEX idx_funds_status ON fund_collections(payment_status);

-- ============================================
-- SPONSORS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS sponsors (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    company_name VARCHAR(200),
    advertisement_text TEXT,
    advertisement_image TEXT,
    sponsorship_amount DECIMAL(10,2),
    payment_status VARCHAR(20) DEFAULT 'pending',
    start_date DATE,
    end_date DATE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- EXPENSE CATEGORIES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS expense_categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- EXPENSES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS expenses (
    id SERIAL PRIMARY KEY,
    category_id INTEGER NOT NULL REFERENCES expense_categories(id) ON DELETE CASCADE,
    item_name VARCHAR(200) NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    paid_to VARCHAR(200),
    paid_by INTEGER REFERENCES users(id),
    payment_method VARCHAR(20) DEFAULT 'cash',
    receipt_image TEXT,
    notes TEXT,
    expense_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- DRAW TICKETS TABLE (Linked to House Number)
-- ============================================
CREATE TABLE IF NOT EXISTS draw_tickets (
    id SERIAL PRIMARY KEY,
    ticket_code VARCHAR(100) NOT NULL UNIQUE,
    user_id INTEGER REFERENCES users(id),
    house_number VARCHAR(50) REFERENCES users(house_number),
    day_number INTEGER NOT NULL,
    is_assigned BOOLEAN DEFAULT FALSE,
    is_winner BOOLEAN DEFAULT FALSE,
    assigned_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_tickets_day ON draw_tickets(day_number);
CREATE INDEX idx_tickets_user ON draw_tickets(user_id);
CREATE INDEX idx_tickets_house ON draw_tickets(house_number);

-- ============================================
-- NAVRATRI DAYS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS navratri_days (
    id SERIAL PRIMARY KEY,
    day_number INTEGER NOT NULL UNIQUE,
    date DATE NOT NULL,
    goddess_name VARCHAR(100),
    dress_code VARCHAR(200),
    event_schedule TEXT,
    is_active BOOLEAN DEFAULT FALSE,
    is_completed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- DAILY DRAWS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS daily_draws (
    id SERIAL PRIMARY KEY,
    day_number INTEGER NOT NULL,
    draw_number INTEGER NOT NULL,
    winner_ticket_id INTEGER REFERENCES draw_tickets(id),
    winner_user_id INTEGER REFERENCES users(id),
    winner_house_number VARCHAR(50),
    prize_description TEXT,
    drawn_at TIMESTAMP,
    is_completed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- ANNOUNCEMENTS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS announcements (
    id SERIAL PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,
    announcement_type VARCHAR(50) DEFAULT 'general',
    priority INTEGER DEFAULT 1,
    is_active BOOLEAN DEFAULT TRUE,
    created_by INTEGER REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- DAILY SCHEDULES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS daily_schedules (
    id SERIAL PRIMARY KEY,
    day_number INTEGER NOT NULL,
    event_time TIME,
    event_name VARCHAR(200) NOT NULL,
    event_description TEXT,
    location VARCHAR(200),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- BROADCASTS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS broadcasts (
    id SERIAL PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,
    broadcast_type VARCHAR(20) DEFAULT 'text',
    media_url TEXT,
    target_audience VARCHAR(20) DEFAULT 'all',
    sent_by INTEGER REFERENCES users(id),
    sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- VIEWS FOR REPORTS
-- ============================================

-- User Payment Summary View
CREATE OR REPLACE VIEW vw_user_payments AS
SELECT 
    u.house_number,
    u.name,
    u.mobile_number,
    COALESCE(SUM(fc.amount), 0) as total_paid,
    COUNT(fc.id) as payment_count
FROM users u
LEFT JOIN fund_collections fc ON u.house_number = fc.house_number 
    AND fc.payment_status = 'paid'
WHERE u.user_type = 'user'
GROUP BY u.house_number, u.name, u.mobile_number;

-- User Tickets View
CREATE OR REPLACE VIEW vw_user_tickets AS
SELECT 
    u.house_number,
    u.name,
    dt.ticket_code,
    dt.day_number,
    nd.goddess_name,
    nd.date as event_date,
    dt.is_winner,
    dt.assigned_at
FROM users u
JOIN draw_tickets dt ON u.house_number = dt.house_number
JOIN navratri_days nd ON dt.day_number = nd.day_number
ORDER BY u.house_number, dt.day_number;

-- Income Summary View
CREATE OR REPLACE VIEW vw_income_summary AS
SELECT 
    'fund_collection' as source,
    SUM(amount) as total_amount,
    COUNT(*) as transaction_count
FROM fund_collections 
WHERE payment_status = 'paid'
UNION ALL
SELECT 
    'sponsorship' as source,
    SUM(sponsorship_amount) as total_amount,
    COUNT(*) as transaction_count
FROM sponsors 
WHERE payment_status = 'paid';

-- Expense Summary View
CREATE OR REPLACE VIEW vw_expense_summary AS
SELECT 
    c.name as category_name,
    SUM(e.amount) as total_amount,
    COUNT(*) as item_count
FROM expenses e
JOIN expense_categories c ON e.category_id = c.id
GROUP BY c.name;

-- ============================================
-- TRIGGER
-- ============================================

CREATE OR REPLACE FUNCTION update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_users_timestamp
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_timestamp();

-- ============================================
-- INITIAL DATA
-- ============================================

-- Default Organizer
INSERT INTO users (house_number, name, mobile_number, user_type, password)
VALUES ('admin', 'Organizer Admin', '9999999999', 'organizer', 'admin123')
ON CONFLICT (house_number) DO NOTHING;

-- Sample Users
INSERT INTO users (house_number, name, mobile_number, user_type) VALUES
    ('A-402', 'Rajesh Kumar', '9876543210', 'user'),
    ('A-101', 'Priya Sharma', '9876543211', 'user'),
    ('B-205', 'Amit Patel', '9876543212', 'user'),
    ('C-303', 'Sneha Gupta', '9876543213', 'user'),
    ('SP-001', 'Sharma Electronics', '9876543214', 'sponsor')
ON CONFLICT (house_number) DO NOTHING;

-- Default Expense Categories
INSERT INTO expense_categories (name, description) VALUES
    ('Light', 'Lighting and electrical expenses'),
    ('Sound', 'Sound system and music expenses'),
    ('Decoration', 'Decoration and setup expenses'),
    ('Food & Drinks', 'Food and beverages'),
    ('Prizes & Gifts', 'Prizes for winners and gifts'),
    ('Miscellaneous', 'Other expenses')
ON CONFLICT (name) DO NOTHING;

-- Navratri Days 2026
INSERT INTO navratri_days (day_number, date, goddess_name, dress_code) VALUES
    (1, '2026-10-15', 'Shailputri', 'Royal Blue & Bandhani'),
    (2, '2026-10-16', 'Brahmacharini', 'White & Silver'),
    (3, '2026-10-17', 'Chandraghanta', 'Red & Gold'),
    (4, '2026-10-18', 'Kushmanda', 'Green & Yellow'),
    (5, '2026-10-19', 'Skandamata', 'Orange & Pink'),
    (6, '2026-10-20', 'Katyayani', 'Purple & Magenta'),
    (7, '2026-10-21', 'Kalaratri', 'Black & Red'),
    (8, '2026-10-22', 'Mahagauri', 'Peacock Blue'),
    (9, '2026-10-23', 'Siddhidatri', 'Multi-color')
ON CONFLICT (day_number) DO NOTHING;

-- ============================================
-- AARTI SLOTS TABLE (Organizer sets, users book)
-- ============================================
CREATE TABLE IF NOT EXISTS aarti_slots (
    id SERIAL PRIMARY KEY,
    day_number INTEGER NOT NULL REFERENCES navratri_days(day_number),
    slot_time VARCHAR(20) NOT NULL,
    slot_label VARCHAR(100),
    max_participants INTEGER DEFAULT 1,
    current_participants INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_aarti_day ON aarti_slots(day_number);

-- ============================================
-- AARTI BOOKINGS TABLE (User requests to book)
-- ============================================
CREATE TABLE IF NOT EXISTS aarti_bookings (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id),
    house_number VARCHAR(50) NOT NULL,
    day_number INTEGER NOT NULL,
    slot_id INTEGER NOT NULL REFERENCES aarti_slots(id),
    status VARCHAR(20) DEFAULT 'pending',
    notes TEXT,
    approved_by INTEGER REFERENCES users(id),
    approved_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_aarti_bookings_user ON aarti_bookings(user_id);
CREATE INDEX idx_aarti_bookings_status ON aarti_bookings(status);

-- ============================================
-- SNACKS TABLE (Organizer manages items)
-- ============================================
CREATE TABLE IF NOT EXISTS snacks (
    id SERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    price DECIMAL(10,2) DEFAULT 0,
    quantity_available INTEGER DEFAULT 0,
    quantity_sold INTEGER DEFAULT 0,
    is_vegetarian BOOLEAN DEFAULT TRUE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- SNACK ORDERS TABLE (Users order snacks)
-- ============================================
CREATE TABLE IF NOT EXISTS snack_orders (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id),
    house_number VARCHAR(50) NOT NULL,
    snack_id INTEGER NOT NULL REFERENCES snacks(id),
    day_number INTEGER NOT NULL,
    quantity INTEGER DEFAULT 1,
    total_price DECIMAL(10,2),
    status VARCHAR(20) DEFAULT 'pending',
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_snack_orders_user ON snack_orders(user_id);
CREATE INDEX idx_snack_orders_status ON snack_orders(status);

-- ============================================
-- GIFTS TABLE (Daily + Sponsor-based)
-- ============================================
CREATE TABLE IF NOT EXISTS gifts (
    id SERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    sponsor_id INTEGER REFERENCES sponsors(id),
    gift_type VARCHAR(30) NOT NULL,
    day_number INTEGER,
    quantity INTEGER DEFAULT 1,
    quantity_assigned INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_gifts_day ON gifts(day_number);
CREATE INDEX idx_gifts_type ON gifts(gift_type);

-- ============================================
-- GIFT ASSIGNMENTS TABLE (Assign to winners)
-- ============================================
CREATE TABLE IF NOT EXISTS gift_assignments (
    id SERIAL PRIMARY KEY,
    gift_id INTEGER NOT NULL REFERENCES gifts(id),
    user_id INTEGER NOT NULL REFERENCES users(id),
    house_number VARCHAR(50) NOT NULL,
    day_number INTEGER,
    assigned_by INTEGER REFERENCES users(id),
    notes TEXT,
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_gift_assignments_day ON gift_assignments(day_number);
CREATE INDEX idx_gift_assignments_user ON gift_assignments(user_id);

-- ============================================
-- SEED DATA FOR NEW TABLES
-- ============================================

-- Sample aarti slots for Day 1
INSERT INTO aarti_slots (day_number, slot_time, slot_label, max_participants) VALUES
    (1, '19:00', 'Maha Aarti - Slot 1', 5),
    (1, '19:30', 'Maha Aarti - Slot 2', 5),
    (1, '20:00', 'Aarti - Slot 3', 10),
    (2, '19:00', 'Maha Aarti - Slot 1', 5),
    (2, '19:30', 'Maha Aarti - Slot 2', 5)
ON CONFLICT DO NOTHING;

-- Sample snacks
INSERT INTO snacks (name, description, price, quantity_available, is_vegetarian) VALUES
    ('Samosa (2 pcs)', 'Crispy samosas with mint chutney', 30.00, 100, TRUE),
    ('Dahi Vada', 'Soft vadas in spiced yogurt', 40.00, 50, TRUE),
    ('Chaat', 'Tangy street food mix', 35.00, 60, TRUE),
    ('Jalebi', 'Hot crispy jalebis', 25.00, 80, TRUE),
    ('Masala Chai', 'Hot spiced tea', 15.00, 200, TRUE),
    ('Cold Drink', 'Packaged cold drinks', 20.00, 150, TRUE)
ON CONFLICT DO NOTHING;

-- Sample gifts
INSERT INTO gifts (name, description, gift_type, day_number, quantity) VALUES
    ('Brass Diya Set', 'Traditional brass diya set', 'daily', 1, 3),
    ('Dry Fruit Box', 'Premium dry fruit collection', 'daily', 1, 5),
    ('Silver Coin', '5gm silver coin', 'sponsor', 1, 2),
    ('Bamboo Basket', 'Handcrafted bamboo basket', 'daily', 2, 3),
    ('Idol of Goddess', 'Small goddess idol', 'daily', 3, 2)
ON CONFLICT DO NOTHING;
