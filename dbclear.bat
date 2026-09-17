@echo off
title Navratri 2026 - DB Clear (User Entries Only)
color 0C
echo ============================================================
echo   NAVRATRI 2026 - DATABASE CLEAR (User Entries Only)
echo ============================================================
echo.
echo This will REMOVE all user-made entries but KEEP:
echo   - Users table (all logins safe)
echo   - Navratri Days (goddess, dress codes, dates)
echo   - Aarti Slots (slot definitions)
echo   - Expense Categories
echo   - Snacks (menu items)
echo   - Gifts (catalog)
echo   - Table structures, API endpoints, site logic
echo.
echo Entries to be REMOVED:
echo   - Fund Collections (payments)
echo   - Expenses
echo   - Aarti Bookings
echo   - Snack Orders (distributions)
echo   - Gift Assignments (distributions)
echo   - Draw Tickets (generated)
echo   - Daily Draws (lucky draw history)
echo   - Song Requests
echo   - Song Suggestions
echo   - Song Upvotes
echo   - Shoutouts
echo   - Shoutout Reactions
echo   - Announcements
echo   - Broadcasts
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
echo Clearing user entries...

"C:\Program Files\PostgreSQL\18\bin\psql.exe" -U postgres -d navratri_2026 -c "TRUNCATE TABLE shoutout_reactions CASCADE; TRUNCATE TABLE shoutouts CASCADE; TRUNCATE TABLE song_upvotes CASCADE; TRUNCATE TABLE song_suggestions CASCADE; TRUNCATE TABLE song_requests CASCADE; TRUNCATE TABLE daily_draws CASCADE; TRUNCATE TABLE draw_tickets CASCADE; TRUNCATE TABLE gift_assignments CASCADE; TRUNCATE TABLE snack_orders CASCADE; TRUNCATE TABLE aarti_bookings CASCADE; TRUNCATE TABLE expenses CASCADE; TRUNCATE TABLE fund_collections CASCADE; TRUNCATE TABLE broadcasts CASCADE; TRUNCATE TABLE announcements CASCADE; TRUNCATE TABLE daily_schedules CASCADE; TRUNCATE TABLE sponsors CASCADE;"

if %errorlevel% equ 0 (
    echo.
    echo ============================================================
    echo   SUCCESS! All user entries cleared.
    echo ============================================================
    echo.
    echo   SAFE (still working):
    echo     - Login (all users preserved)
    echo     - Day schedule (goddess, dress codes)
    echo     - Aarti slot definitions
    echo     - Snack menu items
    echo     - Gift catalog
    echo     - Expense categories
    echo.
    echo   EMPTY (cleared, ready for new data):
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
