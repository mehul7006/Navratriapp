#!/bin/bash

# ==============================================================================
# NAVRATRI 2026 - EC2 setup & run script
# --------------------------------------
# No nginx. No ngrok. No "systemctl postgresql" handling here.
# YOU install PostgreSQL yourself. This script then:
#   [1/3] sets DB credentials (postgres/navratri) + creates database if missing
#   [2/3] boots the API server (it runs every schema migration on boot,
#         so the schema is always migrated "till today")
#   [3/3] seeds baseline data (10 days, organizer admin, expense categories)
#         + verifies counts and API health
# Idempotent: safe to re-run any time. Re-runs never duplicate data.
# ==============================================================================

API_DIR="$HOME/navratri_app/api_server"
LOG_DIR="$HOME/navratri_app/logs"
DART_BIN="dart"

DB_HOST="localhost"
DB_PORT="5432"
DB_NAME="navratri_2026"
DB_USER="postgres"
DB_PASS="navratri"
API_PORT="8080"

mkdir -p "$LOG_DIR"

# Fail fast when the repo is not where the script expects it.
# Also auto-detects a plain `git clone <url>` checkout (~/Navratriapp).
check_paths() {
    for candidate in "$API_DIR" "$HOME/Navratriapp/api_server" "$HOME/navratriapp/api_server"; do
        if [ -f "$candidate/bin/main.dart" ]; then
            if [ "$candidate" != "$API_DIR" ]; then
                echo "        (found API project at $candidate - using it)"
                API_DIR="$candidate"
            fi
            return 0
        fi
    done
    echo " [FAIL] API project not found (looked in $API_DIR, ~/Navratriapp, ~/navratriapp)."
    echo "        Clone it first, e.g.:"
    echo "          git clone <your-repo-url> $HOME/navratri_app"
    return 1
}

need_cmd() {
    command -v "$1" >/dev/null 2>&1 || { echo " [FAIL] '$1' not found. Install it first, then re-run."; exit 1; }
}
need_cmd psql
need_cmd pg_isready
need_cmd curl
need_cmd "$DART_BIN"

# NOTE: all `sudo -u postgres psql` calls below deliberately use the local
# Unix socket (peer auth) with NO -h flag. `sudo` strips PGPASSWORD, so TCP
# connections would prompt for a password. Do not add -h back.
export PGPASSWORD="$DB_PASS"

# ------------------------------------------------------------------ step 1: DB
setup_db() {
    echo " [1/4] DB credentials + database..."
    if ! pg_isready -h "$DB_HOST" -p "$DB_PORT" >/dev/null 2>&1; then
        echo " [FAIL] PostgreSQL not reachable at $DB_HOST:$DB_PORT."
        echo "        Install PostgreSQL first, then re-run this script."
        return 1
    fi
    echo "        [OK] PostgreSQL reachable."

    sudo -u postgres psql -v ON_ERROR_STOP=1 \
        -c "ALTER USER $DB_USER PASSWORD '$DB_PASS';"
    echo "        [OK] password set for user '$DB_USER'."

    local exists
    exists=$(sudo -u postgres psql -tAc \
        "SELECT 1 FROM pg_database WHERE datname = '$DB_NAME'")
    if [ "$exists" != "1" ]; then
        sudo -u postgres psql -v ON_ERROR_STOP=1 \
            -c "CREATE DATABASE $DB_NAME;"
        echo "        [OK] database '$DB_NAME' created."
    else
        echo "        [OK] database '$DB_NAME' already present."
    fi
}

# ------------------------------------------------------------------ schema
# Fresh databases have NO tables and the API's first migration ALTERs a
# table that doesn't exist yet (one shared try/catch swallows it), so the
# API alone can never bootstrap a fresh DB. Create the core schema first.
bootstrap_schema() {
    echo " [2/4] Core schema (16 tables + timestamp trigger)..."
    local have
    have=$(sudo -u postgres psql -d "$DB_NAME" -tAc \
        "SELECT COUNT(*) FROM pg_tables WHERE schemaname = 'public' AND tablename IN
         ('users','navratri_days','fund_collections','expenses','expense_categories',
          'aarti_slots','aarti_bookings','snacks','snack_orders','gifts',
          'gift_assignments','sponsors','draw_tickets','broadcasts',
          'announcements','daily_schedules');")
    if [ "$have" = "16" ]; then
        echo "        [OK] core schema already present, skipping."
        return 0
    fi
    if [ ! -f "$API_DIR/schema/bootstrap.sql" ]; then
        echo " [FAIL] schema file missing: $API_DIR/schema/bootstrap.sql"
        echo "        git pull the latest code, then re-run."
        return 1
    fi
    sudo -u postgres psql -d "$DB_NAME" -v ON_ERROR_STOP=1 \
        -f "$API_DIR/schema/bootstrap.sql" > /dev/null
    echo "        [OK] core schema created."
}

# ------------------------------------------------------------------ step 3: API
# Wait up to ~2 min for the API (first boot runs `pub get` + migrations).
wait_for_api() {
    local i
    for i in $(seq 1 24); do
        if curl -s "http://localhost:$API_PORT/api/daily-info" >/dev/null 2>&1; then
            return 0
        fi
        sleep 5
    done
    return 1
}
start_api() {
    echo " [3/4] Starting API server (port $API_PORT, runs remaining migrations)..."
    export PG_HOST="$DB_HOST" PG_PORT="$DB_PORT" PG_DATABASE="$DB_NAME"
    export PG_USER="$DB_USER" PG_PASSWORD="$DB_PASS"
    pkill -f "dart run bin/main.dart" 2>/dev/null
    sleep 1
    if ! cd "$API_DIR"; then
        echo " [FAIL] cannot enter $API_DIR"
        return 1
    fi
    "$DART_BIN" pub get >/dev/null 2>&1
    PG_HOST="$DB_HOST" PG_PORT="$DB_PORT" PG_DATABASE="$DB_NAME" \
    PG_USER="$DB_USER" PG_PASSWORD="$DB_PASS" \
    nohup "$DART_BIN" run bin/main.dart "$API_PORT" > "$LOG_DIR/api.log" 2>&1 &
    echo "        Waiting for API (migrations running, first boot is slow)..."
    if wait_for_api; then
        echo "        [OK] API up, schema migrated."
    else
        echo "        [FAIL] API did not come up. Last log lines:"
        tail -n 15 "$LOG_DIR/api.log" 2>/dev/null || echo "        (no log yet)"
        return 1
    fi
}

# ------------------------------------------------------------------ step 4: seed
seed_db() {
    echo " [4/4] Seeding baseline data (skips what already exists)..."
    sudo -u postgres psql -d "$DB_NAME" \
        -v ON_ERROR_STOP=1 <<'SEED_EOF'
-- 10 festival days (Day 1 = 11 Oct 2026 ... Day 10 Dussehra = 20 Oct 2026)
INSERT INTO navratri_days (day_number, date, goddess_name, dress_code, is_active, is_completed, max_winners)
SELECT 1, '2026-10-11 05:30:00', 'Shailputri', 'Royal Blue & Bandhani', TRUE, FALSE, 3
WHERE NOT EXISTS (SELECT 1 FROM navratri_days WHERE day_number = 1);
INSERT INTO navratri_days (day_number, date, goddess_name, dress_code, is_active, is_completed, max_winners)
SELECT 2, '2026-10-12 05:30:00', 'Brahmacharini', 'White & Silver', FALSE, FALSE, 3
WHERE NOT EXISTS (SELECT 1 FROM navratri_days WHERE day_number = 2);
INSERT INTO navratri_days (day_number, date, goddess_name, dress_code, is_active, is_completed, max_winners)
SELECT 3, '2026-10-13 05:30:00', 'Chandraghanta', 'Red & Gold', FALSE, FALSE, 3
WHERE NOT EXISTS (SELECT 1 FROM navratri_days WHERE day_number = 3);
INSERT INTO navratri_days (day_number, date, goddess_name, dress_code, is_active, is_completed, max_winners)
SELECT 4, '2026-10-14 05:30:00', 'Kushmanda', 'Green & Yellow', FALSE, FALSE, 3
WHERE NOT EXISTS (SELECT 1 FROM navratri_days WHERE day_number = 4);
INSERT INTO navratri_days (day_number, date, goddess_name, dress_code, is_active, is_completed, max_winners)
SELECT 5, '2026-10-15 05:30:00', 'Skandamata', 'Orange & Pink', FALSE, FALSE, 3
WHERE NOT EXISTS (SELECT 1 FROM navratri_days WHERE day_number = 5);
INSERT INTO navratri_days (day_number, date, goddess_name, dress_code, is_active, is_completed, max_winners)
SELECT 6, '2026-10-16 05:30:00', 'Katyayani', 'Purple & Magenta', FALSE, FALSE, 3
WHERE NOT EXISTS (SELECT 1 FROM navratri_days WHERE day_number = 6);
INSERT INTO navratri_days (day_number, date, goddess_name, dress_code, is_active, is_completed, max_winners)
SELECT 7, '2026-10-17 05:30:00', 'Kalaratri', 'Black & Red', FALSE, FALSE, 3
WHERE NOT EXISTS (SELECT 1 FROM navratri_days WHERE day_number = 7);
INSERT INTO navratri_days (day_number, date, goddess_name, dress_code, is_active, is_completed, max_winners)
SELECT 8, '2026-10-18 05:30:00', 'Mahagauri', 'Peacock Blue', FALSE, FALSE, 3
WHERE NOT EXISTS (SELECT 1 FROM navratri_days WHERE day_number = 8);
INSERT INTO navratri_days (day_number, date, goddess_name, dress_code, is_active, is_completed, max_winners)
SELECT 9, '2026-10-19 05:30:00', 'Siddhidatri', 'Multi-color', FALSE, FALSE, 3
WHERE NOT EXISTS (SELECT 1 FROM navratri_days WHERE day_number = 9);
INSERT INTO navratri_days (day_number, date, goddess_name, dress_code, is_active, is_completed, max_winners)
SELECT 10, '2026-10-20 05:30:00', 'Dussehra', 'Celebration Colors', FALSE, FALSE, 3
WHERE NOT EXISTS (SELECT 1 FROM navratri_days WHERE day_number = 10);
-- organizer login (admin / admin123)
INSERT INTO users (house_number, name, mobile_number, user_type, member_type, is_active, password)
SELECT 'admin', 'Organizer Admin', '9999999999', 'organizer', 'main', TRUE, 'admin123'
WHERE NOT EXISTS (SELECT 1 FROM users WHERE house_number = 'admin' AND user_type = 'organizer');
-- expense categories
INSERT INTO expense_categories (name, description, is_active)
SELECT 'Light', 'Lighting and electrical expenses', TRUE
WHERE NOT EXISTS (SELECT 1 FROM expense_categories WHERE name = 'Light');
INSERT INTO expense_categories (name, description, is_active)
SELECT 'Sound', 'Sound system and music expenses', TRUE
WHERE NOT EXISTS (SELECT 1 FROM expense_categories WHERE name = 'Sound');
INSERT INTO expense_categories (name, description, is_active)
SELECT 'Decoration', 'Decoration and setup expenses', TRUE
WHERE NOT EXISTS (SELECT 1 FROM expense_categories WHERE name = 'Decoration');
INSERT INTO expense_categories (name, description, is_active)
SELECT 'Food & Drinks', 'Food and beverages', TRUE
WHERE NOT EXISTS (SELECT 1 FROM expense_categories WHERE name = 'Food & Drinks');
INSERT INTO expense_categories (name, description, is_active)
SELECT 'Prizes & Gifts', 'Prizes for winners and gifts', TRUE
WHERE NOT EXISTS (SELECT 1 FROM expense_categories WHERE name = 'Prizes & Gifts');
INSERT INTO expense_categories (name, description, is_active)
SELECT 'Miscellaneous', 'Other expenses', TRUE
WHERE NOT EXISTS (SELECT 1 FROM expense_categories WHERE name = 'Miscellaneous');
INSERT INTO expense_categories (name, description, is_active)
SELECT 'Sponsor Expense', 'Sponsored distributions', TRUE
WHERE NOT EXISTS (SELECT 1 FROM expense_categories WHERE name = 'Sponsor Expense');
SEED_EOF
    echo "        [OK] seeds applied."
}

# ------------------------------------------------------------------ verify
verify_all() {
    echo " Verifying..."
    local days admins cats
    days=$(sudo -u postgres psql -d "$DB_NAME" -tAc \
        "SELECT COUNT(*) FROM navratri_days;")
    admins=$(sudo -u postgres psql -d "$DB_NAME" -tAc \
        "SELECT COUNT(*) FROM users WHERE user_type = 'organizer';")
    cats=$(sudo -u postgres psql -d "$DB_NAME" -tAc \
        "SELECT COUNT(*) FROM expense_categories;")
    echo "        days=$days (expect 10)  organizers=$admins (expect >=1)  categories=$cats (expect >=7)"
    if [ "$days" = "10" ] && [ "$admins" -ge 1 ] 2>/dev/null; then
        echo "        [OK] database ready."
    else
        echo "        [FAIL] counts look wrong - inspect manually."
        return 1
    fi
    if curl -s "http://localhost:$API_PORT/api/daily-info" >/dev/null 2>&1; then
        echo "        [OK] API health OK."
    else
        echo "        [WARN] API health check failed."
        return 1
    fi
}

start_app() {
    clear
    echo "============================================"
    echo "   NAVRATRI 2026 - NISHPARK SOCIETY (EC2)   "
    echo "============================================"
    echo ""
    check_paths || { show_menu; return; }
    setup_db || { show_menu; return; }
    echo ""
    bootstrap_schema || { show_menu; return; }
    echo ""
    start_api || { show_menu; return; }
    echo ""
    seed_db
    echo ""
    verify_all
    echo ""
    show_menu
}

show_menu() {
    echo ""
    echo "============================================"
    echo ""
    echo "  Local:   http://localhost:$API_PORT"
    echo ""
    echo "============================================"
    echo ""
    echo "  COMMANDS:"
    echo "    R  = Hot Restart  (restart API server only, re-runs migrations)"
    echo "    L  = Show API logs"
    echo "    S  = Show status"
    echo "    Q  = Quit (stop API)"
    echo ""
    echo "============================================"
    echo ""
    handle_input
}

handle_input() {
    read -p "  > " CHOICE
    CHOICE=$(echo "$CHOICE" | tr '[:lower:]' '[:upper:]')

    case "$CHOICE" in
        "R")
            echo ""
            echo " Hot restarting API server..."
            export PG_HOST="$DB_HOST" PG_PORT="$DB_PORT" PG_DATABASE="$DB_NAME"
            export PG_USER="$DB_USER" PG_PASSWORD="$DB_PASS"
            pkill -f "dart run bin/main.dart" 2>/dev/null
            sleep 1
            if ! cd "$API_DIR"; then
                echo " [FAIL] cannot enter $API_DIR"
                echo ""
                handle_input
                return
            fi
            PG_HOST="$DB_HOST" PG_PORT="$DB_PORT" PG_DATABASE="$DB_NAME" \
            PG_USER="$DB_USER" PG_PASSWORD="$DB_PASS" \
            nohup "$DART_BIN" run bin/main.dart "$API_PORT" > "$LOG_DIR/api.log" 2>&1 &
            if wait_for_api; then
                echo " [OK] API + DB reconnected!"
            else
                echo " [WARN] API not ready yet - check logs (L)..."
            fi
            echo ""
            handle_input
            ;;

        "L")
            echo ""
            echo " === API LOGS (last 20 lines) ==="
            if [ -f "$LOG_DIR/api.log" ]; then
                tail -n 20 "$LOG_DIR/api.log"
            else
                echo " No logs yet."
            fi
            echo ""
            handle_input
            ;;

        "S")
            echo ""
            echo " === STATUS ==="
            pg_isready -h "$DB_HOST" -p "$DB_PORT" >/dev/null 2>&1 \
                && echo " [OK] PostgreSQL: RUNNING" \
                || echo " [OFF] PostgreSQL: STOPPED"
            pgrep -f "dart run bin/main.dart" >/dev/null \
                && echo " [OK] API Server: RUNNING" \
                || echo " [OFF] API Server: STOPPED"
            curl -s "http://localhost:$API_PORT/api/daily-info" >/dev/null 2>&1 \
                && echo " [OK] API Health: OK" \
                || echo " [OFF] API Health: FAIL"
            echo ""
            handle_input
            ;;

        "Q")
            stop_app
            ;;

        *)
            echo " Unknown command. Use R, L, S, or Q."
            handle_input
            ;;
    esac
}

stop_app() {
    echo ""
    echo " Stopping API server..."
    pkill -f "dart run bin/main.dart" 2>/dev/null
    sleep 2
    echo " Done. (PostgreSQL left running.)"
    echo "============================================"
    exit 0
}

# Initial Boot
start_app
