# Organizer Developer Lock

## Purpose
Protect organizer code files from accidental modification during development.

## How It Works
1. `config.json` lists all protected organizer files
2. Before modifying any organizer file, developer must enter password
3. After modification, change must be logged in `CHANGELOG.md`

## Protected Files
All organizer screens, database_helper.dart, and api_server main.dart.

## Password
Stored in `config.json` - ask the project owner for the password.

## Rules
- **Before modifying:** Verify password with project owner
- **After modifying:** Log in CHANGELOG.md with date, file, what/why/impact
- **Wrong password:** Do NOT modify the file

## For AI Assistant (opencode)
When user asks to modify any organizer protected file:
1. Check `config.json` for the protected file list
2. Ask user for password
3. If password matches, proceed with modification
4. Log the change in `CHANGELOG.md`
5. If password is wrong, refuse the modification
