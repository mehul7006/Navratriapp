---
task_id: "2"
epic: cancel-prize-redraw
title: Add cancel API endpoint
status: pending
priority: high
dependencies: ["1"]
parallel: false
---

# Task 2: Add cancel API endpoint

## Description
Create a new API endpoint `POST /api/daily-draws/cancel` that allows organisers to cancel a confirmed prize draw. The endpoint should update the draw record status to 'cancelled' and store the cancellation reason and timestamp.

## Acceptance Criteria
- [ ] `POST /api/daily-draws/cancel` endpoint created
- [ ] Accepts `draw_id` and `reason` in request body
- [ ] Updates draw status to 'cancelled'
- [ ] Sets `cancelled_reason` and `cancelled_at` columns
- [ ] Returns updated draw record
- [ ] Validates draw_id exists and is in 'confirmed' status
- [ ] Returns appropriate error messages

## Technical Details
```dart
// In main.dart
app.post('/api/daily-draws/cancel', (Request request) async {
  final body = await request.readAsString();
  final data = jsonDecode(body);
  
  final drawId = data['draw_id'] as int;
  final reason = data['reason'] as String;
  
  // Validate draw exists and is confirmed
  // Update status to 'cancelled'
  // Set cancelled_reason and cancelled_at
  // Return updated record
});
```

## Testing
- Test cancelling a confirmed draw
- Test cancelling a non-existent draw (should fail)
- Test cancelling a draw with empty reason (should fail)
- Test cancelling a draw that's already cancelled (should fail)
- Verify response includes updated draw record

## Notes
- Only allow cancelling draws with status 'confirmed'
- Reason is required and cannot be empty
- Use database transaction for atomicity
