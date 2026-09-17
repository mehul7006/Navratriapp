@echo off
title Navratri 2026 - DB Clear (User Entries Only)
color 0C
echo ============================================================
echo   NAVRATRI 2026 - DATABASE CLEAR (User Entries Only)
echo ============================================================
echo.
echo This will REMOVE all user-made entries and preset data:
echo.
echo KEPT (safe):
echo   - Navratri Days (goddess, dress codes, dates)
echo   - Expense Categories
echo   - Admin/S-Admin/U-Admin logins only
echo   - Table structures, API endpoints, site logic
echo.
echo REMOVED:
echo   - All users EXCEPT admin, SP-ADMIN, U-ADMIN
echo   - Aarti Slots (per day booking, no preset slots)
echo   - Snacks (direct distribution, no preset menu)
echo   - Fund Collections (payments)
echo   - Expenses
echo   - Aarti Bookings
echo   - Snack Orders (distributions)
echo   - Gift Assignments (distributions)
echo   - Draw Tickets (generated)
echo   - Daily Draws (lucky draw history)
echo   - Song Requests / Suggestions / Upvotes
echo   - Shoutouts / Reactions
echo   - Announcements / Broadcasts
echo   - Daily Schedules
echo   - Sponsors
echo.
echo ============================================================
echo   WARNING: This CANNOT be undone!
echo ============================================================
echo.
set /p confirm="Type YES to confirm: "
if /I not "%confirm%"=="YES" (
    echo Cancelled.
    pause
    exit /b
)
echo.
echo Step 1: Removing all users except admin, SP-ADMIN, U-ADMIN...
"C:\Program Files\PostgreSQL\18\bin\psql.exe" -U postgres -d navratri_2026 -c "DELETE FROM users WHERE house_number NOT IN ('admin', 'SP-ADMIN', 'U-ADMIN');"

echo Step 2: Clearing Aarti Slots (no preset slots)...
"C:\Program Files\PostgreSQL\18\bin\psql.exe" -U postgres -d navratri_2026 -c "TRUNCATE TABLE aarti_bookings CASCADE; TRUNCATE TABLE aarti_slots CASCADE;"

echo Step 3: Clearing Snacks (direct distribution, no preset menu)...
"C:\Program Files\PostgreSQL\18\bin\psql.exe" -U postgres -d navratri_2026 -c "TRUNCATE TABLE snack_orders CASCADE; TRUNCATE TABLE snacks CASCADE;"

echo Step 4: Clearing all remaining user entries...
"C:\Program Files\PostgreSQL\18\bin\psql.exe" -U postgres -d navratri_2026 -c "TRUNCATE TABLE shoutout_reactions CASCADE; TRUNCATE TABLE shoutouts CASCADE; TRUNCATE TABLE song_upvotes CASCADE; TRUNCATE TABLE song_suggestions CASCADE; TRUNCATE TABLE song_requests CASCADE; TRUNCATE TABLE daily_draws CASCADE; TRUNCATE TABLE draw_tickets CASCADE; TRUNCATE TABLE gift_assignments CASCADE; TRUNCATE TABLE expenses CASCADE; TRUNCATE TABLE fund_collections CASCADE; TRUNCATE TABLE broadcasts CASCADE; TRUNCATE TABLE announcements CASCADE; TRUNCATE TABLE daily_schedules CASCADE; TRUNCATE TABLE sponsors CASCADE;"

if %errorlevel% equ 0 (
    echo.
    echo ============================================================
    echo   SUCCESS! Database cleared.
    echo ============================================================
    echo.
    echo   PRESERVED:
    echo     - Admin logins: admin, SP-ADMIN, U-ADMIN
    echo     - Navratri Days (10 days, goddess, dress codes)
    echo     - Expense Categories (7)
    echo     - All table structures and API endpoints
    echo.
    echo   CLEARED (0 rows):
    echo     - Users: only admin/SP-ADMIN/U-ADMIN remain
    echo     - Aarti Slots: 0 (user adds per day)
    Snacks: 0 (user distributes directly)
    echo     - Payments: 0
    echo     - Expenses: 0
    echo     - Aarti Bookings: 0
    echo     - Snack Orders: 0
    echo     - Gift Assignments: 0
    echo     - Draw Tickets: 0
    echo     - Lucky Draw History: 0
    echo     - Songs: 0
    echo     - Shoutouts: 0
    echo     - Announcements: 0
    echo     - Broadcasts: 0
    echo     - Schedule Events: 0
    echo.
) else (
    echo.
    echo ERROR: Failed to clear database. Check PostgreSQL is running.
    echo.
)
pause
