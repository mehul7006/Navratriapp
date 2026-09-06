@echo off
echo ============================================
echo  Navratri App - Database Reset
echo  Saves current state, cleans, restores it
echo ============================================
echo.
set /p confirm="Type YES to confirm: "
if /i not "%confirm%"=="YES" (
    echo Cancelled.
    pause
    exit /b
)

set PGPASSWORD=postgres

echo.
echo Step 1: Saving current database state...

"C:\Program Files\PostgreSQL\17\bin\pg_dump.exe" -U postgres -d navratri_2026 --data-only --disable-triggers -f "%~dp0database_default.sql"

if %ERRORLEVEL% neq 0 (
    echo ERROR: Failed to save database state.
    pause
    exit /b
)

echo.
echo Step 2: Deleting ALL data...

"C:\Program Files\PostgreSQL\17\bin\psql.exe" -U postgres -d navratri_2026 -c "
-- Delete ALL data (order matters for foreign keys)
DELETE FROM song_upvotes;
DELETE FROM song_suggestions;
DELETE FROM song_requests;
DELETE FROM shoutout_reactions;
DELETE FROM shoutouts;
DELETE FROM snack_orders;
DELETE FROM gift_assignments;
DELETE FROM gifts;
DELETE FROM snacks;
DELETE FROM aarti_bookings;
DELETE FROM draw_tickets;
DELETE FROM daily_draws;
DELETE FROM expenses;
DELETE FROM fund_collections;
DELETE FROM broadcasts;
DELETE FROM announcements;
DELETE FROM sponsors;
DELETE FROM users;

-- Reset sequences
ALTER SEQUENCE users_id_seq RESTART WITH 100;
ALTER SEQUENCE aarti_bookings_id_seq RESTART WITH 1;
ALTER SEQUENCE gift_assignments_id_seq RESTART WITH 1;
ALTER SEQUENCE snack_orders_id_seq RESTART WITH 1;
ALTER SEQUENCE draw_tickets_id_seq RESTART WITH 1;
ALTER SEQUENCE daily_draws_id_seq RESTART WITH 1;
ALTER SEQUENCE expenses_id_seq RESTART WITH 1;
ALTER SEQUENCE fund_collections_id_seq RESTART WITH 1;
ALTER SEQUENCE shoutouts_id_seq RESTART WITH 1;
ALTER SEQUENCE announcements_id_seq RESTART WITH 1;
ALTER SEQUENCE sponsors_id_seq RESTART WITH 1;
ALTER SEQUENCE gifts_id_seq RESTART WITH 1;
ALTER SEQUENCE snacks_id_seq RESTART WITH 1;
"

if %ERRORLEVEL% neq 0 (
    echo ERROR: Cleanup failed.
    pause
    exit /b
)

echo.
echo Step 3: Restoring saved state...

"C:\Program Files\PostgreSQL\17\bin\psql.exe" -U postgres -d navratri_2026 -f "%~dp0database_default.sql"

if %ERRORLEVEL%==0 (
    echo.
    echo SUCCESS: Database reset to current state!
) else (
    echo ERROR: Restore failed.
)

echo.
pause
