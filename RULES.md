# Project Rules - Navratri App

## Developer Password Lock (MANDATORY)
**Password: rahUl@2412**

Before ANY modification to these protected areas, I MUST ask for and verify the password:
- `lib/screens/user/` (ALL user UI screens)
- `lib/screens/organizer/` (ALL organizer UI screens)
- `lib/providers/auth_provider.dart`
- `lib/database/database_helper.dart`
- `lib/main.dart` (routing changes)
- `api_server/bin/main.dart` (API logic changes)

**Rule**: If user asks to change anything in the above files/folders:
1. FIRST ask: "Please enter the developer password to proceed"
2. ONLY proceed if password matches `rahUl@2412`
3. If password is wrong, DO NOT make the change and inform user
4. This applies to ALL changes: bug fixes, new features, UI tweaks, logic changes

## Before Every Task
1. **Check current state** - Verify files, database, and servers are in expected state
2. **Read relevant files** - Understand context before making changes
3. **Confirm approach** - Plan the modification before executing

## After Every Modification
1. **Verify change worked** - Check if the modification compiles/works
2. **Test if possible** - Run relevant commands or check output
3. **Confirm to user** - State what was done and the result

## Database Changes
1. **Before**: Check current schema/data
2. **During**: Make changes in correct order (foreign keys)
3. **After**: Verify with query and update clean_database.bat if needed

## Code Changes
1. **Before**: Read the file and understand context
2. **During**: Follow existing code patterns
3. **After**: Check for compile errors, run build if needed

## Communication
- Always state what I'm about to do before doing it
- Confirm success or report errors clearly
- Ask for clarification if unsure about requirements
