---
task_id: "1"
epic: cancel-prize-redraw
title: Add database columns for cancellation tracking
status: pending
priority: high
dependencies: []
parallel: false
---

# Task 1: Add database columns for cancellation tracking

## Description
Add `cancelled_reason` and `cancelled_at` columns to the `daily_draws` table to support prize cancellation tracking. This provides an audit trail for why prizes were cancelled and when.

## Acceptance Criteria
- [ ] `cancelled_reason` TEXT column added to daily_draws table
- [ ] `cancelled_at` TIMESTAMP column added to daily_draws table
- [ ] Columns allow NULL values (for non-cancelled draws)
- [ ] Existing records remain unchanged
- [ ] Schema update is idempotent (can run multiple times safely)

## Technical Details
```sql
-- Add columns to daily_draws table
ALTER TABLE daily_draws ADD COLUMN cancelled_reason TEXT;
ALTER TABLE daily_draws ADD COLUMN cancelled_at TIMESTAMP;
```

## Testing
- Verify columns exist in database
- Verify existing records still have NULL values
- Verify new draws can be created without these columns
- Verify API still works with new schema

## Notes
- Use ALTER TABLE with IF NOT EXISTS syntax for idempotency
- Columns should be nullable since most draws won't be cancelled
- No data migration needed - existing records stay as-is
