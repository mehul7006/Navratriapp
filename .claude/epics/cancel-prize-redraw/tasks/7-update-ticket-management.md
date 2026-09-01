---
task_id: "7"
epic: cancel-prize-redraw
title: Update Ticket Management screen
status: pending
priority: medium
dependencies: ["5"]
parallel: false
---

# Task 7: Update Ticket Management screen

## Description
Add "Cancel Prize" functionality to the Ticket Management screen, allowing organisers to cancel winning tickets from the ticket overview section.

## Acceptance Criteria
- [ ] "Cancel Prize" button appears on winning tickets
- [ ] Button triggers same cancellation dialog
- [ ] Cancellation updates ticket status
- [ ] Ticket shows "Cancelled" status after cancellation
- [ ] Re-draw option available for cancelled prizes
- [ ] Status display updates correctly

## Technical Details
```dart
// In ticket_management_screen.dart
// In the ticket list item widget
if (ticket['status'] == 'winner')
  Row(
    children: [
      // Existing winner badge
      Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text('WINNER', style: TextStyle(color: Colors.white, fontSize: 10)),
      ),
      SizedBox(width: 8),
      // Cancel button
      IconButton(
        icon: Icon(Icons.cancel, color: Colors.red, size: 20),
        onPressed: () => _showCancelDialog(ticket),
        tooltip: 'Cancel Prize',
      ),
    ],
  ),

// After cancellation
if (ticket['status'] == 'cancelled')
  Container(
    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.orange,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text('CANCELLED', style: TextStyle(color: Colors.white, fontSize: 10)),
  ),
```

## Testing
- Test cancel button appears only for winners
- Test dialog works same as Lucky Draw screen
- Test status updates after cancellation
- Test re-draw option available
- Test both screens stay in sync

## Notes
- Reuse same dialog component from Task 5
- Ensure status colors are consistent
- Consider adding reason tooltip on hover
