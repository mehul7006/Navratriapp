---
task_id: "6"
epic: cancel-prize-redraw
title: Add re-draw functionality to Lucky Draw
status: pending
priority: high
dependencies: ["4", "5"]
parallel: false
---

# Task 6: Add re-draw functionality to Lucky Draw

## Description
Add the ability to re-draw for a cancelled prize level in the Lucky Draw screen. After a prize is cancelled, a "Re-draw" button should appear that allows organisers to start a new draw for that same prize level.

## Acceptance Criteria
- [ ] "Re-draw" button appears after prize cancellation
- [ ] Button triggers normal draw process (availability check)
- [ ] Re-draw follows same rules as original draw
- [ ] All users (including cancelled winner) are eligible
- [ ] New winner replaces cancelled one in all displays
- [ ] Draw history shows both cancelled and new draw

## Technical Details
```dart
// In lucky_draw_screen.dart
// After cancellation section
if (_currentWinner != null && _currentWinner!['status'] == 'cancelled')
  Padding(
    padding: const EdgeInsets.only(top: 12),
    child: ElevatedButton.icon(
      onPressed: _isRedrawing ? null : () => _startRedraw(),
      icon: _isRedrawing
        ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
        : Icon(Icons.refresh, color: Colors.white),
      label: Text(_isRedrawing ? 'Re-drawing...' : 'Re-draw Prize'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.goldPrimary,
        foregroundColor: AppTheme.purpleDark,
      ),
    ),
  ),

// Method to start re-draw
Future<void> _startRedraw() async {
  setState(() => _isRedrawing = true);
  
  // Get available users for this prize level
  // Start normal draw process (show availability dialog)
  // On confirm: create new draw record
  // On disqualify: mark as disqualified and try again
  
  setState(() => _isRedrawing = false);
}
```

## Testing
- Test re-draw button appears after cancellation
- Test re-draw triggers availability dialog
- Test re-draw works for each prize level
- Test new winner appears in all displays
- Test draw history shows both records

## Notes
- Reuse existing draw creation logic
- Ensure prize level is passed correctly
- Consider adding counter for number of re-draws
