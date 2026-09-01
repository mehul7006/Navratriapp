---
name: cancel-prize-redraw
status: backlog
created: 2026-09-02T00:17:00Z
progress: 0%
prd: .claude/prds/cancel-prize-redraw.md
github: (will be set on sync)
---

# Epic: Cancel Prize & Re-draw

## Overview
This epic implements the ability for organizers to cancel winning prizes and re-draw for the same prize level. It maintains an audit trail of cancellations and follows the same availability rules as the original draw process.

## Architecture Decisions
1. **Status-based approach**: Use existing `status` column with new 'cancelled' value
2. **Audit trail**: Add `cancelled_reason` and `cancelled_at` columns for tracking
3. **Re-draw mechanism**: Reuse existing draw creation with prize level targeting
4. **UI consistency**: Same dialog pattern as availability check

## Technical Approach

### Frontend Components
1. **Lucky Draw Screen modifications:**
   - Add "Cancel Prize" button after winner confirmation
   - Add cancellation dialog with reason input
   - Add "Re-draw" button after cancellation
   - Update draw history to show cancelled status

2. **Ticket Management Screen modifications:**
   - Add "Cancel Prize" button for winning tickets
   - Reuse same dialog component
   - Update ticket status display

3. **Shared Components:**
   - Cancellation dialog widget (reusable)
   - Prize level badge component (already exists)

### Backend Services
1. **Database changes:**
   - Add `cancelled_reason` TEXT column
   - Add `cancelled_at` TIMESTAMP column
   - Update status enum to include 'cancelled'

2. **API endpoints:**
   - `POST /api/daily-draws/cancel` - Cancel a draw
   - Modify `POST /api/daily-draws/create` to support prize level targeting

3. **DatabaseHelper methods:**
   - `cancelDraw(int drawId, String reason)` - Cancel a draw
   - `createDrawForPrizeLevel(...)` - Create draw for specific prize level

### Infrastructure
- No infrastructure changes required
- Uses existing database and API server

## Implementation Strategy
1. **Phase 1: Database & API** (No UI changes)
   - Add new columns to daily_draws table
   - Add cancel API endpoint
   - Add DatabaseHelper methods
   - Test API independently

2. **Phase 2: Lucky Draw Screen** (Core functionality)
   - Add cancel button and dialog
   - Add re-draw functionality
   - Update draw history display
   - Test complete flow

3. **Phase 3: Ticket Management** (Secondary location)
   - Add cancel button to winning tickets
   - Reuse dialog component
   - Update status display
   - Test both locations work

4. **Phase 4: Verification** (Full testing)
   - Test cancel → re-draw flow
   - Verify winner updates everywhere
   - Check audit trail
   - Ensure no regressions

## Task Breakdown Preview
1. Add database columns (cancelled_reason, cancelled_at)
2. Add cancel API endpoint
3. Add DatabaseHelper.cancelDraw method
4. Modify Lucky Draw screen - add cancel button
5. Create cancellation dialog component
6. Add re-draw functionality to Lucky Draw
7. Update Ticket Management screen
8. Update draw history display
9. Test complete flow
10. Verify all displays update correctly

## Dependencies
- Existing daily_draws table structure
- Existing API endpoints
- Existing Lucky Draw and Ticket Management screens
- Existing UI components (dialogs, buttons)

## Success Criteria (Technical)
- [ ] Database schema updated with new columns
- [ ] Cancel API endpoint working
- [ ] Cancel button visible in Lucky Draw screen
- [ ] Cancel button visible in Ticket Management screen
- [ ] Cancellation dialog requires reason
- [ ] Re-draw works after cancellation
- [ ] Winner name updates in all displays
- [ ] Draw history shows cancelled status
- [ ] No breaking changes to existing features

## Estimated Effort
- **Phase 1:** 2-3 hours (Database + API)
- **Phase 2:** 3-4 hours (Lucky Draw screen)
- **Phase 3:** 2-3 hours (Ticket Management)
- **Phase 4:** 1-2 hours (Testing + verification)
- **Total:** 8-12 hours
