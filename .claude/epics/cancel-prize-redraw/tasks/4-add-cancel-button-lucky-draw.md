---
task_id: "4"
epic: cancel-prize-redraw
title: Modify Lucky Draw screen - add cancel button
status: pending
priority: high
dependencies: ["2", "3"]
parallel: false
---

# Task 4: Modify Lucky Draw screen - add cancel button

## Description
Add a "Cancel Prize" button to the Lucky Draw screen that appears after a winner has been confirmed. This button allows organisers to cancel the winning prize.

## Acceptance Criteria
- [ ] "Cancel Prize" button appears after winner confirmation
- [ ] Button is styled appropriately (red/warning style)
- [ ] Button only shows for confirmed winners
- [ ] Button triggers cancellation dialog
- [ ] Button is disabled during cancellation process
- [ ] Visual feedback when cancellation is in progress

## Technical Details
```dart
// In lucky_draw_screen.dart
// After winner confirmation section
if (_currentWinner != null && _currentWinner!['status'] == 'confirmed')
  Padding(
    padding: const EdgeInsets.only(top: 12),
    child: ElevatedButton.icon(
      onPressed: _isCancelling ? null : () => _showCancelDialog(),
      icon: _isCancelling 
        ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
        : Icon(Icons.cancel, color: Colors.white),
      label: Text(_isCancelling ? 'Cancelling...' : 'Cancel Prize'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
      ),
    ),
  ),
```

## Testing
- Test button appears only for confirmed winners
- Test button triggers dialog
- Test button is disabled during cancellation
- Test button re-enables after cancellation completes

## Notes
- Use existing button styles from the app
- Add loading state for better UX
- Consider adding confirmation step before dialog
