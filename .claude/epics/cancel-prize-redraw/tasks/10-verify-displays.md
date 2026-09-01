---
task_id: "10"
epic: cancel-prize-redraw
title: Verify all displays update correctly
status: pending
priority: medium
dependencies: ["9"]
parallel: false
---

# Task 10: Verify all displays update correctly

## Description
Ensure that after a prize is cancelled and re-drawn, the new winner name appears correctly in all display locations throughout the app.

## Acceptance Criteria
- [ ] User Coupon Screen shows new winner
- [ ] User Winners Screen shows new winner
- [ ] Login Marquee shows new winner
- [ ] Ticket Management shows new winner
- [ ] Lucky Draw History shows both records
- [ ] No stale winner names displayed
- [ ] All displays refresh automatically

## Display Locations to Verify

### 1. User Coupon Screen
- [ ] Prize level badge shows new winner
- [ ] Winner name updated
- [ ] No duplicate entries

### 2. User Winners Screen
- [ ] Winner card shows new winner
- [ ] Prize level correct
- [ ] No duplicate entries

### 3. Login Screen Marquee
- [ ] Yesterday's winners show new winner
- [ ] Marquee scrolls correctly
- [ ] No duplicate entries

### 4. Ticket Management Screen
- [ ] Winning ticket shows new winner
- [ ] Status badge correct
- [ ] Cancel button available for new winner

### 5. Lucky Draw Screen
- [ ] Draw history shows complete trail
- [ ] Cancelled record preserved
- [ ] New draw record created
- [ ] Current winner display updated

## Testing Steps
1. Complete cancel and re-draw flow (Task 9)
2. Navigate to each display location
3. Verify new winner name appears
4. Verify old winner name not shown (unless in history)
5. Check all screens refresh without manual intervention
6. Verify no console errors

## Notes
- Use pull-to-refresh if available
- Check both online and offline states
- Verify data consistency across all screens
- Document any display inconsistencies
