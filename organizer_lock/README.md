# Organizer Developer Lock - FROZEN

## Status: LOCKED (2026-09-11)
## Password: rahUl@2412

## Purpose
Protect organizer code from ANY modification without authorization.

## How It Works

### Before ANY Change (CLI Step):
```
1. User asks to modify organizer file
2. AI reads organizer_lock/config.json
3. AI checks if file is in protected_files list
4. AI STOPS and asks: "Enter password to modify organizer code"
5. User enters password
6. If password == 'rahUl@2412' → proceed
7. If password != 'rahUl@2412' → REFUSE
```

### After Change (Mandatory Log):
Every change MUST be logged in `organizer_lock/CHANGELOG.md` with:
- **Date/Time** of change
- **File Changed** - exact file path
- **Password Used** - confirm password was entered
- **What Changed** - exact description
- **Why Changed** - reason for change
- **Affected Functions** - list all modified functions/methods
- **Affected UI Elements** - list all UI widgets/screens affected
- **Impact on Organizer** - how this affects organizer workflow
- **Risk Level** - Low/Medium/High
- **Before** - what the code looked like
- **After** - what the code looks like now

### Rules - ZERO EXCEPTIONS
- **Even 1 character change** → password required
- **Even "small fix"** → password required
- **Even "just style change"** → password required
- **Even "just add comment"** → password required
- **No workarounds** → password or nothing

## Protected Files (21)
All organizer screens + database_helper.dart + api_server main.dart

## For AI Assistant (opencode)
When user asks to modify ANY organizer file:
1. Read `organizer_lock/config.json`
2. Check if file is in protected_files list
3. **STOP** - ask user for password
4. **WAIT** for password answer
5. If password == `rahUl@2412` → proceed
6. If password wrong → **REFUSE** completely
7. After modification → **LOG** in CHANGELOG.md with full details
8. **RE-LOCK** after logging

## Affected Functions Checklist (for logging)
When logging a change, ALWAYS check and list:
- [ ] Does this affect login flow?
- [ ] Does this affect dashboard display?
- [ ] Does this affect aarti booking?
- [ ] Does this affect snack distribution?
- [ ] Does this affect gift distribution?
- [ ] Does this affect member management?
- [ ] Does this affect lucky draw?
- [ ] Does this affect day management?
- [ ] Does this affect expense tracking?
- [ ] Does this affect reports?
- [ ] Does this affect other screens?
- [ ] Does this affect database queries?
- [ ] Does this affect API endpoints?
