---
name: cancel-prize-redraw
description: Allow organizer to cancel winning prizes and re-draw for the same prize level
status: backlog
created: 2026-09-02T00:16:00Z
---

# PRD: Cancel Prize & Re-draw

## Executive Summary
Organizers need the ability to cancel a winning prize from the draw ticket section and re-draw for that same prize level. This handles cases where a winner is unavailable after confirmation, or the organizer wants to give the prize to someone else. The cancellation maintains an audit trail and follows the same availability rules as the original draw.

## Problem Statement
Currently, once a prize is confirmed for a winner, there's no way to undo this action. If a winner becomes unavailable after confirmation, or the organizer decides to give the prize to someone else, there's no mechanism to handle this. This creates a rigid system that doesn't account for real-world scenarios where prize assignments need to change.

## User Stories

### Story 1: Cancel Prize from Lucky Draw Screen
**As an** organizer  
**I want to** cancel a winning prize from the Lucky Draw screen after it's been confirmed  
**So that** I can re-draw for that prize level if the winner is unavailable or needs to be replaced

**Acceptance Criteria:**
- After a winner is confirmed, a "Cancel Prize" button appears next to the winner info
- Clicking "Cancel Prize" shows a confirmation dialog requiring a reason
- After confirmation, the draw record status changes to 'cancelled'
- The prize level becomes available for re-draw
- The re-draw follows the same availability rules as original draw

### Story 2: Cancel Prize from Ticket Management Screen
**As an** organizer  
**I want to** cancel a winning prize from the Ticket Management screen  
**So that** I can manage prize cancellations from the ticket overview

**Acceptance Criteria:**
- In ticket management, winning tickets show a "Cancel Prize" button
- Clicking shows the same confirmation dialog with reason requirement
- Cancellation updates the draw record and makes prize available for re-draw

### Story 3: Re-draw for Cancelled Prize
**As an** organizer  
**I want to** re-draw for a cancelled prize level  
**So that** a new winner can be selected for that prize

**Acceptance Criteria:**
- After cancellation, a "Re-draw" button appears for that prize level
- Clicking "Re-draw" starts the normal draw process (availability check, etc.)
- All users (including the cancelled winner) are eligible for re-draw
- The new winner replaces the cancelled one in all displays

### Story 4: Audit Trail
**As an** organizer  
**I want to** see why a prize was cancelled  
**So that** I have a record of all prize changes

**Acceptance Criteria:**
- Cancelled draws show the reason in draw history
- Draw history shows "Cancelled" status with reason
- Original winner name is preserved in the record

## Functional Requirements

### Database Changes
1. Add `cancelled_reason` column to `daily_draws` table
2. Add `cancelled_at` timestamp column to `daily_draws` table
3. Status values: 'pending', 'confirmed', 'disqualified', 'cancelled'

### API Changes
1. New endpoint: `POST /api/daily-draws/cancel`
   - Body: `{ draw_id, reason }`
   - Updates status to 'cancelled', sets cancelled_reason and cancelled_at
   - Returns updated draw record

2. Modify `POST /api/daily-draws/create`
   - Allow re-draw for specific prize level
   - Accept optional `prize_level` parameter to target specific prize

### UI Changes
1. **Lucky Draw Screen:**
   - After winner confirmation, show "Cancel Prize" button
   - Clicking shows dialog with reason input field
   - After cancellation, show "Re-draw" button for that prize level
   - Draw history shows cancelled status with reason

2. **Ticket Management Screen:**
   - Winning tickets show "Cancel Prize" button
   - Same dialog and confirmation flow
   - Updated status display

3. **All Display Screens:**
   - Winner name updates automatically after re-draw
   - User Coupon, Winners, Login marquee all reflect new winner

## Non-Functional Requirements
- Cancellation must be immediate and reflected across all screens
- Reason field must be validated (not empty)
- All existing functionality must remain intact
- No data loss - cancelled records preserved for audit

## Success Criteria
- Organizer can cancel any confirmed prize with a reason
- Re-draw follows same availability rules as original draw
- New winner name appears in all display locations
- Draw history shows complete audit trail of cancellations and re-draws
- No breaking changes to existing features

## Constraints & Assumptions
- Only organizers can cancel prizes (role-based access)
- Cancellation is immediate (no undo)
- Re-draw uses same pot mechanism as original draw
- All 9 days follow same cancellation rules

## Out of Scope
- Undo cancellation (once cancelled, it's final)
- Bulk cancellation of multiple prizes
- Automatic re-draw (must be manual)
- Prize level changes (can only re-draw for same level)

## Dependencies
- Existing daily_draws table structure
- Existing API endpoints for draws
- Existing Lucky Draw and Ticket Management screens
