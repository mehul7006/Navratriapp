---
task_id: "8"
epic: cancel-prize-redraw
title: Update draw history display
status: pending
priority: medium
dependencies: ["4"]
parallel: false
---

# Task 8: Update draw history display

## Description
Update the draw history display in Lucky Draw screen to show cancelled status and reason. This provides organisers with a complete audit trail of all draw changes.

## Acceptance Criteria
- [ ] Draw history shows "Cancelled" status
- [ ] Cancelled draws show the reason
- [ ] Cancelled draws show timestamp
- [ ] Visual distinction for cancelled draws
- [ ] Original winner name preserved
- [ ] New winner shown after re-draw

## Technical Details
```dart
// In lucky_draw_screen.dart
// In draw history list item
Container(
  padding: EdgeInsets.all(12),
  decoration: BoxDecoration(
    color: draw['status'] == 'cancelled' 
      ? Colors.orange.withOpacity(0.2)
      : AppTheme.purpleCard.withOpacity(0.5),
    borderRadius: BorderRadius.circular(8),
    border: Border.all(
      color: draw['status'] == 'cancelled' 
        ? Colors.orange 
        : AppTheme.goldPrimary.withOpacity(0.3),
    ),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          // Status badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _getStatusColor(draw['status']),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              draw['status'].toUpperCase(),
              style: TextStyle(color: Colors.white, fontSize: 10),
            ),
          ),
          SizedBox(width: 8),
          // Prize level
          Text('Prize ${draw['prize_level']}', style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
      SizedBox(height: 8),
      // Winner info
      Text('Winner: ${draw['user_name']}', style: TextStyle(color: Colors.white)),
      if (draw['status'] == 'cancelled') ...[
        SizedBox(height: 4),
        Text(
          'Reason: ${draw['cancelled_reason']}',
          style: TextStyle(color: Colors.orange, fontSize: 12),
        ),
        SizedBox(height: 2),
        Text(
          'Cancelled at: ${draw['cancelled_at']}',
          style: TextStyle(color: Colors.grey, fontSize: 11),
        ),
      ],
    ],
  ),
)

// Helper method for status colors
Color _getStatusColor(String status) {
  switch (status) {
    case 'confirmed': return Colors.green;
    case 'disqualified': return Colors.red;
    case 'cancelled': return Colors.orange;
    default: return Colors.grey;
  }
}
```

## Testing
- Test cancelled status displays correctly
- Test reason text shows for cancelled draws
- Test timestamp shows for cancelled draws
- Test visual distinction is clear
- Test original winner name preserved

## Notes
- Use consistent color scheme with rest of app
- Consider adding tooltip with full details
- Ensure text is readable on all backgrounds
